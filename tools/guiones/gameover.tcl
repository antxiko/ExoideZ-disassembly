# GAME OVER sin tocar nada: la barra empieza la partida desde el titulo (por tiempo, como en partida.tcl) y despues
# nadie mueve la nave: los enemigos acaban con las tres vidas y GAME OVER suena entero. 4000 cuadros.
proc m {a} { return [debug read memory $a] }
proc toca {} {
    keymatrixdown 8 0x01
    after time 0.05 { keymatrixup 8 0x01 }
}
proc guion {n} {
    set e [expr {[m 0xE09A] | ([m 0xE09B] << 8)}]
    if {$e == 0x42EF && ![info exists ::empezada]} {
        set ::empezada 1
        after time 2 toca
    }
    return [expr {$n >= 4000}]
}
