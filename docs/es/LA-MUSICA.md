# La música

Cinco músicas, a dos voces. No están grabadas a mano: `tools/musica.py` **ejecuta el propio motor de sonido de la
ROM** con `tools/z80run.py` -la tarea de la música (`tarea_musica`, 0x4C89), cuadro a cuadro, con los dos números
que pone el juego- y apunta lo que escribe en el PSG por la BIOS (WRTPSG; para bajar el volumen lee con RDPSG).

**Cotejadas con openMSX**: los registros de tono y de volumen coinciden con los grabados, **0 distintos** en
todos los cuadros mirados salvo uno, el primero de la música del final, en que se corta un efecto del canal A. Se
grabaron cuatro veces (`tools/guiones/`): sin tocar nada, una partida a ciegas, una partida sin tocar nada hasta
GAME OVER y la estación entera. Cada cuadro grabado se empareja con el del motor que tiene la misma RAM en las dos
voces; el motor arranca con la RAM de la música como la tenía el juego. Mientras giran las cápsulas o suena la vida
de más, su sonido para la música y calla el canal B: esos cuadros no se miran.

Los efectos de sonido no están aquí: los disparos, las explosiones, las cápsulas, la vida de más y los demás.

## El motor

Va en la interrupción, en la tarea 19 (`tarea_musica`, 0x4C89): dos **voces**, cada una con un bloque de 9 bytes
que se copia a un bloque de trabajo (0xE3E4), da un paso y vuelve. La primera toca en el canal B las piezas de la
lista 0x7E99; la segunda, en el canal C (en el A si es la 3) las de la lista 0x7FC7. El juego no pide la música:
escribe los números de las dos voces (0xE3F2 y 0xE3FB) y la tarea empieza sus piezas (`musica`, 0x7D49). Una pieza
es una lista de parejas (duración, nota); la nota 0 es silencio y las otras, el tono de la tabla 0x7E51 (36 notas).
Una lista acaba en 0xFFFF o vuelve a empezar con 0x0000. Una de las piezas de la segunda voz no está en la ROM:
la monta en la RAM, en 0xE000, la rutina 0x7FAE al encender (72 notas de un cuadro).

| | Las dos voces | Quién la pone | Duración |
|---|---|---|---:|
| la ronda empieza | 1 y 1 | la nave entra (0x4882) | 6,0 s |
| la ronda | 2 | la nave ya está (0x62E8) | 5,1 s y vuelve a empezar |
| el final | 4 y 3 | el final de la estación y el robot grande (0x5686, 0x715C) | 7,3 s y vuelve |
| el recuento | 3 y 2 | RATE y BONUS (0x74AC) | 3,2 s |
| GAME OVER | 5 | sin vidas (0x495E) | 5,0 s y vuelve |

## La ronda empieza

<audio controls src="../audio/musica_ronda_entra.mp3"></audio>

## La ronda

<audio controls src="../audio/musica_ronda.mp3"></audio>

## El final

<audio controls src="../audio/musica_final.mp3"></audio>

## El recuento

<audio controls src="../audio/musica_recuento.mp3"></audio>

## GAME OVER

<audio controls src="../audio/musica_game_over.mp3"></audio>
