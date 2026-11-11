# Los textos

El título escribe con casillas propias: copia de la fuente de la BIOS (CGTABL) solo las 24 letras que usa,
"ACEGHIKOPRSTUY0123456789" (0x44E8), a las casillas 0x52-0x69, y dibuja la C en un círculo en la 0x51. El
marcador y GAME OVER van en **sprites**: sus letras se copian de la fuente a los dibujos de los sprites
(`letra_pinta`, 0x4C73). El recuento usa la fuente de la BIOS tal cual, en los dos tercios de abajo.

| dirección | original | traducción | dónde sale |
|---|---|---|---|
| 0x455B | EXOIDE-Z | EXOIDE-Z | el título, en letras grandes de casillas |
| 0x46DB | © 1986 CASIO | © 1986 Casio | el título |
| 0x46E7 | HIGHSCORE | Récord | el título, con sus siete cifras |
| 0x46F0 | PUSH TRIGGER 1 | Pulsa el botón 1 | el título |
| 0x46FE | OR | o | el título |
| 0x4700 | SPACE KEY | la barra espaciadora | el título |
| 0x4991 | GAMEOVER | Fin de la partida | en sprites, en dos líneas |
| 0x7509 | RATE | Porcentaje | el recuento: los blancos rotos de cada cien |
| 0x750E | BONUS | Premio | el recuento |
| 0x7506 | 100 | 100 | el recuento, con el 100 % |
| 0x7516 | 0, 5000 ... 100000 | | los premios del recuento |

El marcador no tiene texto: R y la ronda, los puntos y la nave pequeña con las vidas.
