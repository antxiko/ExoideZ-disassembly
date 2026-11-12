# Secrets and bugs

What was searched for in the code and what was found. A bug only goes here if it has been checked: by running the
game's own routine (`tools/bios.py`) or against the openMSX recordings.

## Secrets

- **Keys 0 to 7 at power-on: the ship does not crash.** Apart from the cursor keys and the space bar, the only keyboard read in the whole ROM is row 0 at
  start-up
  (`init`, 0x403D); if all eight keys are held, the ship never crashes. Checked in openMSX and told in
  [Curiosities](CURIOSITIES.html).
- **The title button chooses the controller.** The game does not read the cursor keys and the joystick together: if
  the game is started with the space bar, it plays with the keyboard; with button 1 of joystick 1, with the joystick
  (0xE098, `titulo_mira`, 0x47DB). After that it reads only that one (`mandos`, 0x77E8), with one button.
- **The seventh prize**, 100,000 points with 100 % of the targets destroyed, which the count's table did not expect:
  also in [Curiosities](CURIOSITIES.html).

## Bug: the scoreboard loses the million

The score has **seven digits** (0xE0AA), and so does the high score, but the in-game scoreboard only draws the six on
the right (`puntos_pinta`, 0x4C54, from 0xE0AB). Running the game's score addition and its high score here:

| score | on the scoreboard | HIGHSCORE (on the title) |
|---|---|---|
| 999,900 | `999900` | `0999900` |
| 1,000,000 | `000000` | `1000000` |
| 1,234,600 | `234600` | `1234600` |

Whoever goes past a million sees the scoreboard start again; the high score on the title does count it.

## Checked and correct

- **The extra lives**: at 5,000 points and every 10,000, by checking whether the ten-thousands digit changes (0x4BC9).
  The count's bonus goes in a hundred at a time (`estado_bonus`, 0x7589), so none is skipped.
- **The points of each class** (100, 200, 300, 500 and 1000) are read backwards from 0x4C3B, and come out right.
