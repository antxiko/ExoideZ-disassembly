#!/usr/bin/env python3
"""Las musicas de Exoide-Z, EJECUTANDO su propio motor de sonido (ver motor_musica.py).

El motor va en la tarea 19 de la interrupcion (`tarea_musica`, 0x4C89), una vez por cuadro: dos voces, la primera
en el canal B (su numero en 0xE3F2, las piezas de 0x7E99) y la segunda en el C (0xE3FB, las piezas de 0x7FC7; la
3 va en el canal A). No hay rutina de peticion: el juego escribe los dos numeros y la tarea empieza las piezas.
Aqui se ponen los dos numeros como los pone el juego en cada momento y se corre la tarea cuadro a cuadro; el motor
llega al PSG por la BIOS (WRTPSG, y RDPSG para bajar el volumen), que se atrapa. Antes se corre 0x7FAE, que
pone en la RAM (0xE000) las 72 notas de un cuadro de la pieza que la lista 0x7FC7 tiene alli.

Uso:  musica.py registros N [cuadros] | mp3 N f.mp3 | todas docs/audio | cotejo
"""
import hashlib
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (numero, fichero, quien la pide, (0xE3F2, 0xE3FB))
MUSICAS = [
    (1, "musica_ronda_entra.mp3", "la ronda empieza: la nave entra (0x4882)", (1, 1)),
    (2, "musica_ronda.mp3", "la ronda, cuando la nave ya esta (0x62E8)", (2, 0)),
    (3, "musica_final.mp3", "el final del mapa y el robot grande (0x5686, 0x715C)", (4, 3)),
    (4, "musica_recuento.mp3", "el recuento: RATE y BONUS (0x74AC)", (3, 2)),
    (5, "musica_game_over.mp3", "GAME OVER (0x495E)", (5, 0)),
]
VOCES = (0xE3F2, 0xE404)          # los dos bloques de 9 bytes de las voces


def cfg(numero):
    b, c = next(m[3] for m in MUSICAS if m[0] == numero)
    return dict(rom="exoidez.rom", org=0x4000, sp=0xF380, frame=0x4C89, pide=0x40B6,
                ram0=((0xE3F2, b), (0xE3FB, c)), init=((0x7FAE, {}),), ram=VOCES, hz=60, max_s=120, cuadros_previos=0)


def rom():
    return open(os.path.join(RAIZ, "exoidez.rom"), "rb").read()


def ejecuta(numero, maximo=None):
    c = cfg(numero)
    maximo = maximo or c["hz"] * c["max_s"]
    z = motor_musica.arranca(c, rom(), numero)
    a, b = c["ram"]
    cuadros, vistos = [], {}
    for k in range(maximo):
        cuadros.append(motor_musica.cuadro(z))
        h = hashlib.sha1(bytes(z.mem[a:b])).digest()
        if h in vistos:
            return cuadros, (None if vistos[h] == k else vistos[h])
        vistos[h] = k + 1
        if z.mem[0xE3F2] == 0 and z.mem[0xE3FB] == 0 and z.mem[0xE3F3] == 0 and z.mem[0xE3FC] == 0:
            return cuadros, None
    return cuadros, None


def mp3(numero, ruta):
    hz = 60
    cuadros, vuelta = ejecuta(numero)
    todo, fundido = motor_musica.desarrolla(cuadros, vuelta, hz)
    motor_musica.a_mp3(motor_musica.sintetiza(todo, hz), ruta, fundido, hz)
    print("%-26s %d cuadros (%.1f s), vuelve al %s" % (os.path.basename(ruta), len(cuadros),
                                                      len(cuadros) / hz, vuelta))


def estados(numero, maximo, inicio, siembra=None):
    """Cada cuadro del motor ejecutado: la RAM de las voces y los registros del PSG (desde los de `inicio`).
    `siembra`: la RAM de la musica (0xE3E1-0xE408) como la tenia el juego en ese cuadro (lo que dejo lo anterior)."""
    c = cfg(numero)
    z = motor_musica.arranca(c, rom(), numero)
    if siembra:
        z.mem[0xE3E1:0xE409] = siembra
    a, b = c["ram"]
    regs = list(inicio)
    out = [(bytes(z.mem[a:b]), tuple(regs))]
    for _ in range(maximo):
        for r, v in motor_musica.cuadro(z):
            if r < 16:
                regs[r] = v
        out.append((bytes(z.mem[a:b]), tuple(regs)))
    return out


