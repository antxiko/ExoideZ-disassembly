#!/usr/bin/env python3
"""Los sprites de Exoide-Z MONTADOS DESDE LA ROM (ninguna imagen es una captura).

Los dibujos de los sprites los hace el propio juego en la VRAM, con espejos (los bits al reves), mitades cambiadas y
copias volteadas: `pantalla_pon` (0x7834) y `sprites_3c00` (0x78D8). Aqui se EJECUTAN las dos rutinas de la ROM con el
Z80 de tools/bios.py y se toma lo que dejan en 0x3800-0x3FFF (el marcador, 0x3F40-0x3FFF, lo pinta despues el juego
con las letras de la BIOS y no se usa aqui). Los sprites son de 16 x 16.

  nave_sprites.png   la nave (0x00 en blanco y su sombra 0x04 en azul celeste, 0x6276), la nave cambiada (0x80 y 0x84
                     debajo, en blanco, con la sombra 0x88 tres puntos mas abajo; `estado_transforma` 0x67BA) y
                     golpeando (0x98 con el brazo 0xA8 encima, o 0x9C con 0xB0; `tarea_robot_golpe` 0x6898), la
                     explosion de la nave (0xD8, 0xDC, 0xE0 y 0xE4 en amarillo oscuro, 0x63D2), su disparo (0x08,
                     blanco) y el de los enemigos (0xD4, rojo oscuro)
  enemigos.png       los enemigos: el dibujo (la clase & 0xFC) + 0x0C y el color de 0x6A05 por la clase & 3 (gris,
                     azul celeste, amarillo oscuro, magenta) (`sale_sprite`, 0x69E4); tocados, 0xDC y 0xE0 en blanco
                     (`tarea_tocados`); y las capsulas (0x6C-0x7C, negras)
  robot_grande.png   el robot grande del final, cuatro sprites (0x70BD): 0x8C con 0x90 encima en el color de la ronda
                     (0x70CD: azul, verde, rojo oscuro, gris) y 0x94 en rojo oscuro; moviendo los brazos, 0xA0 con 0xAC
                     debajo o 0xA4 con 0xB4 (`tarea_robot_grande_brazo`, 0x733D)
  explosion_cuadros.gif  la nave estallando (0xD8 + 4 cada 8 cuadros, tres veces) y un enemigo tocado (0xDC al cuadro
                     3, 0xE0 al 11, fuera al 19)
  robot_cuadros.gif  el robot grande: los brazos 12 cuadros, uno y otro, y quieto 96

Uso: hojas.py docs/imagenes | hojas.py cotejo
"""
import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))
import vdp          # noqa: E402

ORG = 0x4000
ROM = open(os.path.join(RAIZ, "exoidez.rom"), "rb").read()
FONDO = (96, 96, 104)            # gris, para que se vean las capsulas negras
_PAT = None


def b(a):
    return ROM[a - ORG]


def patrones():
    """Los 0x800 bytes de 0x3800 que dejan `pantalla_pon` (0x7834) y `sprites_3c00` (0x78D8) EJECUTADAS."""
    global _PAT
    if _PAT is None:
        from pantallas import Exoide
        m = Exoide(ROM, ORG)
        m.llama(0x7834)
        m.llama(0x78D8)
        _PAT = bytes(m.vdp.vram[0x3800:0x4000])
    return _PAT


def primeros():
    """Lo que deja `pantalla_pon` sola, antes de `sprites_3c00`."""
    from pantallas import Exoide
    global _PRIMEROS
    if _PRIMEROS is None:
        m = Exoide(ROM, ORG)
        m.llama(0x7834)
        _PRIMEROS = bytes(m.vdp.vram[0x3800:0x4000])
    return _PRIMEROS


_PRIMEROS = None


def pinta(im, pat, n, x, y, color, escala=1):
    if color == 0:
        return
    n &= 0xFC
    d = pat[n * 8:n * 8 + 32]
    c = vdp.PALETA[color]
    for fila in range(16):
        for col in range(16):
            if (d[fila + (16 if col >= 8 else 0)] >> (7 - (col & 7))) & 1:
                for ey in range(escala):
                    for ex in range(escala):
                        px, py = (x + col) * escala + ex, (y + fila) * escala + ey
                        if 0 <= px < im.width and 0 <= py < im.height:
                            im.putpixel((px, py), c)


def grupo(im, pat, sprites, x, y, E):
    """Sprites (dy, dx, dibujo, color); el primero, encima."""
    for dy, dx, n, c in reversed(sprites):
        pinta(im, pat, n, x + dx, y + dy, c, E)


NAVE = [(0, 0, 0x00, 15), (0, 0, 0x04, 7)]                         # 0x6276: la nave y su sombra
CAMBIADA = [(0, 0, 0x80, 15), (16, 0, 0x84, 15), (3, 0, 0x88, 7)]   # 0x67D7 y la sombra de 0x6272


