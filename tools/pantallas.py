"""Las pantallas de Exoide-Z.

  - el titulo: EJECUTANDO la ROM (tools/bios.py: el Z80 con la BIOS que usa): la pantalla de INIT (0x7834), los
    dibujos de las casillas (0x43CD) y el titulo (0x42EF) hasta la espera del boton (0x4398). Las letras las
    copia el juego de la fuente de la BIOS (CGTABL): aqui salen de la VRAM que grabo openMSX con C-BIOS;
  - logotipo.png, la cabecera de la web: EXOIDE-Z del titulo;
  - pantallas de los cuadros que grabo openMSX.

El titulo se coteja con la VRAM grabada (work/partida.bin): el titulo espera el boton dentro de la interrupcion y
no se graba mientras espera; el cuadro 189, el primero despues, aun lo tiene en la pantalla. De ese cuadro salen
tambien las letras de la fuente.

Uso: pantallas.py <dir> [cotejo]
"""
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import vdp                  # noqa: E402
from bios import Msx, SCREEN2        # noqa: E402

RAIZ = os.path.dirname(AQUI)
PANTALLAS = {}


def cuadro(grab, n):
    for i, c in enumerate(vdp.cuadros(os.path.join(RAIZ, "work", grab + ".bin"))):
        if i == n:
            return c


class Exoide(Msx):
    def _bios(self):
        if self.pc == 0x007E:                             # SETGRP: SCREEN 2
            self.vdp.regs[:] = SCREEN2
            self.pc = self._pop()
            return
        super()._bios()


def titulo(fuente):
    rom = open(os.path.join(RAIZ, "exoidez.rom"), "rb").read()
    m = Exoide(rom, 0x4000)
    m.mem[0x0004:0x0006] = bytes([0xBF, 0x1B])           # CGTABL: la fuente en 0x1BBF
    m.mem[0x1BBF:0x1BBF + 0x800] = fuente
    m.llama(0x7834)
    m.llama(0x43CD)
    m.sp = 0xF380
    m.hasta(0x42EF, 0x4398)
    return bytes(m.vdp.vram), bytes(m.vdp.regs)


def fuente_de_la_vram():
    """Las letras que usa el titulo, sacadas de las casillas 0x52-0x69 de la VRAM grabada (el juego las copio de
    la fuente de la BIOS), puestas en su sitio de una fuente de 2 KB."""
    c = cuadro("partida", 189)
    rom = open(os.path.join(RAIZ, "exoidez.rom"), "rb").read()
    letras = rom[0x44E8 - 0x4000:0x4500 - 0x4000]
    f = bytearray(0x800)
    for i, ch in enumerate(letras):
        f[ch * 8:ch * 8 + 8] = c["vram"][(0x52 + i) * 8:(0x52 + i) * 8 + 8]
    return bytes(f)


def cotejo(v, regs):
    for n, c in enumerate(vdp.cuadros(os.path.join(RAIZ, "work", "partida.bin"))):
        if c["vram"][0x1800:0x1B00] == v[0x1800:0x1B00] and c["regs"][1] & 0x40:
            break
    t1, t2 = vdp.tela(v, regs, False), vdp.tela(c["vram"], c["regs"], False)
    puntos = sum(1 for y in range(192) for x in range(256) if t1[y][x] != t2[y][x])
    print("titulo contra partida/%d: puntos distintos %d de 49152; registros %s"
          % (n, puntos, "iguales" if regs == bytes(c["regs"]) else "%s / %s" % (regs.hex(), bytes(c["regs"]).hex())))
    return n, puntos


def main(argv):
    fuente = fuente_de_la_vram()
    v, regs = titulo(fuente)
    vdp.imagen(v, regs, 2, con_sprites=False).save(os.path.join(argv[0], "titulo.png"))
    vdp.imagen(v, regs, 4, con_sprites=False).crop((0, 112, 1024, 360)).save(os.path.join(argv[0], "logotipo.png"))
    for f, (g, n) in PANTALLAS.items():
        c = cuadro(g, n)
        vdp.imagen(c["vram"], c["regs"], 2).save(os.path.join(argv[0], f))
    if len(argv) > 1:
        cotejo(v, regs)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
