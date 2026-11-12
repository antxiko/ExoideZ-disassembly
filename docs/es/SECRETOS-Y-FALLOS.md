# Secretos y fallos

Lo que se ha buscado en el código y lo que se ha encontrado. Un fallo solo entra aquí si está comprobado:
ejecutando la propia rutina del juego (`tools/bios.py`) o contra las grabaciones de openMSX.

## Secretos

- **Las teclas 0 a 7 al encender: la nave no choca.** Fuera de los cursores y la barra, la única lectura del teclado de toda la ROM es la
  fila 0 al arrancar (`init`, 0x403D); si las ocho teclas están pulsadas, la nave no choca nunca. Comprobado en openMSX y
  contado en [Curiosidades](CURIOSIDADES.html).
- **El mando lo elige el botón del título.** El juego no lee los cursores y el mando a la vez: si la partida se
  empieza con la barra, juega con el teclado; si con el botón del mando 1, con el mando (0xE098, `titulo_mira`,
  0x47DB). Después solo lee ese (`mandos`, 0x77E8), con un botón.
- **El séptimo premio**, 100.000 puntos con el 100 % de blancos rotos, que la tabla del recuento no esperaba: también
  en [Curiosidades](CURIOSIDADES.html).

## Fallo: el marcador pierde el millón

Los puntos tienen **siete cifras** (0xE0AA), y el récord también, pero el marcador de la partida pinta solo las seis
de la derecha (`puntos_pinta`, 0x4C54, desde 0xE0AB). Ejecutando aquí la suma de puntos del juego y su récord:

| puntos | en el marcador | HIGHSCORE (en el título) |
|---|---|---|
| 999.900 | `999900` | `0999900` |
| 1.000.000 | `000000` | `1000000` |
| 1.234.600 | `234600` | `1234600` |

Quien pase del millón ve el marcador volver a empezar; el récord del título sí lo cuenta.

## Comprobado y correcto

- **Las vidas de más**: a los 5.000 puntos y cada 10.000, mirando si cambia la cifra de las decenas de millar
  (0x4BC9). El premio del recuento entra de cien en cien (`estado_bonus`, 0x7589), así que no se salta ninguna.
- **Los puntos de cada clase** (100, 200, 300, 500 y 1000) se leen hacia atrás desde 0x4C3B, y salen bien.
