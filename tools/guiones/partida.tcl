# Una partida a ciegas. El titulo espera el boton DENTRO de la interrupcion (0x47AE: no pasan cuadros), asi que
# las pulsaciones van por tiempo emulado (after time) y la barra siempre se suelta sola. La presentacion
# no se usa: cuando el estado (0xE09A) pasa a ser el titulo (0x42EF), la barra 2 s despues empieza la partida. Despues, la palanca cambia
# al azar cada 20 cuadros (srand fijo) y la barra (disparo) cada 8. 8000 cuadros.
expr {srand(7)}
proc toca {} {
    keymatrixdown 8 0x01
    after time 0.05 { keymatrixup 8 0x01 }
}
proc guion {n} {
    set e [expr {[debug read memory 0xE09A] | ([debug read memory 0xE09B] << 8)}]
    if {$e == 0x42EF && ![info exists ::empezada]} {
        set ::empezada 1
        after time 2 toca
    }
    if {[info exists ::empezada] && $n > 200 && [debug read memory 0xE09C] == 0 && [lsearch {0x40E5 0x411C 0x415E 0x42EF} [format 0x%04X $e]] < 0} {
        if {$n % 8 == 0} { toca }
        if {$n % 20 == 0} {
            keymatrixup 8 0xF0
            set k [lindex {0x10 0x20 0x40 0x80 0x00 0x30 0x90} [expr {int(rand() * 7)}]]
            if {$k} { keymatrixdown 8 $k }
        }
    }
    return [expr {$n >= 8000}]
}
