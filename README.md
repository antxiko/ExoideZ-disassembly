# Exoide-Z - commented disassembly

*(También [en castellano](README.es.md).)*

The commented disassembly of **Exoide-Z** (Casio, 1986) for the MSX: a 16 KB cartridge at 0x4000.

- **100%** of the binary explained: 9,611 bytes of code and 6,773 of named data, not one byte unassigned.
- **40.4%** of the listing commented, 487 routines and labels, none below 10% of comments.
- The listing reassembles into the original ROM **byte for byte**.
- The title comes from running the ROM, checked against openMSX; the stations built with the ROM's own code; the waves, the capsules, the transformation, the big robot and the count, played in GIF; the five tunes, from its own sound engine and identical to openMSX frame by frame.

The site: <https://antxiko.github.io/ExoideZ-disassembly/>
(in Spanish: <https://antxiko.github.io/ExoideZ-disassembly/es/>).

## Rebuilding it

The ROM image is not distributed. Put yours in the root as `exoidez.rom` (sha256 `77b1b4dc...`) and run `make`. The details, in [UNDER THE HOOD](docs/UNDER-THE-HOOD.md).

## Legal

The game belongs to Casio and its rights holders. The `LICENSE` covers only the tools, comments, analysis and documentation here. See [LEGAL-NOTICE.md](LEGAL-NOTICE.md).
