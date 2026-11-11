# The texts

The title writes with tiles of its own: from the BIOS font (CGTABL) it copies only the 24 letters it uses,
"ACEGHIKOPRSTUY0123456789" (0x44E8), to tiles 0x52-0x69, and draws the C in a circle in 0x51. The status line and
GAME OVER are **sprites**: their letters are copied from the font to the sprite drawings (`letra_pinta`, 0x4C73).
The count uses the BIOS font as it is, in the two lower thirds.

| address | original | translation | where it appears |
|---|---|---|---|
| 0x455B | EXOIDE-Z | EXOIDE-Z | the title, in big letters made of tiles |
| 0x46DB | © 1986 CASIO | © 1986 Casio | the title |
| 0x46E7 | HIGHSCORE | High score | the title, with its seven digits |
| 0x46F0 | PUSH TRIGGER 1 | Press button 1 | the title |
| 0x46FE | OR | or | the title |
| 0x4700 | SPACE KEY | the space bar | the title |
| 0x4991 | GAMEOVER | Game over | in sprites, on two lines |
| 0x7509 | RATE | Rate | the count: the broken targets out of every hundred |
| 0x750E | BONUS | Bonus | the count |
| 0x7506 | 100 | 100 | the count, with 100% |
| 0x7516 | 0, 5000 ... 100000 | | the prizes of the count |

The status line has no text: R and the round, the score and the small ship with the lives.
