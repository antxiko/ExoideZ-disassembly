# Por dentro

## Rehacer la ROM

`make verify` ensambla `src/exoidez.asm` con pasmo y sale la ROM de 16 KB **byte a byte**. `make sanity` comprueba
lo que el reensamblado no cubre: que ningún byte declarado como dato se lea como código, que ningún punto de entrada
caiga en datos y que los 16.384 bytes estén explicados. `make test` pasa las pruebas. La ROM no está en el
repositorio: hay que ponerla en la raíz como `exoidez.rom` (el volcado de GoodMSX, `[!]`, sha1 `3137e676...`).

| | bytes |
|---|---|
| código trazado | 9.611 |
| datos con nombre | 6.773 |
| sin explicar | 0 |

El listado tiene 1.876 comentarios en 4.648 instrucciones (40,4 %), 487 rutinas y etiquetas, ninguna por debajo
del 10 % comentado, y ninguna rutina llamada sin nombre.

## El cartucho

16 KB en la **página 1** (0x4000-0x7FFF), con INIT en 0x4010. Lo que no es código: los trozos de la estación y sus
listas, las órdenes de las casillas y sus colores para cada ronda, las oleadas, los dibujos de los sprites y de las
casillas (algunos empaquetados con una máscara de bits por cada ocho bytes, `desempaqueta`, 0x4055), los textos y
la música.

## La BIOS que usa

WRTVDP para los registros del VDP; SETWRT y el puerto 0x98 directamente para escribir la VRAM (con una espera
entre byte y byte), y FILVRM, LDIRVM, LDIRMV y WRTVRM; GTSTCK, GTTRIG y SNSMAT para los mandos; WRTPSG y RDPSG
para el sonido; y la fuente de la BIOS por su puntero (CGTABL, 0x0004).

## La interrupción, los estados y las tareas

INIT pone un salto a 0x406B en el gancho H.KEYI (0xFD9A) y un `ret` en H.TIMI, y se queda en un `jr $`. La
interrupción corta la del VDP mientras dura, llama al **estado** de 0xE09A (la presentación, el título, la nave que
entra, el final, el recuento...) y cuenta atrás las **23 tareas** (0xEC2D): cuando una llega a cero, salta a su
rutina de la tabla 0x40B7, que vuelve a poner su cuenta (casi todas a 1: cada cuadro).

| tarea | qué hace |
|---|---|
| 0 | el scroll: un tercio de la tabla de nombres escondida |
| 1 | las estrellas |
| 2 | los sprites a la VRAM |
| 3 | la nave: los mandos, los choques, la explosión |
| 4 | los disparos de la nave |
| 5 | las oleadas: salen los enemigos |
| 6 | el mapa: dos filas mas arriba y los trozos nuevos |
| 7 | los enemigos se mueven |
| 8 | los enemigos disparan |
| 9 | sus disparos |
| 10 | los enemigos tocados |
| 11-15 | el robot grande y la nave transformada |
| 16 | las explosiones del suelo |
| 17 | las cápsulas |
| 18 y 20 | los efectos de sonido de los canales A y C |
| 19 | la música |
| 21 | los puntos y la vida de más |
| 22 | la espera de GAME OVER |

## Cómo se ha hecho

El trazado sigue el código desde INIT, la interrupción, las 23 tareas, los estados que se guardan en 0xE09A y
0xE217 y dos tablas de cinco rutinas (las formas de salir y de moverse de los enemigos), declarados en
`src/exoidez.entries`. Lo demás se ha **medido en openMSX** (`tools/omsx_cobertura.tcl`) jugando y esperando la
demostración en un Philips VG 8020: nada de lo que corrió quedó fuera del trazado. Con el cartucho en la página 1
hay que mirar el slot: antes de que entre el cartucho, en 0x4000-0x7FFF está el BASIC, y la medida lo confundía
con el juego.

## La RAM

| | |
|---|---|
| 0xE000-0xE090 | la pieza de música hecha en la RAM |
| 0xE092-0xE096 | las dos tablas de nombres y el registro 2 |
| 0xE097 | la fila 0 del teclado al encender (a 0, la nave no choca) |
| 0xE098 | el teclado (0) o el mando (1) |
| 0xE09A | el estado |
| 0xE09C | la demostración |
| 0xE0A1-0xE0A7 | el récord |
| 0xE0A8 / 0xE0A9 | la ronda / las vidas de reserva |
| 0xE0AA-0xE0B0 | los puntos, siete cifras, una por byte |
| 0xE0B3 / 0xE0B5 | los blancos 0xC8 que había / los rotos |
| 0xE0BA / 0xE0BD | la oleada / el trozo del mapa |
| 0xE0C3 | las veces que se ha escapado el robot grande |
| 0xE0CD | la velocidad de los disparos |
| 0xE219 | la tabla de sprites que va a 0x1F80: la nave, sus disparos, los enemigos |
| 0xE2BD | los ocho enemigos (32 bytes cada uno) |
| 0xE3BF | sus cuatro disparos |
| 0xE3D5-0xE408 | el sonido: los efectos y las dos voces de la música |
| 0xE42D / 0xE44D / 0xE76D | el fondo: las dos copias de la pantalla |
| 0xEA6E | el trozo del mapa desempaquetado |
| 0xEB79 | las tres cápsulas |
| 0xEC2D-0xEC43 | las cuentas de las 23 tareas |
