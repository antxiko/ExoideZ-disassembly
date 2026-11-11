"""Lo que se afirma de la ROM, comprobado contra sus bytes.

Corre con la ROM delante y sin ella: cuando no esta, la imagen se rehace desde
las filas defb/defw del listado, que si viaja con el repositorio. Sin la ROM
solo se comprueba lo que cae en datos.
"""

import os
import re
import subprocess
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))

ROM = os.path.join(RAIZ, "exoidez.rom")
ASM = os.path.join(RAIZ, "src", "exoidez.asm")
NOTAS = os.path.join(RAIZ, "src", "exoidez.notes")
ORG = 0x4000
TAM = 16384

FILA = re.compile(r"^\s+def(b|w)\s+([0-9a-fA-F,h ]+)\s*;\s*([0-9a-f]{4})")


def imagen_desde_el_listado():
    img = bytearray(TAM)
    with open(ASM, encoding="utf-8") as f:
        for ln in f:
            m = FILA.match(ln)
            if not m:
                continue
            ancho, cuerpo, dirr = m.group(1), m.group(2), int(m.group(3), 16)
            p = dirr - ORG
            for tok in cuerpo.split(","):
                tok = tok.strip().rstrip("h")
                if not tok:
                    continue
                v = int(tok, 16)
                if ancho == "b":
                    img[p] = v
                    p += 1
                else:
                    img[p] = v & 0xFF
                    img[p + 1] = v >> 8
                    p += 2
    return bytes(img)


def lee():
    if os.path.exists(ROM):
        with open(ROM, "rb") as f:
            return f.read()
    return imagen_desde_el_listado()


def b(a):
    return lee()[a - ORG]


def w(a):
    rom = lee()
    return rom[a - ORG] | (rom[a - ORG + 1] << 8)


def instruccion(dirr):
    """La instruccion del listado en esa direccion (sin el comentario)."""
    with open(ASM, encoding="utf-8") as f:
        for ln in f:
            m = re.match(r"^\t(\S.*?)\s*;([0-9a-f]{4})", ln)
            if m and int(m.group(2), 16) == dirr:
                return m.group(1).replace("\t", " ").strip()
    return None


class Cabecera(unittest.TestCase):
    def test_ab_e_init_en_0x4010(self):
        rom = lee()
        self.assertEqual(rom[:2], b"AB")
        self.assertEqual(w(0x4002), 0x4010)
        self.assertEqual(rom[4:16], bytes(12))

    def test_son_16_kb(self):
        self.assertEqual(len(lee()), TAM)


class LaInterrupcion(unittest.TestCase):
    def test_va_por_h_keyi(self):
        self.assertEqual([instruccion(a) for a in (0x402A, 0x402D, 0x4030)],
                         ["ld hl,0fd9ah", "ld de,interrupcion", "ld (hl),0c3h"])

    def test_el_bucle_principal_esta_vacio(self):
        self.assertEqual(instruccion(0x4043), "jr bucle_vacio")

    def test_23_tareas(self):
        for k in range(23):
            self.assertTrue(0x4000 <= w(0x40B7 + 2 * k) < 0x8000)
        self.assertEqual(instruccion(0x4081), "ld b,017h")


LETRAS = "ACEGHIKOPRSTUY0123456789"


def texto(a, n):
    s = ""
    for c in lee()[a - ORG:a - ORG + n]:
        s += " " if c == 0 else ("(c)" if c == 0x51 else LETRAS[c - 0x52])
    return s


class LosTextos(unittest.TestCase):
    def test_las_letras_del_titulo(self):
        self.assertEqual(lee()[0x44E8 - ORG:0x4500 - ORG].decode(), LETRAS)

    def test_el_titulo(self):
        self.assertEqual(texto(0x46DB, 12), "(c) 1986 CASIO")
        self.assertEqual(texto(0x46E7, 9), "HIGHSCORE")
        self.assertEqual(texto(0x46F0, 14), "PUSH TRIGGER 1")
        self.assertEqual(texto(0x46FE, 2), "OR")
        self.assertEqual(texto(0x4700, 9), "SPACE KEY")

    def test_en_ascii(self):
        rom = lee()
        self.assertEqual(rom[0x4991 - ORG:0x4999 - ORG], b"GAMEOVER")
        self.assertEqual(rom[0x7506 - ORG:0x7513 - ORG], b"100RATE BONUS")


class ElRecuento(unittest.TestCase):
    def test_los_premios(self):
        rom = lee()
        tramos = [(rom[0x7513 - ORG + 9 * k], rom[0x7516 - ORG + 9 * k:0x751C - ORG + 9 * k].decode())
                  for k in range(7)]
        self.assertEqual(tramos, [(50, "     0"), (60, "  5000"), (70, " 10000"), (80, " 15000"),
                                  (90, " 20000"), (100, " 30000"), (100, "100000")])
        self.assertEqual(instruccion(0x7486), "ld b,006h")    # el bucle mira seis: el 100 % cae en el septimo


class LaNave(unittest.TestCase):
    def test_sin_choques_con_la_fila_0_pulsada(self):
        """0xE097 es la fila 0 del teclado leida al encender; a 0, la nave no choca."""
        self.assertEqual([instruccion(a) for a in (0x403C, 0x403D, 0x4040)],
                         ["xor a", "call 00141h", "ld (0e097h),a"])
        self.assertEqual([instruccion(a) for a in (0x6460, 0x6463, 0x6464)],
                         ["ld a,(0e097h)", "and a", "ret z"])


class Sonido(unittest.TestCase):
    def test_los_tonos(self):
        self.assertEqual(w(0x7E51), 0x357)
        self.assertEqual(w(0x7E51 + 2 * 35), 0x71)


class ElListado(unittest.TestCase):
    def test_densidad_y_flojas(self):
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "densidad.py"), ASM],
            capture_output=True, text=True, check=True).stdout
        m = re.search(r"(\d+) instrucciones, (\d+) comentarios", salida)
        self.assertGreaterEqual(int(m.group(2)) * 100, 40 * int(m.group(1)))
        self.assertIn("---- 0 rutinas por debajo del 10 %", salida)

    def test_ningun_call_sin_nombre(self):
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "sin_bautizar.py"), ASM],
            capture_output=True, text=True, check=True).stdout
        self.assertTrue(salida.startswith("0 rutinas sin bautizar"), salida[:200])

    def test_cada_comentario_en_su_instruccion(self):
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "valida_c.py"), ASM, NOTAS],
            capture_output=True, text=True, check=True).stdout
        self.assertIn("0 fuera de sitio, 0 repetidos", salida)


if __name__ == "__main__":
    unittest.main()
