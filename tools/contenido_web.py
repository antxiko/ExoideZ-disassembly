#!/usr/bin/env python3
"""EL CONTENIDO de la web de esta ROM: lo unico que es de este juego.

jekyll.py y make_web.py son la maquinaria y no llevan dentro el nombre de
ningun juego: lo leen de aqui.

Todas las cifras de aqui estan medidas sobre esta ROM, con las herramientas
de tools/: CODIGO y DATOS los imprime tools/presupuesto.py (make sanity),
INSTRUCCIONES, COMENTARIOS y RUTINAS los da tools/densidad.py (make densidad:
"de N" rutinas, "N instrucciones, M comentarios").
"""

NOMBRE = "Exoide-Z"
EDITOR = "Casio"
ANIO = 1986
REPOSITORIO = "https://github.com/antxiko/ExoideZ-disassembly"
SHA1 = "3137e676c37195d46fe6acc4395d0dc4d711d919"

CODIGO = 9611
DATOS = 6773
RUTINAS = 487
INSTRUCCIONES = 4648
COMENTARIOS = 1876


def densidad(idioma):
    """El porcentaje comentado, con la coma o el punto de cada idioma."""
    d = "%.1f" % (100.0 * COMENTARIOS / INSTRUCCIONES)
    return d.replace(".", ",") if idioma == "es" else d


PIE_LEGAL = {
    "es": "<em>Exoide-Z</em> es un juego de Casio para MSX, de 1986, en un cartucho de 16 KB. "
          "Todos los derechos sobre el juego siguen siendo de sus titulares. Este trabajo es de "
          "preservaci&oacute;n, estudio y documentaci&oacute;n, y la imagen de la ROM no se distribuye.",
    "en": "<em>Exoide-Z</em> is a 1986 Casio game for the MSX, on a 16 KB cartridge. All rights in "
          "the game remain with their holders. This is preservation, study and documentation work, and the "
          "ROM image is not distributed.",
}

PORTADA = {
    "es": dict(
        titulo="Exoide-Z - desensamblado comentado",
        claim="Una nave sube por una estaci&oacute;n espacial que el juego monta trozo a trozo, dispara a las "
              "oleadas y a los blancos del suelo, gira tres c&aacute;psulas y al final se transforma en robot para "
              "romper a pu&ntilde;etazos al robot grande; todo el juego corre en la interrupci&oacute;n, con 23 "
              "tareas. El t&iacute;tulo desde los bytes de la ROM, cotejado con openMSX; las estaciones montadas "
              "con su c&oacute;digo; la partida en GIF y las cinco m&uacute;sicas de su propio motor, "
              "id&eacute;nticas a openMSX cuadro a cuadro.",
        ficha=["Casio - <b>(c) 1986</b>",
               "Cartucho de <b>16 KB</b> en 0x4000",
               "<b>MSX</b>", "Volcado <b>3137e676...</b>"],
        aviso="<b>Aqu&iacute; no hay capturas del juego.</b> El logotipo y el t&iacute;tulo salen de "
              "ejecutar la ROM (cotejados con openMSX), los mapas los monta el c&oacute;digo de la ROM y los GIF "
              "son la ROM <b>funcionando en openMSX</b>: en cada cuadro se apuntan la VRAM, la RAM y los registros "
              "del VDP, y <b>c&oacute;digo nuestro los pinta</b>.",
    ),
    "en": dict(
        titulo="Exoide-Z - commented disassembly",
        claim="A ship flies up a space station that the game builds piece by piece, shoots the waves and the "
              "ground targets, spins three capsules and at the end turns into a robot to break the big robot with "
              "its fists; the whole game runs in the interrupt, with 23 tasks. The title from the ROM's bytes, "
              "checked against openMSX; the stations built with its own code; the game in GIF and the five tunes "
              "from its own engine, identical to openMSX frame by frame.",
        ficha=["Casio - <b>(c) 1986</b>",
               "<b>16 KB</b> cartridge at 0x4000",
               "<b>MSX</b>", "Dump <b>3137e676...</b>"],
        aviso="<b>There are no screenshots of the game here.</b> The logo and the title come from running "
              "the ROM (checked against openMSX), the maps are built by the ROM's code and the GIFs are the ROM "
              "<b>running in openMSX</b>: on every frame the VRAM, the RAM and the VDP registers are logged, and "
              "<b>our own code paints them</b>.",
    ),
}

PAGINAS = [
    [("THE-GAME.html", "LA-PARTIDA.html", "The game", "La partida",
      "the intro, the title, the controls, the shots, the lives and the points",
      "la presentaci&oacute;n, el t&iacute;tulo, los mandos, los disparos, las vidas y los puntos"),
     ("THE-ROUNDS.html", "LAS-RONDAS.html", "The rounds", "Las rondas",
      "the station piece by piece, the enemies, the ground targets, the capsules, the big robot and the count",
      "la estaci&oacute;n trozo a trozo, los enemigos, los blancos del suelo, las c&aacute;psulas, el robot grande "
      "y el recuento"),
     ("THE-SPRITES.html", "LOS-SPRITES.html", "The sprites", "Los sprites",
      "the ship, the robot, the enemies and the big robot put together from the ROM, frame by frame",
      "la nave, el robot, los enemigos y el robot grande montados desde la ROM, cuadro a cuadro"),
     ("THE-TEXTS.html", "LOS-TEXTOS.html", "The texts", "Los textos",
      "every text in the ROM, with its translation",
      "todos los textos de la ROM, con su traducci&oacute;n"),
     ("THE-MUSIC.html", "LA-MUSICA.html", "The music", "La m&uacute;sica",
      "the five tunes, from its own sound engine and checked against openMSX",
      "las cinco m&uacute;sicas, de su propio motor de sonido y cotejadas con openMSX")],
    [("CURIOSITIES.html", "CURIOSIDADES.html", "Curiosities", "Curiosidades",
      "keys 0-7 at power-on and the ship never crashes, the game in the interrupt, the status line in sprites "
      "and the seventh prize",
      "las teclas 0-7 al encender y la nave no choca, el juego en la interrupci&oacute;n, el marcador en sprites y "
      "el s&eacute;ptimo premio")],
    [("UNDER-THE-HOOD.html", "POR-DENTRO.html", "Under the hood", "Por dentro",
      "rebuilding the ROM, the BIOS it uses, the states and the 23 tasks, the RAM and the tools",
      "rehacer la ROM, la BIOS que usa, los estados y las 23 tareas, la RAM y las herramientas")],
]

# Repositorio nuevo: no hay paginas viejas que redirigir.
VIEJAS = {}

LOGOTIPO = "logotipo.png"
