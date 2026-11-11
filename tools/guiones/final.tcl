# EL FINAL DE LA ESTACION, sin trampas del guion: las ocho teclas de la fila 0 del teclado (0-7) pulsadas al
# encender, que el juego lee en INIT (0x403D) y guarda en 0xE097; a 0, la nave no choca (0x6460). Se sueltan en el
# primer cuadro. Despues la partida empieza desde el titulo (la barra por tiempo, como en partida.tcl) y un piloto
# dispara siempre y lleva la nave hacia el enemigo vivo mas cercano; cuando la nave se transforma, lleva su puno
# hacia el robot grande y golpea. 14000 cuadros.
keymatrixdown 0 0xFF
proc m {a} { return [debug read memory $a] }
proc toca {} {
    keymatrixdown 8 0x01
    after time 0.05 { keymatrixup 8 0x01 }
}
proc palanca {dy dx} {
    keymatrixup 8 0xF0
    if {$dy < -4} { keymatrixdown 8 0x20 } elseif {$dy > 4} { keymatrixdown 8 0x40 }
    if {$dx < -4} { keymatrixdown 8 0x10 } elseif {$dx > 4} { keymatrixdown 8 0x80 }
}
proc guion {n} {
    if {$n == 1} { keymatrixup 0 0xFF }
    set e [expr {[m 0xE09A] | ([m 0xE09B] << 8)}]
    if {$e == 0x42EF && ![info exists ::empezada]} {
        set ::empezada 1
        after time 2 toca
    }
    if {[info exists ::empezada] && $n > 200 && [m 0xE09C] == 0} {
        if {$n % 8 == 0} { toca }
        set ny [m 0xE219]
        set nx [m 0xE21A]
        if {[m 0xE2AB] != 0 || [m 0xEC39] != 0} {
            # transformada: el puno (0xE221) hacia el robot grande (0xE249)
            palanca [expr {[m 0xE249] - [m 0xE221]}] [expr {[m 0xE24A] - [m 0xE222]}]
        } else {
            # hacia abajo del enemigo vivo mas cercano en X, sin subir de la mitad
            set mejor 999
            set tx 0x7C
            for {set k 0} {$k < 8} {incr k} {
                set b [expr {0xE2BD + 32 * $k}]
                if {[m $b] != 1} continue
                set s [expr {0xE245 + 4 * (7 - $k)}]
                set x [m [expr {$s + 1}]]
                set d [expr {abs($x - $nx)}]
                if {$d < $mejor} { set mejor $d; set tx $x }
            }
            palanca [expr {0x90 - $ny}] [expr {$tx - $nx}]
        }
    }
    return [expr {$n >= 14000}]
}
