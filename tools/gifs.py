#!/usr/bin/env python3
"""Los GIF de la web: tramos de las grabaciones de openMSX (tools/guiones/*.tcl, grabados con
tools/lanza_graba.ps1 en C-BIOS_MSX1_JP, -bp 0x406B -ram "0xE000 0x1100"), pintados con tools/vdp.py.

Los tramos salen de la RAM grabada: 0xE09A el estado, 0xE0A9 las vidas, 0xE0A8 la ronda, 0xE2B6 los golpes al
robot grande, 0xEB75 las capsulas.

  atraccion  sin tocar nada: la presentacion de CASIO y la demostracion
  gameover   la partida empieza y nadie toca nada: tres vidas perdidas y GAME OVER
  final      con las teclas 0-7 pulsadas al encender (0xE097 = 0: la nave no choca) y un piloto que dispara: la
             estacion entera, las capsulas, la transformacion, el robot grande, el recuento y la ronda 2

Uso: gifs.py docs/imagenes
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vdp          # noqa: E402

# (fichero, grabacion, desde, hasta, cada)
TRAMOS = [
    ("casio.gif", "atraccion", 1, 130, 2),              # la presentacion: cuatro CASIO que se juntan
    ("ronda.gif", "final", 190, 640, 2),                # la ronda empieza: la nave entra y parpadea
    ("disparos.gif", "final", 1500, 1900, 2),           # disparos contra los enemigos y los blancos del suelo
    ("tocado.gif", "gameover", 940, 1060, 2),           # le dan: la explosion y la nave otra vez
    ("game_over.gif", "gameover", 2590, 2900, 2),       # la ultima vida: GAME OVER en sprites
    ("capsulas.gif", "final", 3880, 4270, 2),           # el trozo 6: las tres capsulas
    ("transforma.gif", "final", 7600, 7780, 2),         # el final del mapa: la nave al centro y se transforma
    ("robot.gif", "final", 7930, 8205, 2),              # el robot grande: cinco punetazos
    ("recuento.gif", "final", 8195, 8600, 2),           # el recuento: RATE y BONUS, y la ronda 2
]


def main(salida):
    raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    for fichero, grab, desde, hasta, cada in TRAMOS:
        n, s = vdp.gif(os.path.join(raiz, "work", grab + ".bin"),
                       os.path.join(salida, fichero), desde, hasta, cada=cada, tope_ms=4000)
        print("%-20s %4d imagenes, %5.1f s, %8d bytes" % (
            fichero, n, s, os.path.getsize(os.path.join(salida, fichero))))


if __name__ == "__main__":
    main(sys.argv[1])