def cotejo():
    """Los tonos y los volumenes del motor ejecutado contra los del PSG que grabo openMSX al entrar en cada
    interrupcion (work/*.bin, con la RAM 0xE000-0xF0FF). La musica empieza en el cuadro en que los dos numeros
    (0xE3F2, 0xE3FB) pasan a ser los suyos; cada cuadro grabado se empareja con el cuadro del motor que tiene la
    MISMA RAM en las dos voces (0xE3F2, 18 bytes); el motor arranca con la RAM del sonido como la tenia el juego y se miran el canal B (registros 2, 3 y 9) y el de la segunda
    voz (C, o A con la 3: 4, 5 y 10 o 0, 1 y 8) mientras no suena un efecto en el (0xE3D5 / 0xE3DB a 0x0F),
    mientras los dos numeros siguen siendo los suyos y antes de que vuelva la presentacion; mientras giran
    las capsulas o suena la vida de mas (0xEB77, 0xE299) su sonido para la musica y calla el canal B: no se mira,
    ni despues el registro que dejo hasta que el motor lo vuelve a escribir."""
    import vdp
    out = []
    for grab in ("atraccion", "partida", "final", "gameover"):
        ruta = os.path.join(RAIZ, "work", grab + ".bin")
        if not os.path.exists(ruta):
            continue
        cs = list(vdp.cuadros(ruta, 0x1100))
        par = lambda k: (cs[k]["ram"][0x3F2], cs[k]["ram"][0x3FB])
        for numero, fichero, _, pareja in MUSICAS:
            k0 = next((k for k in range(1, len(cs)) if par(k) == pareja and par(k - 1) != pareja), None)
            if k0 is None:
                continue
            emu = estados(numero, 60 * 60, cs[k0]["psg"], bytes(cs[k0]["ram"][0x3E1:0x409]))
            e, malos, mirados, sueltos, sucios = 0, [], 0, 0, set()
            canal2 = (0, 1, 8) if pareja[1] == 3 else (4, 5, 10)
            for j in range(k0 + 1, min(len(cs), k0 + 60 * 40)):
                ram = bytes(cs[j]["ram"][0x3F2:0x404])
                if par(j) != pareja or (cs[j]["ram"][0x09A] | cs[j]["ram"][0x09B] << 8) in (0x40E5, 0x411C, 0x415E, 0x42EF):
                    break
                if cs[j]["ram"][0xB77] or cs[j]["ram"][0x299]:
                    sucios = set(range(11))   # su sonido toca los canales: hasta que el motor los escriba
                    continue        # las capsulas girando o la vida de mas: su sonido para la musica
                hallado = next((x for x in range(e, min(e + 8, len(emu))) if emu[x][0] == ram), None)
                if hallado is None:
                    sueltos += 1
                    continue
                for x in range(e + 1, hallado + 1):
                    sucios -= {k for k in range(11) if emu[x][1][k] != emu[x - 1][1][k]}
                e = hallado
                mirados += 1
                p, r = cs[j]["psg"], emu[e][1]
                efecto = cs[j]["ram"][0x3D5] != 0x0F if canal2[2] == 8 else cs[j]["ram"][0x3DB] != 0x0F
                mirar = [(2, 3, 9)] + ([] if efecto else [canal2])
                def distinto(t, a, v):
                    if v in sucios:
                        return False
                    if p[v] != r[v]:
                        return True
                    return bool(p[v] & 0x1F) and (p[t] != r[t] or (p[a] & 15) != (r[a] & 15))
                if any(distinto(*c) for c in mirar):
                    malos.append(j - k0)
            out.append((fichero, grab, k0, mirados, malos, sueltos))
    return out


def main(argv):
    if argv and argv[0] == "cotejo":
        for fichero, grab, k0, mirados, malos, sueltos in cotejo():
            print("%-26s %s, empieza en el cuadro %d: %d cuadros mirados, %d distintos %s; %d sin pareja"
                  % (fichero, grab, k0, mirados, len(malos), malos[:8], sueltos))
        return 0
    if argv and argv[0] == "todas":
        os.makedirs(argv[1], exist_ok=True)
        for numero, fichero, _, _ in MUSICAS:
            mp3(numero, os.path.join(argv[1], fichero))
        return 0
    if argv and argv[0] == "mp3":
        mp3(int(argv[1]), argv[2])
        return 0
    if argv and argv[0] == "registros":
        cuadros, vuelta = ejecuta(int(argv[1]), int(argv[2]) if len(argv) > 2 else None)
        for i, escr in enumerate(cuadros):
            print("%5d %s" % (i, " ".join("%X=%02X" % rv for rv in escr)))
        print("cuadros: %d, vuelve al %s" % (len(cuadros), vuelta))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
