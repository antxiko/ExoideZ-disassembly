#!/usr/bin/env python3
"""Los mapas enteros de la estacion de las dos primeras rondas, montados como los monta el juego: el trozo 0 y
despues los de la lista de la ronda (la tabla 0x4999, un byte por trozo, la mitad baja su numero, 0xFF al final)
y los de la lista del final (0x4AA5); cada trozo, 8 filas de 32 casillas desempaquetadas de la tabla 0x56B9 (las
ordenes de 0x5645). El scroll los mete por abajo y sube: el primero queda abajo. Las casillas se pintan con los
dibujos y colores que hay en la VRAM grabada en esa ronda (work/final.bin, el primer tercio), sin el
desplazamiento del scroll. La imagen, en cuatro tiras: la primera (a la izquierda) es el principio, abajo.

Uso: mapas.py docs/imagenes
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vdp          # noqa: E402
from PIL import Image  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = open(os.path.join(RAIZ, "exoidez.rom"), "rb").read()
CUADROS = {0: 1000, 1: 9100}          # un cuadro de cada ronda en work/final.bin


def b(a):
    return ROM[a - 0x4000]


def w(a):
    return b(a) | b(a + 1) << 8


def trozo(n):
    hl, out = w(0x56B9 + 2 * (n & 0x0F)), []
    while b(hl):
        orden = b(hl)
        hl += 1
        if orden == 2:
            out += [b(hl + 1)] * b(hl)
            hl += 2
        else:
            out += [b(hl + 1 + k) for k in range(b(hl))]
            hl += 1 + b(hl)
    return out[:256] + [0] * (256 - len(out[:256]))


def lista(a):
    out = []
    while b(a) != 0xFF:
        out.append(b(a))
        a += 1
    return out


def mapa(ronda):
    return [0] + lista(w(0x4999 + 2 * ronda)) + lista(0x4AA5)


def pinta(trozos, vram):
    filas = []
    for t in reversed(trozos):
        c = trozo(t)
        filas += [c[32 * f:32 * f + 32] for f in range(8)]
    im = Image.new("RGB", (256, 8 * len(filas)))
    px = im.load()
    for y, fila in enumerate(filas):
        for x, t in enumerate(fila):
            for r in range(8):
                p, col = vram[t * 8 + r], vram[0x2000 + t * 8 + r]
                for bit in range(8):
                    px[x * 8 + bit, y * 8 + r] = vdp.PALETA[(col >> 4) if p & (0x80 >> bit) else (col & 15)]
    return im


def en_tiras(im, n):
    """El mapa, tan alto, en n tiras puestas de izquierda a derecha: la primera es la de abajo (el principio) y
    cada una se lee de abajo arriba, como sube el scroll."""
    alto = (im.height + n - 1) // n
    out = Image.new("RGB", (n * 256 + (n - 1) * 8, alto), (40, 40, 40))
    for i in range(n):
        abajo = im.height - i * alto
        tira = im.crop((0, max(0, abajo - alto), 256, abajo))
        out.paste(tira, (i * 264, alto - tira.height))
    return out


def main(salida):
    vrams = {}
    for n, c in enumerate(vdp.cuadros(os.path.join(RAIZ, "work", "final.bin"))):
        for r, k in CUADROS.items():
            if n == k:
                vrams[r] = c["vram"]
        if len(vrams) == len(CUADROS):
            break
    for r in CUADROS:
        t = mapa(r)
        im = en_tiras(pinta(t, vrams[r]), 4)
        ruta = os.path.join(salida, "mapa_ronda%d.png" % (r + 1))
        im.save(ruta)
        print("%-16s %d trozos, %d filas" % (os.path.basename(ruta), len(t), 8 * len(t)))


if __name__ == "__main__":
    main(sys.argv[1])
