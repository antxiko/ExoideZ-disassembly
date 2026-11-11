# Curiosidades

## Las teclas 0-7 al encender: la nave no choca

Al arrancar, el juego lee la fila 0 del teclado (las teclas 0 a 7) y la guarda en 0xE097 (`init`, 0x403D). Antes de
mirar si la nave choca, mira ese byte: si es 0, no choca nunca (`nave_choca`, 0x6460). Con el teclado suelto la
fila vale 0xFF; solo es 0 si las ocho teclas están pulsadas al encender. **Comprobado en openMSX**
(`tools/guiones/final.tcl`): con las ocho pulsadas al encender, 0xE097 queda a 0 y la nave cruza la estación entera,
las cápsulas, el robot grande y el recuento sin perder una vida. Ningún texto lo dice.

## Todo el juego en la interrupción

El programa principal es un `jr $` que salta a sí mismo para siempre (0x4043). Todo lo demás va en la interrupción
(el gancho H.KEYI): el estado del momento, guardado en 0xE09A, y 23 **tareas** con cuenta atrás que se llaman
cuando su cuenta llega a cero (la tabla 0x40B7). Hasta el título espera el botón dentro de la interrupción: mientras
espera, para el juego no pasa ningún cuadro, y en la grabación de openMSX tampoco.

## El marcador son sprites

Los puntos, la R de la ronda y las vidas no son casillas: son ocho sprites cuyas letras se copian de la fuente de
la BIOS a sus dibujos (0x3F40-0x3FFF) cada vez que cambian (`puntos_pinta`, 0x4C54). La pantalla queda entera para
la estación. GAME OVER también va en sprites.

## Una pieza de música hecha en la RAM

La lista de piezas de la segunda voz (0x7FC7) tiene una pieza en 0xE000, en la RAM: al encender, la rutina 0x7FAE
la llena con cuatro grupos de 18 notas de un cuadro. El cotejo con openMSX solo casa si se corre antes esa rutina.

## El robot que se escapa endurece la partida

Si el robot grande llega abajo sin romperse, se va y la estación empieza otra vez, y el juego lo cuenta (0xE0C3). A
la cuarta, los enemigos disparan el doble de deprisa y no solo hacia abajo (`tarea_enemigos_disparan`, 0x6F33). El
recuento pone la cuenta a cero.

## El séptimo premio

El recuento busca el premio en una tabla de tramos con un bucle de seis (0x7486), pero la tabla tiene siete: con el
100 % de blancos rotos no cabe en ninguno de los seis y se queda en el séptimo, **100.000** puntos, más del triple
del de 90 %.

## Lo que no hace nada

Tres instrucciones a las que no salta nadie en 0x7B9F (`call` y `jr` que nunca corren).
