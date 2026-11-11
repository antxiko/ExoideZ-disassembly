# The music

Five tunes, in two voices. They are not hand-made recordings: `tools/musica.py` **runs the ROM's own sound
engine** with `tools/z80run.py` -the music task (`tarea_musica`, 0x4C89), frame by frame, with the two numbers the
game sets- and logs what it writes to the PSG through the BIOS (WRTPSG; to lower the volume it reads with RDPSG).

**Checked against openMSX**: the tone and volume registers match the recorded ones, **0 different** in every frame
checked but one, the first of the end tune, when a channel A effect is cut. They were recorded four times
(`tools/guiones/`): untouched, a blind game, a game left alone until GAME OVER and the whole station. Each recorded
frame is paired with the engine frame that has the same RAM in the two voices; the engine starts with the music RAM
as the game had it. While the capsules spin or the extra life sounds, their sound stops the music and silences
channel B: those frames are not checked.

The sound effects are not here: the shots, the explosions, the capsules, the extra life and the rest.

## The engine

It runs in the interrupt, as task 19 (`tarea_musica`, 0x4C89): two **voices**, each with a 9-byte block that is
copied to a work block (0xE3E4), takes a step and goes back. The first plays the pieces of the list at 0x7E99 on
channel B; the second, on channel C (on A if it is number 3), those of the list at 0x7FC7. The game does not ask
for the music: it writes the numbers of the two voices (0xE3F2 and 0xE3FB) and the task starts their pieces
(`musica`, 0x7D49). A piece is a list of (duration, note) pairs; note 0 is silence and the others, the tone from the
table at 0x7E51 (36 notes). A list ends with 0xFFFF or starts over with 0x0000. One of the second voice's pieces is
not in the ROM: routine 0x7FAE builds it in RAM, at 0xE000, at power-on (72 one-frame notes).

| | The two voices | Who sets it | Length |
|---|---|---|---:|
| the round starts | 1 and 1 | the ship comes in (0x4882) | 6.0 s |
| the round | 2 | the ship is in place (0x62E8) | 5.1 s and loops |
| the end | 4 and 3 | the end of the station and the big robot (0x5686, 0x715C) | 7.3 s and loops |
| the count | 3 and 2 | RATE and BONUS (0x74AC) | 3.2 s |
| GAME OVER | 5 | no lives left (0x495E) | 5.0 s and loops |

## The round starts

<audio controls src="audio/musica_ronda_entra.mp3"></audio>

## The round

<audio controls src="audio/musica_ronda.mp3"></audio>

## The end

<audio controls src="audio/musica_final.mp3"></audio>

## The count

<audio controls src="audio/musica_recuento.mp3"></audio>

## GAME OVER

<audio controls src="audio/musica_game_over.mp3"></audio>
