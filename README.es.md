# Exoide-Z - desensamblado comentado

*(Also [in English](README.md).)*

El desensamblado comentado de **Exoide-Z** (Casio, 1986) para MSX: un cartucho de 16 KB en 0x4000.

- **100 %** del binario explicado: 9.611 bytes de código y 6.773 de datos con nombre, ni un byte sin asignar.
- **40,4 %** del listado comentado, 487 rutinas y etiquetas, ninguna por debajo del 10 % de comentarios.
- El listado se reensambla en la ROM original **byte a byte**.
- El título sale de ejecutar la ROM, cotejado con openMSX; las estaciones, montadas con el propio código de la ROM; las oleadas, las cápsulas, la transformación, el robot grande y el recuento, jugados en GIF; las cinco músicas, de su propio motor de sonido e idénticas a openMSX cuadro a cuadro.

La web: <https://antxiko.github.io/ExoideZ-disassembly/es/>
(en inglés: <https://antxiko.github.io/ExoideZ-disassembly/>).

## Reproducirlo

La imagen de la ROM no se distribuye. Pon la tuya en la raíz como `exoidez.rom` (sha256 `77b1b4dc...`) y ejecuta `make`. El detalle, en [POR DENTRO](docs/es/POR-DENTRO.md).

## Legal

El juego es de Casio y de sus titulares. La licencia de `LICENSE` cubre solo las herramientas, los comentarios, el análisis y la documentación de aquí. Mira [AVISO-LEGAL.md](AVISO-LEGAL.md).
