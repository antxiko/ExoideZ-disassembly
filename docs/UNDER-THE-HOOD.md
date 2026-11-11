# Under the hood

## Rebuilding the ROM

`make verify` assembles `src/exoidez.asm` with pasmo and the 16 KB ROM comes out **byte for byte**. `make sanity`
checks what reassembly does not cover: that no byte declared as data is read as code, that no entry point falls
into data and that all 16,384 bytes are explained. `make test` runs the tests. The ROM is not in the repository:
put it in the root as `exoidez.rom` (the GoodMSX dump, `[!]`, sha1 `3137e676...`).

| | bytes |
|---|---|
| traced code | 9,611 |
| named data | 6,773 |
| unexplained | 0 |

The listing has 1,876 comments on 4,648 instructions (40.4%), 487 routines and labels, none below 10% commented,
and no called routine without a name.

## The cartridge

16 KB in **page 1** (0x4000-0x7FFF), with INIT at 0x4010. What is not code: the station pieces and their lists,
the tile and colour commands of each round, the waves, the sprite and tile drawings (some packed with a bit mask for
every eight bytes, `desempaqueta`, 0x4055), the texts and the music.

## The BIOS it uses

WRTVDP for the VDP registers; SETWRT and port 0x98 directly to write the VRAM (with a wait between bytes), and
FILVRM, LDIRVM, LDIRMV and WRTVRM; GTSTCK, GTTRIG and SNSMAT for the controls; WRTPSG and RDPSG for the sound; and
the BIOS font through its pointer (CGTABL, 0x0004).

## The interrupt, the states and the tasks

INIT puts a jump to 0x406B on the H.KEYI hook (0xFD9A) and a `ret` on H.TIMI, and stays in a `jr $`. The interrupt
switches the VDP interrupt off while it runs, calls the **state** at 0xE09A (the intro, the title, the ship coming
in, the end, the count...) and counts down the **23 tasks** (0xEC2D): when one reaches zero, it jumps to its routine
in the table at 0x40B7, which sets its count again (almost all to 1: every frame).

| task | what it does |
|---|---|
| 0 | the scroll: a third of the hidden name table |
| 1 | the stars |
| 2 | the sprites to the VRAM |
| 3 | the ship: the controls, the crashes, the explosion |
| 4 | the ship's shots |
| 5 | the waves: the enemies come out |
| 6 | the map: two rows up and the new pieces |
| 7 | the enemies move |
| 8 | the enemies shoot |
| 9 | their shots |
| 10 | the enemies that were hit |
| 11-15 | the big robot and the transformed ship |
| 16 | the ground explosions |
| 17 | the capsules |
| 18 and 20 | the sound effects on channels A and C |
| 19 | the music |
| 21 | the points and the extra life |
| 22 | the GAME OVER wait |

## How it was done

The trace follows the code from INIT, the interrupt, the 23 tasks, the states stored at 0xE09A and 0xE217 and two
tables of five routines (the ways the enemies come in and move), declared in `src/exoidez.entries`. The rest was
**measured in openMSX** (`tools/omsx_cobertura.tcl`) playing and waiting for the demo on a Philips VG 8020: nothing
that ran was left out of the trace. With the cartridge in page 1 the slot has to be checked: before the cartridge
comes in, 0x4000-0x7FFF holds BASIC, and the measurement took it for the game.

## The RAM

| | |
|---|---|
| 0xE000-0xE090 | the piece of music built in RAM |
| 0xE092-0xE096 | the two name tables and register 2 |
| 0xE097 | keyboard row 0 at power-on (at 0, the ship never crashes) |
| 0xE098 | keyboard (0) or joystick (1) |
| 0xE09A | the state |
| 0xE09C | the demo |
| 0xE0A1-0xE0A7 | the high score |
| 0xE0A8 / 0xE0A9 | the round / the spare lives |
| 0xE0AA-0xE0B0 | the score, seven digits, one per byte |
| 0xE0B3 / 0xE0B5 | the 0xC8 targets there were / the broken ones |
| 0xE0BA / 0xE0BD | the wave / the map piece |
| 0xE0C3 | the times the big robot has escaped |
| 0xE0CD | the speed of the shots |
| 0xE219 | the sprite table that goes to 0x1F80: the ship, its shots, the enemies |
| 0xE2BD | the eight enemies (32 bytes each) |
| 0xE3BF | their four shots |
| 0xE3D5-0xE408 | the sound: the effects and the two music voices |
| 0xE42D / 0xE44D / 0xE76D | the background: the two copies of the screen |
| 0xEA6E | the unpacked map piece |
| 0xEB79 | the three capsules |
| 0xEC2D-0xEC43 | the counts of the 23 tasks |