def golpe(otro):
    """tarea_robot_golpe: el cuerpo (0x98 o 0x9C) y el brazo (0xA8 o 0xB0) 16 puntos encima, blanco."""
    cuerpo, brazo = (0x9C, 0xB0) if otro else (0x98, 0xA8)
    return [(0, 0, cuerpo, 15), (16, 0, 0x84, 15), (-16, 0, brazo, 15), (3, 0, 0x88, 7)]


def enemigo(clase):
    """sale_sprite (0x69E4): (dibujo, color)."""
    return (clase & 0xFC) + 0x0C, b(0x6A05 + (clase & 3))


def robot(ronda, brazos=None):
    """Los cuatro sprites del robot grande (0x70BD: el de abajo, 0x8C, 0x90 encima y 0x94), con el color de la ronda
    (0x70CD) en los tres primeros y el 6 en el 0x94; con brazos (0 o 1), el de abajo y el 0x8C cambian."""
    c = b(0x70CD + (ronda & 3))
    abajo, cuerpo = (0, 0), (0x8C, c)
    if brazos is not None:
        h, l = (0xA4, 0xB4) if brazos else (0xA0, 0xAC)
        abajo, cuerpo = (l, c), (h, c)
    return [(16, 0, abajo[0], abajo[1]), (0, 0, cuerpo[0], cuerpo[1]), (-16, 0, 0x90, c), (0, 0, 0x94, 6)]


def hoja(Image):
    pat, E = patrones(), 4
    im = Image.new("RGB", (8 * 24 * E, 2 * 44 * E), FONDO)
    grupo(im, pat, NAVE, 4, 20, E)
    grupo(im, pat, CAMBIADA, 28, 8, E)
    grupo(im, pat, golpe(0), 52, 20, E)
    grupo(im, pat, golpe(1), 76, 20, E)
    for k in range(4):
        pinta(im, pat, 0xD8 + 4 * k, 4 + 24 * k, 64, 10, E)
    pinta(im, pat, 0x08, 4 + 24 * 4, 64, 15, E)
    pinta(im, pat, 0xD4, 4 + 24 * 5, 64, 6, E)
    return im


def hoja_enemigos(Image):
    pat, E = patrones(), 4
    im = Image.new("RGB", (8 * 20 * E, 6 * 20 * E), FONDO)
    for fila in range(5):
        for k in range(4):
            d, c = enemigo(4 * fila + k)
            pinta(im, pat, d, 2 + 20 * k, 2 + 20 * fila, c, E)
    for k, d in enumerate((0xDC, 0xE0)):
        pinta(im, pat, d, 2 + 20 * (5 + k), 2, 15, E)
    for k in range(5):
        pinta(im, pat, 0x6C + 4 * k, 2 + 20 * k, 102, 1, E)
    return im


def hoja_robot(Image):
    pat, E = patrones(), 3
    im = Image.new("RGB", (4 * 3 * 24 * E, 56 * E), FONDO)
    for ronda in range(4):
        for k, brazos in enumerate((None, 0, 1)):
            grupo(im, pat, robot(ronda, brazos), 4 + 24 * (3 * ronda + k), 20, E)
    return im


