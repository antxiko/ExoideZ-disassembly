# Curiosities

## Keys 0-7 at power-on: the ship never crashes

At start-up the game reads row 0 of the keyboard (keys 0 to 7) and stores it at 0xE097 (`init`, 0x403D). Before
checking whether the ship crashes, it looks at that byte: if it is 0, it never crashes (`nave_choca`, 0x6460). With
the keyboard untouched the row reads 0xFF; it is only 0 if all eight keys are held at power-on. **Checked in
openMSX** (`tools/guiones/final.tcl`): with the eight held at power-on, 0xE097 stays at 0 and the ship crosses the
whole station, the capsules, the big robot and the count without losing a life. No text says so.

## The whole game in the interrupt

The main program is a `jr $` that jumps to itself forever (0x4043). Everything else runs in the interrupt (the
H.KEYI hook): the current state, stored at 0xE09A, and 23 **tasks** with a countdown that are called when their
count reaches zero (the table at 0x40B7). Even the title waits for the button inside the interrupt: while it waits,
for the game not a single frame goes by, nor in the openMSX recording.

## The status line is sprites

The score, the R of the round and the lives are not tiles: they are eight sprites whose letters are copied from the
BIOS font into their drawings (0x3F40-0x3FFF) every time they change (`puntos_pinta`, 0x4C54). The whole screen is
left to the station. GAME OVER is sprites too.

## A piece of music built in RAM

The list of pieces of the second voice (0x7FC7) has a piece at 0xE000, in RAM: at power-on, routine 0x7FAE fills it
with four groups of 18 one-frame notes. The check against openMSX only matches if that routine is run first.

## The robot that escapes makes the game harder

If the big robot reaches the bottom unbroken, it leaves and the station starts over, and the game counts it
(0xE0C3). From the fourth time, the enemies shoot twice as fast and not only downwards (`tarea_enemigos_disparan`,
0x6F33). The count resets it.

## The seventh prize

The count looks for the prize in a table of steps with a loop of six (0x7486), but the table has seven: with 100%
of the targets broken it fits none of the six and stays on the seventh, **100,000** points, more than three times
the one for 90%.

## What does nothing

Three instructions nothing jumps to at 0x7B9F (a `call` and a `jr` that never run).