def anima(Image):
    pat, E, cuadros = patrones(), 4, []
    for n in range(3 * 32):
        im = Image.new("RGB", (2 * 24 * E, 24 * E), FONDO)
        pinta(im, pat, 0xD8 + 4 * ((n // 8) % 4), 4, 4, 10, E)
        t = n % 32
        if t < 3:
            d = None
        elif t < 11:
            d = 0xDC
        elif t < 19:
            d = 0xE0
        else:
            d = None
        if t < 3:
            dd, cc = enemigo(4)
            pinta(im, pat, dd, 28, 4, cc, E)
        elif d:
            pinta(im, pat, d, 28, 4, 15, E)
        cuadros.append(im)
    return cuadros


def anima_robot(Image):
    pat, E, cuadros = patrones(), 3, []
    for vuelta in range(4):
        for n in range(12 + 96):
            im = Image.new("RGB", (24 * E, 56 * E), FONDO)
            grupo(im, pat, robot(0, vuelta & 1 if n < 12 else None), 4, 20, E)
            cuadros.append(im)
    return cuadros


def guarda_gif(cuadros, ruta, ms=1000 / 60):
    imgs, durs = [], []
    for im in cuadros:
        if imgs and list(im.getdata()) == list(imgs[-1].getdata()):
            durs[-1] += ms
        else:
            imgs.append(im)
            durs.append(ms)
    imgs[0].save(ruta, save_all=True, append_images=imgs[1:], duration=[max(20, int(round(d))) for d in durs],
                 loop=0, disposal=1)


def cotejo():
    """Contra las grabaciones de openMSX (work/*.bin, la RAM 0xE000-0xF0FF):
    1) la tabla de dibujos de los sprites (VRAM 0x3800-0x3F3F) contra la de la ROM ejecutada; aparte, los cuadros
       con GAME OVER (sus letras en 0x3D20-0x3D9F);
    2) en la tabla de sprites de la RAM (0xE219, 32 sprites), la nave: el sprite 0 con 0x00 en blanco y su sombra
       (el 25) con 0x04 en azul celeste en el mismo sitio; la nave cambiada: 0x80 (o 0x98/0x9C golpeando) y 0x84 16
       puntos mas abajo, con la sombra 0x88 tres puntos mas abajo;
    3) los enemigos vivos (0xE2BD, 32 bytes; el estado 1): su sprite (0xE245 + 4 x el numero) con el dibujo y el
       color de su clase (+1);
    4) el robot grande (los sprites 11-14): 0x90 16 puntos encima, 0x94 en color 6 en el mismo sitio, y 0x8C o los
       brazos."""
    pat = patrones()
    tot = dict(patrones=0, game_over=0, sin_3c00=0, pat_mal=0, nave=0, nave_sombra0=0, nave_mal=0, cambiada=0,
               cambiada_entra=0, cambiada_mal=0, enemigos=0,
               enemigos_mal=0, robot=0, robot_mal=0)
    validos_enemigo = {enemigo(k) for k in range(32)}
    for grab in ("atraccion", "partida", "final", "gameover"):
        ruta = os.path.join(RAIZ, "work", grab + ".bin")
        if not os.path.exists(ruta):
            continue
        for c in vdp.cuadros(ruta):
            v, ram = c["vram"], c["ram"]
            t = v[0x3800:0x3F40]
            if any(t):
                if t == pat[:0x740]:
                    tot["patrones"] += 1
                elif t[:0x520] == pat[:0x520] and t[0x5C0:] == pat[0x5C0:0x740]:
                    tot["game_over"] += 1               # las letras de GAME OVER en 0x3D20-0x3DBF (0x4953)
                elif t == primeros()[:0x740]:
                    tot["sin_3c00"] += 1                # aun sin `sprites_3c00` (la presentacion)
                else:
                    tot["pat_mal"] += 1
            s = [tuple(ram[0x219 + 4 * k:0x21D + 4 * k]) for k in range(32)]
            if s[0][0] < 0xC0 and s[0][2] == 0x00 and s[0][3] == 15:
                if s[25][:2] == s[0][:2] and s[25][2:] == (0x04, 7):
                    tot["nave"] += 1
                elif s[25][:2] == s[0][:2] and s[25][2:] == (0x04, 0):
                    tot["nave_sombra0"] += 1            # al final del mapa, la sombra transparente (`estado_fin_mapa`)
                else:
                    tot["nave_mal"] += 1
            if s[0][0] < 0xC0 and s[0][2] in (0x80, 0x98, 0x9C) and s[0][3] == 15:
                ok = (s[1][2:] == (0x84, 15) and s[1][1] == s[0][1] and (s[1][0] - s[0][0]) & 0xFF == 16
                      and s[25][2:] == (0x88, 7) and (s[25][0] - s[0][0]) & 0xFF in (3, 4))
                if ok:
                    tot["cambiada"] += 1
                elif ram[0x09A] | ram[0x09B] << 8 == 0x6286:
                    tot["cambiada_entra"] += 1          # entrando (`nave_entra`): las piezas aun separadas
                elif ram[0x09A] | ram[0x09B] << 8 == 0x67BA:
                    tot["cambiada_entra"] += 1          # cambiando (`estado_transforma`): las piezas se separan
                else:
                    tot["cambiada_mal"] += 1
            for k in range(8):
                e = ram[0x2BD + 32 * k:0x2DD + 32 * k]
                if e[0] != 1:
                    continue
                y, x, d, col = s[11 + k]             # el enemigo k, el sprite 0xE245 + 4 k (`tarea_enemigos`)
                if y >= 0xC0:
                    continue
                ok = (d, col & 15) in validos_enemigo
                tot["enemigos"] += ok
                tot["enemigos_mal"] += not ok
            if s[12][2] in (0x8C, 0xA0, 0xA4) and s[12][0] < 0xC0 and s[14][2] == 0x94:
                ok = ((s[13][0] - s[12][0]) & 0xFF == 0xF0 and s[13][2] == 0x90 and s[14][:2] == s[12][:2]
                      and (s[11][0] - s[12][0]) & 0xFF == 16 and s[14][3] in (0, 6) and
                      (s[12][2] == 0x8C or s[11][2] == {0xA0: 0xAC, 0xA4: 0xB4}[s[12][2]]))
                tot["robot"] += ok
                tot["robot_mal"] += not ok
    return tot


def main(argv):
    if argv and argv[0] == "cotejo":
        print(cotejo())
        return 0
    from PIL import Image
    salida = argv[0]
    os.makedirs(salida, exist_ok=True)
    hoja(Image).save(os.path.join(salida, "nave_sprites.png"))
    hoja_enemigos(Image).save(os.path.join(salida, "enemigos.png"))
    hoja_robot(Image).save(os.path.join(salida, "robot_grande.png"))
    guarda_gif(anima(Image), os.path.join(salida, "explosion_cuadros.gif"))
    guarda_gif(anima_robot(Image), os.path.join(salida, "robot_cuadros.gif"))
    for f in ("nave_sprites.png", "enemigos.png", "robot_grande.png", "explosion_cuadros.gif", "robot_cuadros.gif"):
        print(f, os.path.getsize(os.path.join(salida, f)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
