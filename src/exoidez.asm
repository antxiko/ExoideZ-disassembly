; ==========================================================================
; EXOIDE-Z - ROM de 16 KB en 0x4000
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; DATOS cabecera: "AB", INIT (0x4010) y el resto de la cabecera a cero
;   0x4000..0x4010  (16 bytes)
DATA_cabecera:
	defb 041h,042h	; 4000
	defw 04010h,00000h,00000h,00000h,00000h,00000h,00000h	; 4002

; ======================================================================
; CODIGO 0x4010..0x40b7  (167 bytes)
; ======================================================================


init:		; El arranque: sin interrupciones, H.TIMI con un "ret", la RAM 0xE091-0xEDFF a cero, la pila, la pantalla y los dibujos (0x7834), H.KEYI a 0x406B, el primer estado (0x40E5) y el bucle vacio
	di			;4010   ; sin interrupciones
	ld a,0c9h		;4011   ; un "ret"...
	ld (0fd9fh),a		;4013   ; ...en H.TIMI (0xFD9F)
	ld hl,0e091h		;4016   ; 0xE091...
	ld de,0e092h		;4019   ; ...0xE092...
	ld bc,00d6fh		;401c   ; ...0xD6F bytes...
	ld (hl),000h		;401f   ; ...a cero
	ldir		;4021
	ld sp,0f380h		;4023   ; la pila
	call pantalla_pon		;4026   ; la pantalla y los dibujos
	di			;4029
	ld hl,0fd9ah		;402a   ; H.KEYI (0xFD9A)...
	ld de,interrupcion		;402d   ; ...la interrupcion, 0x406B...
	ld (hl),0c3h		;4030   ; ...con su "jp"
	inc hl			;4032
	ld (hl),e			;4033
	inc hl			;4034
	ld (hl),d			;4035
	ld hl,040e5h		;4036   ; el primer estado: la presentacion (0x40E5)
	ld (0e09ah),hl		;4039
	xor a			;403c   ; la fila 0 del teclado...
	call 00141h		;403d   ; SNSMAT
	ld (0e097h),a		;4040   ; ...en 0xE097
bucle_vacio:		; El bucle principal: nada; todo va en la interrupcion
	jr bucle_vacio		;4043   ; para siempre
partida_borra:		; Una partida nueva: 0xE0A8-0xE0CA a cero y 0xE0A9 (las vidas) = 2
	ld hl,0e0a8h		;4045   ; desde 0xE0A8...
	ld bc,00023h		;4048   ; ...35 bytes...
	xor a			;404b   ; ...a cero
	call llena		;404c
	ld a,002h		;404f   ; dos vidas de reserva
	ld (0e0a9h),a		;4051
	ret			;4054
desempaqueta:		; Desempaqueta B bloques de HL a DE: cada bloque, un byte de mascara y 8 bytes; un bit a 1 lee un byte nuevo, a 0 repite el anterior (A')
	push bc			;4055   ; los bloques
	ld a,(hl)			;4056   ; la mascara
	inc hl			;4057
	ld c,a			;4058
	ex af,af'			;4059   ; el ultimo byte, de A'
	ld b,008h		;405a   ; ocho bytes
desempaqueta_bit:
	sla c		;405c   ; el bit de arriba
	jr nc,desempaqueta_pon		;405e   ; 0: el mismo
	ld a,(hl)			;4060   ; 1: uno nuevo
	inc hl			;4061
desempaqueta_pon:
	ld (de),a			;4062   ; a DE
	inc de			;4063
	djnz desempaqueta_bit		;4064
	ex af,af'			;4066   ; el ultimo, a A'
	pop bc			;4067
	djnz desempaqueta		;4068
	ret			;406a
interrupcion:		; La interrupcion (H.KEYI): la del VDP cortada mientras dura (registro 1 sin el bit 5), el estado de 0xE09A, las 23 tareas con cuenta atras y el registro 1 de vuelta
	in a,(099h)		;406b   ; lee el estado del VDP (la interrupcion atendida)
	ld a,(0e099h)		;406d   ; el registro 1...
	res 5,a		;4070   ; ...sin la interrupcion del VDP
	ld b,a			;4072
	ld c,001h		;4073
	call 00047h		;4075   ; WRTVDP
	ld hl,(0e09ah)		;4078   ; el estado...
	call salta_hl		;407b   ; ...se llama
	ld de,0ec2dh		;407e   ; las 23 cuentas de las tareas
	ld b,017h		;4081
interrupcion_tarea:
	ld a,(de)			;4083   ; una cuenta
	and a			;4084
	jr z,interrupcion_sig		;4085   ; 0: parada
	dec a			;4087   ; una menos
	ld (de),a			;4088
	jr nz,interrupcion_sig		;4089   ; aun no
	push de			;408b
	push bc			;408c
	call tarea		;408d   ; a 0: su tarea
	pop bc			;4090
	pop de			;4091
interrupcion_sig:
	inc de			;4092
	djnz interrupcion_tarea		;4093
	in a,(099h)		;4095   ; el estado del VDP
	ld a,(0e099h)		;4097   ; y el registro 1 como estaba
	ld b,a			;409a
	ld c,001h		;409b
	jp 00047h		;409d   ; WRTVDP
tarea:		; La tarea 23 - B de la tabla 0x40B7
	ld hl,040b7h		;40a0   ; la tabla
	ld a,017h		;40a3   ; 23 - B...
	sub b			;40a5
	add a,a			;40a6   ; ...x 2
	ld b,000h		;40a7
	ld c,a			;40a9   ; el numero x 2
	add hl,bc			;40aa
	ld a,(hl)			;40ab   ; la direccion de la tarea
	inc hl			;40ac
	ld h,(hl)			;40ad
	ld l,a			;40ae
salta_hl:		; jp (hl): el estado o la tarea
	jp (hl)			;40af
estado_nada:		; El estado vacio: 0xE09A = 0x40B6, un "ret"
	ld hl,nada		;40b0
	ld (0e09ah),hl		;40b3
nada:
	ret			;40b6

; ----------------------------------------------------------------------
; DATOS tabla_tareas: Las 23 tareas con cuenta atras (0xEC2D-0xEC43): cuando
;   la cuenta de una llega a 0, la interrupcion salta aqui
;   0x40b7..0x40e5  (46 bytes)
DATA_tabla_tareas:
	defw 054d9h,061aeh,06219h,0638fh,064beh,0696ch,05562h,06c1fh	; 40b7
	defw 06f33h,0701eh,07071h,07102h,07199h,0733dh,0681fh,06898h	; 40c7
	defw 06723h,07635h,07c2ch,04c89h,07cf0h,04b89h,04963h	; 40d7

; ======================================================================
; CODIGO 0x40e5..0x4188  (163 bytes)
; ======================================================================


presentacion:		; La presentacion: la pantalla en blanco, los dibujos de las casillas (0x43CD), y cuatro CASIO que entran por los lados y por arriba y abajo hasta juntarse en el centro (0xE211 de 1 a 20, un paso cada 3 cuadros)
	xor a			;40e5   ; 0xE0CE = 0
	ld (0e0ceh),a		;40e6
	ld a,004h		;40e9   ; 0xE0CD = 4
	ld (0e0cdh),a		;40eb
	call 00041h		;40ee   ; DISSCR
	call scroll_pon		;40f1   ; 0x5458
	call pantalla_borra		;40f4   ; la pantalla en blanco
	call tareas_paradas		;40f7   ; las tareas paradas
	call casillas_pon		;40fa   ; los dibujos de las casillas
	ld a,001h		;40fd   ; el paso 1
	ld (0e211h),a		;40ff
	ld a,003h		;4102   ; cada 3 cuadros
	ld (0e216h),a		;4104
	ld hl,0180ch		;4107   ; la linea que baja (fila 0, columna 12)...
	ld (0e212h),hl		;410a
	ld hl,01aech		;410d   ; ...y la que sube (fila 23)
	ld (0e214h),hl		;4110
	ld hl,presentacion_cuadro		;4113   ; el estado siguiente: 0x411C
	ld (0e09ah),hl		;4116
	jp 00044h		;4119   ; ENASCR
presentacion_cuadro:		; Cada 3 cuadros un paso: los dos CASIO de los lados y, desde el 9, los de arriba y abajo; al 21, la musica y la espera
	ld hl,0e216h		;411c   ; la cuenta...
	dec (hl)			;411f
	ret nz			;4120
	ld (hl),003h		;4121   ; ...otra vez 3
	call presentacion_lineas		;4123   ; los de arriba y abajo
	call presentacion_lados		;4126   ; los de los lados
	ld hl,0e211h		;4129   ; un paso mas
	inc (hl)			;412c
	ld a,(hl)			;412d
	cp 015h		;412e   ; el 21?
	jr nc,presentacion_espera_pon		;4130
	cp 009h		;4132   ; desde el 9...
	ret c			;4134
	ld hl,(0e212h)		;4135   ; ...la linea de arriba baja una fila...
	ld bc,00020h		;4138
	add hl,bc			;413b
	ld (0e212h),hl		;413c
	ld hl,(0e214h)		;413f   ; ...y la de abajo sube
	sbc hl,bc		;4142
	ld (0e214h),hl		;4144
	ret			;4147
presentacion_espera_pon:		; Juntos: 128 cuadros de espera (0xE09D), el estado 0x415E, despues el titulo (0x42EF, en 0xE217) y 13 cuadros del sonido de CASIO (0xE0CC)
	ld a,080h		;4148   ; 128 cuadros
	ld (0e09dh),a		;414a
	ld hl,presentacion_espera		;414d   ; el estado siguiente
	ld (0e09ah),hl		;4150
	ld hl,042efh		;4153   ; y despues, el titulo
	ld (0e217h),hl		;4156
	ld a,00dh		;4159   ; 13 cuadros de sonido
	ld (0e0cch),a		;415b
presentacion_espera:		; La espera: el sonido de CASIO (los 13 registros del PSG de 0x4188 en el primer cuadro, el envolvente al ultimo) y, al acabar o con el boton, el titulo
	ld hl,0e0cch		;415e   ; el sonido
	ld a,(hl)			;4161
	and a			;4162   ; acabado
	jr z,presentacion_espera_va		;4163
	dec a			;4165
	ld (hl),a			;4166
	jr z,presentacion_sonido_fin		;4167   ; el ultimo cuadro?
	cp 00ch		;4169   ; el primero?
	jr nz,presentacion_espera_va		;416b
	ld hl,04188h		;416d   ; los 13 registros del PSG...
	ld b,00dh		;4170
	call psg_tabla		;4172   ; ...de 0x4188
	jr presentacion_espera_va		;4175
presentacion_sonido_fin:
	ld a,004h		;4177   ; el registro 4 (el tono del canal C)...
	ld e,020h		;4179   ; ...a 0x20
	call 00093h		;417b
presentacion_espera_va:
	ld hl,0e09dh		;417e   ; la espera, un cuadro menos
	dec (hl)			;4181
	jp z,estado_siguiente		;4182   ; acabada: el titulo
	jp demo_boton		;4185   ; si no, el boton?

; ----------------------------------------------------------------------
; DATOS sonido_casio: El sonido de CASIO: 13 parejas (registro del PSG, valor)
;   0x4188..0x41a2  (26 bytes)
DATA_sonido_casio:
	defb 000h,050h,001h,000h,002h,040h,003h,000h,004h,000h,005h,000h,007h,0b8h,008h,010h	; 4188  .P...@..........
	defb 009h,010h,00ah,010h,00bh,0f6h,00ch,028h,00dh,000h	; 4198  .......(..

; ======================================================================
; CODIGO 0x41a2..0x41ac  (10 bytes)
; ======================================================================


psg_tabla:		; B parejas (registro, valor) de HL al PSG
	ld a,(hl)			;41a2   ; el registro
	inc hl			;41a3
	ld e,(hl)			;41a4   ; el valor
	inc hl			;41a5
	call 00093h		;41a6   ; WRTPSG
	djnz psg_tabla		;41a9
	ret			;41ab

; ----------------------------------------------------------------------
; DATOS logotipo_casio: Las dos filas del logotipo de CASIO: 0x41AD la de
;   arriba y 0x41B6 la de abajo, nueve casillas cada una (0x70-0x7F), con un 0
;   delante y detras
;   0x41ac..0x41bf  (19 bytes)
DATA_logotipo_casio:
	defb 000h,070h,072h,074h,076h,078h,07ah,07ch,07eh,000h,071h,073h,075h,077h,079h,07bh	; 41ac  .prtvxz|~.qsuwy{
	defb 07dh,07fh,000h	; 41bc

; ======================================================================
; CODIGO 0x41bf..0x421b  (92 bytes)
; ======================================================================


presentacion_lineas:		; Desde el paso 9: los CASIO de arriba y de abajo, cada uno con una fila en blanco (0x421B) detras, que bajan y suben hacia el centro
	ld a,(0e211h)		;41bf   ; el paso 9?
	cp 009h		;41c2
	ret c			;41c4
	ld bc,00008h		;41c5   ; 8 casillas
	ld hl,041b6h		;41c8   ; la fila de abajo...
	ld de,(0e212h)		;41cb   ; ...en la linea que baja
	call 0005ch		;41cf   ; LDIRVM
	ld de,00020h		;41d2   ; una fila arriba
	and a			;41d5
	sbc hl,de		;41d6
	ex de,hl			;41d8
	ld hl,041adh		;41d9   ; la de arriba
	ld bc,00008h		;41dc
	call 0005ch		;41df   ; LDIRVM
	ld de,00020h		;41e2
	and a			;41e5
	sbc hl,de		;41e6
	ex de,hl			;41e8
	ld hl,0421bh		;41e9   ; y una en blanco encima
	ld bc,00008h		;41ec
	call 0005ch		;41ef
	ld bc,00008h		;41f2   ; el CASIO que sube
	ld hl,041adh		;41f5   ; la fila de arriba
	ld de,(0e214h)		;41f8
	call 0005ch		;41fc   ; LDIRVM
	ld de,00020h		;41ff   ; una fila abajo
	add hl,de			;4202
	ex de,hl			;4203
	ld hl,041b6h		;4204   ; la de abajo
	ld bc,00008h		;4207
	call 0005ch		;420a   ; LDIRVM
	ld de,00020h		;420d
	add hl,de			;4210
	ex de,hl			;4211
	ld hl,0421bh		;4212   ; y una en blanco debajo
	ld bc,00008h		;4215
	jp 0005ch		;4218

; ----------------------------------------------------------------------
; DATOS fila_blanco: Ocho casillas 0: la fila en blanco detras de los CASIO
;   que suben y bajan
;   0x421b..0x4223  (8 bytes)
DATA_fila_blanco:
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 421b  ........

; ======================================================================
; CODIGO 0x4223..0x428b  (104 bytes)
; ======================================================================


presentacion_lados:		; Los dos CASIO de los lados en las filas 11 y 12: uno entra por la derecha casilla a casilla (tantas como el paso, 9 como mucho) y el otro por la izquierda, leido desde el final
	ld a,(0e211h)		;4223   ; el paso
	ld c,a			;4226
	cp 009h		;4227   ; 9 como mucho
	jr c,presentacion_lados_der		;4229
	ld c,009h		;422b
presentacion_lados_der:
	ld hl,01980h		;422d   ; la fila 12, desde la derecha
	ld b,a			;4230
	ld a,l			;4231
	sub b			;4232
	ld l,a			;4233
	ex de,hl			;4234
	ld hl,041adh		;4235   ; la fila de arriba del logotipo
	ld b,000h		;4238
	call 0005ch		;423a   ; LDIRVM
	ld de,00020h		;423d   ; una fila abajo
	add hl,de			;4240
	ex de,hl			;4241
	ld hl,041b6h		;4242   ; la de abajo
	ld a,(0e211h)		;4245
	cp 009h		;4248
	jr c,presentacion_lados_der2		;424a
	ld a,009h		;424c   ; 9
presentacion_lados_der2:
	ld c,a			;424e
	call 0005ch		;424f   ; LDIRVM
	ld hl,01960h		;4252   ; el de la izquierda: la fila 11
	ld a,(0e211h)		;4255   ; el paso
	ld c,a			;4258
	cp 009h		;4259
	jr c,presentacion_lados_izq		;425b
	sub 009h		;425d   ; pasado el 9, se mueve a la derecha
	add a,l			;425f   ; + (el paso - 9)
	ld l,a			;4260
	ld c,009h		;4261
presentacion_lados_izq:
	ex de,hl			;4263
	ld hl,041b5h		;4264   ; la fila de arriba desde el final
	ld a,l			;4267
	sub c			;4268
	jr nc,presentacion_lados_izq2		;4269
	dec h			;426b
presentacion_lados_izq2:
	ld l,a			;426c
	call 0005ch		;426d   ; LDIRVM
	ld de,00020h		;4270   ; una fila abajo
	add hl,de			;4273
	ex de,hl			;4274
	ld a,(0e211h)		;4275
	ld c,a			;4278
	cp 009h		;4279
	jr c,presentacion_lados_izq3		;427b
	ld c,009h		;427d   ; 9
presentacion_lados_izq3:
	ld hl,041beh		;427f   ; la fila de abajo desde el final
	ld a,l			;4282
	sub c			;4283
	jr nc,presentacion_lados_izq4		;4284
	dec h			;4286
presentacion_lados_izq4:
	ld l,a			;4287
	jp 0005ch		;4288   ; LDIRVM

; ----------------------------------------------------------------------
; DATOS casillas_titulo_emp: Los dibujos de las casillas del titulo,
;   empaquetados (16 bloques de mascara y 8 bytes, 0x4055), que 0x4486 lleva a
;   0x380 (casillas 0x70-0x7F)
;   0x428b..0x42ef  (100 bytes)
DATA_casillas_titulo_emp:
	defb 0beh,000h,03fh,07fh,0ffh,0f0h,0e0h,09fh,0e0h,0f0h,0ffh,07fh,03fh,000h,0beh,000h	; 428b  ..?.........?...
	defb 0e0h,0f0h,0f8h,078h,000h,0bfh,000h,039h,079h,0f9h,0f3h,0e3h,000h,0adh,000h,03eh	; 429b  ...x...9y......>
	defb 07fh,077h,0e3h,0adh,0e3h,0ffh,0c1h,080h,000h,0b9h,000h,003h,007h,00fh,08fh,0f7h	; 42ab  .w..............
	defb 087h,083h,0c0h,0cfh,0e7h,0e3h,000h,0b7h,000h,0feh,0ffh,007h,000h,0feh,0abh,0ffh	; 42bb  ................
	defb 007h,0ffh,0feh,000h,0bah,000h,038h,039h,0bbh,03bh,0c7h,03bh,0bbh,039h,038h,000h	; 42cb  ......89.;.;.98.
	defb 0a6h,000h,0ffh,0c1h,080h,099h,080h,0c1h,0ffh,000h,0b8h,000h,080h,0c0h,0e0h,087h	; 42db  ................
	defb 0e0h,0c0h,080h,000h	; 42eb

; ======================================================================
; CODIGO 0x42ef..0x44e0  (497 bytes)
; ======================================================================


titulo:		; El titulo: EXOIDE-Z en letras grandes (seis filas de 0x455B desde la fila 4), (c) 1986 CASIO, HIGHSCORE con el record, PUSH TRIGGER 1 OR SPACE KEY; despues espera el boton dentro de la interrupcion (0x47AE)
	call 00041h		;42ef   ; DISSCR
	call pantalla_borra		;42f2   ; la pantalla en blanco
	ld hl,01861h		;42f5   ; la fila 3, columna 1...
	call 00053h		;42f8   ; SETWRT
	ld b,001h		;42fb   ; el marco de arriba: 0x02...
	ld a,002h		;42fd
	call vram_relleno		;42ff
	ld b,01ch		;4302   ; ...28 de 0x03...
	ld a,003h		;4304
	call vram_relleno		;4306
	ld b,001h		;4309   ; ...y 0x0F
	ld a,00fh		;430b
	call vram_relleno		;430d
	ld hl,0455bh		;4310   ; las seis filas del nombre
	ld de,01880h		;4313   ; desde la fila 4
	ld bc,000c0h		;4316
	call 0005ch		;4319   ; LDIRVM
	ld hl,01941h		;431c   ; la fila 10, columna 1: el marco de abajo
	call 00053h		;431f
	ld b,001h		;4322
	ld a,01eh		;4324
	call vram_relleno		;4326
	ld b,01ch		;4329
	ld a,02ah		;432b
	call vram_relleno		;432d
	ld b,001h		;4330
	ld a,02bh		;4332
	call vram_relleno		;4334
	ld hl,046dbh		;4337   ; (c) 1986 CASIO...
	ld de,0198ah		;433a   ; ...en la fila 12, columna 10
	ld bc,0000ch		;433d
	call 0005ch		;4340
	ld hl,046e7h		;4343   ; HIGHSCORE...
	ld de,019e8h		;4346   ; ...en la fila 15, columna 8
	ld bc,00009h		;4349
	call 0005ch		;434c
	call record		;434f   ; las cifras del record
	ld hl,0e0c4h		;4352   ; sus siete casillas...
	ld de,019f2h		;4355   ; ...en la columna 18
	ld bc,00007h		;4358
	call 0005ch		;435b
	ld hl,046f0h		;435e   ; PUSH TRIGGER 1...
	ld de,01a29h		;4361   ; ...en la fila 17, columna 9
	ld bc,0000eh		;4364
	call 0005ch		;4367
	ld hl,046feh		;436a   ; OR...
	ld de,01a6fh		;436d   ; ...en la fila 19, columna 15
	ld bc,00002h		;4370
	call 0005ch		;4373
	ld hl,04700h		;4376   ; SPACE KEY...
	ld de,01aach		;4379   ; ...en la fila 21, columna 12
	ld bc,00009h		;437c
	call 0005ch		;437f
	call 00044h		;4382   ; ENASCR
	xor a			;4385   ; sin demostracion...
	ld (0e09ch),a		;4386
	ld (0e098h),a		;4389   ; ...el teclado
	ld hl,07000h		;438c   ; la espera: 0x7000 vueltas
	ld (0e09dh),hl		;438f
	ld hl,040e5h		;4392   ; y despues, la presentacion otra vez
	ld (0e217h),hl		;4395
	jp titulo_espera		;4398   ; espera el boton
record:		; El record: si los puntos (0xE0AA, siete cifras) pasan del record (0xE0A1), se copian; sus casillas (+ 0x60) en 0xE0C4
	ld de,0e0a1h		;439b   ; el record...
	ld hl,0e0aah		;439e   ; ...contra los puntos
	ld b,007h		;43a1   ; siete cifras
record_cifra:
	ld a,(de)			;43a3
	cp (hl)			;43a4
	jr c,record_nuevo		;43a5   ; menos: el record queda
	jr nz,record_queda		;43a7   ; mas: record nuevo
	inc hl			;43a9
	inc de			;43aa
	djnz record_cifra		;43ab
record_queda:
	ld hl,0e0a1h		;43ad
	jr record_casillas		;43b0
record_nuevo:
	ld hl,0e0aah		;43b2   ; los puntos...
	ld de,0e0a1h		;43b5   ; ...al record
	ld bc,00007h		;43b8
	push hl			;43bb
	ldir		;43bc
	pop hl			;43be
record_casillas:		; Las siete cifras de HL como casillas (0x60 el 0) en 0xE0C4
	ld de,0e0c4h		;43bf
	ld b,007h		;43c2
record_casilla:
	ld a,(hl)			;43c4   ; la cifra...
	add a,060h		;43c5   ; ...+ 0x60
	ld (de),a			;43c7
	inc hl			;43c8
	inc de			;43c9
	djnz record_casilla		;43ca
	ret			;43cc
casillas_pon:		; Los dibujos y colores de las casillas del juego: desde la casilla 2, hechos en la RAM con sus espejos (los bits al reves) y vueltos del reves, y copiados a los tres tercios
	ld hl,00010h		;43cd   ; desde la casilla 2
	call 00053h		;43d0   ; SETWRT
	ld de,0e0d1h		;43d3   ; los dibujos (0xE0D1)...
	ld hl,0e42dh		;43d6   ; ...y su espejo en 0xE42D
	ld b,0a8h		;43d9   ; 168 bytes
	call vram_y_espejo		;43db
	ld hl,0e179h		;43de   ; 24 bytes...
	ld b,018h		;43e1
	call vram_b		;43e3   ; ...a la VRAM
	dec hl			;43e6
	ld b,018h		;43e7
	call vram_b_atras		;43e9   ; y del reves
	ld de,0e191h		;43ec   ; 32 mas...
	ld hl,0e42dh		;43ef
	ld b,020h		;43f2
	call vram_espejo_cuatro		;43f4   ; ...con espejo y volteados
	ld de,0e1b1h		;43f7   ; 8 mas
	ld hl,0e42dh		;43fa
	ld b,008h		;43fd
	call vram_y_espejo		;43ff
	ld hl,02008h		;4402   ; los colores de las casillas 1-14: 0xFE (blanco sobre gris)
	ld bc,00070h		;4405
	ld a,0feh		;4408
	call 00056h		;440a   ; FILVRM
	ld hl,02078h		;440d   ; desde el color de la casilla 15
	call 00053h		;4410
	ld hl,0e1b9h		;4413   ; 8 colores
	call vram8		;4416
	ld hl,0e1c9h		;4419   ; 56 mas, con los colores cambiados (0x4542)
	ld b,038h		;441c
	call colores_cambiados		;441e
	ld hl,0e1c1h		;4421
	call vram8		;4424
	ld b,050h		;4427   ; 80 de 0x0E (gris)
	ld a,00eh		;4429
	call vram_relleno		;442b
	ld b,018h		;442e   ; 24 de 0x4E (azul sobre gris)
	ld a,04eh		;4430
	call vram_relleno		;4432
	ld hl,0e201h		;4435
	call vram8		;4438
	ld b,008h		;443b   ; 8 de 0xFE
	ld a,0feh		;443d
	call vram_relleno		;443f
	ld b,018h		;4442   ; 24 de 0x0E
	ld a,00eh		;4444
	call vram_relleno		;4446
	ld hl,0e209h		;4449
	call vram8		;444c
	ld b,040h		;444f   ; 64 de 0xFE
	ld a,0feh		;4451
	call vram_relleno		;4453
	ld b,048h		;4456   ; 72 de 0x0E
	ld a,00eh		;4458
	call vram_relleno		;445a
	ld b,008h		;445d   ; 8 de 0xFE
	ld a,0feh		;445f
	call vram_relleno		;4461
	ld hl,044e0h		;4464   ; el (c)...
	ld de,00288h		;4467   ; ...a la casilla 0x51
	ld bc,00008h		;446a
	call 0005ch		;446d
	ld hl,00290h		;4470   ; las letras de 0x44E8...
	ld de,044e8h		;4473   ; ...desde la casilla 0x52
	ld b,018h		;4476   ; 24 letras
	call letras_vram		;4478
	ld hl,02288h		;447b   ; sus colores...
	ld bc,00178h		;447e
	ld a,0f0h		;4481   ; ...blanco sobre transparente
	call 00056h		;4483
	ld hl,0428bh		;4486   ; las casillas del logotipo de CASIO, empaquetadas...
	ld de,0e42dh		;4489   ; ...a 0xE42D
	ld b,010h		;448c
	call desempaqueta		;448e
	ld hl,0e42dh		;4491   ; a la casilla 0x70
	ld de,00380h		;4494
	ld bc,00080h		;4497
	call 0005ch		;449a
	ld hl,00000h		;449d   ; el primer tercio entero...
	ld de,0e42dh		;44a0
	ld bc,00400h		;44a3
	push bc			;44a6
	call 00059h		;44a7   ; LDIRMV: a la RAM
	pop bc			;44aa
	ld hl,0e42dh		;44ab   ; al segundo tercio
	ld de,00800h		;44ae
	push bc			;44b1
	call 0005ch		;44b2
	pop bc			;44b5
	ld hl,0e42dh		;44b6   ; y al tercero
	ld de,01000h		;44b9
	push bc			;44bc
	call 0005ch		;44bd
	pop bc			;44c0
	ld hl,02000h		;44c1   ; los colores igual
	ld de,0e42dh		;44c4
	push bc			;44c7
	call 00059h		;44c8
	pop bc			;44cb
	ld hl,0e42dh		;44cc
	ld de,02800h		;44cf
	push bc			;44d2
	call 0005ch		;44d3
	pop bc			;44d6
	ld hl,0e42dh		;44d7
	ld de,03000h		;44da
	jp 0005ch		;44dd

; ----------------------------------------------------------------------
; DATOS dibujo_copyright: El dibujo de la casilla 0x51: la C en un circulo
;   0x44e0..0x44e8  (8 bytes)
DATA_dibujo_copyright:
	defb 03ch,042h,099h,0a1h,0a1h,099h,042h,03ch	; 44e0  <B....B<

; ----------------------------------------------------------------------
; DATOS letras_titulo: Las letras que el titulo copia de la fuente de la BIOS
;   a las casillas 0x52-0x69: "ACEGHIKOPRSTUY0123456789"
;   0x44e8..0x4500  (24 bytes)
DATA_letras_titulo:
	defb 041h,043h,045h,047h,048h,049h,04bh,04fh,050h,052h,053h,054h,055h,059h,030h,031h	; 44e8  ACEGHIKOPRSTUY01
	defb 032h,033h,034h,035h,036h,037h,038h,039h	; 44f8  23456789

; ======================================================================
; CODIGO 0x4500..0x455b  (91 bytes)
; ======================================================================


vram_y_espejo:		; B bytes de DE a la VRAM, y su espejo (los bits al reves) en HL; despues el espejo a la VRAM, del reves
	push bc			;4500
vram_y_espejo_byte:
	inc ix		;4501
	dec ix		;4503
	ld a,(de)			;4505   ; el byte...
	out (098h),a		;4506   ; ...a la VRAM
	push bc			;4508
	ld b,008h		;4509   ; sus bits...
vram_y_espejo_bit:
	rrca			;450b
	rl (hl)		;450c   ; ...al reves en (HL)
	djnz vram_y_espejo_bit		;450e
	pop bc			;4510
	inc de			;4511   ; el siguiente
	inc hl			;4512
	djnz vram_y_espejo_byte		;4513
	pop bc			;4515
	dec hl			;4516   ; el espejo, desde el final
	jp vram_b_atras		;4517   ; el espejo, leido hacia atras
vram_espejo_cuatro:		; B bytes a la VRAM y su espejo; despues el original y el espejo del reves y el espejo derecho
	push bc			;451a
vram_espejo_cuatro_byte:
	inc ix		;451b
	dec ix		;451d
	ld a,(de)			;451f   ; el byte
	out (098h),a		;4520   ; a la VRAM
	push bc			;4522
	ld b,008h		;4523   ; sus 8 bits
vram_espejo_cuatro_bit:
	rrca			;4525
	rl (hl)		;4526   ; al reves en (HL)
	djnz vram_espejo_cuatro_bit		;4528
	pop bc			;452a
	inc de			;452b
	inc hl			;452c
	djnz vram_espejo_cuatro_byte		;452d
	pop bc			;452f
	push bc			;4530
	ex de,hl			;4531   ; el original...
	dec hl			;4532
	call vram_b_atras		;4533   ; el original del reves
	pop bc			;4536   ; ...hacia atras
	push bc			;4537
	ex de,hl			;4538   ; el espejo...
	dec hl			;4539
	call vram_b_atras		;453a   ; el espejo del reves
	pop bc			;453d
	inc hl			;453e   ; y el espejo derecho
	jp vram_b		;453f   ; el espejo
colores_cambiados:		; B colores de HL a la VRAM, y luego hacia atras con la tinta cambiada (el color de arriba en negativo)
	push bc			;4542
	call vram_b		;4543   ; tal cual
	pop bc			;4546
	dec hl			;4547
color_cambiado:
	inc ix		;4548   ; espera
	dec ix		;454a
	ld a,(hl)			;454c   ; el fondo...
	and 00fh		;454d   ; el fondo
	ld c,a			;454f
	ld a,(hl)			;4550   ; ...y la tinta al reves
	cpl			;4551   ; la tinta, en negativo
	and 0f0h		;4552
	or c			;4554   ; juntos
	out (098h),a		;4555   ; a la VRAM
	dec hl			;4557   ; hacia atras
	djnz color_cambiado		;4558
	ret			;455a

; ----------------------------------------------------------------------
; DATOS titulo_nombre: EXOIDE-Z en letras grandes: seis filas de 32 casillas
;   (las que copia 0x4310) y otra vez las mismas
;   0x455b..0x46db  (384 bytes)
DATA_titulo_nombre:
	defb 000h,004h,005h,00dh,00dh,010h,00ah,016h,00eh,016h,032h,00dh,00dh,03eh,005h,010h	; 455b  ..........2..>..
	defb 005h,00dh,02dh,001h,005h,00dh,00dh,010h,001h,001h,005h,00dh,00dh,010h,029h,000h	; 456b  ..-...........).
	defb 000h,004h,00ch,027h,020h,028h,033h,03bh,037h,03fh,00ch,027h,01ch,021h,00ch,021h	; 457b  ...' (3;7?.'.!.!
	defb 00ch,027h,031h,02eh,00ch,027h,020h,028h,001h,001h,01dh,014h,015h,024h,029h,000h	; 458b  .'1..' (.....$).
	defb 000h,004h,00ch,011h,00dh,010h,043h,035h,041h,022h,00ch,021h,00ch,021h,00ch,021h	; 459b  ......C5A".!.!.!
	defb 00ch,021h,00ch,021h,00ch,011h,00dh,010h,007h,013h,001h,038h,040h,022h,029h,000h	; 45ab  .!.!.......8@").
	defb 000h,004h,00ch,027h,020h,028h,00bh,036h,03ah,042h,00ch,021h,00ch,021h,00ch,021h	; 45bb  ...' (.6:B.!.!.!
	defb 00ch,021h,00ch,021h,00ch,027h,020h,028h,01ah,026h,00bh,037h,03fh,001h,029h,000h	; 45cb  .!.!.' (.&.7?.).
	defb 000h,004h,00ch,011h,00dh,010h,038h,040h,034h,03ch,00ch,011h,006h,021h,00ch,021h	; 45db  ......8@4<...!.!
	defb 00ch,011h,02ch,02fh,00ch,011h,00dh,010h,001h,001h,009h,018h,019h,010h,029h,000h	; 45eb  ..,/..........).
	defb 000h,004h,01dh,020h,020h,028h,017h,01fh,017h,023h,039h,020h,020h,03dh,01dh,028h	; 45fb  ...  (...#9  =.(
	defb 01dh,020h,030h,001h,01dh,020h,020h,028h,001h,001h,01dh,020h,020h,028h,029h,000h	; 460b  . 0..  (...  ().
	defb 000h,004h,005h,00dh,00dh,010h,005h,016h,00eh,010h,032h,00dh,00dh,03eh,007h,013h	; 461b  ..........2..>..
	defb 005h,00dh,02dh,001h,005h,00dh,00dh,010h,001h,001h,005h,00dh,00dh,010h,029h,000h	; 462b  ..-...........).
	defb 000h,004h,00ch,027h,020h,028h,033h,03bh,037h,03fh,00ch,027h,01ch,021h,012h,025h	; 463b  ...' (3;7?.'.!.%
	defb 00ch,027h,031h,02eh,00ch,027h,020h,028h,001h,001h,01dh,014h,015h,03fh,029h,000h	; 464b  .'1..' (.....?).
	defb 000h,004h,00ch,011h,00dh,010h,043h,035h,041h,022h,00ch,021h,00ch,021h,00ch,021h	; 465b  ......C5A".!.!.!
	defb 00ch,021h,00ch,021h,00ch,011h,00dh,010h,007h,013h,001h,009h,023h,022h,029h,000h	; 466b  .!.!........#").
	defb 000h,004h,00ch,027h,020h,028h,00bh,036h,03ah,042h,00ch,021h,00ch,021h,00ch,021h	; 467b  ...' (.6:B.!.!.!
	defb 00ch,021h,00ch,021h,00ch,027h,020h,028h,01ah,026h,00bh,00ah,024h,001h,029h,000h	; 468b  .!.!.' (.&..$.).
	defb 000h,004h,00ch,011h,00dh,010h,038h,040h,034h,03ch,00ch,011h,006h,021h,008h,01bh	; 469b  ......8@4<...!..
	defb 00ch,011h,02ch,02fh,00ch,011h,00dh,010h,001h,001h,038h,018h,019h,010h,029h,000h	; 46ab  ..,/......8...).
	defb 000h,004h,01dh,020h,020h,028h,01dh,01fh,017h,028h,039h,020h,020h,03dh,01ah,026h	; 46bb  ...  (...(9  =.&
	defb 01dh,020h,030h,001h,01dh,020h,020h,028h,001h,001h,01dh,020h,020h,028h,029h,000h	; 46cb  . 0..  (...  ().

; ----------------------------------------------------------------------
; DATOS texto_copyright: "(c) 1986 CASIO" en las casillas propias (0x51 la C
;   en un circulo, 0x52-0x69 las letras de 0x44E8)
;   0x46db..0x46e7  (12 bytes)
DATA_texto_copyright:
	defb 051h,000h,061h,069h,068h,066h,000h,053h,052h,05ch,057h,059h	; 46db  Q.aihf.SR\WY

; ----------------------------------------------------------------------
; DATOS texto_highscore: "HIGHSCORE"
;   0x46e7..0x46f0  (9 bytes)
DATA_texto_highscore:
	defb 056h,057h,055h,056h,05ch,053h,059h,05bh,054h	; 46e7  VWUV\SY[T

; ----------------------------------------------------------------------
; DATOS texto_push: "PUSH TRIGGER 1"
;   0x46f0..0x46fe  (14 bytes)
DATA_texto_push:
	defb 05ah,05eh,05ch,056h,000h,05dh,05bh,057h,055h,055h,054h,05bh,000h,061h	; 46f0  Z^\V.][WUUT[.a

; ----------------------------------------------------------------------
; DATOS texto_or: "OR"
;   0x46fe..0x4700  (2 bytes)
DATA_texto_or:
	defb 059h,05bh	; 46fe

; ----------------------------------------------------------------------
; DATOS texto_space: "SPACE KEY"
;   0x4700..0x4709  (9 bytes)
DATA_texto_space:
	defb 05ch,05ah,052h,053h,054h,000h,058h,054h,05fh	; 4700  \ZRST.XT_

; ----------------------------------------------------------------------
; DATOS casillas_emp: Los dibujos de las casillas del juego empaquetados (40
;   bloques, 0x78CA): van a 0xE0D1
;   0x4709..0x47ae  (165 bytes)
DATA_casillas_emp:
	defb 0a0h,0ffh,0c0h,0a0h,0ffh,000h,080h,0c0h,08ah,000h,00fh,00ch,08ah,00ch,0fch,000h	; 4709  ................
	defb 08ah,000h,0ffh,0c0h,08ah,00ch,0fch,0c0h,0a8h,003h,006h,00ch,08ah,000h,03fh,030h	; 4719  ..............?0
	defb 082h,000h,001h,080h,00ch,08ah,000h,0ffh,000h,08ah,000h,01fh,018h,0e0h,0ffh,0feh	; 4729  ................
	defb 003h,08eh,000h,0f0h,0e0h,030h,08eh,030h,01fh,03fh,000h,0b8h,0c0h,07ch,0f8h,00ch	; 4739  .....0.0.?...|..
	defb 08eh,000h,0ffh,0feh,003h,0aah,000h,0ffh,000h,001h,0b2h,000h,0e0h,0c0h,080h,08eh	; 4749  ................
	defb 000h,0f8h,0f0h,018h,0bfh,00ch,01ch,038h,0f0h,0e0h,000h,003h,08fh,000h,0c0h,0f0h	; 4759  .......8........
	defb 03ch,00fh,0f8h,080h,0c0h,060h,070h,030h,087h,000h,001h,003h,006h,0aah,018h,00ch	; 4769  <....`p0........
	defb 006h,003h,0aah,080h,0c0h,060h,030h,0aah,080h,0c0h,060h,030h,082h,000h,080h,0a0h	; 4779  .....`0...`0....
	defb 0f4h,04eh,082h,0feh,04fh,08ah,00eh,0feh,00eh,08ah,00eh,0feh,00eh,0a8h,0feh,00eh	; 4789  .N..O...........
	defb 0feh,08ah,00eh,0feh,00eh,082h,00eh,0feh,088h,00eh,0feh,08ah,00eh,0feh,00eh,081h	; 4799  ................
	defb 0feh,00eh,088h,00eh,0feh	; 47a9

; ======================================================================
; CODIGO 0x47ae..0x48f2  (324 bytes)
; ======================================================================


titulo_espera:		; El titulo espera DENTRO de la interrupcion (no pasan cuadros): primero a que se suelte el boton; despues 0x7000 vueltas a que se pulse la barra (0xE098 = 0) o el boton del mando 1 (0xE098 = 1); sin boton, la demostracion
	xor a			;47ae   ; la barra (GTTRIG 0)...
	call 000d8h		;47af   ; GTTRIG
	cp 0ffh		;47b2   ; ...aun pulsada?
	jr z,titulo_espera		;47b4
	ld a,001h		;47b6   ; el boton del mando 1
	call 000d8h		;47b8
	cp 0ffh		;47bb
	jr z,titulo_espera		;47bd
	xor a			;47bf
	ld (0e0cch),a		;47c0
titulo_espera_boton:
	ld hl,(0e09dh)		;47c3   ; una vuelta menos
	dec hl			;47c6
	ld (0e09dh),hl		;47c7
	ld a,h			;47ca   ; acabadas?
	or l			;47cb
	jr nz,titulo_mira		;47cc
	inc a			;47ce   ; la demostracion (0xE09C = 1)
	ld (0e09ch),a		;47cf
	ld hl,demo_boton		;47d2   ; el estado: el boton corta la demostracion
	ld (0e09ah),hl		;47d5
	jp partida		;47d8   ; empieza
titulo_mira:		; La barra o el boton del mando 1
	xor a			;47db   ; el teclado
	ld (0e098h),a		;47dc
	call 000d8h		;47df   ; GTTRIG 0
	cp 0ffh		;47e2
	jr z,titulo_pulsado		;47e4
	ld a,001h		;47e6   ; el mando
	ld (0e098h),a		;47e8
	call 000d8h		;47eb   ; GTTRIG 1
	cp 0ffh		;47ee
	jp nz,titulo_espera_boton		;47f0
titulo_pulsado:
	ld a,(0e0cch)		;47f3   ; 0xE0CC (el sonido de CASIO) acabado?
	and a			;47f6
	jr nz,titulo_espera_boton		;47f7
	call partida_borra		;47f9   ; una partida nueva
	ld hl,partida		;47fc   ; el estado: la partida
	ld (0e09ah),hl		;47ff
	ret			;4802
demo_boton:		; En la demostracion y la presentacion, cada cuadro: la barra o el boton del mando 1 la cortan
	xor a			;4803   ; la barra?
	call 000d8h		;4804   ; GTTRIG 0
	cp 0ffh		;4807
	jr z,estado_siguiente		;4809
	ld a,001h		;480b   ; el boton del mando 1?
	call 000d8h		;480d   ; GTTRIG 1
	cp 0ffh		;4810
	ret nz			;4812
estado_siguiente:		; El estado guardado en 0xE217 (el titulo o la presentacion) y los canales B y C callados
	ld hl,(0e217h)		;4813   ; el siguiente...
	ld (0e09ah),hl		;4816   ; ...es el estado
	call canal_b_calla		;4819   ; el canal B callado
	jp canal_c_calla		;481c   ; y el C
partida:		; La partida: 0xE0CB = 0xC0 y la ronda
	ld a,0c0h		;481f   ; 0xE0CB = 0xC0
	ld (0e0cbh),a		;4821
ronda:		; Una ronda nueva: la ronda (0x4890), la cuenta de 0xE0BC a 0, y 0xE0B3-0xE0B6 a 0
	call ronda_datos		;4824   ; los datos de la ronda
	xor a			;4827
	ld (0e0bch),a		;4828
	ld hl,00000h		;482b
	ld (0e0b3h),hl		;482e
	ld (0e0b5h),hl		;4831
ronda_empieza:		; La ronda empieza (o vuelve a empezar tras una vida): la pantalla, los sprites, la nave, los enemigos, el marcador, el sonido y la tarea de la ronda (0x4C89)
	call 00041h		;4834   ; DISSCR
	ld hl,0e299h		;4837   ; la RAM 0xE299-0xEC2C...
	ld bc,00994h		;483a
	xor a			;483d   ; ...a cero
	ld (0ec31h),a		;483e
	call llena		;4841
	call scroll_pon		;4844   ; 0x5458
	call pantalla_borra		;4847   ; la pantalla en blanco
	call sprites_ram		;484a   ; los sprites de la RAM
	call sprites_3c00		;484d   ; los dibujos de sprites de 0x3C00
	call vidas_pinta		;4850   ; el marcador
	call ronda_pinta		;4853
	call puntos_pinta		;4856
	call estrellas_pon		;4859   ; 0x61A2
	call fondo_pon		;485c
	call tarea_explosiones		;485f
	call nave_entra_pon		;4862
	call tarea_sprites		;4865
	ld a,001h		;4868   ; las tareas 18 y 20 (los efectos) y la 21, a 1
	ld (0ec3fh),a		;486a
	ld (0ec41h),a		;486d
	ld (0ec42h),a		;4870
	ld a,00fh		;4873   ; los efectos de los canales A y C, parados
	ld (0e3d5h),a		;4875
	ld (0e3dbh),a		;4878
	call 00044h		;487b   ; ENASCR
	ld a,(0e0cbh)		;487e   ; 0xE0CB?
	and a			;4881
	ld a,002h		;4882   ; 2...
	jr z,ronda_musica		;4884
	dec a			;4886   ; ...o 1 (y 0xE3FB)
	ld (0e3fbh),a		;4887
ronda_musica:
	ld (0e3f2h),a		;488a   ; 0xE3F2
	jp tarea_musica		;488d
ronda_datos:		; Los datos de la ronda: el mapa de la estacion (0x4999 por la ronda & 3; el de la demostracion en 0x49B4) en 0xE0BF y 0xE0C1, y la oleada de enemigos (0x4AAD, por la ronda: las 8 primeras y luego 4-7) en 0xE0CF y 0xE0BA
	ld hl,049b4h		;4890   ; la demostracion: 0x49B4
	ld a,(0e09ch)		;4893   ; la demostracion?
	and a			;4896
	jr nz,ronda_mapa		;4897
	ld a,(0e0a8h)		;4899   ; la ronda...
	and 003h		;489c   ; ...de 0 a 3
	ld (0e0b9h),a		;489e   ; 0xE0B9 = la ronda & 3
	add a,a			;48a1   ; x 2
	ld hl,04999h		;48a2   ; la tabla
	ld b,000h		;48a5
	ld c,a			;48a7
	add hl,bc			;48a8
	ld a,(hl)			;48a9   ; el mapa
	inc hl			;48aa
	ld h,(hl)			;48ab
	ld l,a			;48ac
	dec hl			;48ad   ; menos 1
ronda_mapa:
	ld (0e0bfh),hl		;48ae   ; el mapa
	ld bc,00020h		;48b1   ; y 32 bytes mas alla
	add hl,bc			;48b4
	ld (0e0c1h),hl		;48b5
	ld a,(0e0a8h)		;48b8   ; la ronda
	cp 008h		;48bb   ; pasada la 8...
	jr c,ronda_oleada		;48bd
	and 003h		;48bf   ; ...las 4-7 otra vez
	add a,004h		;48c1
ronda_oleada:
	add a,a			;48c3
	ld hl,04aadh		;48c4   ; la tabla de oleadas
	ld b,000h		;48c7   ; x 2
	ld c,a			;48c9
	add hl,bc			;48ca
	ld a,(hl)			;48cb   ; la oleada
	inc hl			;48cc
	ld h,(hl)			;48cd
	ld l,a			;48ce
	ld c,(hl)			;48cf   ; dos bytes...
	inc hl			;48d0
	ld b,(hl)			;48d1   ; dos bytes
	inc hl			;48d2
	ld (0e0cfh),bc		;48d3   ; ...en 0xE0CF
	ld (0e0bah),hl		;48d7   ; y el resto en 0xE0BA
	ret			;48da
sprites_ram:		; La tabla de sprites de la RAM (0xE219, 32 sprites) con la Y fuera (0xE0), y seis sprites de 0x48F2 en 0xE281
	ld hl,0e219h		;48db   ; 128 bytes...
	ld bc,00080h		;48de
	ld a,0e0h		;48e1   ; ...de 0xE0
	call llena		;48e3
	ld hl,048f2h		;48e6   ; 24 bytes de 0x48F2...
	ld de,0e281h		;48e9   ; ...a 0xE281
	ld bc,00018h		;48ec
	ldir		;48ef
	ret			;48f1

; ----------------------------------------------------------------------
; DATOS sprites_iniciales: Seis sprites (Y, X, dibujo, color) del principio de
;   la ronda
;   0x48f2..0x490a  (24 bytes)
DATA_sprites_iniciales:
	defb 007h,068h,0e8h,00fh	; 48f2
	defb 007h,078h,0ech,00fh	; 48f6
	defb 007h,088h,0f0h,00fh	; 48fa
	defb 0f7h,000h,0f4h,00fh	; 48fe
	defb 0f7h,010h,0f8h,00fh	; 4902
	defb 0f7h,0e8h,0fch,00fh	; 4906

; ======================================================================
; CODIGO 0x490a..0x4981  (119 bytes)
; ======================================================================


tocado:		; La nave perdida: 0xE0CD = 4, una mas en 0xE0BC, el puntero de la oleada atras; si quedan vidas, una menos y la ronda otra vez; si no, GAME OVER
	ld a,004h		;490a   ; 0xE0CD = 4
	ld (0e0cdh),a		;490c
	ld a,(0e0bch)		;490f   ; una mas en 0xE0BC
	inc a			;4912
	ld (0e0bch),a		;4913
	ld hl,(0e0bah)		;4916   ; la oleada, un paso atras
	dec hl			;4919
	ld (0e0bah),hl		;491a
	ld a,(0e0a9h)		;491d   ; quedan vidas?
	and a			;4920
	jr z,game_over		;4921
	dec a			;4923   ; una menos
	ld (0e0a9h),a		;4924
	call tareas_paradas		;4927   ; las tareas paradas
	ld a,0c0h		;492a   ; 0xE0CB = 0xC0
	ld (0e0cbh),a		;492c
	jp ronda_empieza		;492f   ; la ronda otra vez
game_over:		; GAME OVER: en sprites (las letras de la BIOS a los dibujos de 0x3D20), la musica 5 y 0x250 cuadros; despues la presentacion
	ld hl,00250h		;4932   ; 0x250 cuadros
	ld (0e09dh),hl		;4935
	ld hl,040e5h		;4938   ; despues, la presentacion
	ld (0e217h),hl		;493b
	ld hl,03d20h		;493e   ; los dibujos de 0x3D20...
	ld bc,00100h		;4941
	xor a			;4944
	call 00056h		;4945   ; ...a cero
	ld hl,04991h		;4948   ; GAMEOVER...
	ld de,03d20h		;494b   ; ...a los dibujos de 0x3D20
	ld b,008h		;494e
	call letras_sprites		;4950
	ld hl,04981h		;4953   ; cuatro sprites...
	ld de,0e219h		;4956   ; ...a la tabla de la RAM
	ld bc,00010h		;4959
	ldir		;495c
	ld a,005h		;495e   ; la musica 5
	ld (0e3f2h),a		;4960
game_over_espera:		; La espera de GAME OVER (tambien es la tarea 22): la cuenta; el boton la corta
	ld hl,(0e09dh)		;4963   ; un cuadro menos
	dec hl			;4966
	ld (0e09dh),hl		;4967
	ld a,l			;496a
	or h			;496b
	jr z,game_over_fin		;496c   ; acabada
	ld hl,0ec43h		;496e   ; 0xEC43 a 1 (la tarea, otra vez)
	inc (hl)			;4971
	jp demo_boton		;4972   ; el boton?
game_over_fin:
	ld hl,040e5h		;4975   ; la presentacion
	ld (0e09ah),hl		;4978
	call tareas_paradas		;497b   ; las tareas paradas
	jp presentacion		;497e

; ----------------------------------------------------------------------
; DATOS game_over_sprites: Los cuatro sprites de GAME OVER (Y, X, dibujo,
;   color)
;   0x4981..0x4991  (16 bytes)
DATA_game_over_sprites:
	defb 050h,070h,0a4h,00fh	; 4981
	defb 050h,080h,0a8h,00fh	; 4985
	defb 060h,070h,0ach,00fh	; 4989
	defb 060h,080h,0b0h,00fh	; 498d

; ----------------------------------------------------------------------
; DATOS texto_game_over: "GAMEOVER": las ocho letras que se copian de la
;   fuente de la BIOS a los dibujos de los sprites
;   0x4991..0x4999  (8 bytes)
DATA_texto_game_over:
	defb 047h,041h,04dh,045h,04fh,056h,045h,052h	; 4991  GAMEOVER

; ----------------------------------------------------------------------
; DATOS tabla_mapas: Los mapas de la estacion de las rondas (por la ronda & 3)
;   0x4999..0x49a1  (8 bytes)
DATA_tabla_mapas:
	defw 049a1h,049e2h,04a23h,04a64h	; 4999  -> DATA_mapas 0x49e2 0x4a23 0x4a64

; ----------------------------------------------------------------------
; DATOS mapas: Los mapas de la estacion: filas de casillas (0x81-0x8E y 1-9),
;   0xFF al final de cada uno
;   0x49a1..0x4aad  (268 bytes)
DATA_mapas:
	defb 001h,002h,002h,003h,004h,005h,007h,008h,009h,00ah,00bh,00ch,00dh,00eh,001h,001h	; 49a1  ................
	defb 002h,003h,004h,005h,007h,008h,009h,00ah,00bh,00ch,00dh,00eh,001h,001h,002h,006h	; 49b1  ................
	defb 082h,081h,081h,08ah,08bh,08ch,08dh,08eh,081h,082h,082h,083h,084h,085h,087h,088h	; 49c1  ................
	defb 089h,08ah,08bh,08ch,08dh,08eh,081h,081h,082h,083h,084h,085h,087h,088h,089h,08dh	; 49d1  ................
	defb 0ffh,002h,002h,001h,007h,008h,008h,009h,00ah,00bh,00bh,00bh,00ch,001h,00eh,002h	; 49e1  ................
	defb 002h,007h,008h,008h,008h,009h,002h,001h,002h,00dh,003h,004h,005h,002h,001h,002h	; 49f1  ................
	defb 006h,082h,081h,082h,08ah,08bh,08ch,087h,088h,089h,081h,08dh,083h,084h,084h,084h	; 4a01  ................
	defb 085h,081h,08eh,081h,083h,084h,085h,082h,087h,088h,089h,081h,082h,08ah,08bh,08ch	; 4a11  ................
	defb 08dh,0ffh,002h,002h,003h,004h,005h,007h,008h,009h,00ah,00bh,00ch,00dh,00eh,002h	; 4a21  ................
	defb 002h,003h,004h,005h,007h,008h,009h,00ah,00bh,00ch,00dh,003h,004h,005h,002h,001h	; 4a31  ................
	defb 002h,006h,081h,082h,081h,087h,088h,088h,089h,08ah,08bh,08bh,08bh,08bh,08ch,08dh	; 4a41  ................
	defb 08eh,082h,087h,088h,088h,089h,08ah,08bh,08ch,08dh,08eh,082h,082h,083h,084h,085h	; 4a51  ................
	defb 08dh,08dh,0ffh,003h,004h,004h,004h,005h,001h,002h,002h,001h,007h,008h,008h,008h	; 4a61  ................
	defb 009h,001h,001h,002h,001h,00dh,00dh,00dh,001h,002h,00eh,001h,00ah,00bh,00ch,002h	; 4a71  ................
	defb 001h,002h,006h,081h,082h,081h,08ah,08bh,08bh,08bh,08ch,081h,082h,082h,081h,08dh	; 4a81  ................
	defb 081h,083h,084h,085h,081h,082h,082h,081h,082h,087h,088h,089h,082h,081h,083h,084h	; 4a91  ................
	defb 084h,084h,085h,0ffh,001h,001h,001h,002h,00eh,002h,0ffh,0ffh	; 4aa1  ............

; ----------------------------------------------------------------------
; DATOS oleadas: Las oleadas de enemigos de cada ronda (0x4AAD: ocho punteros;
;   cada una, dos bytes para 0xE0CF y la lista)
;   0x4aad..0x4b3d  (144 bytes)
DATA_oleadas:
	defb 0bdh,04ah,0cdh,04ah,0ddh,04ah,0edh,04ah,0fdh,04ah,00dh,04bh,01dh,04bh,02dh,04bh	; 4aad  .J.J.J.J.J.K.K-K
	defb 0c6h,04ah,004h,002h,080h,00ah,0ffh,0bfh,04ah,005h,010h,002h,004h,00ch,010h,000h	; 4abd  .J......J.......
	defb 0d6h,04ah,002h,080h,006h,009h,0ffh,0cfh,04ah,004h,008h,00ch,005h,011h,002h,000h	; 4acd  .J......J.......
	defb 0e6h,04ah,008h,003h,080h,012h,0ffh,0dfh,04ah,002h,00ah,00ch,003h,006h,005h,000h	; 4add  .J......J.......
	defb 0f6h,04ah,080h,00ah,00fh,007h,0ffh,0efh,04ah,00ah,003h,011h,004h,008h,00eh,000h	; 4aed  .J......J.......
	defb 006h,04bh,002h,005h,080h,006h,0ffh,0ffh,04ah,00ah,00eh,005h,003h,012h,009h,000h	; 4afd  .K......J.......
	defb 016h,04bh,012h,080h,009h,00eh,0ffh,00fh,04bh,003h,005h,00eh,006h,00dh,012h,000h	; 4b0d  .K......K.......
	defb 026h,04bh,009h,00fh,012h,080h,0ffh,01fh,04bh,00eh,013h,00dh,00ah,007h,003h,000h	; 4b1d  &K......K.......
	defb 036h,04bh,080h,00bh,00fh,013h,0ffh,02fh,04bh,003h,005h,00fh,012h,007h,013h,000h	; 4b2d  6K...../K.......

; ======================================================================
; CODIGO 0x4b3d..0x4b58  (27 bytes)
; ======================================================================


vidas_pinta:		; Las vidas en el marcador: el dibujo de la nave (0x4B58) en el sprite de 0x3FE8 y la cifra (9 como mucho) en 0x3FF8
	ld hl,04b58h		;4b3d   ; la nave...
	ld de,03fe8h		;4b40   ; ...al dibujo de 0x3FE8
	ld bc,00008h		;4b43
	call 0005ch		;4b46
	ld de,03ff8h		;4b49   ; la cifra en 0x3FF8
	ld a,(0e0a9h)		;4b4c   ; las vidas
	cp 00ah		;4b4f   ; 10 o mas: 9
	jr c,vidas_cifra		;4b51
	ld a,009h		;4b53
vidas_cifra:
	jp cifra_pinta		;4b55

; ----------------------------------------------------------------------
; DATOS dibujo_nave_vidas: El dibujo de la nave pequena del marcador
;   0x4b58..0x4b60  (8 bytes)
DATA_dibujo_nave_vidas:
	defb 0d6h,0aah,0feh,0feh,0bah,038h,06ch,000h	; 4b58  .....8l.

; ======================================================================
; CODIGO 0x4b60..0x4c2c  (204 bytes)
; ======================================================================


ronda_pinta:		; La ronda en el marcador: R (0x3FB8) y sus dos cifras (0x3FC8 y 0x3FD8)
	ld de,03fb8h		;4b60   ; en 0x3FB8...
	ld a,052h		;4b63   ; ...la R
	call letra_pinta		;4b65
	ld a,(0e0a8h)		;4b68   ; la ronda + 1...
	inc a			;4b6b
	ld bc,01000h		;4b6c   ; B las decenas
ronda_decenas:
	sub 00ah		;4b6f   ; - 10
	jr c,ronda_unidades		;4b71
	inc b			;4b73
	jr ronda_decenas		;4b74
ronda_unidades:
	add a,00ah		;4b76
	ld c,a			;4b78
	ld a,b			;4b79   ; las decenas...
	ld de,03fc8h		;4b7a   ; ...en 0x3FC8
	push bc			;4b7d
	call cifra_pinta		;4b7e
	pop bc			;4b81
	ld a,c			;4b82   ; las unidades en 0x3FD8
	ld de,03fd8h		;4b83
	jp cifra_pinta		;4b86
tarea_puntos:		; La tarea 21: los puntos pedidos (0xE29B, la clase) se suman, cada clase con sus seis cifras de 0x4C3B; en la demostracion, nada; y el sonido de la vida de mas
	call vida_sonido_paso		;4b89   ; el sonido de la vida
	ld a,001h		;4b8c   ; la tarea, otra vez el cuadro siguiente
	ld (0ec42h),a		;4b8e
	ld a,(0e29bh)		;4b91   ; puntos pedidos?
	and a			;4b94
	ret z			;4b95
	dec a			;4b96   ; (clase - 1) x 6
	add a,a			;4b97
	ld b,a			;4b98
	add a,a			;4b99
	add a,b			;4b9a
	ld de,04c3bh		;4b9b   ; la tabla
	add a,e			;4b9e
	ld e,a			;4b9f
	jr nc,puntos_suma_va		;4ba0
	inc d			;4ba2
puntos_suma_va:
	ld a,(0e09ch)		;4ba3   ; la demostracion: no
	and a			;4ba6
	jr nz,puntos_hechos		;4ba7
	ld hl,0e0b0h		;4ba9   ; desde la cifra de abajo
	call puntos_suma		;4bac
	call puntos_pinta		;4baf   ; al marcador
puntos_hechos:
	xor a			;4bb2   ; gastados
	ld (0e29bh),a		;4bb3
	ret			;4bb6
puntos_suma:		; Seis cifras de DE (hacia atras) a las de HL, una por byte, con acarreo; despues, la vida de mas
	ld b,006h		;4bb7   ; seis cifras
puntos_cifra:
	ld a,(de)			;4bb9   ; la cifra + la de la tabla
	add a,(hl)			;4bba
	ld (hl),a			;4bbb
	sub 00ah		;4bbc   ; 10 o mas?
	jr c,puntos_sin_acarreo		;4bbe
	ld (hl),a			;4bc0   ; se lleva una
	dec hl			;4bc1
	inc (hl)			;4bc2
	jr puntos_cifra_sig		;4bc3
puntos_sin_acarreo:
	dec hl			;4bc5
puntos_cifra_sig:
	dec de			;4bc6
	djnz puntos_cifra		;4bc7
	ld hl,0e0b1h		;4bc9   ; la vida de mas: las decenas de millar (0xE0AB) contra 0xE0B1
	ld a,(0e0abh)		;4bcc
	cp (hl)			;4bcf
	jr nz,vida_mas		;4bd0   ; cambian: vida
	inc hl			;4bd2
	ld a,(hl)			;4bd3   ; 0xE0B2...
	and a			;4bd4
	ret nz			;4bd5
	ld a,(0e0ach)		;4bd6   ; ...o los millares en 5
	cp 005h		;4bd9
	ret nz			;4bdb
vida_mas:		; Una vida de mas: apuntada (0xE0B1/0xE0B2), una mas en 0xE0A9, en el marcador, y su sonido
	ld (hl),a			;4bdc   ; apuntada
	ld hl,0e0a9h		;4bdd   ; una vida mas
	inc (hl)			;4be0
	call vidas_pinta		;4be1   ; en el marcador
vida_sonido:		; El sonido de la vida de mas: 0xE299 = 1 y desde el paso 0 (0xE29A)
	xor a			;4be4
	ld (0e29ah),a		;4be5
	inc a			;4be8
	ld (0e299h),a		;4be9
vida_sonido_paso:		; Un paso: el canal C con el tono de 0x4C2C cada cuatro pasos, volumen 15; con un 0, acabado
	ld a,(0e299h)		;4bec   ; sonando?
	and a			;4bef   ; sonando?
	ret z			;4bf0
	xor a			;4bf1
	ld (0ec40h),a		;4bf2   ; la tarea parada
	call canal_b_calla		;4bf5   ; el canal B callado
	ld a,(0e29ah)		;4bf8   ; un paso mas
	inc a			;4bfb
	ld (0e29ah),a		;4bfc   ; un paso mas
	ld e,000h		;4bff   ; tono 0...
	rrca			;4c01   ; ...salvo en los pasos multiplos de 4: el de la tabla
	jr c,vida_sonido_tono		;4c02   ; cada 4 pasos...
	rrca			;4c04
	jr c,vida_sonido_tono		;4c05
	ld c,a			;4c07   ; ...el tono de la tabla
	ld b,e			;4c08
	ld hl,04c2ch		;4c09
	add hl,bc			;4c0c
	ld e,(hl)			;4c0d   ; el tono
vida_sonido_tono:
	ld a,004h		;4c0e   ; el registro 4
	call 00093h		;4c10   ; WRTPSG
	ld a,005h		;4c13   ; el 5 a 0
	ld e,000h		;4c15
	call 00093h		;4c17   ; WRTPSG
	ld a,00ah		;4c1a   ; volumen 15 en el canal C
	ld e,00fh		;4c1c
	call 00093h		;4c1e   ; WRTPSG
	ld a,(hl)			;4c21   ; 0: acabado
	and a			;4c22
	ret nz			;4c23
	ld (0e299h),a		;4c24   ; acabado
	inc a			;4c27
	ld (0ec40h),a		;4c28   ; la tarea, a 1
	ret			;4c2b

; ----------------------------------------------------------------------
; DATOS vida_sonido_datos: Los tonos del sonido de la vida de mas (0 al final)
;   y las seis cifras de los puntos de cada clase (0x4C3B)
;   0x4c2c..0x4c54  (40 bytes)
DATA_vida_sonido_datos:
	defb 06bh,055h,047h,06bh,055h,047h,06bh,055h,047h,000h,000h,000h,000h,001h,000h,000h	; 4c2c  kUGkUGkUG.......
	defb 000h,000h,000h,002h,000h,000h,000h,000h,000h,003h,000h,000h,000h,000h,000h,005h	; 4c3c  ................
	defb 000h,000h,000h,000h,001h,000h,000h,000h	; 4c4c  ........

; ======================================================================
; CODIGO 0x4c54..0x4cd4  (128 bytes)
; ======================================================================


puntos_pinta:		; Las seis cifras de los puntos (0xE0AB) a los dibujos de los sprites del marcador, desde 0x3F40, de 16 en 16
	ld hl,0e0abh		;4c54   ; las cifras
	ld de,03f40h		;4c57   ; el primer dibujo
	ld b,006h		;4c5a   ; seis
puntos_pinta_cifra:
	push hl			;4c5c
	push de			;4c5d
	push bc			;4c5e
	ld a,(hl)			;4c5f   ; la cifra
	call cifra_pinta		;4c60   ; a la VRAM
	pop bc			;4c63
	pop de			;4c64
	pop hl			;4c65
	inc hl			;4c66   ; la cifra siguiente
	ld a,010h		;4c67   ; el dibujo siguiente
	add a,e			;4c69   ; + 16
	ld e,a			;4c6a
	jr nc,puntos_pinta_sig		;4c6b
	inc d			;4c6d
puntos_pinta_sig:
	djnz puntos_pinta_cifra		;4c6e
	ret			;4c70
cifra_pinta:		; La cifra A (como "0" + A) de la fuente de la BIOS a DE en la VRAM
	or 030h		;4c71   ; "0" + A
letra_pinta:		; La letra A de la fuente de la BIOS (CGTABL) a DE: 8 bytes
	ld hl,(00004h)		;4c73   ; la fuente
	ld b,000h		;4c76
	add a,a			;4c78   ; x 8
	rl b		;4c79
	add a,a			;4c7b
	rl b		;4c7c
	add a,a			;4c7e
	rl b		;4c7f
	ld c,a			;4c81
	add hl,bc			;4c82
	ld bc,00008h		;4c83   ; 8 bytes
	jp 0005ch		;4c86   ; LDIRVM
tarea_musica:		; La tarea 19: las dos voces de la musica, una en el canal B (0xE3F2, piezas de 0x7E99) y otra en el C (0xE3FB, piezas de 0x7FC7; en el A si es la 3): cada una se copia al bloque de trabajo 0xE3E4, da un paso y vuelve
	ld a,001h		;4c89   ; otra vez el cuadro siguiente
	ld (0ec40h),a		;4c8b
	ld a,(0e3fbh)		;4c8e   ; la segunda voz: la 3 va en el canal A...
	cp 003h		;4c91
	push af			;4c93
	ld hl,04cd9h		;4c94   ; el canal C...
	jr nz,tarea_musica_c		;4c97
	ld hl,04cdeh		;4c99   ; ...o el A
tarea_musica_c:
	ld de,0e404h		;4c9c   ; la configuracion del canal (5 bytes) a 0xE404
	ld bc,00005h		;4c9f
	ldir		;4ca2
	ld hl,0e3fbh		;4ca4   ; la voz del canal C
	ld de,0e3e4h		;4ca7
	call voz_paso		;4caa
	pop af			;4cad
	call z,efecto_a_corta		;4cae   ; con la 3, el efecto del canal A cortado
	ld hl,04cd4h		;4cb1   ; el canal B
	ld de,0e404h		;4cb4
	ld bc,00005h		;4cb7
	ldir		;4cba
	ld hl,0e3f2h		;4cbc   ; la voz del canal B
	ld de,0e3e4h		;4cbf
voz_paso:		; Una voz: sus 9 bytes a 0xE3E4, un paso de la musica y de vuelta
	push hl			;4cc2
	push de			;4cc3
	ld bc,00009h		;4cc4   ; 9 bytes
	ldir		;4cc7
	call musica		;4cc9   ; un paso
	pop hl			;4ccc
	pop de			;4ccd
	ld bc,00009h		;4cce   ; y de vuelta
	ldir		;4cd1
	ret			;4cd3

; ----------------------------------------------------------------------
; DATOS voces_canales: Los tres canales de la musica, 5 bytes cada uno: el
;   registro del volumen, el del tono, y la lista de piezas (0x4CD4 el B,
;   0x4CD9 el C, 0x4CDE el A)
;   0x4cd4..0x4ce3  (15 bytes)
DATA_voces_canales:
	defb 009h,002h,0fdh,099h,07eh,00ah,004h,0fbh,0c7h,07fh,008h,000h,0fbh,0c7h,07fh	; 4cd4  ....~..........

; ======================================================================
; CODIGO 0x4ce3..0x4e79  (406 bytes)
; ======================================================================


estacion_casillas:		; Los dibujos de la estacion: 21 bloques empaquetados (0x4F95) a 0xEB85 y, en cada tercio, sus casillas hechas con las ordenes de 0x4E79 y los colores de la ronda; despues lo de cada ronda
	ld hl,04f95h		;4ce3   ; empaquetados...
	ld de,0eb85h		;4ce6   ; ...a 0xEB85
	ld b,015h		;4ce9
	call desempaqueta		;4ceb
	ld hl,00000h		;4cee   ; el primer tercio
	ld (0e427h),hl		;4cf1
	call estacion_tercio		;4cf4
	ld hl,00800h		;4cf7   ; el segundo
	ld (0e427h),hl		;4cfa
	call estacion_tercio		;4cfd
	ld hl,01000h		;4d00   ; el tercero
	ld (0e427h),hl		;4d03
estacion_tercio:		; Un tercio: la casilla 0 en blanco, cuatro casillas de 0xEB85, las de las ordenes de 0x4E79; los colores (los de la ronda, 0x501E/0x5032/0x5046/0x505A)
	ld de,00000h		;4d06   ; la casilla 0
	call tercio_setwrt		;4d09   ; en el tercio
	ld b,020h		;4d0c   ; 32 bytes a 0
	xor a			;4d0e
	call vram_relleno		;4d0f
	ld hl,0eb85h		;4d12   ; cuatro casillas de 0xEB85
	ld b,004h		;4d15
estacion_cuatro:
	push hl			;4d17
	push bc			;4d18
	call vram8		;4d19   ; una casilla
	pop bc			;4d1c
	pop hl			;4d1d
	djnz estacion_cuatro		;4d1e
	ld ix,04e79h		;4d20   ; las ordenes de 0x4E79
	call casillas_ordenes		;4d24   ; las ordenes
	ld de,02000h		;4d27   ; los colores
	call tercio_setwrt		;4d2a   ; los colores del tercio
	ld b,020h		;4d2d   ; 32 bytes a 0
	xor a			;4d2f
	call vram_relleno		;4d30   ; la casilla 0 transparente
	ld a,(0e0a8h)		;4d33   ; la ronda (0-3)
	and 003h		;4d36
	ld hl,0501eh		;4d38   ; la 0: 0x501E y 0x47
	ld b,047h		;4d3b
	jr z,estacion_colores		;4d3d
	ld hl,05032h		;4d3f   ; la 1: 0x5032 y 0xC3
	ld b,0c3h		;4d42
	cp 001h		;4d44
	jr z,estacion_colores		;4d46
	ld hl,05046h		;4d48   ; la 2: 0x5046 y 0x69
	ld b,069h		;4d4b
	cp 002h		;4d4d
	jr z,estacion_colores		;4d4f
	ld hl,0505ah		;4d51   ; la 3: 0x505A y 0x1F
	ld b,01fh		;4d54
estacion_colores:
	ld (0eb72h),hl		;4d56   ; los colores de la ronda
	ld a,b			;4d59   ; 32 de ese color
	ld b,020h		;4d5a
	call vram_relleno		;4d5c   ; la casilla 0 en ese color
	ld ix,0506eh		;4d5f   ; las ordenes de colores de 0x506E
	call colores_ordenes		;4d63   ; las ordenes de colores
	ld de,02580h		;4d66   ; y cuatro filas de 8 con el color cambiado
	call colores_cambiados8		;4d69   ; cuatro filas de 8 cambiadas
	ld de,025a0h		;4d6c
	call colores_cambiados8		;4d6f
	ld de,025e0h		;4d72
	call colores_cambiados8		;4d75
	ld de,02600h		;4d78
	call colores_cambiados8		;4d7b
	call estacion_casillas2		;4d7e   ; 0x51AA
	ld a,(0e0a8h)		;4d81   ; lo de cada ronda
	and 003h		;4d84   ; la ronda & 3
	jp z,ronda0_casillas		;4d86
	cp 001h		;4d89
	jp z,ronda1_casillas		;4d8b
	cp 002h		;4d8e
	jp z,ronda2_casillas		;4d90
	jp ronda3_casillas		;4d93
casillas_ordenes:		; Las ordenes de casillas (IX) a 0xEC50 y a la VRAM: 0 acaba; 1 v n, n veces v; 2 dir n, n bytes de dir; 3 n, n grupos de cuatro casillas de 0xEC58 (cada una de 8 bytes con 10 menos)
	ld de,0ec50h		;4d96   ; a 0xEC50
casillas_orden:
	ld a,(ix+000h)		;4d99
	inc ix		;4d9c   ; la orden
	and a			;4d9e   ; 0: acaba
	ret z			;4d9f
	cp 002h		;4da0   ; 2: copia
	jr z,casillas_copia		;4da2
	cp 003h		;4da4   ; 3: a la VRAM
	jr z,casillas_vram		;4da6
	ld a,(ix+000h)		;4da8   ; 1: el valor...
	inc ix		;4dab
	ld b,(ix+000h)		;4dad   ; ...n veces
casillas_repite:
	ld (de),a			;4db0
	inc de			;4db1
	djnz casillas_repite		;4db2
	inc ix		;4db4
	jr casillas_orden		;4db6
casillas_copia:
	ld l,(ix+000h)		;4db8   ; la direccion...
	inc ix		;4dbb
	ld h,(ix+000h)		;4dbd   ; la direccion
	inc ix		;4dc0
	ld c,(ix+000h)		;4dc2   ; ...n bytes
	ld b,000h		;4dc5
	ldir		;4dc7   ; copia
	inc ix		;4dc9
	jr casillas_orden		;4dcb
casillas_vram:
	ld hl,0ec58h		;4dcd   ; desde 0xEC58
	ld b,(ix+000h)		;4dd0
casillas_vram_grupo:
	push bc			;4dd3
	ld b,004h		;4dd4
	push hl			;4dd6
casillas_vram_una:
	push bc			;4dd7
	call casilla_vram		;4dd8   ; una casilla
	pop bc			;4ddb   ; las cuatro
	djnz casillas_vram_una		;4ddc
	pop hl			;4dde
	ld bc,00008h		;4ddf   ; el grupo siguiente (+8)
	add hl,bc			;4de2
	pop bc			;4de3
	djnz casillas_vram_grupo		;4de4
	inc ix		;4de6   ; la orden siguiente
	jr casillas_ordenes		;4de8
casilla_vram:		; 8 bytes a la VRAM y HL 10 atras (las casillas de 0xEC50 se solapan)
	call vram8		;4dea   ; 8 bytes
	ld bc,0000ah		;4ded   ; 10 atras
	and a			;4df0
	sbc hl,bc		;4df1
	ret			;4df3
colores_cambiados8:		; 8 colores de 0xEC25, cambiados por la tabla de la ronda (0xEB72), en DE
	call tercio_setwrt		;4df4   ; en DE
	ld hl,0ec25h		;4df7   ; de 0xEC25
	ld b,008h		;4dfa
color_cambiado8:
	ld a,(hl)			;4dfc
	call color_ronda		;4dfd   ; por la tabla
	out (098h),a		;4e00   ; a la VRAM
	inc hl			;4e02
	djnz color_cambiado8		;4e03
	ret			;4e05
colores_ordenes:		; Lo mismo que 0x4D96 con los colores: cada byte pasa por la tabla de la ronda
	ld de,0ec50h		;4e06
colores_orden:
	ld a,(ix+000h)		;4e09
	inc ix		;4e0c   ; la orden
	and a			;4e0e   ; 0: acaba
	ret z			;4e0f
	cp 002h		;4e10   ; 2: copia
	jr z,colores_copia		;4e12
	cp 003h		;4e14   ; 3: a la VRAM
	jr z,colores_vram		;4e16
	ld a,(ix+000h)		;4e18   ; 1: el valor
	inc ix		;4e1b
	ld b,(ix+000h)		;4e1d   ; n veces
colores_repite:
	ld (de),a			;4e20
	inc de			;4e21
	djnz colores_repite		;4e22
	inc ix		;4e24
	jr colores_orden		;4e26
colores_copia:
	ld l,(ix+000h)		;4e28
	inc ix		;4e2b   ; la direccion
	ld h,(ix+000h)		;4e2d
	inc ix		;4e30
	ld c,(ix+000h)		;4e32   ; cuantos
	ld b,000h		;4e35
	ldir		;4e37   ; copia
	inc ix		;4e39
	jr colores_orden		;4e3b
colores_vram:
	ld hl,0ec58h		;4e3d
	ld b,(ix+000h)		;4e40
colores_vram_grupo:
	push bc			;4e43
	ld b,004h		;4e44
	push hl			;4e46
colores_vram_una:
	push bc			;4e47
	call color_vram8		;4e48   ; una casilla de colores
	pop bc			;4e4b   ; las cuatro
	djnz colores_vram_una		;4e4c
	pop hl			;4e4e
	ld bc,00008h		;4e4f   ; el grupo siguiente
	add hl,bc			;4e52
	pop bc			;4e53
	djnz colores_vram_grupo		;4e54
	inc ix		;4e56   ; la orden siguiente
	jr colores_ordenes		;4e58
color_vram8:
	push de			;4e5a
	ld b,008h		;4e5b
color_vram8_byte:
	ld a,(hl)			;4e5d   ; el color
	call color_ronda		;4e5e   ; por la tabla
	out (098h),a		;4e61   ; a la VRAM
	inc hl			;4e63
	djnz color_vram8_byte		;4e64
	pop de			;4e66
	ld bc,0000ah		;4e67   ; 10 atras
	and a			;4e6a
	sbc hl,bc		;4e6b
	ret			;4e6d
color_ronda:		; A = el byte A de la tabla de colores de la ronda (0xEB72)
	ld de,(0eb72h)		;4e6e   ; la tabla
	add a,e			;4e72
	ld e,a			;4e73
	jr nc,color_ronda_va		;4e74
	inc d			;4e76
color_ronda_va:
	ld a,(de)			;4e77
	ret			;4e78

; ----------------------------------------------------------------------
; DATOS estacion_datos: Las ordenes de las casillas (0x4E79) y de sus colores
;   (0x506E), los dibujos empaquetados (0x4F95, 21 bloques) y las tablas de
;   colores de las cuatro rondas (0x501E, 0x5032, 0x5046, 0x505A)
;   0x4e79..0x51aa  (817 bytes)
DATA_estacion_datos:
	defb 002h,095h,0ebh,008h,002h,08dh,0ebh,010h,003h,002h,001h,000h,008h,002h,08dh,0ebh	; 4e79  ................
	defb 008h,003h,001h,002h,095h,0ebh,008h,001h,000h,008h,003h,001h,002h,0a5h,0ebh,008h	; 4e89  ................
	defb 002h,09dh,0ebh,010h,003h,002h,002h,0b5h,0ebh,008h,002h,0adh,0ebh,010h,003h,002h	; 4e99  ................
	defb 001h,000h,008h,002h,09dh,0ebh,008h,003h,001h,002h,0a5h,0ebh,008h,001h,000h,008h	; 4ea9  ................
	defb 003h,001h,001h,000h,008h,002h,0adh,0ebh,008h,003h,001h,002h,0b5h,0ebh,008h,001h	; 4eb9  ................
	defb 000h,008h,003h,001h,001h,000h,008h,002h,0bdh,0ebh,008h,002h,0a5h,0ebh,008h,002h	; 4ec9  ................
	defb 09dh,0ebh,008h,003h,003h,001h,000h,008h,002h,0c5h,0ebh,008h,002h,0b5h,0ebh,008h	; 4ed9  ................
	defb 002h,0adh,0ebh,008h,003h,003h,002h,0a5h,0ebh,008h,002h,09dh,0ebh,008h,002h,0bdh	; 4ee9  ................
	defb 0ebh,008h,001h,000h,008h,003h,003h,002h,0b5h,0ebh,008h,002h,0adh,0ebh,008h,002h	; 4ef9  ................
	defb 0c5h,0ebh,008h,001h,000h,008h,003h,003h,002h,0a5h,0ebh,008h,002h,0cdh,0ebh,010h	; 4f09  ................
	defb 002h,09dh,0ebh,008h,003h,003h,002h,0b5h,0ebh,008h,002h,0ddh,0ebh,010h,002h,0adh	; 4f19  ................
	defb 0ebh,008h,003h,003h,001h,000h,008h,001h,07eh,008h,002h,08dh,0ebh,008h,003h,002h	; 4f29  ........~.......
	defb 002h,095h,0ebh,008h,001h,07eh,008h,001h,000h,008h,003h,002h,002h,0a5h,0ebh,008h	; 4f39  .....~..........
	defb 002h,0edh,0ebh,010h,002h,09dh,0ebh,008h,003h,003h,002h,0b5h,0ebh,008h,002h,0fdh	; 4f49  ................
	defb 0ebh,010h,002h,0adh,0ebh,008h,003h,003h,001h,000h,018h,003h,002h,002h,0a5h,0ebh	; 4f59  ................
	defb 008h,001h,00fh,008h,003h,001h,001h,00fh,010h,003h,001h,001h,00fh,008h,002h,09dh	; 4f69  ................
	defb 0ebh,008h,003h,001h,002h,0b5h,0ebh,008h,001h,0f0h,008h,003h,001h,001h,0f0h,010h	; 4f79  ................
	defb 003h,001h,001h,0f0h,008h,002h,0adh,0ebh,008h,003h,001h,000h,0ffh,03fh,003h,03fh	; 4f89  .............?.?
	defb 003h,03fh,003h,03fh,003h,0ffh,000h,001h,03fh,003h,03fh,003h,03fh,003h,0ffh,03fh	; 4f99  .?.?....?.?.?..?
	defb 003h,03fh,003h,03fh,003h,07fh,0ffh,0c0h,000h,07fh,080h,07fh,0c0h,000h,001h,081h	; 4fa9  .?.?............
	defb 001h,0ffh,0b6h,000h,0ffh,0f0h,0ffh,000h,0b6h,000h,0ffh,00fh,0ffh,000h,0ffh,0ffh	; 4fb9  ................
	defb 080h,0bfh,0a3h,0bfh,0a3h,0bfh,0a3h,0ffh,0bfh,0a3h,0bfh,0a3h,0bfh,0a3h,0bfh,0ffh	; 4fc9  ................
	defb 0ffh,0ffh,001h,0ffh,0c7h,0ffh,0c7h,0ffh,0c7h,0feh,0ffh,0c7h,0ffh,0c7h,0ffh,0c7h	; 4fd9  ................
	defb 0ffh,0ffh,000h,001h,025h,01bh,01fh,02fh,03fh,07fh,0efh,01fh,03fh,01fh,027h,00ah	; 4fe9  ....%../?...?.'.
	defb 002h,000h,0bfh,000h,044h,098h,0f8h,0f4h,0f8h,0fch,0eeh,0f8h,0fch,0f8h,064h,0a8h	; 4ff9  ....D.........d.
	defb 000h,081h,002h,001h,0c0h,004h,003h,0eeh,009h,000h,00ah,009h,000h,00ah,0eeh,009h	; 5009  ................
	defb 000h,00bh,009h,000h,00bh,000h,047h,057h,045h,007h,050h,004h,044h,005h,055h,06fh	; 5019  ......GWE.P.D.Uo
	defb 00fh,087h,0a7h,042h,045h,027h,04ah,057h,048h,000h,0c3h,023h,0c2h,003h,020h,00ch	; 5029  ...BE'JWH..#.. .
	defb 0cch,002h,022h,06fh,00fh,082h,0a2h,0c2h,0c5h,023h,0cah,053h,0c8h,000h,069h,089h	; 5039  .."o.....#.S..i.
	defb 068h,009h,080h,006h,066h,008h,088h,06fh,00fh,088h,0a8h,062h,065h,029h,06ah,059h	; 5049  h...f..o...be)jY
	defb 068h,000h,01fh,0efh,01eh,00fh,0e0h,001h,011h,00eh,0eeh,06fh,00fh,08eh,0aeh,012h	; 5059  h..........o....
	defb 015h,02fh,01ah,05fh,018h,001h,001h,018h,003h,002h,001h,000h,008h,001h,001h,008h	; 5069  ./._............
	defb 003h,001h,001h,001h,008h,001h,000h,008h,003h,001h,001h,002h,007h,001h,001h,001h	; 5079  ................
	defb 001h,002h,00fh,001h,001h,001h,003h,002h,001h,003h,008h,001h,001h,001h,001h,003h	; 5089  ................
	defb 00fh,003h,002h,001h,000h,008h,001h,002h,008h,003h,001h,002h,00dh,0ech,008h,001h	; 5099  ................
	defb 000h,008h,003h,001h,001h,000h,008h,002h,015h,0ech,008h,003h,001h,001h,003h,008h	; 50a9  ................
	defb 001h,000h,008h,003h,001h,001h,000h,008h,001h,004h,002h,001h,005h,004h,001h,006h	; 50b9  ................
	defb 002h,002h,00dh,0ech,008h,001h,002h,008h,003h,003h,001h,000h,008h,001h,004h,002h	; 50c9  ................
	defb 001h,005h,004h,001h,006h,002h,001h,003h,008h,002h,015h,0ech,008h,003h,003h,002h	; 50d9  ................
	defb 00dh,0ech,008h,001h,002h,008h,001h,004h,002h,001h,005h,004h,001h,006h,002h,001h	; 50e9  ................
	defb 000h,008h,003h,003h,001h,003h,008h,002h,015h,0ech,008h,001h,004h,002h,001h,005h	; 50f9  ................
	defb 004h,001h,006h,002h,001h,000h,008h,003h,003h,002h,00dh,0ech,008h,001h,005h,010h	; 5109  ................
	defb 001h,002h,008h,003h,003h,001h,003h,008h,001h,005h,010h,002h,015h,0ech,008h,003h	; 5119  ................
	defb 003h,001h,000h,008h,001h,002h,007h,001h,007h,001h,001h,001h,008h,003h,002h,001h	; 5129  ................
	defb 001h,008h,001h,002h,007h,001h,007h,001h,001h,000h,008h,003h,002h,002h,00dh,0ech	; 5139  ................
	defb 008h,001h,008h,010h,001h,002h,008h,003h,003h,001h,003h,008h,001h,008h,010h,002h	; 5149  ................
	defb 015h,0ech,008h,003h,003h,001h,000h,008h,001h,004h,002h,001h,008h,004h,001h,006h	; 5159  ................
	defb 002h,001h,000h,008h,003h,002h,002h,00dh,0ech,008h,002h,01dh,0ech,008h,003h,001h	; 5169  ................
	defb 002h,01dh,0ech,008h,002h,01dh,0ech,008h,003h,001h,002h,01dh,0ech,008h,001h,002h	; 5179  ................
	defb 008h,003h,001h,001h,003h,008h,002h,01dh,0ech,008h,003h,001h,002h,01dh,0ech,008h	; 5189  ................
	defb 002h,01dh,0ech,008h,003h,001h,002h,01dh,0ech,008h,002h,015h,0ech,008h,003h,001h	; 5199  ................
	defb 000h	; 51a9

; ======================================================================
; CODIGO 0x51aa..0x51cb  (33 bytes)
; ======================================================================


estacion_casillas2:		; Mas casillas en cada tercio: desde la casilla 0xE0 (0x700) las ordenes de 0x51CB, sus colores (0x51EF) y las casillas sueltas de 0x52A8
	ld de,00700h		;51aa   ; la casilla 0xE0
	call tercio_setwrt		;51ad
	ld ix,051cbh		;51b0   ; las ordenes
	call casillas_ordenes		;51b4
	ld de,02700h		;51b7   ; sus colores
	call tercio_setwrt		;51ba
	ld ix,051efh		;51bd
	call colores_ordenes		;51c1
	ld ix,052a8h		;51c4   ; y las sueltas
	jp casillas_sueltas		;51c8

; ----------------------------------------------------------------------
; DATOS estacion_datos2: Las ordenes de las casillas 0xE0 en adelante (0x51CB)
;   y las de sus colores (0x51EF)
;   0x51cb..0x5214  (73 bytes)
DATA_estacion_datos2:
	defb 002h,0a5h,0ebh,008h,001h,000h,001h,001h,07fh,00fh,002h,09dh,0ebh,008h,003h,003h	; 51cb  ................
	defb 002h,0b5h,0ebh,008h,001h,000h,001h,001h,001h,00eh,001h,000h,001h,002h,0adh,0ebh	; 51db  ................
	defb 008h,003h,003h,000h,002h,00dh,0ech,008h,001h,00ch,008h,001h,00dh,007h,001h,001h	; 51eb  ................
	defb 001h,001h,002h,008h,003h,003h,001h,003h,008h,001h,004h,001h,001h,00eh,007h,001h	; 51fb  ................
	defb 00fh,008h,002h,015h,0ech,008h,003h,003h,000h	; 520b  .........

; ======================================================================
; CODIGO 0x5214..0x523c  (40 bytes)
; ======================================================================


ronda0_casillas:		; Las casillas propias de la ronda 0 (y 4, 8...): 0x523C desde la casilla 0xC8 y sus colores (0x5259)
	ld ix,0523ch		;5214
	call casillas_c8		;5218
	ld ix,05259h		;521b
	call colores_c8		;521f
	ret			;5222
casillas_c8:		; Las ordenes de IX desde la casilla 0xC8 (0x640) del tercio
	ld de,00640h		;5223   ; la casilla 0xC8
	call tercio_setwrt		;5226
	jp casillas_ordenes		;5229
colores_c8:		; Lo mismo, en los colores (0x2640)
	ld de,02640h		;522c
	call tercio_setwrt		;522f
	jp casillas_ordenes		;5232
tercio_setwrt:		; SETWRT en DE + el tercio que se esta haciendo (0xE427)
	ld hl,(0e427h)		;5235   ; el tercio
	add hl,de			;5238
	jp 00053h		;5239   ; SETWRT

; ----------------------------------------------------------------------
; DATOS ronda0_datos: Las casillas de la ronda 0 (0x523C), sus colores
;   (0x5259) y las casillas sueltas (0x52A8: direccion, color de arriba y de
;   abajo)
;   0x523c..0x52c7  (139 bytes)
DATA_ronda0_datos:
	defb 002h,0a5h,0ebh,008h,002h,078h,052h,010h,002h,09dh,0ebh,008h,003h,003h,002h,0b5h	; 523c  .....xR.........
	defb 0ebh,008h,002h,088h,052h,010h,002h,0adh,0ebh,008h,003h,003h,000h,002h,098h,052h	; 524c  ....R..........R
	defb 008h,001h,089h,010h,001h,057h,008h,003h,003h,001h,045h,008h,001h,068h,007h,001h	; 525c  .....W....E..h..
	defb 060h,002h,001h,068h,007h,002h,0a0h,052h,008h,003h,003h,000h,07fh,03fh,01fh,00fh	; 526c  `..h...R.....?..
	defb 007h,0e3h,001h,0e0h,0e0h,001h,0e3h,007h,00fh,01fh,03fh,07fh,001h,003h,007h,00fh	; 527c  ..........?.....
	defb 01fh,038h,07fh,0f8h,0f8h,07fh,038h,01fh,00fh,007h,003h,001h,057h,057h,057h,057h	; 528c  .8....8.....WWWW
	defb 057h,057h,057h,047h,007h,045h,045h,045h,045h,045h,045h,045h,001h,00bh,027h,010h	; 529c  WWWG.EEEEEEE..'.
	defb 00ch,001h,06bh,027h,00fh,011h,001h,015h,027h,012h,010h,001h,075h,027h,011h,013h	; 52ac  ..k'....'...u'..
	defb 001h,01fh,027h,00dh,012h,001h,07fh,027h,013h,00eh,000h	; 52bc  ..'....'...

; ======================================================================
; CODIGO 0x52c7..0x5316  (79 bytes)
; ======================================================================


casillas_sueltas:		; Casillas de un color: (direccion de los colores, el color de las 8 de arriba, el de las 8 de abajo); 0 acaba
	ld a,(ix+000h)		;52c7   ; 0: acaba
	and a			;52ca
	ret z			;52cb
	inc ix		;52cc
	ld e,(ix+000h)		;52ce   ; la direccion
	inc ix		;52d1
	ld d,(ix+000h)		;52d3
	ld hl,(0e427h)		;52d6   ; en el tercio
	add hl,de			;52d9
	inc ix		;52da
	ld a,(ix+000h)		;52dc   ; el primer color, de la tabla de la ronda
	call color_ronda		;52df
	inc ix		;52e2
	call color8		;52e4   ; 8 filas
	ld a,(ix+000h)		;52e7   ; el segundo
	call color_ronda		;52ea
	inc ix		;52ed
	call color8		;52ef
	jr casillas_sueltas		;52f2
color8:		; El color A en 8 bytes (WRTVRM), saltando a la casilla de abajo cada 8
	ld b,008h		;52f4
color8_byte:
	push af			;52f6
	call 0004dh		;52f7   ; WRTVRM
	inc hl			;52fa
	ld a,l			;52fb   ; al final de la casilla...
	and 007h		;52fc
	jr nz,color8_sig		;52fe
	ld de,00018h		;5300   ; ...la de la fila de abajo (+ 0x18)
	add hl,de			;5303
color8_sig:
	pop af			;5304
	djnz color8_byte		;5305
	ret			;5307
ronda1_casillas:		; Las de la ronda 1: 0x5316 y sus colores
	ld ix,05316h		;5308
	call casillas_c8		;530c
	ld ix,05333h		;530f
	jp colores_c8		;5313

; ----------------------------------------------------------------------
; DATOS ronda1_datos: Las casillas de la ronda 1 y sus colores
;   0x5316..0x5376  (96 bytes)
DATA_ronda1_datos:
	defb 002h,0a5h,0ebh,008h,002h,056h,053h,010h,002h,0a5h,0ebh,008h,003h,003h,002h,0b5h	; 5316  .....VS.........
	defb 0ebh,008h,002h,066h,053h,010h,002h,0adh,0ebh,008h,003h,003h,000h,001h,023h,007h	; 5326  ...fS.........#.
	defb 001h,0c3h,001h,001h,06fh,00ch,001h,0efh,004h,001h,023h,008h,003h,003h,001h,003h	; 5336  ....o.....#.....
	defb 001h,001h,0c2h,007h,001h,0efh,004h,001h,06eh,00ch,001h,0c2h,008h,003h,003h,000h	; 5346  ........n.......
	defb 000h,000h,000h,000h,00fh,008h,00bh,00bh,00bh,00bh,008h,00fh,00fh,01fh,03fh,07fh	; 5356  ..............?.
	defb 000h,001h,003h,007h,0f0h,010h,0d0h,0d0h,0d0h,0d0h,010h,0f0h,000h,000h,000h,000h	; 5366  ................

; ======================================================================
; CODIGO 0x5376..0x5384  (14 bytes)
; ======================================================================


ronda2_casillas:		; Las de la ronda 2: 0x5384 y sus colores (0x53A1)
	ld ix,05384h		;5376
	call casillas_c8		;537a
	ld ix,053a1h		;537d
	jp colores_c8		;5381

; ----------------------------------------------------------------------
; DATOS ronda2_datos: Las casillas de la ronda 2 y sus colores
;   0x5384..0x53ea  (102 bytes)
DATA_ronda2_datos:
	defb 002h,0a5h,0ebh,008h,002h,0cah,053h,010h,002h,0a5h,0ebh,008h,003h,003h,002h,0b5h	; 5384  ......S.........
	defb 0ebh,008h,002h,0dah,053h,010h,002h,0adh,0ebh,008h,003h,003h,000h,001h,089h,007h	; 5394  ....S...........
	defb 001h,069h,001h,001h,038h,005h,001h,030h,006h,001h,0c8h,005h,001h,089h,008h,003h	; 53a4  .i..8..0........
	defb 003h,001h,009h,001h,001h,068h,007h,001h,038h,005h,001h,0c0h,006h,001h,0c8h,005h	; 53b4  .....h..8.......
	defb 001h,068h,008h,003h,003h,000h,007h,00fh,01fh,03fh,07fh,0e5h,0e5h,0e5h,0e5h,0e5h	; 53c4  .h.......?......
	defb 0e5h,07fh,03fh,01fh,00fh,007h,0e0h,0f0h,0f8h,0fch,0feh,0afh,0afh,0afh,0afh,0afh	; 53d4  ..?.............
	defb 0afh,0feh,0fch,0f8h,0f0h,0e0h	; 53e4

; ======================================================================
; CODIGO 0x53ea..0x53f8  (14 bytes)
; ======================================================================


ronda3_casillas:		; Las de la ronda 3: 0x53F8 y sus colores (0x5415)
	ld ix,053f8h		;53ea
	call casillas_c8		;53ee
	ld ix,05415h		;53f1
	jp colores_c8		;53f5

; ----------------------------------------------------------------------
; DATOS ronda3_datos: Las casillas de la ronda 3 y sus colores
;   0x53f8..0x5458  (96 bytes)
DATA_ronda3_datos:
	defb 002h,0a5h,0ebh,008h,002h,038h,054h,010h,002h,0a5h,0ebh,008h,003h,003h,002h,0b5h	; 53f8  .....8T.........
	defb 0ebh,008h,002h,048h,054h,010h,002h,0adh,0ebh,008h,003h,003h,000h,001h,0efh,007h	; 5408  ...HT...........
	defb 001h,01fh,001h,001h,017h,00ch,001h,047h,004h,001h,0efh,008h,003h,003h,001h,00fh	; 5418  .......G........
	defb 001h,001h,01eh,007h,001h,047h,004h,001h,014h,00ch,001h,01eh,008h,003h,003h,000h	; 5428  .....G..........
	defb 000h,000h,000h,000h,003h,004h,009h,00bh,00fh,00fh,007h,003h,00fh,01fh,03fh,07fh	; 5438  ..............?.
	defb 000h,001h,003h,007h,0c0h,0e0h,0f0h,0f0h,0f0h,0f0h,0e0h,0c0h,000h,000h,000h,000h	; 5448  ................

; ======================================================================
; CODIGO 0x5458..0x56b9  (609 bytes)
; ======================================================================


scroll_pon:		; El scroll al empezar: se ensena la tabla 0x1800 (0xE092 = 0x18, 0xE094 = 0x1C), las dos copias de la RAM (0xE44D y 0xE76D) y el registro 2 = 6
	ld a,018h		;5458   ; la que se ensena: 0x1800...
	ld (0e092h),a		;545a
	ld a,01ch		;545d   ; ...y la otra, 0x1C00
	ld (0e094h),a		;545f
	ld hl,0e44dh		;5462   ; la copia que se ensena...
	ld (0e429h),hl		;5465
	ld (0e418h),hl		;5468
	ld hl,0e76dh		;546b   ; ...y la otra
	ld (0e42bh),hl		;546e
	ld a,007h		;5471   ; el registro 2: 7 (0x1C00)...
	ld (0e096h),a		;5473
	dec a			;5476   ; ...y 6 (0x1800), el de ahora
	ld (0e095h),a		;5477
	ld b,a			;547a
	ld c,002h		;547b
	jp 00047h		;547d   ; WRTVDP
fondo_pon:		; El fondo de la ronda: 0xE00F (3 bytes de 0xE267), las casillas de la estacion, la RAM del scroll a cero (0xE42D, 0x640 bytes), el primer trozo del mapa y las dos tablas de nombres; despues el mapa siguiente (0xE0BD) segun las vidas perdidas
	ld hl,0e267h		;5480   ; de 0xE267...
	ld de,0e00fh		;5483   ; ...a 0xE00F...
	ld b,003h		;5486   ; ...3 bytes
	call sprites_yx		;5488
	call estacion_casillas		;548b   ; las casillas de la estacion
	xor a			;548e   ; el paso del scroll a 0
	ld (0e425h),a		;548f
	ld (0ea6dh),a		;5492   ; el desplazamiento de casilla a 0
	ld (0eb6eh),a		;5495   ; 0xEB6E a 0
	dec a			;5498   ; 0xE422 = 0xFF
	ld (0e422h),a		;5499
	ld a,008h		;549c   ; 8 filas por trozo
	ld (0e426h),a		;549e
	ld hl,002c0h		;54a1   ; 0x2C0: la fila 22 de la copia
	ld (0e423h),hl		;54a4
	ld hl,0e42dh		;54a7   ; la RAM del scroll...
	ld bc,00640h		;54aa   ; ...0x640 bytes...
	xor a			;54ad   ; ...a cero
	call llena		;54ae
	xor a			;54b1
	call mapa_trozo_pon		;54b2   ; el primer trozo
	call tarea_scroll		;54b5   ; la tabla de nombres
	call tarea_mapa		;54b8   ; y la otra
	ld hl,(0e0bdh)		;54bb   ; el mapa de la ronda...
	ld b,(hl)			;54be
	ld a,(0e0bch)		;54bf   ; ...y las vidas perdidas en ella (0xE0BC)
	ld hl,(0e0bfh)		;54c2
	ld de,(0e0c1h)		;54c5
	and a			;54c9   ; ninguna: el mapa de 0xE0BF
	jr z,fondo_mapa		;54ca
	cp 003h		;54cc   ; tres o mas: el otro (0xE0C1)
	jr nc,fondo_mapa_otro		;54ce
	bit 7,b		;54d0   ; una o dos: el otro si el mapa lo dice (bit 7)
	jr z,fondo_mapa		;54d2
fondo_mapa_otro:
	ex de,hl			;54d4
fondo_mapa:
	ld (0e0bdh),hl		;54d5   ; el mapa
	ret			;54d8
tarea_scroll:		; La tarea 0, cada cuadro: un tercio de la tabla de nombres escondida (el paso 0xE425: 0, 3, 6, 9 el primero; 1, 4, 7, 10 el segundo; el tercero en los otros) desde la copia, con el desplazamiento 0xEA6D; en los pasos 2, 5, 8 y 11, se cambia de tabla
	ld a,001h		;54d9   ; otra vez en el cuadro siguiente
	ld (0ec2dh),a		;54db
	ld a,(0e425h)		;54de   ; el paso
	ld bc,00000h		;54e1   ; el primer tercio
	cp 000h		;54e4   ; los pasos 0, 3, 6 y 9: el primer tercio
	jr z,scroll_tercio		;54e6
	cp 003h		;54e8
	jr z,scroll_tercio		;54ea
	cp 006h		;54ec
	jr z,scroll_tercio		;54ee
	cp 009h		;54f0
	jr z,scroll_tercio		;54f2
	ld bc,00100h		;54f4   ; el segundo
	cp 001h		;54f7   ; los pasos 1, 4, 7 y 10: el segundo
	jr z,scroll_tercio		;54f9
	cp 004h		;54fb
	jr z,scroll_tercio		;54fd
	cp 007h		;54ff
	jr z,scroll_tercio		;5501
	cp 00ah		;5503
	jr z,scroll_tercio		;5505
	ld bc,00200h		;5507   ; el tercero
scroll_tercio:
	ld hl,(0e093h)		;550a   ; la tabla escondida + el tercio
	add hl,bc			;550d
	call 00053h		;550e   ; SETWRT
	ld hl,(0e429h)		;5511   ; la copia + el tercio
	add hl,bc			;5514
	ld a,(0ea6dh)		;5515   ; el desplazamiento de casilla
	ld d,a			;5518
	ld b,000h		;5519   ; 256 casillas
scroll_casilla:
	ld a,(hl)			;551b   ; la casilla
	add a,d			;551c   ; + el desplazamiento
	out (098h),a		;551d   ; a la VRAM
	inc hl			;551f   ; la siguiente
	djnz scroll_casilla		;5520
	ld a,(0e425h)		;5522   ; el paso 2, 5, 8 u 11?
	cp 002h		;5525   ; los pasos 2, 5, 8 y 11...
	jr z,scroll_cambia		;5527
	cp 005h		;5529
	jr z,scroll_cambia		;552b
	cp 008h		;552d
	jr z,scroll_cambia		;552f
	cp 00bh		;5531
	ret nz			;5533   ; ...cambian de tabla
scroll_cambia:
	call tablas_cambia		;5534   ; se cambia de tabla
	ld a,(0eb6eh)		;5537   ; 0xEB6E = 2: quieto
	cp 002h		;553a
	ret z			;553c
	ld a,(0ea6dh)		;553d   ; si no, el desplazamiento uno mas
	inc a			;5540
	ld (0ea6dh),a		;5541
	ret			;5544
tablas_cambia:		; Se cambian la tabla que se ensena y la escondida (0xE092/0xE094) y los valores del registro 2 (0xE095/0xE096), y el registro 2
	ld hl,0e092h		;5545   ; la tabla que se ensena y la otra
	ld de,0e094h		;5548
	call cambia		;554b
	ld de,0e095h		;554e
	ld hl,0e096h		;5551   ; y los valores del registro 2
	call cambia		;5554
	ld c,002h		;5557   ; el registro 2
	jp 00047h		;5559
cambia:		; (HL) y (DE) se cambian
	ld b,(hl)			;555c   ; el de HL
	ld a,(de)			;555d   ; el de DE...
	ld (hl),a			;555e   ; ...a HL
	ld a,b			;555f
	ld (de),a			;5560   ; y el de HL a DE
	ret			;5561
tarea_mapa:		; La tarea 6: cada cuadro, 0x40 bytes de la copia que se ensena a la escondida, una fila mas arriba (el scroll); cada 12 pasos se cambian las copias y entran 32 casillas nuevas del mapa (contando las 0xC8 en 0xE0B3)
	ld a,001h		;5562   ; otra vez en el cuadro siguiente
	ld (0ec33h),a		;5564
	ld hl,(0e42bh)		;5567   ; la copia escondida...
	ld de,(0e423h)		;556a   ; ...+ la posicion
	add hl,de			;556e
	ex de,hl			;556f
	ld bc,00020h		;5570
	and a			;5573
	sbc hl,bc		;5574
	ld bc,(0e429h)		;5576   ; la que se ensena...
	add hl,bc			;557a
	ld bc,00040h		;557b   ; 0x40 bytes
	ld a,(0eb6eh)		;557e   ; quieto (0xEB6E = 2)?
	cp 002h		;5581
	jr z,tarea_mapa_paso		;5583
	ldir		;5585
tarea_mapa_paso:
	ld hl,(0e423h)		;5587   ; la posicion, dos filas arriba
	ld bc,00040h		;558a   ; dos filas (0x40)
	and a			;558d
	sbc hl,bc		;558e
	ld (0e423h),hl		;5590   ; guardada
	ld a,(0e425h)		;5593   ; el paso siguiente
	inc a			;5596
	ld (0e425h),a		;5597   ; guardado
	cp 00ch		;559a   ; el 12?
	ret nz			;559c
	xor a			;559d   ; el paso a 0
	ld (0e425h),a		;559e   ; el paso a 0
	ld (0ea6dh),a		;55a1   ; sin desplazamiento
	ld a,(0eb6eh)		;55a4   ; quieto?
	cp 002h		;55a7
	jr z,tarea_mapa_nuevo		;55a9
	ld hl,0e429h		;55ab   ; se cambian las copias
	ld de,0e42bh		;55ae
	call cambia		;55b1   ; se cambian las direcciones de las dos copias
	inc hl			;55b4
	inc de			;55b5
	call cambia		;55b6
tarea_mapa_nuevo:		; Un trozo nuevo: 32 casillas del trozo del mapa (0xE427) en la fila de arriba de la copia
	ld hl,002c0h		;55b9   ; la posicion, otra vez a la fila 22
	ld (0e423h),hl		;55bc
	ld a,(0e422h)		;55bf   ; 0xE422?
	and a			;55c2
	ret nz			;55c3
	ld hl,(0e429h)		;55c4   ; la fila de arriba de la copia
	ld bc,00020h		;55c7
	and a			;55ca
	sbc hl,bc		;55cb
	ex de,hl			;55cd
	ld hl,(0e427h)		;55ce   ; el trozo del mapa
	ld a,(0eb6eh)		;55d1
	cp 002h		;55d4
	ret z			;55d6
	ld b,c			;55d7   ; 32 casillas
	ld c,0c8h		;55d8   ; 0xC8: las que se cuentan
	ld ix,(0e0b3h)		;55da
mapa_casilla:
	ld a,(hl)			;55de
	ld (de),a			;55df
	cp c			;55e0   ; una 0xC8?
	jr nz,mapa_casilla_sig		;55e1
	inc ix		;55e3   ; una mas
mapa_casilla_sig:
	inc hl			;55e5
	inc de			;55e6
	djnz mapa_casilla		;55e7
	ld (0e0b3h),ix		;55e9   ; los blancos contados
	ld hl,0e426h		;55ed   ; 8 filas por trozo
	dec (hl)			;55f0   ; una fila menos del trozo
	jr z,mapa_trozo		;55f1   ; acabado: otro
	ld hl,(0e427h)		;55f3   ; la fila siguiente del trozo
	ld bc,00020h		;55f6   ; la fila de arriba del trozo
	and a			;55f9
	sbc hl,bc		;55fa
	ld (0e427h),hl		;55fc   ; guardada
	ret			;55ff
mapa_trozo:		; El trozo siguiente del mapa (0xE0BD): su numero (la mitad baja) en la tabla 0x56B9; el 6 lleva al estado 0x75EE; 0xFF acaba el mapa
	ld (hl),008h		;5600   ; 8 filas otra vez
	ld a,(0eb6eh)		;5602   ; 0xEB6E = 4?
	cp 004h		;5605
	jr z,mapa_trozo_pon		;5607
	ld hl,(0e0bdh)		;5609   ; el trozo siguiente
	inc hl			;560c
	ld (0e0bdh),hl		;560d
	ld a,(hl)			;5610
	cp 0ffh		;5611   ; 0xFF: el final
	jr z,mapa_fin		;5613
mapa_trozo_pon:		; El trozo A: desempaquetado (1 n bytes, copia; 2 n v, n veces v; 0 acaba) en 0xEA6E, y su ultima fila en 0xEB4E
	ld hl,0eb4eh		;5615   ; se lee desde el final
	ld (0e427h),hl		;5618
	and 00fh		;561b   ; su numero
	ld b,a			;561d
	cp 006h		;561e   ; el 6?
	jr nz,mapa_trozo_tabla		;5620
	ld hl,075eeh		;5622   ; el estado 0x75EE
	ld (0e09ah),hl		;5625
	ld a,04fh		;5628   ; 0xEB74 = 0x4F
	ld (0eb74h),a		;562a
	xor a			;562d
	ld (0ec32h),a		;562e
mapa_trozo_tabla:
	ld a,b			;5631
	add a,a			;5632
	ld hl,056b9h		;5633   ; la tabla de trozos
	add a,l			;5636
	ld l,a			;5637
	jr nc,mapa_trozo_dir		;5638
	inc h			;563a
mapa_trozo_dir:
	ld a,(hl)			;563b
	inc hl			;563c
	ld h,(hl)			;563d
	ld l,a			;563e
	call mapa_trozo_vacio		;563f   ; con 0xEB6E = 4, el trozo vacio (0x613B)
	ld de,0ea6eh		;5642   ; a 0xEA6E
mapa_trozo_orden:
	ld a,(hl)			;5645
	and a			;5646   ; 0: acaba
	ret z			;5647   ; 0: acaba
	inc hl			;5648
	cp 002h		;5649   ; 2: repite
	jr z,mapa_trozo_repite		;564b   ; 2: repite
	ld c,(hl)			;564d   ; 1: n bytes tal cual
	ld b,000h		;564e
	inc hl			;5650
	ldir		;5651   ; copia
	jr mapa_trozo_orden		;5653
mapa_trozo_repite:
	ld b,(hl)			;5655   ; n veces...
	inc hl			;5656
	ld a,(hl)			;5657   ; ...v
mapa_trozo_repite_byte:
	ld (de),a			;5658
	inc de			;5659
	djnz mapa_trozo_repite_byte		;565a
	inc hl			;565c
	jr mapa_trozo_orden		;565d
mapa_trozo_vacio:
	ld a,(0eb6eh)		;565f
	cp 004h		;5662
	ret nz			;5664
	ld hl,0613bh		;5665   ; el trozo vacio
	ret			;5668
mapa_fin:		; El mapa acabado: 0xEB6E una mas; con 1, otro mapa (0x4AA5) y las musicas 4 y 3; con 2, el estado 0x675F
	ld a,(0eb6eh)		;5669   ; un paso mas
	inc a			;566c
	ld (0eb6eh),a		;566d
	cp 004h		;5670   ; 4: vacio
	jp z,mapa_trozo_pon		;5672
	cp 002h		;5675   ; 2: el final
	jr z,mapa_final		;5677
	cp 001h		;5679   ; 1: el otro mapa
	ret nz			;567b
	xor a			;567c   ; 0xEC32 a 0
	ld (0ec32h),a		;567d
	ld a,(0e2a6h)		;5680   ; 0xE2A6?
	and a			;5683
	jr nz,mapa_otro		;5684
	ld a,004h		;5686   ; la musica 4...
	ld (0e3f2h),a		;5688
	dec a			;568b   ; ...y la 3
	ld (0e3fbh),a		;568c
mapa_otro:
	ld hl,04aa5h		;568f   ; el mapa de 0x4AA5
	ld (0e0bdh),hl		;5692
	ld a,(hl)			;5695
	jp mapa_trozo_pon		;5696
mapa_final:
	xor a			;5699   ; 0xEC30 a 0
	ld (0ec30h),a		;569a
	inc a			;569d   ; 0xE2AB = 1
	ld (0e2abh),a		;569e
	ld de,0675fh		;56a1   ; el estado 0x675F
	ld (0e09ah),de		;56a4
	ld a,(hl)			;56a8
	jp mapa_trozo_pon		;56a9
estado_56ac:		; Un estado: en el paso 0 del scroll, 0xEB6E = 3 y el estado vacio
	ld a,(0e425h)		;56ac   ; el paso del scroll
	and a			;56af   ; a mitad: nada
	ret nz			;56b0
	ld a,003h		;56b1   ; 0xEB6E = 3
	ld (0eb6eh),a		;56b3
	jp estado_nada		;56b6   ; el estado vacio

; ----------------------------------------------------------------------
; DATOS tabla_trozos: Los 16 trozos de la estacion (el numero es la mitad baja
;   del byte del mapa)
;   0x56b9..0x56d9  (32 bytes)
DATA_tabla_trozos:
	defw 056d9h,0572dh,057aeh,05867h,0590ch,059bdh,05a5ch,05b4fh	; 56b9
	defw 05beeh,05c97h,05d31h,05dd0h,05e79h,05f13h,06006h,060f7h	; 56c9

; ----------------------------------------------------------------------
; DATOS mapa_trozos: Los trozos de la estacion que el scroll mete por arriba:
;   ordenes 1 n (n bytes tal cual), 2 n v (n veces v) y 0 al final; 8 filas de
;   32 casillas cada uno
;   0x56d9..0x613b  (2658 bytes)
DATA_mapa_trozos:
	defb 001h,005h,000h,008h,018h,020h,008h,002h,017h,000h,001h,004h,008h,018h,020h,008h	; 56d9  ..... ........ .
	defb 001h,005h,000h,004h,01ch,024h,004h,002h,017h,000h,001h,004h,004h,01ch,024h,004h	; 56e9  .....$........$.
	defb 001h,005h,000h,004h,018h,020h,004h,002h,017h,000h,001h,004h,004h,018h,020h,004h	; 56f9  ..... ........ .
	defb 001h,005h,000h,00ch,01ch,024h,00ch,002h,017h,000h,001h,004h,00ch,01ch,024h,00ch	; 5709  .....$........$.
	defb 001h,005h,000h,014h,02ch,034h,014h,002h,017h,000h,001h,004h,014h,02ch,034h,014h	; 5719  ....,4.......,4.
	defb 002h,060h,000h,000h,001h,005h,000h,008h,018h,020h,008h,002h,017h,000h,001h,004h	; 5729  .`....... ......
	defb 008h,018h,020h,008h,001h,005h,000h,004h,01ch,024h,004h,002h,017h,000h,001h,004h	; 5739  .. ......$......
	defb 004h,01ch,024h,004h,001h,005h,000h,004h,02ch,034h,004h,002h,017h,000h,001h,004h	; 5749  ..$.....,4......
	defb 004h,02ch,034h,004h,001h,005h,000h,00ch,000h,000h,00ch,002h,017h,000h,001h,004h	; 5759  .,4.............
	defb 00ch,000h,000h,00ch,001h,005h,000h,008h,000h,000h,008h,002h,017h,000h,001h,004h	; 5769  ................
	defb 008h,000h,000h,008h,001h,005h,000h,004h,000h,000h,004h,002h,017h,000h,001h,004h	; 5779  ................
	defb 004h,000h,000h,004h,001h,005h,000h,004h,028h,030h,004h,002h,017h,000h,001h,004h	; 5789  ........(0......
	defb 004h,028h,030h,004h,001h,005h,000h,00ch,01ch,024h,00ch,002h,017h,000h,001h,004h	; 5799  .(0......$......
	defb 00ch,01ch,024h,00ch,000h,001h,005h,000h,008h,018h,020h,008h,002h,017h,000h,001h	; 57a9  ..$....... .....
	defb 004h,008h,018h,020h,008h,001h,009h,000h,004h,01ch,024h,004h,000h,010h,028h,030h	; 57b9  ... ......$...(0
	defb 002h,00fh,000h,001h,008h,028h,030h,010h,000h,004h,01ch,024h,004h,001h,009h,000h	; 57c9  .....(0....$....
	defb 004h,0b0h,0bch,004h,0a8h,004h,01ch,024h,002h,00fh,000h,001h,008h,01ch,024h,004h	; 57d9  .......$......$.
	defb 0a8h,004h,0b0h,0bch,004h,001h,009h,000h,00ch,0b4h,0c0h,00ch,0ach,00ch,0e0h,0ech	; 57e9  ................
	defb 002h,00fh,000h,001h,008h,0e0h,0ech,00ch,0ach,00ch,0b4h,0c0h,00ch,001h,009h,000h	; 57f9  ................
	defb 008h,0b4h,0c0h,008h,000h,008h,0e4h,0f0h,002h,00fh,000h,001h,008h,0e4h,0f0h,008h	; 5809  ................
	defb 000h,008h,0b4h,0c0h,008h,001h,009h,000h,004h,0b4h,0c0h,004h,0a8h,004h,0e8h,0f4h	; 5819  ................
	defb 002h,00fh,000h,001h,008h,0e8h,0f4h,004h,0a8h,004h,0b4h,0c0h,004h,001h,009h,000h	; 5829  ................
	defb 004h,0b8h,0c4h,004h,0ach,00ch,01ch,024h,002h,00fh,000h,001h,008h,01ch,024h,00ch	; 5839  .......$......$.
	defb 0ach,004h,0b8h,0c4h,004h,001h,009h,000h,00ch,01ch,024h,00ch,000h,014h,02ch,034h	; 5849  ..........$...,4
	defb 002h,00fh,000h,001h,008h,02ch,034h,014h,000h,00ch,01ch,024h,00ch,000h,001h,008h	; 5859  .....,4....$....
	defb 000h,008h,0b0h,0bch,004h,01ch,024h,004h,002h,011h,000h,001h,007h,004h,01ch,024h	; 5869  ......$........$
	defb 004h,0b0h,0bch,008h,001h,008h,000h,004h,0b4h,0c0h,004h,0c8h,0d4h,004h,002h,011h	; 5879  ................
	defb 000h,001h,007h,004h,0c8h,0d4h,004h,0b4h,0c0h,004h,001h,008h,000h,004h,0b8h,0c4h	; 5889  ................
	defb 004h,0cch,0d8h,004h,002h,011h,000h,001h,007h,004h,0cch,0d8h,004h,0b8h,0c4h,004h	; 5899  ................
	defb 001h,008h,000h,00ch,01ch,024h,004h,0d0h,0dch,004h,002h,011h,000h,001h,007h,004h	; 58a9  .....$..........
	defb 0d0h,0dch,004h,01ch,024h,00ch,001h,008h,000h,008h,0b0h,0bch,00ch,054h,060h,00ch	; 58b9  ....$........T`.
	defb 002h,011h,000h,001h,007h,00ch,054h,060h,00ch,0b0h,0bch,008h,001h,008h,000h,004h	; 58c9  ......T`........
	defb 0b4h,0c0h,008h,058h,064h,014h,002h,011h,000h,001h,007h,014h,058h,064h,008h,0b4h	; 58d9  ...Xd.......Xd..
	defb 0c0h,004h,001h,005h,000h,004h,0b8h,0c4h,004h,002h,017h,000h,001h,004h,004h,0b8h	; 58e9  ................
	defb 0c4h,004h,001h,005h,000h,00ch,01ch,024h,00ch,002h,017h,000h,001h,004h,00ch,01ch	; 58f9  .......$........
	defb 024h,00ch,000h,001h,008h,000h,008h,0b0h,0bch,004h,01ch,024h,004h,002h,011h,000h	; 5909  $..........$....
	defb 001h,007h,004h,01ch,024h,004h,0b0h,0bch,008h,001h,008h,000h,004h,0b4h,0c0h,004h	; 5919  ....$...........
	defb 0c8h,0d4h,004h,002h,011h,000h,001h,007h,004h,0c8h,0d4h,004h,0b4h,0c0h,004h,001h	; 5929  ................
	defb 008h,000h,004h,0b8h,0c4h,004h,0cch,0d8h,004h,002h,011h,000h,001h,007h,004h,0cch	; 5939  ................
	defb 0d8h,004h,0b8h,0c4h,004h,001h,008h,000h,00ch,01ch,024h,004h,0d0h,0dch,004h,002h	; 5949  ..........$.....
	defb 011h,000h,001h,007h,004h,0d0h,0dch,004h,01ch,024h,00ch,001h,008h,000h,008h,0b0h	; 5959  .........$......
	defb 0bch,004h,01ch,024h,004h,002h,011h,000h,001h,007h,004h,01ch,024h,004h,0b0h,0bch	; 5969  ...$........$...
	defb 008h,001h,008h,000h,004h,0b4h,0c0h,004h,0c8h,0d4h,004h,002h,011h,000h,001h,007h	; 5979  ................
	defb 004h,0c8h,0d4h,004h,0b4h,0c0h,004h,001h,008h,000h,004h,0b8h,0c4h,004h,0cch,0d8h	; 5989  ................
	defb 004h,002h,011h,000h,001h,007h,004h,0cch,0d8h,004h,0b8h,0c4h,004h,001h,008h,000h	; 5999  ................
	defb 00ch,01ch,024h,004h,0d0h,0dch,004h,002h,011h,000h,001h,007h,004h,0d0h,0dch,004h	; 59a9  ..$.............
	defb 01ch,024h,00ch,000h,001h,005h,000h,008h,0b0h,0bch,008h,002h,017h,000h,001h,004h	; 59b9  .$..............
	defb 008h,0b0h,0bch,008h,001h,005h,000h,004h,0b4h,0c0h,004h,002h,017h,000h,001h,004h	; 59c9  ................
	defb 004h,0b4h,0c0h,004h,001h,005h,000h,004h,0b8h,0c4h,00ch,002h,017h,000h,001h,004h	; 59d9  ................
	defb 00ch,0b8h,0c4h,004h,001h,008h,000h,00ch,01ch,024h,008h,038h,044h,010h,002h,011h	; 59e9  .........$.8D...
	defb 000h,001h,007h,010h,038h,044h,008h,01ch,024h,00ch,001h,008h,000h,008h,0b0h,0bch	; 59f9  ....8D..$.......
	defb 004h,03ch,048h,004h,002h,011h,000h,001h,007h,004h,03ch,048h,004h,0b0h,0bch,008h	; 5a09  .<H.......<H....
	defb 001h,008h,000h,004h,0b4h,0c0h,004h,0c8h,0d4h,004h,002h,011h,000h,001h,007h,004h	; 5a19  ................
	defb 0c8h,0d4h,004h,0b4h,0c0h,004h,001h,008h,000h,004h,0b8h,0c4h,004h,0cch,0d8h,004h	; 5a29  ................
	defb 002h,011h,000h,001h,007h,004h,0cch,0d8h,004h,0b8h,0c4h,004h,001h,008h,000h,00ch	; 5a39  ................
	defb 01ch,024h,004h,0d0h,0dch,004h,002h,011h,000h,001h,007h,004h,0d0h,0dch,004h,01ch	; 5a49  .$..............
	defb 024h,00ch,000h,001h,005h,000h,008h,0e0h,0ech,008h,002h,017h,000h,001h,004h,008h	; 5a59  $...............
	defb 0e0h,0ech,008h,001h,0e0h,000h,004h,0e4h,0f0h,004h,080h,038h,044h,080h,000h,080h	; 5a69  ...........8D...
	defb 038h,044h,038h,044h,038h,044h,038h,044h,038h,044h,080h,000h,000h,080h,038h,044h	; 5a79  8D8D8D8D8D....8D
	defb 080h,004h,0e4h,0f0h,004h,000h,004h,0e8h,0f4h,004h,084h,03ch,048h,084h,0a8h,084h	; 5a89  ...........<H...
	defb 03ch,048h,03ch,048h,03ch,048h,03ch,048h,03ch,048h,084h,0a8h,0a8h,084h,03ch,048h	; 5a99  <H<H<H<H<H....<H
	defb 084h,004h,0e8h,0f4h,004h,000h,00ch,01ch,024h,00ch,004h,068h,074h,004h,0ach,00ch	; 5aa9  ........$..ht...
	defb 018h,020h,018h,020h,018h,020h,018h,020h,018h,020h,00ch,0ach,0ach,004h,068h,074h	; 5ab9  . . . . . ....ht
	defb 004h,00ch,01ch,024h,00ch,000h,008h,0e0h,0ech,008h,004h,06ch,078h,004h,000h,008h	; 5ac9  ...$.......lx...
	defb 01ch,024h,01ch,024h,01ch,024h,01ch,024h,01ch,024h,008h,000h,000h,004h,06ch,078h	; 5ad9  .$.$.$.$.$....lx
	defb 004h,008h,0e0h,0ech,008h,000h,004h,0e4h,0f0h,004h,00ch,070h,07ch,00ch,0a8h,00ch	; 5ae9  ...........p|...
	defb 018h,020h,018h,020h,018h,020h,018h,020h,018h,020h,00ch,0a8h,0a8h,00ch,070h,07ch	; 5af9  . . . . . ....p|
	defb 00ch,004h,0e4h,0f0h,004h,000h,004h,0e8h,0f4h,004h,088h,054h,060h,088h,0ach,088h	; 5b09  ...........T`...
	defb 054h,060h,054h,060h,054h,060h,054h,060h,054h,060h,088h,0ach,0ach,088h,054h,060h	; 5b19  T`T`T`T`T`....T`
	defb 088h,004h,0e8h,0f4h,004h,000h,00ch,01ch,024h,00ch,08ch,058h,064h,08ch,000h,08ch	; 5b29  ........$..Xd...
	defb 058h,064h,058h,064h,058h,064h,058h,064h,058h,064h,08ch,000h,000h,08ch,058h,064h	; 5b39  XdXdXdXdXd....Xd
	defb 08ch,00ch,01ch,024h,00ch,000h,001h,00ah,000h,008h,000h,000h,004h,01ch,024h,01ch	; 5b49  ...$..........$.
	defb 024h,004h,002h,012h,000h,001h,004h,008h,0b4h,0c0h,008h,001h,00ah,000h,004h,000h	; 5b59  $...............
	defb 000h,004h,0c8h,0d4h,068h,074h,004h,002h,012h,000h,001h,004h,004h,0b4h,0c0h,004h	; 5b69  ....ht..........
	defb 001h,00ah,000h,004h,028h,030h,004h,0cch,0d8h,06ch,078h,004h,002h,012h,000h,001h	; 5b79  ....(0...lx.....
	defb 004h,004h,0b8h,0c4h,004h,001h,00ah,000h,00ch,01ch,024h,004h,0d0h,0dch,070h,07ch	; 5b89  ..........$...p|
	defb 004h,002h,012h,000h,001h,004h,00ch,01ch,024h,00ch,001h,00ah,000h,008h,018h,020h	; 5b99  ........$...... 
	defb 00ch,054h,060h,054h,060h,00ch,002h,012h,000h,001h,004h,008h,018h,020h,008h,001h	; 5ba9  .T`T`........ ..
	defb 00ah,000h,004h,01ch,024h,008h,058h,064h,058h,064h,014h,002h,012h,000h,001h,004h	; 5bb9  ....$.XdXd......
	defb 004h,01ch,024h,004h,001h,005h,000h,004h,018h,020h,004h,002h,017h,000h,001h,004h	; 5bc9  ..$...... ......
	defb 004h,018h,020h,004h,001h,005h,000h,00ch,01ch,024h,00ch,002h,017h,000h,001h,004h	; 5bd9  .. ......$......
	defb 00ch,01ch,024h,00ch,000h,001h,00ah,000h,008h,000h,000h,004h,01ch,024h,01ch,024h	; 5be9  ..$..........$.$
	defb 004h,002h,012h,000h,001h,004h,008h,0b4h,0c0h,008h,001h,00ah,000h,004h,000h,000h	; 5bf9  ................
	defb 004h,018h,020h,0c8h,0d4h,004h,002h,012h,000h,001h,004h,004h,0b4h,0c0h,004h,001h	; 5c09  .. .............
	defb 00ah,000h,004h,000h,000h,004h,01ch,024h,0cch,0d8h,004h,002h,012h,000h,001h,004h	; 5c19  .......$........
	defb 004h,0b4h,0c0h,004h,001h,00ah,000h,00ch,000h,000h,004h,0c8h,0d4h,0d0h,0dch,004h	; 5c29  ................
	defb 002h,012h,000h,001h,004h,00ch,0b4h,0c0h,00ch,001h,00ah,000h,008h,000h,000h,004h	; 5c39  ................
	defb 0cch,0d8h,01ch,024h,004h,002h,012h,000h,001h,004h,008h,0b4h,0c0h,008h,001h,00ah	; 5c49  ...$............
	defb 000h,004h,000h,000h,004h,0d0h,0dch,0c8h,0d4h,004h,002h,012h,000h,001h,004h,004h	; 5c59  ................
	defb 0b4h,0c0h,004h,001h,00ah,000h,004h,000h,000h,004h,01ch,024h,0cch,0d8h,004h,002h	; 5c69  ...........$....
	defb 012h,000h,001h,004h,004h,0b4h,0c0h,004h,001h,00ah,000h,00ch,000h,000h,004h,018h	; 5c79  ................
	defb 020h,0d0h,0dch,004h,002h,012h,000h,001h,004h,00ch,0b4h,0c0h,00ch,000h,001h,005h	; 5c89   ...............
	defb 000h,008h,018h,020h,008h,002h,017h,000h,001h,004h,008h,018h,020h,008h,001h,005h	; 5c99  ... ........ ...
	defb 000h,004h,01ch,024h,004h,002h,017h,000h,001h,004h,004h,01ch,024h,004h,001h,005h	; 5ca9  ...$........$...
	defb 000h,004h,018h,020h,00ch,002h,017h,000h,001h,004h,004h,018h,020h,004h,001h,00ah	; 5cb9  ... ........ ...
	defb 000h,00ch,01ch,024h,008h,038h,044h,038h,044h,010h,002h,012h,000h,001h,004h,00ch	; 5cc9  ...$.8D8D.......
	defb 01ch,024h,00ch,001h,00ah,000h,008h,018h,020h,004h,03ch,048h,03ch,048h,004h,002h	; 5cd9  .$...... .<H<H..
	defb 012h,000h,001h,004h,008h,018h,020h,008h,001h,00ah,000h,004h,01ch,024h,004h,0c8h	; 5ce9  ...... ......$..
	defb 0d4h,068h,074h,004h,002h,012h,000h,001h,004h,004h,01ch,024h,004h,001h,00ah,000h	; 5cf9  .ht........$....
	defb 004h,02ch,034h,004h,0cch,0d8h,06ch,078h,004h,002h,012h,000h,001h,004h,004h,0b0h	; 5d09  .,4...lx........
	defb 0bch,004h,001h,00ah,000h,00ch,000h,000h,004h,0d0h,0dch,070h,07ch,004h,002h,012h	; 5d19  ...........p|...
	defb 000h,001h,004h,00ch,0b4h,0c0h,00ch,000h,001h,005h,000h,008h,0b4h,0c0h,008h,002h	; 5d29  ................
	defb 012h,000h,001h,009h,004h,01ch,024h,01ch,024h,004h,000h,000h,008h,001h,005h,000h	; 5d39  ......$.$.......
	defb 004h,0b4h,0c0h,004h,002h,012h,000h,001h,009h,004h,068h,074h,0c8h,0d4h,004h,000h	; 5d49  ..........ht....
	defb 000h,004h,001h,005h,000h,004h,0b8h,0c4h,004h,002h,012h,000h,001h,009h,004h,06ch	; 5d59  ...............l
	defb 078h,0cch,0d8h,004h,028h,030h,004h,001h,005h,000h,00ch,01ch,024h,00ch,002h,012h	; 5d69  x...(0......$...
	defb 000h,001h,009h,004h,070h,07ch,0d0h,0dch,004h,01ch,024h,00ch,001h,005h,000h,008h	; 5d79  ....p|....$.....
	defb 018h,020h,008h,002h,012h,000h,001h,009h,00ch,054h,060h,054h,060h,00ch,018h,020h	; 5d89  . .......T`T`.. 
	defb 008h,001h,005h,000h,004h,01ch,024h,004h,002h,012h,000h,001h,009h,014h,058h,064h	; 5d99  ......$.......Xd
	defb 058h,064h,008h,01ch,024h,004h,001h,005h,000h,004h,018h,020h,004h,002h,017h,000h	; 5da9  Xd..$...... ....
	defb 001h,004h,004h,018h,020h,004h,001h,005h,000h,00ch,01ch,024h,00ch,002h,017h,000h	; 5db9  .... ......$....
	defb 001h,004h,00ch,01ch,024h,00ch,000h,001h,005h,000h,008h,0b4h,0c0h,008h,002h,012h	; 5dc9  ....$...........
	defb 000h,001h,009h,004h,01ch,024h,01ch,024h,004h,000h,000h,008h,001h,005h,000h,004h	; 5dd9  .....$.$........
	defb 0b4h,0c0h,004h,002h,012h,000h,001h,009h,004h,0c8h,0d4h,018h,020h,004h,000h,000h	; 5de9  ............ ...
	defb 004h,001h,005h,000h,004h,0b4h,0c0h,004h,002h,012h,000h,001h,009h,004h,0cch,0d8h	; 5df9  ................
	defb 01ch,024h,004h,000h,000h,004h,001h,005h,000h,00ch,0b4h,0c0h,00ch,002h,012h,000h	; 5e09  .$..............
	defb 001h,009h,004h,0d0h,0dch,0c8h,0d4h,004h,000h,000h,00ch,001h,005h,000h,008h,0b4h	; 5e19  ................
	defb 0c0h,008h,002h,012h,000h,001h,009h,004h,01ch,024h,0cch,0d8h,004h,000h,000h,008h	; 5e29  .........$......
	defb 001h,005h,000h,004h,0b4h,0c0h,004h,002h,012h,000h,001h,009h,004h,0c8h,0d4h,0d0h	; 5e39  ................
	defb 0dch,004h,000h,000h,004h,001h,005h,000h,004h,0b4h,0c0h,004h,002h,012h,000h,001h	; 5e49  ................
	defb 009h,004h,0cch,0d8h,01ch,024h,004h,000h,000h,004h,001h,005h,000h,00ch,0b4h,0c0h	; 5e59  .....$..........
	defb 00ch,002h,012h,000h,001h,009h,004h,0d0h,0dch,018h,020h,004h,000h,000h,00ch,000h	; 5e69  .......... .....
	defb 001h,005h,000h,008h,018h,020h,008h,002h,017h,000h,001h,004h,008h,018h,020h,008h	; 5e79  ..... ........ .
	defb 001h,005h,000h,004h,01ch,024h,004h,002h,017h,000h,001h,004h,004h,01ch,024h,004h	; 5e89  .....$........$.
	defb 001h,005h,000h,004h,018h,020h,004h,002h,017h,000h,001h,004h,00ch,018h,020h,004h	; 5e99  ..... ........ .
	defb 001h,005h,000h,00ch,01ch,024h,00ch,002h,012h,000h,001h,009h,010h,038h,044h,038h	; 5ea9  .....$.......8D8
	defb 044h,008h,01ch,024h,00ch,001h,005h,000h,008h,018h,020h,008h,002h,012h,000h,001h	; 5eb9  D..$...... .....
	defb 009h,004h,03ch,048h,03ch,048h,004h,018h,020h,008h,001h,005h,000h,004h,01ch,024h	; 5ec9  ..<H<H.. ......$
	defb 004h,002h,012h,000h,001h,009h,004h,068h,074h,0c8h,0d4h,004h,01ch,024h,004h,001h	; 5ed9  .......ht....$..
	defb 005h,000h,004h,0b0h,0bch,004h,002h,012h,000h,001h,009h,004h,06ch,078h,0cch,0d8h	; 5ee9  ............lx..
	defb 004h,02ch,034h,004h,001h,005h,000h,00ch,0b4h,0c0h,00ch,002h,012h,000h,001h,009h	; 5ef9  .,4.............
	defb 004h,070h,07ch,0d0h,0dch,004h,000h,000h,00ch,000h,001h,005h,000h,008h,018h,020h	; 5f09  .p|............ 
	defb 008h,002h,017h,000h,001h,004h,008h,018h,020h,008h,001h,0e0h,000h,004h,01ch,024h	; 5f19  ........ ......$
	defb 004h,000h,000h,080h,038h,044h,038h,044h,038h,044h,038h,044h,080h,038h,044h,038h	; 5f29  ....8D8D8D8D.8D8
	defb 044h,038h,044h,038h,044h,080h,000h,000h,004h,01ch,024h,004h,000h,004h,02ch,034h	; 5f39  D8D8D.....$...,4
	defb 004h,0a8h,0a8h,084h,03ch,048h,03ch,048h,03ch,048h,03ch,048h,084h,03ch,048h,03ch	; 5f49  ....<H<H<H<H.<H<
	defb 048h,03ch,048h,03ch,048h,084h,0a8h,0a8h,004h,02ch,034h,004h,000h,00ch,000h,000h	; 5f59  H<H<H....,4.....
	defb 00ch,0ach,0ach,004h,0c8h,0d4h,068h,074h,0c8h,0d4h,068h,074h,004h,068h,074h,0c8h	; 5f69  ......ht..ht.ht.
	defb 0d4h,068h,074h,0c8h,0d4h,004h,0ach,0ach,00ch,000h,000h,00ch,000h,008h,000h,000h	; 5f79  .ht.............
	defb 008h,000h,000h,004h,0cch,0d8h,06ch,078h,0cch,0d8h,06ch,078h,004h,06ch,078h,0cch	; 5f89  ......lx..lx.lx.
	defb 0d8h,06ch,078h,0cch,0d8h,004h,000h,000h,008h,000h,000h,008h,000h,004h,000h,000h	; 5f99  .lx.............
	defb 004h,0a8h,0a8h,00ch,0d0h,0dch,070h,07ch,0d0h,0dch,070h,07ch,00ch,070h,07ch,0d0h	; 5fa9  ......p|..p|.p|.
	defb 0dch,070h,07ch,0d0h,0dch,00ch,0a8h,0a8h,004h,000h,000h,004h,000h,004h,028h,030h	; 5fb9  .p|...........(0
	defb 004h,0ach,0ach,088h,054h,060h,054h,060h,054h,060h,054h,060h,088h,054h,060h,054h	; 5fc9  ....T`T`T`T`.T`T
	defb 060h,054h,060h,054h,060h,088h,0ach,0ach,004h,028h,030h,004h,000h,00ch,01ch,024h	; 5fd9  `T`T`....(0....$
	defb 00ch,000h,000h,08ch,058h,064h,058h,064h,058h,064h,058h,064h,08ch,058h,064h,058h	; 5fe9  ....XdXdXdXd.XdX
	defb 064h,058h,064h,058h,064h,08ch,000h,000h,00ch,01ch,024h,00ch,000h,001h,005h,000h	; 5ff9  dXdXd.....$.....
	defb 008h,0e0h,0ech,008h,002h,017h,000h,001h,004h,008h,0e0h,0ech,008h,001h,00dh,000h	; 6009  ................
	defb 004h,0e4h,0f0h,004h,000h,000h,080h,038h,044h,038h,044h,080h,002h,007h,000h,001h	; 6019  .......8D8D.....
	defb 00ch,080h,038h,044h,038h,044h,080h,000h,000h,004h,0e4h,0f0h,004h,001h,00dh,000h	; 6029  ..8D8D..........
	defb 004h,0e8h,0f4h,004h,0a8h,0a8h,084h,03ch,048h,03ch,048h,084h,002h,007h,000h,001h	; 6039  .......<H<H.....
	defb 00ch,084h,03ch,048h,03ch,048h,084h,0a8h,0a8h,004h,0e8h,0f4h,004h,001h,00dh,000h	; 6049  ..<H<H..........
	defb 00ch,01ch,024h,00ch,0ach,0ach,004h,0e0h,0ech,0e0h,0ech,004h,002h,007h,000h,001h	; 6059  ..$.............
	defb 00ch,004h,0e0h,0ech,0e0h,0ech,004h,0ach,0ach,00ch,01ch,024h,00ch,001h,00dh,000h	; 6069  ...........$....
	defb 008h,0e0h,0ech,008h,000h,000h,004h,0e4h,0f0h,0e4h,0f0h,004h,002h,007h,000h,001h	; 6079  ................
	defb 00ch,004h,0e4h,0f0h,0e4h,0f0h,004h,000h,000h,008h,0e0h,0ech,008h,001h,00dh,000h	; 6089  ................
	defb 004h,0e4h,0f0h,004h,0a8h,0a8h,00ch,0e8h,0f4h,0e8h,0f4h,00ch,002h,007h,000h,001h	; 6099  ................
	defb 00ch,00ch,0e8h,0f4h,0e8h,0f4h,00ch,0a8h,0a8h,004h,0e4h,0f0h,004h,001h,00dh,000h	; 60a9  ................
	defb 004h,0e8h,0f4h,004h,0ach,0ach,088h,054h,060h,054h,060h,088h,002h,007h,000h,001h	; 60b9  .......T`T`.....
	defb 00ch,088h,054h,060h,054h,060h,088h,0ach,0ach,004h,0e8h,0f4h,004h,001h,00dh,000h	; 60c9  ..T`T`..........
	defb 00ch,01ch,024h,00ch,000h,000h,08ch,058h,064h,058h,064h,08ch,002h,007h,000h,001h	; 60d9  ..$....XdXd.....
	defb 00ch,08ch,058h,064h,058h,064h,08ch,000h,000h,00ch,01ch,024h,00ch,000h,002h,080h	; 60e9  ..XdXd.....$....
	defb 000h,001h,005h,000h,010h,028h,030h,010h,002h,017h,000h,001h,004h,010h,028h,030h	; 60f9  .....(0.......(0
	defb 010h,001h,005h,000h,004h,01ch,024h,004h,002h,017h,000h,001h,004h,004h,01ch,024h	; 6109  ......$........$
	defb 004h,001h,005h,000h,004h,018h,020h,004h,002h,017h,000h,001h,004h,004h,018h,020h	; 6119  ...... ........ 
	defb 004h,001h,005h,000h,00ch,01ch,024h,00ch,002h,017h,000h,001h,004h,00ch,01ch,024h	; 6129  ......$........$
	defb 00ch,000h	; 6139

; ----------------------------------------------------------------------
; DATOS trozo_vacio: El trozo vacio, con 0xEB6E = 4 (2 0 0: 256 casillas a 0)
;   y siete bytes detras
;   0x613b..0x614f  (20 bytes)
DATA_trozo_vacio:
	defb 002h,000h,000h,000h,013h,018h,020h,02ah,048h,05ch,064h,06eh,094h,09eh,0a6h,0b0h	; 613b  ...... *H\dn....
	defb 0c2h,0d6h,0ech,0fah	; 614b

; ======================================================================
; CODIGO 0x614f..0x6193  (68 bytes)
; ======================================================================


estrellas_casillas:		; Los dibujos de las estrellas: las casillas 0xF8-0xFF de cada tercio, de 0x619A hacia atras (cada una la estrella una fila mas abajo), en celeste (0x70)
	ld hl,007c0h		;614f   ; la casilla 0xF8 del primer tercio
	call estrellas_tercio		;6152
	ld hl,00fc0h		;6155   ; del segundo
	call estrellas_tercio		;6158
	ld hl,017c0h		;615b   ; del tercero
	call estrellas_tercio		;615e
	ld hl,027c0h		;6161   ; sus colores...
	ld bc,00040h		;6164   ; ...64 bytes...
	ld a,070h		;6167   ; ...celeste sobre transparente
	push bc			;6169
	push af			;616a
	call 00056h		;616b   ; FILVRM
	pop af			;616e
	pop bc			;616f
	push bc			;6170
	push af			;6171
	ld hl,02fc0h		;6172   ; el segundo tercio
	call 00056h		;6175
	pop af			;6178
	pop bc			;6179
	ld hl,037c0h		;617a   ; el tercero
	jp 00056h		;617d
estrellas_tercio:		; Las ocho casillas: 8 bytes de 0x6193-0x619A, cada vez uno antes
	call 00053h		;6180   ; SETWRT
	ld hl,0619ah		;6183   ; desde el final
	ld b,008h		;6186   ; ocho casillas
estrellas_casilla:
	push hl			;6188
	push bc			;6189
	call vram8		;618a   ; 8 bytes
	pop bc			;618d   ; la siguiente
	pop hl			;618e
	dec hl			;618f   ; la siguiente empieza un byte antes: la estrella baja
	djnz estrellas_casilla		;6190
	ret			;6192

; ----------------------------------------------------------------------
; DATOS estrella_dibujo: La estrella y siete ceros: leida desde 0x619A hacia
;   atras, cada casilla la tiene una fila mas abajo
;   0x6193..0x61a2  (15 bytes)
DATA_estrella_dibujo:
	defb 000h,000h,000h,000h,000h,000h,000h,010h,000h,000h,000h,000h,000h,000h,000h	; 6193  ...............

; ======================================================================
; CODIGO 0x61a2..0x626a  (200 bytes)
; ======================================================================


estrellas_pon:		; Las estrellas al empezar: sus casillas, la columna 0 (0xE415) y la casilla 0xF7 (0xE41A)
	call estrellas_casillas		;61a2   ; las casillas
	xor a			;61a5   ; la columna 0
	ld (0e415h),a		;61a6
	ld a,0f7h		;61a9   ; la casilla de antes de la primera
	ld (0e41ah),a		;61ab
tarea_estrellas:		; La tarea 1, cada cuadro: en los pasos 2, 5, 8 y 11 del scroll, las 16 estrellas (0x613F, posiciones) en tres tercios pasan a la casilla siguiente (0xF8-0xFF) y cada 8, a la fila de abajo; solo donde la copia del fondo esta vacia
	ld a,001h		;61ae   ; otra vez en el cuadro siguiente
	ld (0ec2eh),a		;61b0
	ld hl,(0e091h)		;61b3   ; la tabla escondida
	ld (0e416h),hl		;61b6   ; la tabla escondida
	ld hl,(0e429h)		;61b9   ; la copia del fondo
	ld (0e418h),hl		;61bc   ; la copia
	ld a,(0e425h)		;61bf   ; el paso 2, 5, 8 u 11?
	cp 002h		;61c2
	jr z,estrellas_mueve		;61c4
	cp 005h		;61c6
	jr z,estrellas_mueve		;61c8
	cp 008h		;61ca
	jr z,estrellas_mueve		;61cc
	cp 00bh		;61ce
	ret nz			;61d0
estrellas_mueve:
	ld b,003h		;61d1   ; tres tercios
	ld c,0f8h		;61d3   ; 0xF8 + ...
	ld a,(0e41ah)		;61d5   ; la casilla siguiente
	inc a			;61d8
	or c			;61d9
	ld (0e41ah),a		;61da
	cp c			;61dd   ; vuelta a 0xF8?
	ld a,(0e415h)		;61de
	jr nz,estrellas_tercio_va		;61e1
	add a,020h		;61e3   ; la fila de abajo (+ 0x20)
	ld (0e415h),a		;61e5
estrellas_tercio_va:
	ld c,a			;61e8
estrellas_tercio2:
	push bc			;61e9
	ld hl,0613fh		;61ea   ; las 16 posiciones
	ld b,010h		;61ed
estrella_una:
	push hl			;61ef
	ld a,c			;61f0   ; la fila + la posicion
	add a,(hl)			;61f1
	ld e,a			;61f2
	ld d,000h		;61f3
	ld hl,(0e418h)		;61f5   ; en la copia...
	add hl,de			;61f8
	ld a,(hl)			;61f9   ; ...el fondo vacio?
	and a			;61fa
	jr nz,estrella_sig		;61fb
	ld hl,(0e416h)		;61fd   ; en la tabla escondida
	add hl,de			;6200
	call 00053h		;6201   ; SETWRT
	ld a,(0e41ah)		;6204   ; la casilla de la estrella
	out (098h),a		;6207
estrella_sig:
	pop hl			;6209
	inc hl			;620a   ; la estrella siguiente
	djnz estrella_una		;620b
	ld hl,0e417h		;620d   ; el tercio siguiente (+ 0x100)
	inc (hl)			;6210   ; el tercio siguiente
	ld hl,0e419h		;6211
	inc (hl)			;6214
	pop bc			;6215
	djnz estrellas_tercio2		;6216
	ret			;6218
tarea_sprites:		; La tarea 2, cada cuadro: los 32 sprites de la RAM (0xE219) a la VRAM (0x1F80)
	ld hl,0ec2fh		;6219   ; otra vez en el cuadro siguiente
	inc (hl)			;621c
	ld de,01f80h		;621d   ; a 0x1F80
	ld hl,0e219h		;6220
	ld bc,00080h		;6223   ; 128 bytes
	jp 0005ch		;6226   ; LDIRVM
nave_entra_pon:		; La nave que entra (los sprites de 0x626A), el estado 0x6286, 0xE00 cuadros para la demostracion
	ld hl,0626ah		;6229   ; los sprites de la nave
	call nave_sprites		;622c
	ld hl,040e5h		;622f   ; despues, la presentacion
	ld (0e217h),hl		;6232
	ld hl,00e00h		;6235   ; la demostracion dura 0xE00 cuadros
	ld (0e09dh),hl		;6238
	ld hl,06286h		;623b   ; el estado: la nave entra
	ld (0e09ah),hl		;623e
	xor a			;6241
	ld (0e2a5h),a		;6242
	ld a,(0e09ch)		;6245   ; la demostracion?
	and a			;6248
	ret nz			;6249
	inc a			;624a   ; 0xE2A8 = 1
	ld (0e2a8h),a		;624b
	ret			;624e
nave_sprites:		; 8 bytes de HL a los dos sprites de la nave (0xE219) y 4 a su sombra (0xE27D); despues las posiciones de 0xE227 (cuatro sprites: Y 8, X 0x0F)
	ld de,0e219h		;624f   ; los dos sprites
	ld bc,00008h		;6252
	ldir		;6255
	ld de,0e27dh		;6257   ; la sombra
	ld bc,00004h		;625a
	ldir		;625d
	ld hl,0e227h		;625f   ; cuatro sprites mas...
	ld de,0080fh		;6262   ; ...en Y 8, X 0x0F
	ld b,004h		;6265
	jp sprites_yx		;6267

; ----------------------------------------------------------------------
; DATOS nave_dibujos: Los sprites de la nave al entrar (0x626A) y al empezar
;   (0x6276): dos sprites y la sombra
;   0x626a..0x6286  (28 bytes)
DATA_nave_dibujos:
	defb 09fh,000h,080h,00fh,0afh,000h,084h,00fh,0a2h,000h,088h,007h,0a7h,07ch,000h,00fh	; 626a  .............|..
	defb 0e0h,0e0h,0e0h,0e0h,0a7h,07ch,004h,007h,08fh,07ch,000h,000h	; 627a  .....|...|..

; ======================================================================
; CODIGO 0x6286..0x6440  (442 bytes)
; ======================================================================


nave_entra:		; El estado del principio: la nave sube hasta Y 0x9F, X 0x7C; despues 64 cuadros parpadeando; despues la ronda empieza (las tareas de la nave, los enemigos y los disparos)
	ld a,(0e09ch)		;6286   ; en la demostracion, el boton
	and a			;6289
	call nz,demo_boton		;628a
	ld a,(0e0cbh)		;628d   ; la espera 0xE0CB?
	and a			;6290
	jr z,nave_entra_mueve		;6291
	dec a			;6293   ; un cuadro menos
	ld (0e0cbh),a		;6294
	ret			;6297
nave_entra_mueve:
	ld ix,0e219h		;6298   ; los sprites de la nave
	ld iy,0e27dh		;629c   ; su sombra
	ld a,(0e2a5h)		;62a0   ; ya en su sitio?
	and a			;62a3
	jr nz,nave_entra_espera		;62a4
	ld bc,0009fh		;62a6   ; hacia Y 0x9F
	call hacia		;62a9
	inc ix		;62ac
	inc iy		;62ae
	ld c,07ch		;62b0   ; hacia X 0x7C
	call hacia		;62b2
	ld a,b			;62b5   ; ya esta?
	and a			;62b6
	ret nz			;62b7
	ld a,040h		;62b8   ; 64 cuadros
	ld (0e2a5h),a		;62ba
	ret			;62bd
nave_entra_espera:
	dec a			;62be
	ld (0e2a5h),a		;62bf
	jr z,nave_entra_fin		;62c2   ; acabados
	cp 010h		;62c4   ; los 16 ultimos...
	ret nc			;62c6
	bit 0,a		;62c7   ; ...uno de cada dos...
	ret z			;62c9
	ld (iy+000h),0e0h		;62ca   ; ...la sombra fuera
	inc (ix+000h)		;62ce
	dec (ix+004h)		;62d1
	ret			;62d4
nave_entra_fin:
	xor a			;62d5   ; 0xE2AB = 0
	ld (0e2abh),a		;62d6
	ld hl,06276h		;62d9   ; los sprites de siempre
	call nave_sprites		;62dc
	call tarea_nave		;62df   ; las tareas de la nave...
	call tarea_disparos		;62e2   ; ...los disparos...
	call enemigos_pon		;62e5   ; ...y los enemigos
	ld a,002h		;62e8   ; la musica 2
	ld (0e3f2h),a		;62ea
	ld hl,estado_espera_scroll		;62ed   ; el estado: 0x62FD, o 0x6305 si el scroll esta parado (0xEB6E)
	ld a,(0eb6eh)		;62f0
	and a			;62f3
	jr z,nave_entra_estado		;62f4
	ld hl,estado_scroll_sigue		;62f6
nave_entra_estado:
	ld (0e09ah),hl		;62f9
	ret			;62fc
estado_espera_scroll:		; Un estado: 0xE422 cuadros y el estado vacio
	ld hl,0e422h		;62fd
	dec (hl)			;6300
	ret nz			;6301
	jp estado_nada		;6302
estado_scroll_sigue:		; Un estado: espera 0xE422 y el trozo 8 del mapa; despues el scroll sigue con el otro mapa (0xE0C1)
	ld hl,0e422h		;6305   ; la espera
	ld a,(hl)			;6308
	and a			;6309   ; acabada?
	jr z,estado_scroll_sigue_va		;630a
	dec (hl)			;630c   ; un cuadro menos
	ret			;630d
estado_scroll_sigue_va:
	ld a,(0e426h)		;630e   ; en la primera fila del trozo?
	cp 008h		;6311
	ret nz			;6313
	xor a			;6314   ; el scroll en marcha
	ld (0eb6eh),a		;6315
	call mapa_trozo_pon		;6318   ; el trozo
	ld hl,(0e0c1h)		;631b   ; el otro mapa
	ld (0e0bdh),hl		;631e
	jp estado_nada		;6321
hacia:		; Un punto de (IX) hacia C, y lo mismo en (IX+4) y (IY); B uno mas si se movio
	ld a,(ix+000h)		;6324   ; ya esta?
	cp c			;6327
	ret z			;6328
	ld c,001h		;6329
	jr c,hacia_va		;632b   ; por debajo: + 1
	ld c,0ffh		;632d
hacia_va:
	inc b			;632f
	ld a,(ix+000h)		;6330   ; un punto en (IX)
	add a,c			;6333   ; un punto
	ld (ix+000h),a		;6334
	ld a,(ix+004h)		;6337   ; en (IX+4)
	add a,c			;633a
	ld (ix+004h),a		;633b
	ld a,(iy+000h)		;633e   ; y en (IY)
	add a,c			;6341
	ld (iy+000h),a		;6342
	ret			;6345
sprites_yx:		; B sprites de 4 bytes desde HL con Y = D y X = E
	ld (hl),d			;6346   ; la Y
	inc hl			;6347
	ld (hl),e			;6348   ; la X
	inc hl			;6349
	inc hl			;634a
	inc hl			;634b   ; el siguiente sprite
	djnz sprites_yx		;634c
	ret			;634e
nave_mandos:		; Los mandos de la nave en DE (D el boton, E la palanca): de verdad (0x77E8) o, en la demostracion, al azar: hacia abajo si esta arriba y una direccion al azar cada 32 cuadros; y la cuenta de la demostracion
	ld a,(0e09ch)		;634f   ; la demostracion?
	and a			;6352
	jp z,mandos		;6353   ; no: los mandos
	call demo_boton		;6356   ; el boton la corta
	ld a,(0e219h)		;6359   ; la Y de la nave
	cp 06fh		;635c   ; por encima de 0x6F: abajo (5)
	ld a,005h		;635e
	jr c,nave_mandos_dir		;6360
	ld a,(0e2a9h)		;6362   ; cada 32 cuadros...
	inc a			;6365
	and 01fh		;6366
	ld (0e2a9h),a		;6368
	ld a,(0e2a7h)		;636b
	jr nz,nave_mandos_dir		;636e
	ld a,r		;6370   ; ...una direccion al azar (1-8)
	and 007h		;6372
	inc a			;6374
nave_mandos_dir:
	ld (0e2a7h),a		;6375
	ld e,a			;6378
	ld d,001h		;6379   ; el boton, siempre
	ld hl,(0e09dh)		;637b   ; la cuenta de la demostracion
	ld a,h			;637e
	or l			;637f
	jr z,nave_mandos_fin		;6380
	dec hl			;6382   ; un cuadro menos
	ld (0e09dh),hl		;6383
	ret			;6386
nave_mandos_fin:		; Acabada: 0xE2A8 y 0xE0CE
	inc a			;6387
	ld (0e2a8h),a		;6388
	ld (0e0ceh),a		;638b
	ret			;638e
tarea_nave:		; La tarea 3: la nave. Si esta tocada (0xE2A6), su explosion; si choca (0x6460), tocada; si no, se mueve con la palanca (la tabla 0x6440)
	ld a,(0e2a6h)		;638f   ; tocada?
	and a			;6392
	jr nz,nave_explota		;6393
	call nave_choca		;6395   ; choca?
	and a			;6398
	jr z,nave_mueve		;6399
	ld a,(0e2a8h)		;639b   ; 0xE2A8?
	and a			;639e
	jr z,nave_mueve		;639f
	ld a,003h		;63a1   ; tocada: 3 pasos
	ld (0e2a6h),a		;63a3
nave_tocada:		; Tocada: la sombra y el segundo sprite fuera, el dibujo 0xD8 (la explosion) en color 10, sin musica; el sonido 0 del canal A
	ld a,0e0h		;63a6   ; fuera
	ld (0e21dh),a		;63a8
	ld (0e221h),a		;63ab
	ld (0e27dh),a		;63ae
	ld a,0d8h		;63b1   ; la explosion
	ld (0e21bh),a		;63b3
	ld a,00ah		;63b6   ; color 10
	ld (0e21ch),a		;63b8
	xor a			;63bb   ; el efecto 0 del canal A, sin musica
	ld (0ec32h),a		;63bc
	ld (0e3d5h),a		;63bf
	ld (0e3f2h),a		;63c2
	ld (0e3fbh),a		;63c5
	inc a			;63c8   ; el efecto, ya
	ld (0ec3fh),a		;63c9
	ld a,010h		;63cc   ; la tarea, en 16 cuadros
	ld (0ec30h),a		;63ce
	ret			;63d1
nave_explota:		; Cada 8 cuadros, el dibujo de la explosion + 4 hasta 0xE8; tres veces; despues, fuera
	ld a,(0e219h)		;63d2   ; ya fuera?
	cp 0e0h		;63d5
	jp z,nave_perdida		;63d7
	ld a,008h		;63da   ; cada 8 cuadros
	ld (0ec30h),a		;63dc
	ld a,(0e21bh)		;63df   ; el dibujo siguiente
	add a,004h		;63e2
	ld (0e21bh),a		;63e4
	cp 0e8h		;63e7   ; el ultimo?
	ret nz			;63e9
	ld a,0d8h		;63ea
	ld (0e21bh),a		;63ec
	ld a,(0e2a6h)		;63ef   ; otra vuelta
	dec a			;63f2
	ld (0e2a6h),a		;63f3
	cp 001h		;63f6
	ret nz			;63f8
	ld a,0e0h		;63f9   ; fuera
	ld (0e219h),a		;63fb
	ld a,060h		;63fe   ; en 96 cuadros
	ld (0ec30h),a		;6400
	ret			;6403
nave_perdida:		; Fuera: en partida, una vida menos (0x490A); en la demostracion, la presentacion
	ld a,(0e09ch)		;6404
	and a			;6407
	jp z,tocado		;6408
	jp presentacion		;640b
nave_mueve:		; Cada cuadro: los mandos; la direccion (1-8) en la tabla 0x6440: el borde y el paso en Y, el borde y el paso en X
	ld a,001h		;640e   ; otra vez en el cuadro siguiente
	ld (0ec30h),a		;6410
	call nave_mandos		;6413   ; los mandos
	ld a,e			;6416   ; la palanca
	and a			;6417
	ret z			;6418
	dec a			;6419   ; (direccion - 1) x 4
	add a,a			;641a
	add a,a			;641b
	ld c,a			;641c
	ld b,000h		;641d
	ld hl,06440h		;641f   ; la tabla
	add hl,bc			;6422
	ld a,(0e219h)		;6423   ; en el borde de Y?
	cp (hl)			;6426
	inc hl			;6427
	jr z,nave_mueve_x		;6428
	add a,(hl)			;642a   ; + el paso
	ld (0e219h),a		;642b
	ld (0e27dh),a		;642e   ; y la sombra
nave_mueve_x:
	inc hl			;6431   ; en el borde de X?
	ld a,(0e21ah)		;6432
	cp (hl)			;6435   ; en el borde?
	ret z			;6436
	inc hl			;6437   ; + el paso
	add a,(hl)			;6438   ; + el paso
	ld (0e21ah),a		;6439
	ld (0e27eh),a		;643c   ; y la sombra
	ret			;643f

; ----------------------------------------------------------------------
; DATOS nave_direcciones: Las ocho direcciones de la palanca: el borde y el
;   paso en Y, el borde y el paso en X
;   0x6440..0x6460  (32 bytes)
DATA_nave_direcciones:
	defb 01fh,0feh,000h,000h	; 6440
	defb 01fh,0feh,0eeh,002h	; 6444
	defb 000h,000h,0eeh,002h	; 6448
	defb 0afh,002h,0eeh,002h	; 644c
	defb 0afh,002h,000h,000h	; 6450
	defb 0afh,002h,002h,0feh	; 6454
	defb 000h,000h,002h,0feh	; 6458
	defb 01fh,0feh,002h,0feh	; 645c

; ======================================================================
; CODIGO 0x6460..0x69a2  (1346 bytes)
; ======================================================================


nave_choca:		; ¿Choca la nave? Con 0xE097 = 0 (la fila 0 del teclado leida al encender: las ocho teclas 0-7 pulsadas), nunca; contra los 8 enemigos de 0xE2BD (0x20 bytes, el estado 1 vivo) y los 4 disparos de 0xE3BF (5 bytes), a menos de 14 puntos; A distinto de 0 si choca
	ld a,(0e097h)		;6460   ; la fila 0 del teclado al encender: 0, la nave no choca
	and a			;6463
	ret z			;6464
	ld hl,0e219h		;6465   ; la nave: D = Y, E = X
	ld d,(hl)			;6468
	inc hl			;6469
	ld e,(hl)			;646a
	ld hl,0e2bdh		;646b   ; los enemigos
	ld bc,0080eh		;646e   ; 8, a menos de 14
nave_choca_enemigo:
	ld a,(hl)			;6471   ; vivo?
	cp 001h		;6472
	ld a,020h		;6474
	jr nz,nave_choca_sig		;6476
	inc hl			;6478
	inc hl			;6479
	call cerca		;647a   ; cerca?
	and a			;647d   ; si: choca
	ret nz			;647e
	ld a,01dh		;647f
nave_choca_sig:
	add a,l			;6481   ; el siguiente (+ 0x20)
	ld l,a			;6482
	jr nc,nave_choca_sig2		;6483
	inc h			;6485
nave_choca_sig2:
	djnz nave_choca_enemigo		;6486   ; el siguiente
	ld hl,0e3bfh		;6488   ; los disparos de los enemigos
	ld bc,0040ah		;648b   ; 4, a menos de 10
nave_choca_disparo:
	ld a,(hl)			;648e   ; en vuelo?
	and a			;648f
	ld a,005h		;6490   ; 5 bytes cada uno
	jr z,nave_choca_disparo_sig		;6492
	inc hl			;6494   ; el siguiente
	call cerca		;6495   ; cerca?
	and a			;6498
	ret nz			;6499
	ld a,003h		;649a   ; 3 mas
nave_choca_disparo_sig:
	add a,l			;649c
	ld l,a			;649d
	jr nc,nave_choca_disparo_sig2		;649e
	inc h			;64a0
nave_choca_disparo_sig2:
	djnz nave_choca_disparo		;64a1   ; el siguiente
	xor a			;64a3
	ret			;64a4
cerca:		; ¿(HL) y (HL+1) a menos de C de D (Y) y E (X)? A = C si si, 0 si no
	ld a,(hl)			;64a5   ; la Y...
	inc hl			;64a6
	sub d			;64a7   ; ...menos la de la nave
	cp c			;64a8
	jr c,cerca_x		;64a9
	neg		;64ab   ; al reves
	cp c			;64ad
	ld a,000h		;64ae   ; no
	ret nc			;64b0
cerca_x:
	ld a,(hl)			;64b1   ; la X
	sub e			;64b2   ; la X menos la de la nave
	cp c			;64b3
	jr c,cerca_si		;64b4
	neg		;64b6   ; al reves
	cp c			;64b8
	ld a,000h		;64b9   ; no
	ret nc			;64bb
cerca_si:
	ld a,c			;64bc
	ret			;64bd
tarea_disparos:		; La tarea 4: los disparos de la nave. El boton dispara (con el boton sostenido, uno cada 16 cuadros); cuatro disparos (0xE29C, sprites desde 0xE225) que suben 0xE0CD puntos por cuadro, chocan con los enemigos (0x6567) y con el suelo (0x65DF) o salen por arriba
	call nave_mandos		;64be   ; los mandos
	ld a,001h		;64c1   ; otra vez el cuadro siguiente
	ld (0ec31h),a		;64c3
	ld hl,0e2a2h		;64c6   ; 0xE2A2 = 1: se puede disparar uno
	ld (hl),a			;64c9
	ld a,d			;64ca   ; el boton?
	cp 001h		;64cb
	jr nz,disparo_suelto		;64cd
	ld a,(0e2a6h)		;64cf   ; tocada...
	ld b,a			;64d2
	ld a,(0e2abh)		;64d3   ; ...o entrando: no
	or b			;64d6
	jr nz,disparos		;64d7
	ld a,(0e2a0h)		;64d9   ; ya sostenido?
	and a			;64dc
	jr z,disparo_pide		;64dd
	ld a,(0e2a1h)		;64df   ; cada 16 cuadros...
	dec a			;64e2
	and 00fh		;64e3
	ld (0e2a1h),a		;64e5
	jr nz,disparos		;64e8
disparo_pide:
	dec (hl)			;64ea   ; uno pedido (0xE2A2 = 0)
	ld a,001h		;64eb   ; sostenido
	ld (0e2a0h),a		;64ed
	dec a			;64f0
	ld (0e2a1h),a		;64f1
	jr disparos		;64f4
disparo_suelto:
	xor a			;64f6   ; suelto
	ld (0e2a0h),a		;64f7
disparos:		; Los cuatro disparos
	ld de,0e29ch		;64fa   ; desde el primero
	ld b,004h		;64fd
disparo_uno:
	ld a,(de)			;64ff   ; en vuelo?
	and a			;6500
	jr nz,disparo_vuela		;6501
	ld a,(0e2a2h)		;6503   ; pedido?
	and a			;6506
	jr nz,disparo_sig		;6507
	inc a			;6509   ; sale
	ld (0e2a2h),a		;650a
	ld (de),a			;650d
	call disparo_sprite		;650e   ; su sprite
	ld a,(0e219h)		;6511   ; en la Y...
	ld (hl),a			;6514
	inc hl			;6515
	ld a,(0e21ah)		;6516   ; ...y la X de la nave
	ld (hl),a			;6519
	ld a,(0e0cdh)		;651a   ; el sonido del disparo (0 o 1, segun 0xE0CD)...
	rrca			;651d
	rrca			;651e
	rrca			;651f
	and 001h		;6520
	ld (0e3dbh),a		;6522   ; ...en el canal C
	ld a,001h		;6525
	ld (0ec41h),a		;6527
disparo_sig:
	inc de			;652a
	djnz disparo_uno		;652b
	ret			;652d
disparo_vuela:
	call disparo_sprite		;652e   ; su sprite
	push hl			;6531
	push de			;6532
	push bc			;6533
	push hl			;6534
	call disparo_enemigo		;6535   ; da a un enemigo?
	pop hl			;6538   ; da a un enemigo?
	and a			;6539
	jr nz,disparo_da		;653a
	call disparo_suelo		;653c   ; da al suelo?
	and a			;653f   ; da al suelo?
	jr nz,disparo_da		;6540
	pop bc			;6542
	pop de			;6543
	pop hl			;6544
	ld a,(0e0cdh)		;6545   ; sube 0xE0CD puntos
	ld c,a			;6548   ; la velocidad del disparo
	ld a,(hl)			;6549   ; la Y...
	sub c			;654a   ; ...sube
	cp 00fh		;654b   ; fuera por arriba?
	jr c,disparo_fin		;654d
	ld (hl),a			;654f   ; la Y nueva
	jr disparo_sig		;6550
disparo_da:
	pop bc			;6552
	pop de			;6553
	pop hl			;6554
disparo_fin:
	ld (hl),0e0h		;6555   ; fuera (Y 0xE0)
	xor a			;6557   ; acabado
	ld (de),a			;6558
	jr disparo_sig		;6559
disparo_sprite:		; HL = el sprite del disparo B (0xE225 + (B - 1) x 4)
	ld a,b			;655b
	dec a			;655c   ; (B - 1) x 4
	add a,a			;655d
	add a,a			;655e
	ld hl,0e225h		;655f   ; los sprites de los disparos
	add a,l			;6562
	ld l,a			;6563
	ret nc			;6564
	inc h			;6565
	ret			;6566
disparo_enemigo:		; ¿El disparo (HL) da a un enemigo? Su casilla de 32 x 32 (el centro, 0x65D1) contra los 8 enemigos de 0xE2BD y las 3 cosas de 0xEB7B; a uno, el estado 2 y los puntos de la clase 1; a otra, una mas en su cuenta
	ld a,(hl)			;6567   ; la Y...
	call hacia_centro		;6568   ; ...hacia el centro
	ld (0e2a3h),a		;656b
	add a,(hl)			;656e
	and 0e0h		;656f   ; en multiplos de 32
	ld d,a			;6571
	inc hl			;6572   ; la X
	ld a,(hl)			;6573
	call hacia_centro		;6574
	ld (0e2a4h),a		;6577
	add a,(hl)			;657a
	and 0e0h		;657b
	ld e,a			;657d
	ld hl,0e2bdh		;657e   ; los enemigos
	ld bc,008e0h		;6581   ; 8, en multiplos de 32
disparo_contra_uno:
	ld a,(hl)			;6584   ; vivo?
	cp 001h		;6585
	ld a,020h		;6587
	jr nz,disparo_contra_sig		;6589
	inc hl			;658b
	inc hl			;658c
	call misma_casilla		;658d   ; en la misma casilla?
	and a			;6590
	jr nz,disparo_enemigo_da		;6591   ; si: le da
	ld a,01dh		;6593
disparo_contra_sig:
	add a,l			;6595
	ld l,a			;6596
	jr nc,disparo_contra_sig2		;6597
	inc h			;6599
disparo_contra_sig2:
	djnz disparo_contra_uno		;659a   ; el siguiente
	ld a,(0eb75h)		;659c   ; hay cosas en 0xEB7B?
	and a			;659f
	ret z			;65a0
	ld hl,0eb7bh		;65a1   ; tres
	ld bc,003e0h		;65a4
disparo_cosa:
	call misma_casilla		;65a7
	and a			;65aa   ; la misma casilla?
	jr nz,disparo_cosa_da		;65ab
	inc hl			;65ad   ; la siguiente (+3)
	inc hl			;65ae
	inc hl			;65af
	djnz disparo_cosa		;65b0
	xor a			;65b2
	ret			;65b3
disparo_cosa_da:
	dec hl			;65b4
	dec hl			;65b5
	dec hl			;65b6
	inc (hl)			;65b7   ; un golpe mas
	ld a,002h		;65b8   ; el efecto 2
	jr disparo_efecto		;65ba
disparo_enemigo_da:
	ld a,001h		;65bc   ; los puntos de la clase 1
	ld (0e29bh),a		;65be
	dec hl			;65c1
	dec hl			;65c2
	dec hl			;65c3
	ld a,002h		;65c4   ; el enemigo, estado 2 (tocado)
	ld (hl),a			;65c6
	dec a			;65c7   ; el efecto 1
disparo_efecto:
	ld (0e3d5h),a		;65c8   ; el efecto del canal A
	ld a,001h		;65cb
	ld (0ec3fh),a		;65cd
	ret			;65d0
hacia_centro:		; El desplazamiento de A hacia el centro de su casilla de 32 (A & 0x1F: hasta 16, -(A & 0x0F); si no, 16 - (A & 0x0F))
	bit 4,a		;65d1   ; en la mitad de arriba?
	jr z,hacia_centro_abajo		;65d3
	and 00fh		;65d5
	neg		;65d7
	ret			;65d9
hacia_centro_abajo:
	cpl			;65da
	and 00fh		;65db
	inc a			;65dd
	ret			;65de
disparo_suelo:		; ¿El disparo da a un blanco del suelo (las casillas 0xC8 y 0xE0)? Mira 2 x 2 casillas de la copia del fondo; si da: los puntos (2 la 0xE0; la 0xC8, 3 y una mas en 0xE0B5), la explosion y el blanco roto (las casillas 0x90-0x9F) en las dos copias y en las dos tablas de nombres
	ld a,(hl)			;65df   ; por debajo de 0x9F: no
	cp 09fh		;65e0   ; por debajo de 0x9F: no
	ld a,000h		;65e2
	ret nc			;65e4
	ld d,a			;65e5   ; la fila de su casilla x 32...
	ld a,(hl)			;65e6   ; la Y / 8...
	and 0f8h		;65e7
	sla a		;65e9   ; ...x 32
	rl d		;65eb
	sla a		;65ed
	rl d		;65ef
	ld e,a			;65f1
	inc hl			;65f2   ; ...+ su columna
	ld a,(hl)			;65f3   ; la X / 8
	and 0f8h		;65f4
	rrca			;65f6
	rrca			;65f7
	rrca			;65f8
	add a,e			;65f9   ; la fila + la columna
	ld e,a			;65fa
	jr nc,disparo_suelo_mira		;65fb
	inc d			;65fd
disparo_suelo_mira:
	ld hl,(0e429h)		;65fe   ; en la copia que se ensena
	add hl,de			;6601   ; la casilla en la copia
	ld bc,0c8e0h		;6602   ; 0xC8 y 0xE0
	ld a,(hl)			;6605   ; la casilla
	cp b			;6606   ; 0xC8?
	jr z,disparo_suelo_da		;6607
	cp c			;6609   ; 0xE0?
	jr z,disparo_suelo_da		;660a
	inc hl			;660c   ; a la derecha
	inc de			;660d
	ld a,(hl)			;660e   ; la de la derecha
	cp b			;660f
	jr z,disparo_suelo_da		;6610
	cp c			;6612
	jr z,disparo_suelo_da		;6613
	ld bc,0001fh		;6615   ; abajo
	add hl,bc			;6618   ; la fila de abajo (+ 0x20 en total)
	ex de,hl			;6619
	add hl,bc			;661a
	ex de,hl			;661b
	ld bc,0c8e0h		;661c
	ld a,(hl)			;661f   ; la de abajo
	cp b			;6620
	jr z,disparo_suelo_da		;6621
	cp c			;6623
	jr z,disparo_suelo_da		;6624
	inc hl			;6626   ; abajo a la derecha
	inc de			;6627
	ld a,(hl)			;6628   ; la de abajo a la derecha
	cp b			;6629
	jr z,disparo_suelo_da		;662a
	cp c			;662c
	ld a,000h		;662d
	ret nz			;662f   ; ninguna: A = 0
disparo_suelo_da:
	ld a,(hl)			;6630   ; la 0xC8?
	cp b			;6631
	ld a,003h		;6632
	jr z,disparo_suelo_c8		;6634
	dec a			;6636   ; la 0xE0: los puntos 2
	call efecto_a_pide		;6637   ; el efecto 2
	ld a,(0eb75h)		;663a   ; sin cosas: a veces (1 de 16) los puntos 5
	and a			;663d
	ret nz			;663e
	ld a,r		;663f   ; a veces...
	and 00fh		;6641
	ret nz			;6643
	ld a,005h		;6644   ; ...los puntos 5
	jr disparo_suelo_puntos		;6646
disparo_suelo_c8:
	ld hl,(0e0b5h)		;6648   ; una 0xC8 rota mas
	inc hl			;664b
	ld (0e0b5h),hl		;664c
disparo_suelo_puntos:
	ld (0e29bh),a		;664f   ; los puntos
	ld a,001h		;6652   ; el efecto 1
	call efecto_a_pide		;6654
	push de			;6657
	call explosion_pon		;6658   ; la explosion
	pop de			;665b
	ld hl,(0e429h)		;665c   ; el blanco roto en la copia que se ensena...
	call roto_ram		;665f
	ld hl,(0e42bh)		;6662   ; ...y en la otra, una fila mas abajo
	ld bc,00020h		;6665
	add hl,bc			;6668
	call roto_ram		;6669
	ld hl,(0e091h)		;666c   ; y en las dos tablas de nombres
	ld a,(0e425h)		;666f
	cp 002h		;6672
	jr nc,disparo_suelo_vram		;6674
	ld bc,0ffe0h		;6676   ; una fila arriba en los pasos 0 y 1
	add hl,bc			;6679
disparo_suelo_vram:
	call roto_vram		;667a
	ld hl,(0e093h)		;667d
	call roto_vram		;6680
	ld a,001h		;6683   ; A = 1: dio
	ret			;6685
roto_vram:		; El blanco roto en la VRAM: tres filas de dos casillas (0x90 + el desplazamiento y 12 mas) en HL + DE
	add hl,de			;6686
	ld c,090h		;6687   ; la casilla 0x90
	ld b,003h		;6689   ; tres filas
roto_vram_fila:
	push bc			;668b
	ld a,(0ea6dh)		;668c   ; el desplazamiento del scroll
	add a,c			;668f   ; + la casilla
	call 0004dh		;6690   ; WRTVRM
	inc hl			;6693   ; a la derecha
	ld a,(0ea6dh)		;6694
	add a,c			;6697
	add a,00ch		;6698   ; la de la derecha, + 12
	call 0004dh		;669a   ; WRTVRM
	ld b,000h		;669d
	ld c,01fh		;669f   ; la fila siguiente
	add hl,bc			;66a1   ; la fila siguiente
	pop bc			;66a2
	ld a,004h		;66a3   ; + 4
	add a,c			;66a5   ; la casilla + 4
	ld c,a			;66a6
	djnz roto_vram_fila		;66a7
	ret			;66a9
efecto_a_pide:		; El efecto A en el canal A, si no suena otro
	ld b,a			;66aa
	ld a,(0e3d5h)		;66ab   ; alguno sonando?
	and 00fh		;66ae   ; alguno?
	ret z			;66b0
	ld a,b			;66b1
	ld (0e3d5h),a		;66b2   ; el efecto
	ld a,001h		;66b5   ; la tarea, ya
	ld (0ec3fh),a		;66b7
	ret			;66ba
roto_ram:		; El blanco roto en una copia del fondo: tres filas de 0x90 + 4n y 0x9C + 4n
	add hl,de			;66bb
	ld a,090h		;66bc
	ld b,003h		;66be
roto_ram_fila:
	push af			;66c0
	ld (hl),a			;66c1   ; la casilla
	inc hl			;66c2
	add a,00ch		;66c3   ; la de la derecha, + 12
	ld (hl),a			;66c5
	ld a,01fh		;66c6   ; la fila siguiente
	add a,l			;66c8
	ld l,a			;66c9
	jr nc,roto_ram_sig		;66ca
	inc h			;66cc
roto_ram_sig:
	pop af			;66cd
	add a,004h		;66ce
	djnz roto_ram_fila		;66d0
	ret			;66d2
explosion_pon:		; Una explosion en uno de los tres sprites de 0xE266 que este libre (0xEB6F): en la casilla DE, 3 pasos
	ld ix,0eb6fh		;66d3   ; las cuentas
	ld hl,0e266h		;66d7   ; los sprites
	ld b,003h		;66da   ; tres
explosion_libre:
	ld a,(ix+000h)		;66dc   ; libre?
	and a			;66df
	jr z,explosion_si		;66e0   ; libre: aqui
	inc ix		;66e2   ; el siguiente
	ld a,004h		;66e4
	add a,l			;66e6
	ld l,a			;66e7
	jr nc,explosion_sig		;66e8
	inc h			;66ea
explosion_sig:
	djnz explosion_libre		;66eb
	ret			;66ed
explosion_si:
	ld a,e			;66ee   ; la X de la casilla
	and 01fh		;66ef   ; la columna...
	rlca			;66f1   ; ...x 8: la X
	rlca			;66f2
	rlca			;66f3
	ld (hl),a			;66f4
	dec hl			;66f5
	rr d		;66f6   ; la Y
	rr e		;66f8   ; la fila...
	rr d		;66fa
	rr e		;66fc
	ld a,e			;66fe   ; ...x 8
	and 0f8h		;66ff
	ld e,a			;6701
	ld a,(0ea6dh)		;6702   ; con el desplazamiento del scroll
	add a,a			;6705   ; + el desplazamiento x 2
	add a,e			;6706
	dec a			;6707
	ld (hl),a			;6708   ; la Y
	ld (ix+000h),003h		;6709   ; 3 pasos
	ret			;670d
misma_casilla:		; ¿(HL) y (HL+1), con el desplazamiento de 0xE2A3/0xE2A4 y la mascara C, dan D y E? A = 1 si
	ld a,(0e2a3h)		;670e
	add a,(hl)			;6711   ; la Y + el desplazamiento
	inc hl			;6712
	and c			;6713   ; en su casilla
	cp d			;6714   ; la de DE?
	ld a,000h		;6715   ; no: 0
	ret nz			;6717
	ld a,(0e2a4h)		;6718
	add a,(hl)			;671b   ; la X
	and c			;671c
	cp e			;671d
	ld a,000h		;671e
	ret nz			;6720
	inc a			;6721   ; si: 1
	ret			;6722
tarea_explosiones:		; La tarea 16: en los pasos 2, 5, 8 y 11 del scroll, las tres explosiones de 0xEB6F dan un paso: el dibujo + 2 (y fuera al acabar, 0xDE)
	ld a,001h		;6723   ; otra vez el cuadro siguiente
	ld (0ec3dh),a		;6725   ; la tarea 16, otra vez el cuadro siguiente
	ld a,(0e425h)		;6728   ; el paso 2, 5, 8 u 11?
	inc a			;672b   ; el paso + 1, de 3 en 3
	ld b,003h		;672c
	sub b			;672e
	jr z,explosiones		;672f
	sub b			;6731
	jr z,explosiones		;6732
	sub b			;6734
	jr z,explosiones		;6735
	sub b			;6737
	ret nz			;6738
explosiones:
	ld ix,0eb6fh		;6739   ; las cuentas
	ld hl,0e265h		;673d   ; los sprites
	ld de,00004h		;6740
	ld b,003h		;6743   ; tres
explosion_paso:
	ld a,(ix+000h)		;6745   ; en marcha?
	and a			;6748
	jr z,explosion_sig2		;6749
	dec a			;674b   ; un paso menos
	ld (ix+000h),a		;674c
	jr nz,explosion_dibujo		;674f
	ld (hl),0deh		;6751   ; acabada: el dibujo 0xDE
explosion_dibujo:
	cp 002h		;6753
	jr z,explosion_sig2		;6755
	inc (hl)			;6757   ; el dibujo + 2
	inc (hl)			;6758
explosion_sig2:
	inc ix		;6759
	add hl,de			;675b
	djnz explosion_paso		;675c
	ret			;675e
estado_fin_mapa:		; El estado del final del mapa: la nave (si no esta tocada) va al centro, Y 0xA7 y X 0x7C, un punto por cuadro; alli, el segundo sprite encima, la sombra transparente, 64 cuadros y el estado 0x67BA (se transforma)
	ld a,(0e2a6h)		;675f   ; tocada: nada
	and a			;6762
	ret nz			;6763
	ld ix,0e219h		;6764   ; la nave
	ld iy,0e27dh		;6768   ; su sombra
	ld b,000h		;676c   ; ninguno movido
	ld a,(ix+000h)		;676e   ; en Y 0xA7?
	cp 0a7h		;6771
	jr z,fin_mapa_x		;6773
	ld a,001h		;6775   ; por encima: + 1
	jr c,fin_mapa_y		;6777
	neg		;6779   ; por debajo: - 1
fin_mapa_y:
	inc b			;677b   ; uno movido
	add a,(ix+000h)		;677c
	ld (ix+000h),a		;677f
	ld (iy+000h),a		;6782
fin_mapa_x:
	ld a,(ix+001h)		;6785   ; en X 0x7C?
	cp 07ch		;6788
	jr z,fin_mapa_llega		;678a
	ld a,001h		;678c
	jr c,fin_mapa_x_va		;678e
	neg		;6790
fin_mapa_x_va:
	add a,(ix+001h)		;6792
	ld (ix+001h),a		;6795
	ld (iy+001h),a		;6798
	inc b			;679b
fin_mapa_llega:
	ld a,b			;679c   ; ya en su sitio?
	and a			;679d
	ret nz			;679e
	ld a,(ix+000h)		;679f   ; el segundo sprite, encima
	ld (ix+004h),a		;67a2
	ld a,(ix+001h)		;67a5
	ld (ix+005h),a		;67a8
	ld (iy+003h),000h		;67ab   ; la sombra, transparente
	ld a,040h		;67af   ; 64 cuadros
	ld (0e2a5h),a		;67b1
	ld hl,estado_transforma		;67b4   ; el estado: se transforma
	ld (0e09ah),hl		;67b7
estado_transforma:		; El estado del final del mapa: 0xE2A5 cuadros; en los 16 ultimos, uno de cada dos, la nave cambia: un punto arriba, los dibujos 0x80 y 0x84 en blanco; al acabar, la sombra y el sprite de 0x6282, sin musica, y 0x70D1
	ld ix,0e219h		;67ba
	ld a,(0e2a5h)		;67be   ; la cuenta
	dec a			;67c1
	ld (0e2a5h),a		;67c2
	jr z,transforma_fin		;67c5   ; acabada
	cp 010h		;67c7   ; los 16 ultimos...
	ret nc			;67c9
	bit 0,a		;67ca   ; ...uno de cada dos
	ret z			;67cc
	ld ix,0e219h		;67cd
	dec (ix+000h)		;67d1   ; un punto arriba
	inc (ix+004h)		;67d4
	ld (ix+002h),080h		;67d7   ; el dibujo 0x80...
	ld (ix+003h),00fh		;67db   ; ...blanco
	ld (ix+005h),07ch		;67df   ; el segundo sprite en X 0x7C...
	ld (ix+006h),084h		;67e3   ; ...0x84, blanco
	ld (ix+007h),00fh		;67e7
	ret			;67eb
transforma_fin:
	ld hl,06272h		;67ec   ; la sombra de 0x6272
	ld de,0e27dh		;67ef
	ld bc,00004h		;67f2
	ldir		;67f5
	ld hl,06282h		;67f7   ; otro sprite de 0x6282
	ld de,0e221h		;67fa
	ld bc,00004h		;67fd
	ldir		;6800
	ld a,07ch		;6802   ; la sombra en X 0x7C
	ld (0e27eh),a		;6804
	ld a,007h		;6807   ; color 7
	ld (0e280h),a		;6809
	xor a			;680c   ; 0xE2AC y 0xE2AD a 0
	ld (0e2ach),a		;680d
	ld (0e2adh),a		;6810
	ld (0e3f2h),a		;6813   ; sin musica
	ld (0e3fbh),a		;6816
	call estado_nada		;6819   ; el estado vacio
	jp robot_entra_pon		;681c
tarea_robot:		; La tarea 14: la nave cambiada (cuatro sprites desde 0xE219) se mueve con la palanca como la nave (la tabla 0x6440, 16 puntos mas abajo); si 0xE2B4 y la toca lo de 0xE245, tocada
	ld a,(0e2b4h)		;681f   ; 0xE2B4?
	and a			;6822
	jr z,robot_mueve		;6823
	ld ix,0e219h		;6825   ; la nave cambiada
	ld iy,0e245h		;6829   ; el robot grande
	call toca_16		;682d   ; la toca?
	and a			;6830
	jr z,robot_mueve		;6831
	ld (ix+004h),0e0h		;6833   ; tocada: los sprites fuera
	ld (ix+008h),0e0h		;6837   ; fuera
	ld a,0e0h		;683b
	ld (0e27dh),a		;683d   ; la sombra fuera
	xor a			;6840   ; la tarea parada
	ld (0ec3ch),a		;6841
	ld a,003h		;6844   ; 3 pasos de explosion
	ld (0e2a6h),a		;6846
	jp nave_tocada		;6849
robot_mueve:
	ld a,001h		;684c   ; otra vez el cuadro siguiente
	ld (0ec3bh),a		;684e   ; los mandos
	call nave_mandos		;6851
	ld a,e			;6854   ; la palanca
	and a			;6855
	ret z			;6856
	dec a			;6857   ; (direccion - 1) x 4
	add a,a			;6858
	add a,a			;6859
	ld c,a			;685a
	ld b,000h		;685b
	ld hl,06440h		;685d   ; la tabla
	add hl,bc			;6860
	ld b,010h		;6861   ; 16 puntos mas abajo
	ld a,(0e219h)		;6863
	add a,b			;6866
	cp (hl)			;6867   ; en el borde?
	inc hl			;6868
	jr z,robot_mueve_x		;6869
	sub b			;686b
	add a,(hl)			;686c   ; + el paso
	ld (0e219h),a		;686d
	add a,003h		;6870   ; la sombra, 3 mas abajo
	ld (0e27dh),a		;6872
	ld a,(0e21dh)		;6875   ; los otros dos sprites
	add a,(hl)			;6878
	ld (0e21dh),a		;6879
	ld a,(0e221h)		;687c
	add a,(hl)			;687f
	ld (0e221h),a		;6880
robot_mueve_x:
	inc hl			;6883
	ld a,(0e21ah)		;6884   ; la X
	cp (hl)			;6887   ; en el borde?
	ret z			;6888   ; en el borde: nada
	inc hl			;6889
	add a,(hl)			;688a   ; + el paso
	ld (0e21ah),a		;688b   ; en los cuatro sprites
	ld (0e21eh),a		;688e
	ld (0e222h),a		;6891
	ld (0e27eh),a		;6894
	ret			;6897
tarea_robot_golpe:		; La tarea 15: con el boton (una vez por pulsacion), un golpe: los dibujos 0x98/0xA8 o 0x9C/0xB0 (uno y otro) y el efecto 2 del canal C; 12 cuadros despues, el dibujo 0x80 otra vez
	ld a,001h		;6898   ; otra vez el cuadro siguiente
	ld (0ec3ch),a		;689a
	ld a,(0e2adh)		;689d   ; golpeando?
	and a			;68a0
	jr nz,robot_golpe_fin		;68a1
	call mandos		;68a3   ; los mandos
	ld a,d			;68a6   ; el boton?
	cp 001h		;68a7
	jr z,robot_golpe		;68a9
	xor a			;68ab   ; suelto
	ld (0e2ach),a		;68ac
	ret			;68af
robot_golpe:
	ld a,(0e2ach)		;68b0   ; ya sostenido?
	and a			;68b3
	ret nz			;68b4
	ld ix,0e219h		;68b5
	ld a,(0e2aeh)		;68b9   ; uno y otro
	cpl			;68bc
	ld (0e2aeh),a		;68bd
	and a			;68c0
	ld bc,098a8h		;68c1   ; 0x98 y 0xA8...
	jr z,robot_golpe_dibujo		;68c4
	ld bc,09cb0h		;68c6   ; ...o 0x9C y 0xB0
robot_golpe_dibujo:
	ld (ix+002h),b		;68c9   ; el cuerpo
	ld (ix+00ah),c		;68cc   ; el brazo...
	ld (ix+00bh),00fh		;68cf   ; ...blanco
	ld a,001h		;68d3   ; golpeando
	ld (0e2adh),a		;68d5
	ld (0e2ach),a		;68d8
	ld (0ec41h),a		;68db   ; el efecto 2 del canal C
	add a,a			;68de
	ld (0e3dbh),a		;68df
	ld a,00ch		;68e2   ; 12 cuadros
	ld (0ec3ch),a		;68e4
	ret			;68e7
robot_golpe_fin:
	ld ix,0e219h		;68e8
	ld (ix+002h),080h		;68ec   ; el dibujo 0x80
	ld (ix+00bh),000h		;68f0   ; el brazo, transparente
	xor a			;68f4
	ld (0e2adh),a		;68f5
	ret			;68f8
enemigos_pon:		; Los enemigos al empezar: 0xE2BD (8 x 32 bytes) y 0xE3BF (los disparos) a cero, cuatro sprites en Y 0xD4, X 6; y la primera oleada
	ld hl,0e2bdh		;68f9   ; los enemigos...
	ld bc,00100h		;68fc
	xor a			;68ff
	call llena		;6900   ; ...a cero
	ld hl,0e3bfh		;6903   ; sus disparos
	ld bc,00014h		;6906
	xor a			;6909
	call llena		;690a
	ld hl,0e237h		;690d   ; cuatro sprites...
	ld de,0d406h		;6910   ; ...en Y 0xD4, X 6
	ld b,004h		;6913
	call sprites_yx		;6915
	ld a,004h		;6918   ; 0xE2BB y 0xE2BC = 4
	ld (0e2bbh),a		;691a
	ld (0e2bch),a		;691d
	ld a,080h		;6920   ; la tarea 5, en 128 cuadros
	ld (0ec32h),a		;6922
	ld hl,0ec34h		;6925   ; las tareas 7-10 a 0
	ld bc,00004h		;6928
	call llena		;692b
oleada_sig:		; La oleada siguiente de la lista (0xE0BA): su clase (0xE2BA); 0xFF salta a otra lista; con 0x80, la clase sale de la lista de 0xE0CF (6 bytes, 0 vuelve atras)
	xor a			;692e   ; ninguno salido
	ld (0e2b9h),a		;692f   ; 0xE2B9 = 0
	ld hl,(0e0bah)		;6932   ; la lista
	ld a,(hl)			;6935   ; la clase
	cp 0ffh		;6936   ; 0xFF: otra lista
	jr nz,oleada_clase		;6938
	inc hl			;693a   ; la otra lista
	ld a,(hl)			;693b
	inc hl			;693c
	ld h,(hl)			;693d
	ld l,a			;693e
	ld (0e0bah),hl		;693f   ; guardada
	ld a,(hl)			;6942   ; su primera clase
oleada_clase:
	ld (0e2bah),a		;6943   ; la clase
	ld (0e3beh),a		;6946
	inc hl			;6949
	ld (0e0bah),hl		;694a
	cp 080h		;694d   ; 0x80?
	jr nz,oleada_va		;694f
oleada_80:		; La clase de la lista de 0xE0CF; un 0 vuelve 6 atras
	ld hl,(0e0cfh)		;6951   ; la lista
	ld a,(hl)			;6954
	and a			;6955   ; 0: 6 atras
	jr nz,oleada_80_pon		;6956
	ld bc,0fffah		;6958
	add hl,bc			;695b
	ld a,(hl)			;695c
oleada_80_pon:
	ld (0e2bah),a		;695d
	inc hl			;6960
	ld (0e0cfh),hl		;6961
oleada_va:
	xor a			;6964   ; 0xE3BD y 0xE2B8 a 0
	ld (0e3bdh),a		;6965
	ld (0e2b8h),a		;6968
	ret			;696b
tarea_oleada:		; La tarea 5: los enemigos de la oleada salen (la clase / 4 en la tabla de 0x69A2: cinco formas de salir); con 24 salidos (0xE2B9), la siguiente
	ld a,001h		;696c   ; otra vez el cuadro siguiente
	ld (0ec32h),a		;696e
	ld a,(0e2b9h)		;6971   ; 24 salidos?
	cp 018h		;6974
	jr nz,oleada_cambia		;6976
	ld a,0ffh		;6978   ; la tarea, en 255 cuadros
	ld (0ec32h),a		;697a
	jr oleada_sig		;697d
oleada_cambia:
	ld a,(0e3beh)		;697f   ; una 0x80...
	cp 080h		;6982
	jr nz,oleada_salta		;6984
	ld a,(0e2b8h)		;6986   ; ...con 4 salidos: otra clase
	cp 004h		;6989
	jr nz,oleada_salta		;698b
	call oleada_80		;698d
oleada_salta:
	ld a,(0e2bah)		;6990   ; la clase / 4, en palabras
	rrca			;6993   ; la clase / 2...
	and 07eh		;6994   ; ...par
	ld c,a			;6996
	ld b,000h		;6997
	ld hl,069a2h		;6999   ; la tabla de cinco
	add hl,bc			;699c   ; la direccion de la forma
	ld a,(hl)			;699d
	inc hl			;699e
	ld h,(hl)			;699f
	ld l,a			;69a0
	jp (hl)			;69a1   ; salta

; ----------------------------------------------------------------------
; DATOS tabla_formas: Las cinco formas de salir de los enemigos (la clase / 4)
;   0x69a2..0x69ac  (10 bytes)
DATA_tabla_formas:
	defw 069ach,06a2dh,06a77h,06ac2h,06b6dh	; 69a2

; ======================================================================
; CODIGO 0x69ac..0x6a05  (89 bytes)
; ======================================================================


sale_forma0:		; La forma 0 de salir (clases 0-3): de cuatro en cuatro (0xE2BB los que faltan del grupo, 0xE2BC los que quedan); cada uno con los 16 bytes de 0x6A09 o 0x6A18 (segun el lado, 0x6C11)
	ld a,(0e2bbh)		;69ac   ; quedan del grupo?
	and a			;69af
	jr nz,sale_forma0_uno		;69b0
	ld a,(0e2bch)		;69b2   ; otro grupo: quedan 4 o mas?
	cp 004h		;69b5
	ret c			;69b7
	call grupo_nuevo		;69b8   ; el grupo
	ld a,060h		;69bb   ; la tarea, en 96 cuadros
	ld (0ec32h),a		;69bd
	ld a,(0e2bah)		;69c0   ; la clase 2...
	cp 002h		;69c3
	call z,lado_nave		;69c5   ; ...sale por el lado de la nave
	ret			;69c8
sale_forma0_uno:
	call grupo_uno_menos		;69c9   ; uno menos en el grupo
	call hueco		;69cc   ; un hueco libre?
	and a			;69cf
	ret z			;69d0
	push bc			;69d1
	call lado_cambia		;69d2   ; el lado
	ld hl,06a09h		;69d5   ; por la izquierda: 0x6A09
	and a			;69d8
	jr z,sale_forma0_pon		;69d9
	ld hl,06a18h		;69db   ; por la derecha: 0x6A18
sale_forma0_pon:
	ld bc,00010h		;69de   ; 16 bytes al enemigo
	ldir		;69e1
	pop bc			;69e3
sale_sprite:		; El sprite del enemigo B: el dibujo (la clase / 4 x 4 + 0xC) y el color de 0x6A05 (la clase & 3)
	call enemigo_sprite		;69e4   ; su sprite
	inc hl			;69e7   ; la Y y la X
	inc hl			;69e8
	ld a,(0e2bah)		;69e9   ; la clase
	ld c,a			;69ec   ; la clase
	and 0fch		;69ed   ; / 4...
	rrca			;69ef   ; / 4
	rrca			;69f0
	add a,a			;69f1   ; ...x 4 + 0xC: el dibujo
	add a,a			;69f2
	add a,00ch		;69f3
	ld (hl),a			;69f5   ; el dibujo
	inc hl			;69f6
	ex de,hl			;69f7
	ld a,c			;69f8   ; la clase & 3...
	and 003h		;69f9   ; la clase & 3
	ld c,a			;69fb
	ld b,000h		;69fc
	ld hl,06a05h		;69fe   ; ...el color de la tabla
	add hl,bc			;6a01
	ld a,(hl)			;6a02   ; el color
	ld (de),a			;6a03   ; al sprite
	ret			;6a04

; ----------------------------------------------------------------------
; DATOS sale_datos0: Los cuatro colores de los enemigos (0x6A05) y los dos
;   movimientos de la forma 0 (0x6A09 desde la izquierda, 0x6A18 desde la
;   derecha)
;   0x6a05..0x6a27  (34 bytes)
DATA_sale_datos0:
	defb 00eh,007h,00ah,00dh,000h,000h,000h,000h,000h,001h,000h,000h,000h,000h,000h,09ch	; 6a05  ................
	defb 000h,080h,000h,000h,000h,000h,000h,000h,001h,000h,000h,000h,000h,000h,09ch,000h	; 6a15  ................
	defb 080h,0ffh	; 6a25

; ======================================================================
; CODIGO 0x6a27..0x6a67  (64 bytes)
; ======================================================================


grupo_uno_menos:		; Uno menos en el grupo (0xE2BB)
	dec a			;6a27
	ld (0e2bbh),a		;6a28
	jr sale_forma1_cuenta		;6a2b
sale_forma1:		; La forma 1 (clases 4-7): de cuatro en cuatro, cada 13 cuadros, desde uno de los ocho sitios de 0x6A67 (por los salidos)
	ld a,(0e2bbh)		;6a2d   ; quedan del grupo?
	and a			;6a30
	jr nz,sale_forma1_uno		;6a31
	ld a,(0e2bch)		;6a33   ; quedan 4 o mas?
	cp 004h		;6a36
	ret c			;6a38
	call grupo_nuevo		;6a39
sale_forma1_cuenta:
	ld a,00dh		;6a3c   ; la tarea, en 13 cuadros
	ld (0ec32h),a		;6a3e
	ret			;6a41
sale_forma1_uno:
	call grupo_uno_menos		;6a42
	call hueco		;6a45   ; un hueco?
	and a			;6a48   ; libre?
	ret z			;6a49
	push bc			;6a4a
	ld a,(0e2b9h)		;6a4b   ; el sitio: los salidos & 7...
	and 007h		;6a4e   ; los salidos & 7
	add a,a			;6a50
	ld c,a			;6a51
	ld b,000h		;6a52
	ld hl,06a67h		;6a54   ; ...en la tabla
	add hl,bc			;6a57   ; su sitio
	ld a,001h		;6a58   ; el estado 1
	ld (de),a			;6a5a   ; el estado 1
	inc de			;6a5b
	ld bc,00002h		;6a5c   ; la Y y la X
	ldir		;6a5f   ; la Y y la X
	xor a			;6a61   ; y 0
	ld (de),a			;6a62   ; y 0
	pop bc			;6a63
	jp sale_sprite		;6a64

; ----------------------------------------------------------------------
; DATOS sale_sitios1: Los ocho sitios (Y, X) por donde sale la forma 1
;   0x6a67..0x6a77  (16 bytes)
DATA_sale_sitios1:
	defb 088h,0feh	; 6a67
	defb 028h,002h	; 6a69
	defb 0c8h,0feh	; 6a6b
	defb 008h,002h	; 6a6d
	defb 0e8h,0feh	; 6a6f
	defb 068h,0feh	; 6a71
	defb 0a8h,002h	; 6a73
	defb 048h,002h	; 6a75

; ======================================================================
; CODIGO 0x6a77..0x6b38  (193 bytes)
; ======================================================================


sale_forma2:		; La forma 2 (clases 8-11): de cuatro en cuatro, desde arriba (Y 0xFF), cada uno en su columna (B x 32); desde la clase 10, los impares con un paso de lado al azar
	ld a,(0e2bbh)		;6a77   ; quedan del grupo?
	and a			;6a7a
	jr nz,sale_forma2_uno		;6a7b
	ld a,(0e2bch)		;6a7d
	cp 004h		;6a80
	ret c			;6a82
grupo_nuevo:		; Un grupo de cuatro: 0xE2BC cuatro menos, 0xE2BB = 4
	sub 004h		;6a83
	ld (0e2bch),a		;6a85
	ld a,004h		;6a88
	ld (0e2bbh),a		;6a8a
	ret			;6a8d
sale_forma2_uno:
	call grupo_uno_menos		;6a8e
	call hueco		;6a91   ; un hueco?
	and a			;6a94
	ret z			;6a95
	ex de,hl			;6a96   ; Y 0xFF: arriba del todo
	ld (hl),0ffh		;6a97
	inc hl			;6a99
	ld a,b			;6a9a   ; la columna: (B - 1) x 32
	dec a			;6a9b   ; (B - 1)...
	rrca			;6a9c   ; ...x 32 (rotado)
	rrca			;6a9d
	rrca			;6a9e
	ld (hl),a			;6a9f   ; la X
	ld a,(0e2bah)		;6aa0   ; la clase 10 o mas...
	cp 00ah		;6aa3   ; la clase 10?
	ld c,000h		;6aa5
	jr c,sale_forma2_pon		;6aa7
	bit 0,b		;6aa9   ; ...los impares...
	jr z,sale_forma2_pon		;6aab
	ld a,r		;6aad   ; ...al azar: 0, -0x10, +0x10 o 2
	and 003h		;6aaf
	ld c,0f0h		;6ab1
	jr z,sale_forma2_pon		;6ab3
	cp 001h		;6ab5   ; 1: 16 a la derecha
	ld c,010h		;6ab7
	jr z,sale_forma2_pon		;6ab9
	ld c,002h		;6abb   ; 2: 2
sale_forma2_pon:
	inc hl			;6abd
	ld (hl),c			;6abe
	jp sale_sprite		;6abf
sale_forma3:		; La forma 3 (clases 12-15): de cuatro en cuatro, cada 48 cuadros, desde arriba hacia la nave: la X cerca de la de la nave (al azar 16 a un lado u otro, entre 0x1F y 0xAF) y uno de los movimientos de 0x6B38 o 0x6B4C segun el lado
	ld a,(0e2bbh)		;6ac2   ; quedan del grupo?
	and a			;6ac5
	jr nz,sale_forma3_uno		;6ac6
	ld a,(0e2bch)		;6ac8
	cp 004h		;6acb
	ret c			;6acd
	jr grupo_nuevo		;6ace
sale_forma3_uno:
	dec a			;6ad0
	ld (0e2bbh),a		;6ad1   ; uno menos en el grupo
	ld a,030h		;6ad4   ; la tarea, en 48 cuadros
	ld (0ec32h),a		;6ad6
	call hueco		;6ad9   ; un hueco?
	and a			;6adc
	ret z			;6add
	push bc			;6ade
	ld a,(0e2bah)		;6adf   ; la clase
	ld c,a			;6ae2
	ld a,0ffh		;6ae3   ; Y 0xFF
	ld (de),a			;6ae5   ; el estado 0xFF
	inc de			;6ae6
	ld a,(0e219h)		;6ae7   ; la Y de la nave...
	cp 01fh		;6aea   ; la nave arriba del todo (menos de 0x1F)?
	ld b,01fh		;6aec
	jr c,sale_forma3_borde		;6aee
	cp 02fh		;6af0   ; cerca de arriba (menos de 0x2F)?
	jr c,sale_forma3_pon		;6af2
	ld b,a			;6af4
	ld a,r		;6af5   ; ...y al azar
	and 003h		;6af7   ; un cuarto de las veces, en el borde
	jr z,sale_forma3_borde		;6af9
	cp 001h		;6afb   ; un cuarto, 16 a un lado
	ld a,b			;6afd
	ld b,010h		;6afe
	jr z,sale_forma3_x		;6b00
	ld b,0f0h		;6b02   ; el resto, 16 al otro
sale_forma3_x:
	add a,b			;6b04   ; + la Y de la nave
	cp 0afh		;6b05   ; 0xAF como mucho
	jr c,sale_forma3_pon		;6b07
	ld b,0afh		;6b09
sale_forma3_borde:
	ld a,b			;6b0b
sale_forma3_pon:
	inc a			;6b0c
	ld b,a			;6b0d
	srl b		;6b0e
	call lado_nave		;6b10   ; el lado de la nave
	ld a,b			;6b13
	ld hl,06b38h		;6b14   ; por la izquierda: 0x6B38
	jr nc,sale_forma3_mov		;6b17
	ld hl,06b4ch		;6b19   ; por la derecha: 0x6B4C
	neg		;6b1c
	sub 010h		;6b1e
sale_forma3_mov:
	ld (de),a			;6b20
	inc de			;6b21   ; los datos del movimiento
	ld a,c			;6b22   ; la clase - 12...
	sub 00ch		;6b23   ; (clase - 12) x 2
	add a,a			;6b25   ; ...x 2
	add a,l			;6b26
	ld l,a			;6b27
	jr nc,sale_forma3_mov_dir		;6b28
	inc h			;6b2a
sale_forma3_mov_dir:
	ld a,(hl)			;6b2b
	inc hl			;6b2c
	ld h,(hl)			;6b2d
	ld l,a			;6b2e
	ld bc,00006h		;6b2f   ; 6 bytes del movimiento
	ldir		;6b32
	pop bc			;6b34
	jp sale_sprite		;6b35

; ----------------------------------------------------------------------
; DATOS sale_datos3: Los movimientos de la forma 3: dos tablas de cuatro
;   punteros (0x6B38 y 0x6B4C) a 6 bytes
;   0x6b38..0x6b60  (40 bytes)
DATA_sale_datos3:
	defb 040h,06bh,040h,06bh,046h,06bh,046h,06bh,000h,002h,0ffh,002h,002h,000h,000h,002h	; 6b38  @k@kFkFk........
	defb 0ffh,002h,002h,0ffh,054h,06bh,054h,06bh,05ah,06bh,05ah,06bh,000h,002h,001h,0feh	; 6b48  ....TkTkZkZk....
	defb 002h,000h,000h,002h,001h,0feh,002h,001h	; 6b58  ........

; ======================================================================
; CODIGO 0x6b60..0x6bc0  (96 bytes)
; ======================================================================


enemigo_sprite:		; HL = el sprite del enemigo B (0xE245 + (8 - B) x 4)
	ld a,008h		;6b60
	sub b			;6b62   ; (8 - B) x 4
	add a,a			;6b63
	add a,a			;6b64
	ld hl,0e245h		;6b65   ; los sprites de los enemigos
	add a,l			;6b68
	ld l,a			;6b69
	ret nc			;6b6a
	inc h			;6b6b
	ret			;6b6c
sale_forma4:		; La forma 4 (clases 16-19): de cuatro en cuatro, cada 80 cuadros, con los 14 bytes de 0x6BC0 y el lado (0xE3BD)
	ld a,(0e2bbh)		;6b6d   ; quedan del grupo?
	and a			;6b70
	jr nz,sale_forma4_uno		;6b71
	ld a,(0e2bch)		;6b73
	cp 004h		;6b76
	ret c			;6b78
	call grupo_nuevo		;6b79   ; un grupo
	ld a,050h		;6b7c   ; la tarea, en 80 cuadros
	ld (0ec32h),a		;6b7e   ; la tarea
	ld a,(0e2bah)		;6b81   ; la 18: el lado de la nave
	cp 012h		;6b84
	jp z,lado_nave		;6b86
	cp 011h		;6b89   ; la 17: el otro lado
	jp z,lado_cambia		;6b8b
	ret			;6b8e
sale_forma4_uno:
	call grupo_uno_menos		;6b8f
	ld a,(0e2bah)		;6b92   ; la clase
	cp 011h		;6b95   ; la 17...
	jr z,sale_forma4_pon		;6b97
	cp 012h		;6b99   ; ...y la 18: su lado
	jr z,sale_forma4_pon		;6b9b
	push af			;6b9d
	call lado_cambia		;6b9e   ; las otras cambian de lado
	pop af			;6ba1
	cp 013h		;6ba2   ; la 19...
	jr z,sale_forma4_pon		;6ba4
	xor a			;6ba6   ; ...si no, a la izquierda
	ld (0e3bdh),a		;6ba7
sale_forma4_pon:
	call hueco		;6baa   ; un hueco?
	and a			;6bad
	ret z			;6bae
	push bc			;6baf
	ld hl,06bc0h		;6bb0   ; 14 bytes
	ld bc,0000eh		;6bb3   ; 14 bytes
	ldir		;6bb6
	ld a,(0e3bdh)		;6bb8   ; y el lado
	ld (de),a			;6bbb   ; el lado
	pop bc			;6bbc
	jp sale_sprite		;6bbd

; ----------------------------------------------------------------------
; DATOS sale_datos4: Los 14 bytes de la forma 4
;   0x6bc0..0x6bce  (14 bytes)
DATA_sale_datos4:
	defb 000h,0ffh,000h,000h,000h,001h,000h,000h,000h,0f4h,000h,0d0h,000h,0bch	; 6bc0  ..............

; ======================================================================
; CODIGO 0x6bce..0x6c86  (184 bytes)
; ======================================================================


hueco:		; Un hueco libre entre los 8 enemigos de 0xE2BD (32 bytes): el estado 1, la clase, y uno mas salido; DE detras; B el numero (0 si no hay); con 24 salidos, la tarea de la oleada en 1
	ld hl,0e2bdh		;6bce   ; los enemigos
	ld b,008h		;6bd1   ; 8
hueco_mira:
	ld a,(hl)			;6bd3   ; libre?
	and a			;6bd4
	jr z,hueco_pon		;6bd5
	ld a,020h		;6bd7
	add a,l			;6bd9
	ld l,a			;6bda
	jr nc,hueco_sig		;6bdb
	inc h			;6bdd
hueco_sig:
	djnz hueco_mira		;6bde
	ld a,b			;6be0   ; ninguno: A = 0
	ret			;6be1
hueco_pon:
	inc (hl)			;6be2   ; el estado 1: vivo
	inc hl			;6be3   ; la clase
	ld a,(0e2bah)		;6be4   ; la clase
	ld (hl),a			;6be7
	inc hl			;6be8
	inc hl			;6be9
	inc hl			;6bea
	ex de,hl			;6beb   ; DE detras
	ld a,(0e2b8h)		;6bec   ; uno mas del grupo
	inc a			;6bef
	ld (0e2b8h),a		;6bf0   ; los salidos del grupo
	ld a,(0e2b9h)		;6bf3   ; uno mas de la oleada
	inc a			;6bf6
	ld (0e2b9h),a		;6bf7   ; los de la oleada
	cp 018h		;6bfa   ; 24?
	ret nz			;6bfc
	ld a,001h		;6bfd   ; la tarea de la oleada, ya
	ld (0ec32h),a		;6bff
	ret			;6c02
lado_nave:		; 0xE3BD = 0xFF si la nave esta en la mitad derecha (X 0x78 o mas); C si a la izquierda
	ld hl,0e3bdh		;6c03
	ld (hl),000h		;6c06   ; a la izquierda: 0
	ld a,(0e21ah)		;6c08   ; la X de la nave
	cp 078h		;6c0b   ; la mitad izquierda?
	ret c			;6c0d
	ld (hl),0ffh		;6c0e   ; la derecha: 0xFF
	ret			;6c10
lado_cambia:		; El lado (0xE3BD) al reves, salvo en la clase 2
	ld a,(0e2bah)		;6c11   ; la clase
	cp 002h		;6c14   ; la 2?
	ld a,(0e3bdh)		;6c16
	ret z			;6c19
	cpl			;6c1a   ; al reves
	ld (0e3bdh),a		;6c1b
	ret			;6c1e
tarea_enemigos:		; La tarea 7, cada cuadro: los enemigos vivos (estado 1) se mueven segun su forma (0x6C74) y su sprite va a la nueva Y, X; por debajo de 0xC0 se acaban (uno mas en 0xE2BC)
	ld a,001h		;6c1f   ; otra vez el cuadro siguiente
	ld (0ec34h),a		;6c21
	ld ix,0e2bdh		;6c24   ; los enemigos
	ld hl,0e245h		;6c28   ; sus sprites
	ld b,008h		;6c2b   ; 8
enemigo_uno:
	ld a,(ix+000h)		;6c2d   ; vivo?
	cp 001h		;6c30
	jr z,enemigo_mueve		;6c32
	inc hl			;6c34
enemigo_sig:
	inc hl			;6c35
	inc hl			;6c36
	inc hl			;6c37
	ld de,00020h		;6c38   ; el siguiente (+ 32)
	add ix,de		;6c3b
	djnz enemigo_uno		;6c3d
	ret			;6c3f
enemigo_mueve:
	push ix		;6c40
	push hl			;6c42
	push bc			;6c43
	ld bc,00004h		;6c44   ; sus datos de movimiento (+4)
	add ix,bc		;6c47   ; +4: sus datos
	call enemigo_forma		;6c49   ; se mueve: D = Y, E = X
	pop bc			;6c4c
	pop hl			;6c4d
	pop ix		;6c4e
	ld a,d			;6c50   ; abajo del todo?
	cp 0c0h		;6c51   ; abajo del todo?
	ld (ix+002h),a		;6c53   ; la Y y la X...
	ld (ix+003h),e		;6c56   ; la X
	jr nc,enemigo_fuera		;6c59
	ld (hl),a			;6c5b   ; ...a su sprite
	inc hl			;6c5c
	ld (hl),e			;6c5d   ; al sprite
	jr enemigo_sig		;6c5e
enemigo_fuera:
	ld a,0e0h		;6c60   ; fuera
	ld (ix+002h),a		;6c62
	ld (hl),a			;6c65
	inc hl			;6c66
	ld a,(0e2bch)		;6c67   ; uno mas en el grupo siguiente
	inc a			;6c6a
	ld (0e2bch),a		;6c6b
	ld (ix+000h),000h		;6c6e   ; libre
	jr enemigo_sig		;6c72
enemigo_forma:		; Salta al movimiento de su forma (la clase / 4, tabla 0x6C86)
	ld a,(ix-003h)		;6c74   ; la clase
	rrca			;6c77   ; / 2...
	and 07eh		;6c78   ; ...par
	ld c,a			;6c7a
	ld b,000h		;6c7b
	ld hl,06c86h		;6c7d   ; la tabla
	add hl,bc			;6c80   ; la direccion del movimiento
	ld a,(hl)			;6c81
	inc hl			;6c82
	ld h,(hl)			;6c83
	ld l,a			;6c84
	jp (hl)			;6c85   ; salta

; ----------------------------------------------------------------------
; DATOS tabla_movimientos: Los cinco movimientos de los enemigos (la clase /
;   4)
;   0x6c86..0x6c90  (10 bytes)
DATA_tabla_movimientos:
	defw 06c90h,06d24h,06d94h,06e0fh,06e82h	; 6c86

; ======================================================================
; CODIGO 0x6c90..0x70bd  (1069 bytes)
; ======================================================================


mueve_forma0:		; La forma 0: vuelta en espiral con numeros de 16 bits: la Y sube con su velocidad, la X sale de un oscilador (+8 a +0xD) que se frena a si mismo (un dieciseisavo y un sesentaicuatroavo al reves); en el lado derecho, la X al reves
	ld c,(ix+000h)		;6c90   ; la velocidad en Y...
	ld b,(ix+001h)		;6c93
	ld l,(ix+002h)		;6c96   ; ...a la Y
	ld h,(ix+003h)		;6c99   ; (+0, +1) la velocidad en Y; (+2, +3) la Y, 16 bits
	add hl,bc			;6c9c   ; la Y + la velocidad
	ld (ix+002h),l		;6c9d   ; guardada
	ld (ix+003h),h		;6ca0
	ex de,hl			;6ca3   ; la Y nueva a DE
	ld c,(ix+004h)		;6ca4   ; la otra
	ld b,(ix+005h)		;6ca7
	ld l,(ix+006h)		;6caa   ; (+6, +7) el angulo...
	ld h,(ix+007h)		;6cad
	add hl,bc			;6cb0   ; ...+ (+4, +5)
	ld (ix+006h),l		;6cb1   ; guardado
	ld (ix+007h),h		;6cb4
	ld c,(ix+008h)		;6cb7   ; el oscilador
	ld b,(ix+009h)		;6cba
	push bc			;6cbd   ; (+8, +9) guardado
	add hl,bc			;6cbe   ; el angulo + (+8, +9)...
	ex de,hl			;6cbf
	ld c,(ix+00ah)		;6cc0   ; + los dos de +0xA y +0xC
	ld b,(ix+00bh)		;6cc3
	add hl,bc			;6cc6   ; ...+ (+0xA, +0xB)...
	ld c,(ix+00ch)		;6cc7
	ld b,(ix+00dh)		;6cca
	add hl,bc			;6ccd   ; ...+ (+0xC, +0xD)
	ld e,h			;6cce   ; la X, la parte alta
	pop bc			;6ccf   ; el oscilador / 16
	sra b		;6cd0   ; (+8, +9) / 16...
	rr c		;6cd2
	sra b		;6cd4
	rr c		;6cd6
	sra b		;6cd8
	rr c		;6cda
	sra b		;6cdc
	rr c		;6cde
	ld l,(ix+00ah)		;6ce0   ; a +0xA
	ld h,(ix+00bh)		;6ce3
	add hl,bc			;6ce6   ; ...a (+0xA, +0xB)
	ld (ix+00ah),l		;6ce7   ; guardado
	ld (ix+00bh),h		;6cea
	ld b,h			;6ced   ; en BC
	ld c,l			;6cee
	ld hl,00000h		;6cef   ; al reves...
	and a			;6cf2
	sbc hl,bc		;6cf3   ; 0 - BC...
	sra h		;6cf5   ; ... / 64
	rr l		;6cf7   ; ... / 64
	sra h		;6cf9
	rr l		;6cfb
	sra h		;6cfd
	rr l		;6cff
	sra h		;6d01
	rr l		;6d03
	sra h		;6d05
	rr l		;6d07
	sra h		;6d09
	rr l		;6d0b
	ld c,(ix+008h)		;6d0d   ; a +8
	ld b,(ix+009h)		;6d10
	add hl,bc			;6d13   ; + (+8, +9)
	ld (ix+008h),l		;6d14   ; guardado
	ld (ix+009h),h		;6d17
	ld a,(ix+00eh)		;6d1a   ; del lado derecho?
	and a			;6d1d
	ret z			;6d1e
	ld a,e			;6d1f   ; la X al reves
	neg		;6d20   ; al reves
	ld e,a			;6d22
	ret			;6d23
mueve_forma1:		; La forma 1: baja 2 puntos; la clase 5 baja 4 y cada 8 se mueve de lado; la 6 baja en diagonal y rebota en el centro; la 7 baja deprisa hasta la fila de la nave y despacio en ella
	ld e,(ix+001h)		;6d24   ; la X
	ld a,(ix-003h)		;6d27   ; la clase
	cp 005h		;6d2a   ; la clase 5?
	jr z,mueve_clase5		;6d2c
	cp 006h		;6d2e   ; la 6?
	jr z,mueve_clase6		;6d30
	cp 007h		;6d32   ; la 7?
	jr z,mueve_clase7		;6d34
	inc (ix+000h)		;6d36   ; 2 abajo
	inc (ix+000h)		;6d39
	ld d,(ix+000h)		;6d3c
	ret			;6d3f
mueve_clase5:
	ld a,(ix+000h)		;6d40   ; 4 abajo
	add a,004h		;6d43   ; 4 abajo
	ld d,a			;6d45
	ld (ix+000h),a		;6d46
	dec a			;6d49   ; cada 8...
	and 007h		;6d4a   ; cada 8
	ld e,(ix+001h)		;6d4c
	ret nz			;6d4f
	ld a,e			;6d50   ; ...un paso de lado
	add a,(ix+002h)		;6d51   ; + su paso de lado
	ld (ix+001h),a		;6d54   ; guardado
	ld e,a			;6d57
	ret			;6d58
mueve_clase6:
	ld a,(ix+003h)		;6d59   ; a que lado de la mitad?
	cp 080h		;6d5c   ; a la derecha de la mitad?
	ld a,002h		;6d5e   ; 2 abajo, 2 a la derecha...
	ld b,002h		;6d60
	jr c,mueve_clase6_va		;6d62
	ld b,004h		;6d64   ; ...o 2 arriba, 4 a la derecha
	ld a,0feh		;6d66
mueve_clase6_va:
	add a,(ix+000h)		;6d68   ; la Y + eso
	ld (ix+000h),a		;6d6b
	ld d,a			;6d6e
	ld a,b			;6d6f
	add a,(ix+003h)		;6d70   ; la X + lo suyo
	ld (ix+003h),a		;6d73
	ret			;6d76
mueve_clase7:
	ld a,(0e219h)		;6d77   ; la fila de la nave (de 32)
	and 0e0h		;6d7a
	ld b,a			;6d7c
	ld a,(ix+000h)		;6d7d
	and 0e0h		;6d80
	cp b			;6d82
	ld a,001h		;6d83   ; en ella: 1
	jr z,mueve_clase7_va		;6d85
	ld a,004h		;6d87   ; si no: 4
mueve_clase7_va:
	add a,(ix+000h)		;6d89
	ld (ix+000h),a		;6d8c
	ld d,a			;6d8f
	ld e,(ix+001h)		;6d90
	ret			;6d93
mueve_forma2:		; La forma 2: baja (las clases 10 y 11 el doble); la 8 tal cual; la 9 cae en picado cuando esta en la columna de la nave; las demas, al llegar a la altura de la nave + algo, se tuercen hacia ella de lado
	ld a,(ix+002h)		;6d94   ; ya de lado (0xFF)?
	cp 0ffh		;6d97
	jr z,mueve_forma2_va		;6d99
	ld a,(ix-003h)		;6d9b   ; las clases 10 y 11...
	cp 00ah		;6d9e
	jr c,mueve_forma2_baja		;6da0
	inc (ix+000h)		;6da2   ; ...un punto mas
mueve_forma2_baja:
	inc (ix+000h)		;6da5   ; un punto abajo
mueve_forma2_va:
	ld d,(ix+000h)		;6da8
	ld e,(ix+001h)		;6dab
	ld a,(ix-003h)		;6dae   ; la 8: nada mas
	cp 008h		;6db1
	ret z			;6db3
	cp 009h		;6db4   ; la 9
	jp z,mueve_clase9		;6db6
	ld a,(ix+002h)		;6db9   ; sin giro?
	and a			;6dbc
	ret z			;6dbd
	cp 0ffh		;6dbe   ; ya de lado?
	jr nz,mueve_forma2_gira		;6dc0
	ld a,(ix+001h)		;6dc2   ; de lado: X + el paso
	add a,(ix+003h)		;6dc5
	ld (ix+001h),a		;6dc8
	ld e,a			;6dcb
	cp 008h		;6dcc   ; fuera por un lado?
	jr c,mueve_forma2_fuera		;6dce
	cp 0f8h		;6dd0
	ret c			;6dd2
mueve_forma2_fuera:
	ld (ix+002h),000h		;6dd3
	ld d,0c0h		;6dd7   ; fuera (Y 0xC0)
	ret			;6dd9
mueve_forma2_gira:
	ld a,(0e219h)		;6dda   ; a la altura de la nave + lo suyo?
	add a,(ix+002h)		;6ddd
	cp d			;6de0
	ret nz			;6de1
	ld (ix+002h),0ffh		;6de2   ; de lado desde ahora
	ld a,(ix-003h)		;6de6   ; el paso: (clase - 9) x 2...
	sub 009h		;6de9   ; (clase - 9) x 2
	add a,a			;6deb
	ld b,a			;6dec
	ld a,(0e21ah)		;6ded   ; ...hacia la nave
	cp e			;6df0   ; a que lado esta la nave?
	ld a,b			;6df1
	jr nc,mueve_forma2_paso		;6df2
	neg		;6df4
mueve_forma2_paso:
	ld (ix+003h),a		;6df6
	ret			;6df9
mueve_clase9:		; En la columna de la nave (de 16), 3 puntos abajo
	ld a,e			;6dfa
	and 0f0h		;6dfb   ; la columna del enemigo
	ld b,a			;6dfd
	ld a,(0e21ah)		;6dfe   ; la de la nave
	and 0f0h		;6e01
	cp b			;6e03   ; la misma?
	ret nz			;6e04
	ld a,(ix+000h)		;6e05
	add a,003h		;6e08   ; 3 abajo
	ld (ix+000h),a		;6e0a
	ld d,a			;6e0d
	ret			;6e0e
mueve_forma3:		; La forma 3, en tres partes (+2): primero en linea recta (+3, +4) hasta el borde; despues de lado hacia la columna de la nave (+5); por fin en picado con su movimiento (+6, +7)
	ld a,(ix+002h)		;6e0f   ; la parte
	cp 001h		;6e12   ; la segunda parte?
	jp z,forma3_lado		;6e14
	cp 002h		;6e17   ; la tercera?
	jp z,forma3_picado		;6e19
	ld a,(ix+000h)		;6e1c   ; la primera: + su paso en Y...
	add a,(ix+003h)		;6e1f   ; la Y
	ld (ix+000h),a		;6e22
	ld d,a			;6e25
	ld a,(ix+001h)		;6e26   ; ...y en X
	add a,(ix+004h)		;6e29   ; la X
	ld (ix+001h),a		;6e2c
	ld e,a			;6e2f
	and a			;6e30   ; en un borde?
	jr z,forma3_sigue		;6e31   ; en el borde de la izquierda?
	cp 0f0h		;6e33   ; en el de la derecha?
	ret nz			;6e35
forma3_sigue:
	inc (ix+002h)		;6e36   ; la parte siguiente
	ret			;6e39
forma3_lado:
	ld d,(ix+000h)		;6e3a   ; la Y
	ld a,(0e21ah)		;6e3d   ; la columna de la nave
	ld b,a			;6e40
	ld e,(ix+001h)		;6e41   ; la X
	cp e			;6e44   ; ya en ella?
	jr z,forma3_sigue		;6e45   ; ya en la columna: la parte siguiente
	ld a,e			;6e47   ; + su paso
	add a,(ix+005h)		;6e48   ; + el paso
	ld e,a			;6e4b
	ld (ix+001h),e		;6e4c
	cp b			;6e4f   ; llega?
	ret nz			;6e50
	bit 0,(ix-003h)		;6e51   ; los impares...
	jr z,forma3_sigue		;6e55
	ld a,(0e219h)		;6e57   ; ...por debajo de la nave...
	cp (ix+000h)		;6e5a
	jr nc,forma3_sigue		;6e5d
	ld a,(ix+006h)		;6e5f   ; ...dan la vuelta
	neg		;6e62   ; el paso de lado al reves
	ld (ix+006h),a		;6e64
	jr forma3_sigue		;6e67
forma3_picado:
	ld a,(ix+000h)		;6e69
	add a,(ix+006h)		;6e6c   ; la Y + el paso
	ld d,a			;6e6f
	ld (ix+000h),d		;6e70
	ld a,(ix+001h)		;6e73
	add a,(ix+007h)		;6e76   ; la X + el paso
	ld e,a			;6e79
	ld (ix+001h),e		;6e7a
	and a			;6e7d   ; en el borde: fuera
	ret nz			;6e7e
	ld d,0c0h		;6e7f   ; fuera
	ret			;6e81
mueve_forma4:		; La forma 4: como la 0, con la Y 0x23 mas abajo y el oscilador de otro modo; fuera de 0x10-0xEF, se acaba
	ld c,(ix+000h)		;6e82   ; (+0, +1) la velocidad en Y
	ld b,(ix+001h)		;6e85
	ld l,(ix+002h)		;6e88   ; (+2, +3) la Y
	ld h,(ix+003h)		;6e8b
	add hl,bc			;6e8e   ; + la velocidad
	ld (ix+002h),l		;6e8f   ; guardada
	ld (ix+003h),h		;6e92
	ld c,(ix+004h)		;6e95   ; (+4, +5)...
	ld b,(ix+005h)		;6e98
	ld l,(ix+006h)		;6e9b   ; ...+ (+6, +7)
	ld h,(ix+007h)		;6e9e
	add hl,bc			;6ea1
	ld (ix+006h),l		;6ea2   ; guardado
	ld (ix+007h),h		;6ea5
	ld b,h			;6ea8   ; en BC
	ld c,l			;6ea9
	ld e,(ix+008h)		;6eaa   ; (+8, +9)
	ld d,(ix+009h)		;6ead
	push de			;6eb0
	ld hl,00000h		;6eb1   ; 0 - (+8, +9)...
	and a			;6eb4
	sbc hl,de		;6eb5
	add hl,bc			;6eb7   ; ...+ BC...
	ld c,(ix+00ah)		;6eb8   ; ...+ (+0xA, +0xB)
	ld b,(ix+00bh)		;6ebb
	add hl,bc			;6ebe
	ld a,h			;6ebf   ; la Y + 0x23
	add a,023h		;6ec0   ; la Y + 0x23
	pop de			;6ec2
	ld l,(ix+00ch)		;6ec3   ; (+0xC, +0xD)...
	ld h,(ix+00dh)		;6ec6
	add hl,de			;6ec9   ; ...+ (+8, +9)
	ld d,a			;6eca   ; D = la Y
	add hl,bc			;6ecb
	ld c,(ix+002h)		;6ecc   ; + la Y de 16 bits
	ld b,(ix+003h)		;6ecf
	add hl,bc			;6ed2
	ld a,(ix+00eh)		;6ed3   ; del lado derecho?
	and a			;6ed6
	ld a,h			;6ed7
	jr z,mueve_forma4_x		;6ed8   ; a la izquierda: tal cual
	neg		;6eda   ; a la derecha: al reves
mueve_forma4_x:
	ld e,a			;6edc   ; E = la X
	cp 010h		;6edd   ; fuera por un lado?
	jr c,mueve_fuera		;6edf   ; menos de 0x10: fuera
	cp 0f0h		;6ee1   ; 0xF0 o mas: fuera
	jp nc,mueve_fuera		;6ee3
	push de			;6ee6
	ld c,(ix+00ah)		;6ee7   ; (+0xA, +0xB) / 16...
	ld b,(ix+00bh)		;6eea
	push bc			;6eed
	sra b		;6eee
	rr c		;6ef0
	sra b		;6ef2
	rr c		;6ef4
	sra b		;6ef6
	rr c		;6ef8
	sra b		;6efa
	rr c		;6efc
	ld l,(ix+008h)		;6efe   ; ...a (+8, +9)
	ld h,(ix+009h)		;6f01
	add hl,bc			;6f04
	ld (ix+008h),l		;6f05
	ld (ix+009h),h		;6f08
	ex de,hl			;6f0b
	ld hl,00000h		;6f0c   ; 0 - eso...
	and a			;6f0f
	sbc hl,de		;6f10
	sra h		;6f12   ; ... / 32...
	rr l		;6f14
	sra h		;6f16
	rr l		;6f18
	sra h		;6f1a
	rr l		;6f1c
	sra h		;6f1e
	rr l		;6f20
	sra h		;6f22
	rr l		;6f24
	pop bc			;6f26
	add hl,bc			;6f27   ; ...a (+0xA, +0xB)
	ld (ix+00ah),l		;6f28
	ld (ix+00bh),h		;6f2b
	pop de			;6f2e
	ret			;6f2f
mueve_fuera:
	ld d,0c0h		;6f30   ; fuera (Y 0xC0)
	ret			;6f32
tarea_enemigos_disparan:		; La tarea 8 (cada 16 o 32 cuadros): si se puede disparar (0xE0CE), un enemigo vivo dispara a la nave: uno de los 4 disparos libres de 0xE3BF (5 bytes); desde la ronda 4, el doble de deprisa
	ld a,001h		;6f33   ; otra vez el cuadro siguiente
	ld (0ec35h),a		;6f35
	ld a,(0e0ceh)		;6f38   ; se puede disparar?
	and a			;6f3b
	ret z			;6f3c
	ld ix,0e3bfh		;6f3d   ; los disparos
	ld b,004h		;6f41   ; 4
disparo_libre:
	ld a,(ix+000h)		;6f43   ; libre?
	and a			;6f46
	jr z,enemigo_dispara		;6f47
	ld de,00005h		;6f49   ; el siguiente (+5)
	add ix,de		;6f4c
	djnz disparo_libre		;6f4e
	ret			;6f50
enemigo_dispara:
	ld hl,0e2bdh		;6f51   ; los enemigos
	ld b,008h		;6f54
enemigo_dispara_uno:
	ld a,(hl)			;6f56   ; vivo?
	cp 001h		;6f57
	jr z,enemigo_dispara_va		;6f59
enemigo_dispara_sig:
	ld a,020h		;6f5b
	add a,l			;6f5d
	ld l,a			;6f5e
	jr nc,enemigo_dispara_sig2		;6f5f
	inc h			;6f61
enemigo_dispara_sig2:
	djnz enemigo_dispara_uno		;6f62   ; el siguiente
	ret			;6f64
enemigo_dispara_va:
	push hl			;6f65
	inc hl			;6f66
	ld c,(hl)			;6f67   ; la clase
	inc hl			;6f68   ; la Y y la X del enemigo
	push bc			;6f69
	call apunta		;6f6a   ; apunta
	pop bc			;6f6d
	pop hl			;6f6e
	ld a,(ix+000h)		;6f6f   ; ha salido?
	and a			;6f72   ; ha salido?
	jr z,enemigo_dispara_sig		;6f73
	bit 0,c		;6f75   ; la tarea: cada 16 cuadros, o 32 con las clases impares
	ld a,010h		;6f77
	jr z,enemigo_dispara_cuenta		;6f79
	add a,a			;6f7b   ; 32
enemigo_dispara_cuenta:
	ld (0ec35h),a		;6f7c
	ld a,(0e0c3h)		;6f7f   ; la ronda 4 o mas...
	cp 004h		;6f82
	ret c			;6f84
	sla (ix+003h)		;6f85   ; ...el doble de deprisa
	sla (ix+004h)		;6f89
	ret			;6f8d
apunta:		; El disparo sale del enemigo (Y, X) solo si la nave esta en su misma fila o columna de 16, o en su diagonal: el paso (+3 Y, +4 X) de -1, 0 o 1 hacia ella; antes de la ronda 4, las clases 0 y 1 solo hacia abajo y en su columna
	ld a,(hl)			;6f8e   ; la Y del enemigo...
	ld (ix+001h),a		;6f8f   ; la Y del disparo
	and 0f0h		;6f92
	ld d,a			;6f94   ; la fila del enemigo
	inc hl			;6f95   ; ...y la X
	ld a,(hl)			;6f96
	ld (ix+002h),a		;6f97   ; la X del disparo
	and 0f0h		;6f9a
	ld e,a			;6f9c   ; su columna
	ld a,(0e0c3h)		;6f9d   ; la ronda 4 o mas?
	cp 004h		;6fa0   ; la ronda 4 o mas?
	jr nc,apunta_todo		;6fa2
	ld a,c			;6fa4   ; las clases 0 y 1...
	and 003h		;6fa5   ; la clase & 3...
	cp 002h		;6fa7   ; ...2 o 3?
	jr nc,apunta_todo		;6fa9
	ld a,(0e21ah)		;6fab   ; ...en la columna de la nave?
	and 0f0h		;6fae   ; la columna de la nave
	cp e			;6fb0   ; la del enemigo?
	ret nz			;6fb1
	inc (ix+000h)		;6fb2   ; sale
	ld (ix+003h),002h		;6fb5   ; hacia abajo, 2
	ld (ix+004h),000h		;6fb9   ; sin paso de lado
	ret			;6fbd
apunta_todo:
	ld (ix+003h),000h		;6fbe   ; quieto, de momento
	ld (ix+004h),000h		;6fc2
	ld a,(0e219h)		;6fc6   ; la nave en su fila?
	ld b,a			;6fc9
	and 0f0h		;6fca   ; la fila de la nave (de 16)
	cp d			;6fcc
	ld a,(0e21ah)		;6fcd
	ld c,a			;6fd0
	jr nz,apunta_columna		;6fd1
	inc (ix+000h)		;6fd3   ; sale, de lado
	cp (ix+002h)		;6fd6   ; a que lado?
	ld (ix+004h),0ffh		;6fd9   ; a la izquierda
	ret c			;6fdd
	ld (ix+004h),001h		;6fde   ; a la derecha
	ret			;6fe2
apunta_columna:
	and 0f0h		;6fe3   ; en su columna?
	cp e			;6fe5
	jr nz,apunta_diagonal		;6fe6   ; no: la diagonal
	inc (ix+000h)		;6fe8   ; sale, arriba o abajo
	ld a,b			;6feb
	cp (ix+001h)		;6fec   ; a que lado?
	ld (ix+003h),0ffh		;6fef   ; arriba
	ret c			;6ff3
	ld (ix+003h),001h		;6ff4   ; abajo
	ret			;6ff8
apunta_diagonal:
	ld a,b			;6ff9   ; la distancia en Y...
	and 0f0h		;6ffa
	sub d			;6ffc
	ld b,001h		;6ffd
	jr nc,apunta_diagonal_x		;6fff
	ld b,0ffh		;7001
	neg		;7003
apunta_diagonal_x:
	ld d,a			;7005   ; ...y en X
	ld a,c			;7006
	and 0f0h		;7007
	sub e			;7009
	ld c,001h		;700a
	jr nc,apunta_diagonal_mira		;700c
	ld c,0ffh		;700e
	neg		;7010
apunta_diagonal_mira:
	cp d			;7012   ; iguales: en la diagonal
	ret nz			;7013
	inc (ix+000h)		;7014   ; sale
	ld (ix+003h),b		;7017
	ld (ix+004h),c		;701a
	ret			;701d
tarea_disparos_enemigos:		; La tarea 9, cada cuadro: los 4 disparos de los enemigos avanzan su paso; fuera de la pantalla se acaban
	ld a,001h		;701e   ; otra vez el cuadro siguiente
	ld (0ec36h),a		;7020
	ld ix,0e3bfh		;7023   ; los disparos
	ld hl,0e235h		;7027   ; sus sprites
	ld d,000h		;702a
	ld b,004h		;702c
disparo_enemigo_uno:
	ld a,(ix+000h)		;702e   ; en vuelo?
	and a			;7031
	jr nz,disparo_enemigo_mueve		;7032
disparo_enemigo_sig:
	ld e,004h		;7034   ; + 4: el sprite siguiente
	add hl,de			;7036
	inc e			;7037   ; + 5: el disparo siguiente
	add ix,de		;7038
	djnz disparo_enemigo_uno		;703a
	ret			;703c
disparo_enemigo_mueve:
	push hl			;703d
	call disparo_enemigo_paso		;703e
	pop hl			;7041
	jr disparo_enemigo_sig		;7042
disparo_enemigo_paso:		; Un paso: la Y + el paso (fuera por debajo de 0xC0), la X + el paso (fuera por los lados)
	ld a,(ix+001h)		;7044   ; la Y + el paso
	add a,(ix+003h)		;7047
	ld (ix+001h),a		;704a
	cp 0c0h		;704d   ; abajo del todo?
	jr nc,disparo_enemigo_fin		;704f
	ld (hl),a			;7051   ; al sprite
	ld a,(ix+002h)		;7052   ; la X + el paso
	add a,(ix+004h)		;7055
	ld (ix+002h),a		;7058
	cp 002h		;705b   ; por los lados?
	jr c,disparo_enemigo_fin		;705d
	cp 0f2h		;705f
	jr nc,disparo_enemigo_fin		;7061
	inc hl			;7063
	ld (hl),a			;7064
	ret			;7065
disparo_enemigo_fin:
	ld (ix+000h),000h		;7066   ; acabado
	ld (ix+001h),0e0h		;706a
	ld (hl),0e0h		;706e
	ret			;7070
tarea_tocados:		; La tarea 10, cada cuadro: los enemigos tocados (estado 2 o mas) cuentan su explosion: al 3 el dibujo 0xDC, al 11 el 0xE0, al 19 fuera (uno mas en 0xE2BC)
	ld a,001h		;7071   ; otra vez el cuadro siguiente
	ld (0ec37h),a		;7073
	ld hl,0e2bdh		;7076   ; los enemigos
	ld ix,0e245h		;7079   ; sus sprites
	ld b,008h		;707d
tocado_uno:
	ld a,(hl)			;707f   ; tocado?
	cp 002h		;7080
	jr nc,tocado_cuenta		;7082
tocado_sig:
	ld de,00004h		;7084   ; el sprite siguiente
	add ix,de		;7087
	ld a,020h		;7089   ; el enemigo siguiente (+32)
	add a,l			;708b
	ld l,a			;708c
	jr nc,tocado_sig2		;708d
	inc h			;708f
tocado_sig2:
	djnz tocado_uno		;7090   ; el siguiente
	ret			;7092
tocado_cuenta:
	inc a			;7093   ; un paso mas
	ld (hl),a			;7094
	cp 003h		;7095   ; el 3: 0xDC, blanco
	ld de,0dc0fh		;7097
	jr z,tocado_dibujo		;709a
	cp 00bh		;709c   ; el 11: 0xE0
	ld d,0e0h		;709e
	jr z,tocado_dibujo		;70a0
	cp 013h		;70a2   ; el 19: fuera
	jr nz,tocado_sig		;70a4
	ld (hl),000h		;70a6
	ld (ix+000h),0e0h		;70a8
	ld a,(0e2bch)		;70ac   ; uno mas en el grupo siguiente
	inc a			;70af
	ld (0e2bch),a		;70b0
	jr tocado_sig		;70b3
tocado_dibujo:
	ld (ix+002h),d		;70b5
	ld (ix+003h),e		;70b8
	jr tocado_sig		;70bb

; ----------------------------------------------------------------------
; DATOS robot_sprites: Los cuatro sprites del robot grande del final (0x70BD)
;   y su color en cada ronda (0x70CD)
;   0x70bd..0x70d1  (20 bytes)
DATA_robot_sprites:
	defb 067h,07ch,000h,000h,057h,07ch,08ch,000h,047h,07ch,090h,000h,057h,07ch,094h,000h	; 70bd  g|..W|..G|..W|..
	defb 004h,002h,006h,00eh	; 70cd

; ======================================================================
; CODIGO 0x70d1..0x7189  (184 bytes)
; ======================================================================


robot_entra_pon:		; El robot grande del final: sus cuatro sprites (0xE245), 8 destellos de 10 cuadros (0xE2AF, 0xE2B1) y su color de la ronda
	ld a,(0e2a6h)		;70d1   ; la nave tocada: nada
	and a			;70d4
	ret nz			;70d5
	ld hl,070bdh		;70d6   ; los cuatro sprites
	ld de,0e245h		;70d9   ; a 0xE245
	ld bc,00010h		;70dc   ; 16 bytes
	ldir		;70df
	xor a			;70e1   ; 0xE2B6 y 0xE2B4 a 0
	ld (0e2b6h),a		;70e2
	ld (0e2b4h),a		;70e5
	ld a,008h		;70e8   ; 8 destellos
	ld (0e2afh),a		;70ea
	ld a,00ah		;70ed   ; de 10 cuadros
	ld (0e2b1h),a		;70ef
	ld a,(0e0a8h)		;70f2   ; el color de la ronda
	and 003h		;70f5   ; la ronda & 3
	ld b,000h		;70f7
	ld c,a			;70f9
	ld hl,070cdh		;70fa   ; la tabla de colores
	add hl,bc			;70fd
	ld a,(hl)			;70fe
	ld (0e2b0h),a		;70ff   ; el color del robot
tarea_robot_entra:		; La tarea 11: el robot grande parpadea (8 destellos: su color y el de 0x7191 en el PSG) y despues sube hasta Y 0x1F; alli empieza (0x7199, 0x733D)
	ld ix,0e249h		;7102   ; sus sprites
	ld a,(0e2afh)		;7106   ; destellos?
	and a			;7109
	jr z,robot_sube		;710a
	ld (0ec38h),a		;710c
	ld a,(0e2b1h)		;710f   ; la cuenta del destello
	dec a			;7112
	ld (0e2b1h),a		;7113
	jr nz,robot_destello		;7116
	ld a,(0e2afh)		;7118   ; un destello menos
	dec a			;711b
	ld (0e2afh),a		;711c
	jr z,robot_destellos_fin		;711f
	ld a,00ah		;7121   ; 10 cuadros
	ld (0e2b1h),a		;7123
robot_destello:
	bit 0,a		;7126   ; uno y otro
	ld a,000h		;7128
	ld b,a			;712a
	ld hl,07189h		;712b   ; el sonido de 0x7189
	jr z,robot_destello_color		;712e
	ld hl,07191h		;7130   ; el de 0x7191
	ld a,001h		;7133
	ld (0ec38h),a		;7135
	ld a,(0e2b0h)		;7138   ; su color
	ld b,006h		;713b
robot_destello_color:
	ld (ix+003h),a		;713d
	ld (ix+007h),a		;7140
	ld (ix+00bh),b		;7143
robot_sonido:
	ld b,004h		;7146   ; 4 registros del PSG
	jp psg_tabla		;7148
robot_destellos_fin:
	ld hl,056ach		;714b   ; el estado 0x56AC
	ld (0e09ah),hl		;714e
	ld a,010h		;7151   ; la tarea en 16 cuadros
	ld (0ec38h),a		;7153
	call tarea_robot		;7156   ; la nave cambiada se mueve...
	call tarea_robot_golpe		;7159   ; ...y golpea
	ld a,004h		;715c   ; las musicas 4 y 3
	ld (0e3f2h),a		;715e
	dec a			;7161
	ld (0e3fbh),a		;7162
	ld hl,07189h		;7165
	jr robot_sonido		;7168
robot_sube:
	ld a,(ix+000h)		;716a   ; en Y 0x1F?
	cp 01fh		;716d   ; arriba del todo?
	jr z,robot_llega		;716f
	dec (ix-004h)		;7171   ; un punto mas arriba los cuatro
	dec (ix+000h)		;7174
	dec (ix+004h)		;7177
	dec (ix+008h)		;717a
	ld a,001h		;717d   ; la tarea, a 1
	ld (0ec38h),a		;717f
	ret			;7182
robot_llega:
	call tarea_robot_grande		;7183
	jp tarea_robot_grande_brazo		;7186

; ----------------------------------------------------------------------
; DATOS robot_sonidos: Los dos sonidos del destello: 4 parejas (registro,
;   valor) cada uno
;   0x7189..0x7199  (16 bytes)
DATA_robot_sonidos:
	defb 007h,0b8h,000h,000h,001h,000h,008h,000h,007h,0b8h,000h,057h,001h,003h,008h,00fh	; 7189  ...........W....

; ======================================================================
; CODIGO 0x7199..0x7506  (877 bytes)
; ======================================================================


tarea_robot_grande:		; La tarea 12: el robot grande. Tocado (0xE2B3), se deshace en cuatro pasos y viene el recuento (0x73A4); si no, va de un lado a otro, baja (mas deprisa si esta por encima de la nave) y si llega abajo se va; los golpes de la nave cambiada (0x72AE)
	ld ix,0e245h		;7199   ; sus sprites
	ld a,(0e2b3h)		;719d   ; deshaciendose?
	and a			;71a0
	jr z,robot_grande_mueve		;71a1
	inc a			;71a3   ; un paso mas
	ld (0e2b3h),a		;71a4
	ld (ix+006h),0e0h		;71a7   ; fuera un trozo
	cp 004h		;71ab   ; el 4: el recuento
	jr z,robot_grande_fin		;71ad
	cp 002h		;71af   ; el 2: en 16 cuadros
	ld a,010h		;71b1
	jr z,robot_grande_cuenta		;71b3
	ld (ix+004h),0e0h		;71b5   ; otro trozo fuera
	ld a,040h		;71b9   ; en 64 cuadros
robot_grande_cuenta:
	ld (0ec39h),a		;71bb
	ret			;71be
robot_grande_fin:
	ld hl,0e219h		;71bf   ; todos los sprites fuera
	ld bc,00068h		;71c2   ; 0x68 bytes
	ld a,0e0h		;71c5
	call llena		;71c7
	jp recuento		;71ca   ; el recuento
robot_grande_mueve:
	ld a,001h		;71cd   ; otra vez el cuadro siguiente
	ld (0ec39h),a		;71cf
	call robot_grande_parpadea		;71d2   ; el parpadeo del cuarto golpe
	ld a,(0e2adh)		;71d5   ; la nave golpeando?
	and a			;71d8
	jr z,robot_grande_anda		;71d9
	call robot_grande_golpe		;71db   ; le da?
	and a			;71de
	jr z,robot_grande_anda		;71df
	xor a			;71e1   ; si: las tareas de la nave paradas...
	ld (0ec3bh),a		;71e2
	ld (0ec3ch),a		;71e5
	ld (0e3f2h),a		;71e8   ; ...sin musica
	ld (0e3fbh),a		;71eb
	ld a,010h		;71ee   ; en 16 cuadros
	ld (0ec39h),a		;71f0
	ret			;71f3
robot_grande_anda:
	ld a,(ix+004h)		;71f4   ; abajo del todo (0xC7)?
	cp 0c7h		;71f7
	jr nc,robot_grande_se_va		;71f9
	ld a,(0e219h)		;71fb   ; por encima de la nave?
	cp (ix+004h)		;71fe
	jr c,robot_grande_baja2		;7201
	ld a,(0e2b2h)		;7203   ; hacia que lado?
	and a			;7206
	ld b,0e0h		;7207   ; a la izquierda, hasta 8
	jr z,robot_grande_der		;7209
	ld b,008h		;720b
	dec (ix+001h)		;720d   ; un punto a la izquierda los cuatro
	dec (ix+005h)		;7210
	dec (ix+009h)		;7213
	dec (ix+00dh)		;7216
	jr robot_grande_borde		;7219
robot_grande_der:
	inc (ix+001h)		;721b   ; a la derecha, hasta 0xE0
	inc (ix+005h)		;721e
	inc (ix+009h)		;7221
	inc (ix+00dh)		;7224
robot_grande_borde:
	ld a,b			;7227
	cp (ix+001h)		;7228   ; en el borde?
	jr nz,robot_grande_baja		;722b
	ld a,(0e2b2h)		;722d   ; da la vuelta
	cpl			;7230
	ld (0e2b2h),a		;7231
robot_grande_baja:
	ld a,(ix+001h)		;7234   ; cada 8 puntos de lado...
	and 007h		;7237
	ret nz			;7239
robot_grande_punto:
	inc (ix+000h)		;723a   ; ...un punto abajo
	inc (ix+004h)		;723d
	inc (ix+008h)		;7240
	inc (ix+00ch)		;7243
	ret			;7246
robot_grande_baja2:
	call robot_grande_punto		;7247   ; por encima de la nave: dos abajo
	jr robot_grande_punto		;724a
robot_grande_se_va:		; Abajo del todo: se va. Sus sprites fuera, las tareas 12-15 paradas; si la nave sigue entera, vuelve a ser nave (0xE21B = 0x80), el scroll otra vez (0xE422 = 0xFF), el estado 0x6286, la musica 2 y una vuelta mas (0xE0C3)
	ld a,0e0h		;724c   ; fuera
	ld (ix+000h),a		;724e
	ld (ix+004h),a		;7251
	ld (ix+008h),a		;7254
	ld (ix+00ch),a		;7257
	xor a			;725a   ; las tareas 12-15...
	ld hl,0ec39h		;725b
	ld bc,00004h		;725e
	call llena		;7261   ; ...paradas
	ld a,(0e2a6h)		;7264   ; la nave tocada?
	and a			;7267
	ret nz			;7268
	ld a,0e0h		;7269   ; el otro sprite fuera
	ld (0e221h),a		;726b
	ld a,080h		;726e   ; el dibujo de la nave
	ld (0e21bh),a		;7270
	ld a,0ffh		;7273   ; el scroll otra vez
	ld (0e422h),a		;7275
	inc a			;7278   ; sin la segunda musica
	ld (0e3fbh),a		;7279
	ld hl,06286h		;727c   ; el estado: la nave entra
	ld (0e09ah),hl		;727f
	ld a,002h		;7282   ; la musica 2
	ld (0e3f2h),a		;7284
	ld hl,0e0c3h		;7287   ; una vuelta mas
	inc (hl)			;728a
	jp canal_a_calla		;728b   ; el canal A callado
robot_grande_parpadea:		; Con cuatro golpes (0xE2B6), sus colores cambian cada 2 cuadros
	ld a,(0e2b6h)		;728e   ; cuatro golpes?
	cp 004h		;7291
	ret nz			;7293
	ld hl,0e2b7h		;7294   ; la cuenta
	inc (hl)			;7297
	bit 1,(hl)		;7298   ; uno y otro
	ld a,000h		;729a
	ld b,a			;729c
	jr z,robot_grande_color		;729d
	ld b,006h		;729f   ; su color y el 6
	ld a,(0e2b0h)		;72a1
robot_grande_color:
	ld (ix+007h),a		;72a4
	ld (ix+00bh),a		;72a7
	ld (ix+00fh),b		;72aa
	ret			;72ad
robot_grande_golpe:		; ¿El puno de la nave cambiada (0xE221) le da al robot grande (0xE249)? Un golpe mas (0xE2B6): los puntos 2, el efecto 3; al quinto, los puntos 5, el robot se deshace (el dibujo 0xDC) y 0xE2B3 = 1
	push ix		;72ae   ; el robot grande
	ld ix,0e249h		;72b0
	ld iy,0e221h		;72b4   ; el puno
	call toca_16		;72b8   ; le da?
	pop ix		;72bb
	and a			;72bd
	ret z			;72be
	ld a,(0e2b6h)		;72bf   ; un golpe mas
	inc a			;72c2
	ld (0e2b6h),a		;72c3
	cp 005h		;72c6   ; el quinto?
	ld a,000h		;72c8
	jr z,robot_grande_roto		;72ca
	inc a			;72cc   ; el efecto del canal A
	ld (0ec3fh),a		;72cd
	inc a			;72d0   ; los puntos 2
	ld (0e29bh),a		;72d1
	inc a			;72d4   ; el efecto 3
	ld (0e3d5h),a		;72d5
	ld a,010h		;72d8   ; las tareas de la nave en 16 cuadros
	ld (0ec3bh),a		;72da
	ld (0ec3ch),a		;72dd
	inc a			;72e0
	ld (0ec39h),a		;72e1
	ld a,030h		;72e4   ; el robot en 48
	ld (0ec3ah),a		;72e6
	xor a			;72e9
	ret			;72ea
robot_grande_roto:
	ld (0e3d5h),a		;72eb   ; sin efecto
	inc a			;72ee
	ld (0ec3fh),a		;72ef
	ld a,005h		;72f2   ; los puntos 5
	ld (0e29bh),a		;72f4
	ld (ix+000h),0e0h		;72f7   ; tres trozos fuera
	ld (ix+008h),0e0h		;72fb
	ld (ix+00ch),0e0h		;72ff
	ld (ix+006h),0dch		;7303   ; el dibujo 0xDC (la explosion)...
	ld (ix+007h),00fh		;7307   ; ...blanco
	xor a			;730b   ; la tarea 13 parada
	ld (0ec3ah),a		;730c
	inc a			;730f   ; deshaciendose
	ld (0e2b3h),a		;7310
	ret			;7313
toca_16:		; ¿(IY) a menos de 8 de (IX) en Y y en X? A = 1 si
	ld a,(ix+000h)		;7314   ; la Y - 8...
	sub 008h		;7317   ; la Y de (IX) - 8
	ld b,a			;7319
	add a,010h		;731a   ; ...y + 8
	ld c,a			;731c   ; + 8
	ld a,(iy+000h)		;731d   ; la de (IY)
	cp b			;7320   ; por encima?
	jr c,toca_16_no		;7321
	cp c			;7323   ; por debajo?
	jr nc,toca_16_no		;7324
	ld a,(ix+001h)		;7326   ; la X - 8...
	sub 008h		;7329   ; la X - 8
	ld b,a			;732b
	add a,010h		;732c   ; ...y + 8
	ld c,a			;732e
	ld a,(iy+001h)		;732f   ; la de (IY)
	cp b			;7332
	jr c,toca_16_no		;7333
	cp c			;7335
	jr nc,toca_16_no		;7336
	ld a,001h		;7338   ; si: 1
	ret			;733a
toca_16_no:
	xor a			;733b
	ret			;733c
tarea_robot_grande_brazo:		; La tarea 13: el robot grande mueve los brazos: uno y otro (0xA0/0xAC o 0xA4/0xB4) con su color, cada 12 cuadros; y luego quieto 96 cuadros (el dibujo 0x8C)
	ld ix,0e245h		;733d   ; sus sprites
	ld a,(0e2b4h)		;7341   ; uno y otro
	cpl			;7344
	ld (0e2b4h),a		;7345
	and a			;7348
	jr z,robot_grande_quieto		;7349
	ld a,(0e2b5h)		;734b   ; y cual de los dos
	cpl			;734e
	ld (0e2b5h),a		;734f
	ld hl,0a0ach		;7352   ; 0xA0 y 0xAC...
	and a			;7355
	jr z,robot_grande_brazo_pon		;7356
	ld hl,0a4b4h		;7358   ; ...o 0xA4 y 0xB4
robot_grande_brazo_pon:
	ld (ix+002h),l		;735b
	ld a,(0e2b0h)		;735e
	ld (ix+003h),a		;7361
	ld (ix+006h),h		;7364
	ld a,00ch		;7367   ; en 12 cuadros
	ld (0ec3ah),a		;7369
	ret			;736c
robot_grande_quieto:
	ld (ix+003h),000h		;736d   ; transparente
	ld (ix+006h),08ch		;7371   ; el dibujo 0x8C
	ld a,(0e2a6h)		;7375
	and a			;7378
	ret nz			;7379
	ld a,060h		;737a   ; en 96 cuadros
	ld (0ec3ah),a		;737c
	ret			;737f
numero_cifras:		; El numero HL en cifras ASCII hacia atras desde IX (cinco como mucho, sin los ceros de delante)
	ld b,005h		;7380   ; cinco cifras
numero_cifra:
	push bc			;7382
	ld de,0000ah		;7383   ; HL / 10: E el resto
	call divide		;7386   ; HL / 10: el resto en E
	pop bc			;7389
	ld a,e			;738a   ; la cifra
	or 030h		;738b   ; en ASCII
	ld (ix+000h),a		;738d   ; a su sitio
	dec ix		;7390   ; la anterior
	ld a,h			;7392   ; ya menos de 10?
	and a			;7393   ; quedan cifras?
	jr nz,numero_cifra_sig		;7394
	ld a,l			;7396   ; la ultima: menos de 10?
	cp 00ah		;7397
	jr nc,numero_cifra_sig		;7399
	or 030h		;739b   ; la ultima
	ld (ix+000h),a		;739d   ; en su sitio
	ret			;73a0
numero_cifra_sig:
	djnz numero_cifra		;73a1
	ret			;73a3
recuento:		; El recuento del final de la ronda: la pantalla en blanco, las letras de la BIOS en las casillas 0x20-0x59 de los dos tercios de abajo, los blancos rotos y los que habia (0xE0B5, 0xE0B3) RATE, el porcentaje de rotos, y BONUS, el premio que le toca (0x7513); la musica; 256 cuadros y el estado 0x7589
	call sprites_ram		;73a4   ; los sprites fuera
	call scroll_pon		;73a7   ; el scroll al principio
	call sonido_calla		;73aa   ; el sonido callado
	xor a			;73ad   ; el scroll y las estrellas paradas
	ld (0ec2dh),a		;73ae
	ld (0ec2eh),a		;73b1
	ld (0ec33h),a		;73b4   ; la tarea 6 parada
	ld (0e0c3h),a		;73b7   ; las vueltas a 0
	ld hl,01800h		;73ba   ; la pantalla en blanco
	ld bc,00300h		;73bd
	call 00056h		;73c0
	ld hl,0e40bh		;73c3   ; los numeros, "0000000000"
	ld bc,0000ah		;73c6
	ld a,030h		;73c9
	call llena		;73cb
	ld hl,(00004h)		;73ce   ; la fuente de la BIOS, desde el espacio...
	ld de,00100h		;73d1
	add hl,de			;73d4
	ld de,00900h		;73d5   ; ...a las casillas 0x20-0x59 del segundo tercio...
	ld bc,001d0h		;73d8
	push hl			;73db
	push bc			;73dc
	call 0005ch		;73dd
	pop bc			;73e0
	pop hl			;73e1
	ld de,01100h		;73e2   ; ...y del tercero
	push bc			;73e5
	call 0005ch		;73e6
	pop bc			;73e9
	ld hl,02900h		;73ea   ; en blanco
	ld a,0f0h		;73ed
	push bc			;73ef
	call 00056h		;73f0
	pop bc			;73f3
	ld hl,03100h		;73f4
	ld a,0f0h		;73f7
	call 00056h		;73f9
	ld hl,(0e0b5h)		;73fc   ; los blancos rotos...
	ld ix,0e414h		;73ff   ; ...en cifras en 0xE410
	call numero_cifras		;7403
	ld hl,(0e0b3h)		;7406   ; los que habia...
	ld ix,0e40fh		;7409   ; ...en 0xE40B
	call numero_cifras		;740d
	ld hl,0190ch		;7410   ; en la fila 8, columna 12: el dibujo de un blanco (0xC8) y el numero
	ld de,0e40bh		;7413
	ld a,0c8h		;7416
	call recuento_linea		;7418
	ld hl,0196ch		;741b   ; en la fila 11: un blanco roto (0x90) y el numero
	ld de,0e410h		;741e
	ld a,090h		;7421
	call recuento_linea		;7423
	ld hl,07509h		;7426   ; "RATE"...
	ld de,019cch		;7429   ; ...en la fila 14, columna 12
	ld bc,00005h		;742c
	call 0005ch		;742f
	ld hl,(0e0b5h)		;7432   ; los rotos x 100...
	add hl,hl			;7435
	add hl,hl			;7436
	ld d,h			;7437
	ld e,l			;7438
	add hl,hl			;7439
	add hl,hl			;743a
	add hl,hl			;743b
	ld b,h			;743c
	ld c,l			;743d
	add hl,hl			;743e
	add hl,de			;743f
	add hl,bc			;7440
	ld de,(0e0b3h)		;7441
	call divide		;7445   ; ...entre los que habia
	ld a,l			;7448
	ld c,a			;7449
	cp 064h		;744a   ; 100 o mas?
	jr c,recuento_cifras		;744c
	push bc			;744e
	ld hl,07506h		;744f   ; "100"
	ld b,003h		;7452
	call vram_b		;7454
	pop bc			;7457
	jr recuento_por_ciento		;7458
recuento_cifras:
	xor a			;745a
	out (098h),a		;745b   ; un espacio
	ld b,a			;745d
	ld a,c			;745e
recuento_decenas:
	sub 00ah		;745f
	jr c,recuento_unidades		;7461
	inc b			;7463
	jr recuento_decenas		;7464
recuento_unidades:
	push af			;7466
	ld a,b			;7467   ; las decenas...
	or 030h		;7468
	out (098h),a		;746a   ; ...a la VRAM
	inc ix		;746c   ; espera
	dec ix		;746e
	pop af			;7470
	add a,00ah		;7471   ; las unidades
	or 030h		;7473
	out (098h),a		;7475   ; a la VRAM
	inc ix		;7477
	dec ix		;7479
recuento_por_ciento:
	ld a,025h		;747b   ; "%"
	out (098h),a		;747d
	ld a,c			;747f
	ld hl,07513h		;7480   ; la tabla de premios
	ld de,00009h		;7483
	ld b,006h		;7486   ; 6 tramos: con el 100 %, el septimo
recuento_premio:
	cp (hl)			;7488   ; por debajo de su tope?
	jr c,recuento_premio_pon		;7489
	add hl,de			;748b
	djnz recuento_premio		;748c
recuento_premio_pon:
	inc hl			;748e
	ld e,(hl)			;748f
	inc hl			;7490
	ld d,(hl)			;7491
	inc hl			;7492
	ld (0e3d3h),de		;7493   ; el premio (en centenas) a 0xE3D3
	ld de,01a4ch		;7497   ; y su texto en la fila 18, columna 12
	ld bc,00006h		;749a
	call 0005ch		;749d
	ld hl,0750eh		;74a0   ; "BONUS"...
	ld de,01a0dh		;74a3   ; ...en la fila 16, columna 13
	ld bc,00005h		;74a6
	call 0005ch		;74a9
	ld a,003h		;74ac   ; las musicas 3 y 2
	ld (0e3f2h),a		;74ae
	dec a			;74b1
	ld (0e3fbh),a		;74b2
	ld hl,recuento_espera		;74b5   ; el estado: la espera
	ld (0e09ah),hl		;74b8
	ld hl,00100h		;74bb   ; 256 cuadros
	ld (0e09dh),hl		;74be
recuento_espera:
	ld hl,(0e09dh)		;74c1   ; un cuadro menos
	dec hl			;74c4
	ld (0e09dh),hl		;74c5
	ld a,l			;74c8
	or h			;74c9
	ret nz			;74ca
	ld (0ec40h),a		;74cb   ; el sonido de la vida
	ld hl,07589h		;74ce   ; el estado 0x7589
	ld (0e09ah),hl		;74d1
	ret			;74d4
recuento_linea:		; El dibujo de 2 x 2 casillas (A, A + 4, A + 8, A + 12) en HL y el numero de DE (cinco cifras, sin los ceros de delante) en la fila de abajo
	ld b,002h		;74d5   ; dos columnas
recuento_linea_col:
	push bc			;74d7
	push hl			;74d8
	push af			;74d9   ; la casilla
	call 0004dh		;74da   ; WRTVRM
	pop af			;74dd
	add a,004h		;74de   ; la de abajo, + 4
	ld bc,00020h		;74e0
	add hl,bc			;74e3
	push af			;74e4
	call 0004dh		;74e5   ; WRTVRM
	pop af			;74e8
	add a,008h		;74e9   ; la siguiente, + 8
	pop hl			;74eb
	pop bc			;74ec
	inc hl			;74ed   ; una columna a la derecha
	djnz recuento_linea_col		;74ee
	ld c,020h		;74f0   ; dos filas mas abajo...
	add hl,bc			;74f2
	ld c,005h		;74f3   ; ...cinco cifras
recuento_ceros:
	ld a,(de)			;74f5
	cp 030h		;74f6   ; un 0 de delante?
	jr nz,recuento_numero		;74f8   ; ya no es 0
	inc hl			;74fa
	inc de			;74fb
	dec bc			;74fc
	ld a,c			;74fd
	cp 001h		;74fe   ; la ultima se queda
	jr nz,recuento_ceros		;7500
recuento_numero:
	ex de,hl			;7502
	jp 0005ch		;7503   ; LDIRVM

; ----------------------------------------------------------------------
; DATOS recuento_datos: "100", "RATE", "BONUS" y los siete premios (el tope,
;   el premio en centenas, el texto): por debajo del 50 % nada; del 50, 5000;
;   del 60, 10000; del 70, 15000; del 80, 20000; del 90, 30000; y el septimo,
;   100000, al que se llega con el 100 % porque el bucle solo mira seis
;   0x7506..0x7552  (76 bytes)
DATA_recuento_datos:
	defb 031h,030h,030h,052h,041h,054h,045h,020h,042h,04fh,04eh,055h,053h,032h,000h,000h	; 7506  100RATE BONUS2..
	defb 020h,020h,020h,020h,020h,030h,03ch,032h,000h,020h,020h,035h,030h,030h,030h,046h	; 7516       0<2.  5000F
	defb 064h,000h,020h,031h,030h,030h,030h,030h,050h,096h,000h,020h,031h,035h,030h,030h	; 7526  d. 10000P.. 1500
	defb 030h,05ah,0c8h,000h,020h,032h,030h,030h,030h,030h,064h,02ch,001h,020h,033h,030h	; 7536  0Z.. 20000d,. 30
	defb 030h,030h,030h,064h,0e8h,003h,031h,030h,030h,030h,030h,030h	; 7546  000d..100000

; ======================================================================
; CODIGO 0x7552..0x75e2  (144 bytes)
; ======================================================================


letras_sprites:		; B letras de HL (de la fuente de la BIOS) a los dibujos de sprites desde DE, de 16 en 16
	push bc			;7552
	push de			;7553
	push hl			;7554
	ld a,(hl)			;7555   ; la letra
	call letra_pinta		;7556   ; su dibujo
	pop hl			;7559   ; la siguiente letra
	pop de			;755a
	pop bc			;755b
	inc hl			;755c
	ld a,010h		;755d   ; el dibujo siguiente (+16)
	add a,e			;755f   ; + 16
	ld e,a			;7560
	jr nc,letras_sprites_sig		;7561
	inc d			;7563
letras_sprites_sig:
	djnz letras_sprites		;7564
	ret			;7566
divide:		; HL = HL / DE y DE = el resto (16 bits, bit a bit)
	ld c,l			;7567   ; el dividendo en A y C
	ld a,h			;7568
	ld hl,00000h		;7569   ; el resto, de 0
	ld b,010h		;756c   ; 16 bits
	or a			;756e
divide_bit:
	rl c		;756f   ; el bit de arriba del dividendo...
	rla			;7571
	rl l		;7572   ; ...al resto
	rl h		;7574
	push hl			;7576
	sbc hl,de		;7577   ; cabe?
	ccf			;7579
	jr c,divide_sig		;757a
	ex (sp),hl			;757c
divide_sig:
	inc sp			;757d   ; el resto que no cabe, fuera de la pila
	inc sp			;757e
	djnz divide_bit		;757f
	ex de,hl			;7581   ; el resto a DE
	rl c		;7582   ; el ultimo bit
	ld l,c			;7584   ; el cociente
	rla			;7585
	ld h,a			;7586
	or a			;7587
	ret			;7588
estado_bonus:		; El estado del premio: el BONUS (0xE3D3, en centenas) pasa a los puntos de cien en cien, con un sonido; despues 128 cuadros y la ronda siguiente
	ld hl,(0e3d3h)		;7589   ; queda premio?
	ld a,h			;758c
	or l			;758d
	jr z,bonus_fin		;758e
	ld a,001h		;7590   ; los puntos de la clase 1 (100)
	ld (0e29bh),a		;7592
	ld hl,(0e3d3h)		;7595   ; cien menos
	dec hl			;7598
	ld (0e3d3h),hl		;7599
	call bonus_sonido		;759c   ; el sonido
	ld a,h			;759f
	or l			;75a0
	ret nz			;75a1
bonus_fin:
	ld a,080h		;75a2   ; 128 cuadros
	ld (0e09dh),a		;75a4
	ld hl,bonus_espera		;75a7   ; el estado de la espera
	ld (0e09ah),hl		;75aa
bonus_espera:
	ld a,(0e09dh)		;75ad   ; un cuadro menos
	dec a			;75b0
	ld (0e09dh),a		;75b1
	ret nz			;75b4
	ld hl,0e265h		;75b5   ; los sprites fuera
	ld bc,00018h		;75b8
	ld a,0e0h		;75bb
	call llena		;75bd
	ld hl,0e0a8h		;75c0   ; la ronda siguiente
	inc (hl)			;75c3
	call estado_nada		;75c4
	xor a			;75c7   ; 0xE0CB = 0
	ld (0e0cbh),a		;75c8
	jp ronda		;75cb   ; empieza
bonus_sonido:		; Uno de los dos sonidos de 0x75E2/0x75E8 (3 registros del PSG), uno y otro
	xor a			;75ce
	ld (0ec40h),a		;75cf
	ld a,l			;75d2   ; uno y otro
	and 002h		;75d3
	ld b,003h		;75d5
	ld hl,075e2h		;75d7
	jr z,bonus_sonido_pon		;75da
	ld hl,075e8h		;75dc
bonus_sonido_pon:
	jp psg_tabla		;75df

; ----------------------------------------------------------------------
; DATOS bonus_sonidos: Los dos sonidos del premio: 3 parejas (registro, valor)
;   cada uno
;   0x75e2..0x75ee  (12 bytes)
DATA_bonus_sonidos:
	defb 002h,000h,003h,000h,009h,000h,002h,06bh,003h,000h,009h,00ch	; 75e2  .......k....

; ======================================================================
; CODIGO 0x75ee..0x761d  (47 bytes)
; ======================================================================


estado_capsulas:		; Un estado, con el trozo 6 del mapa: 0x4F cuadros despues salen las tres capsulas (sus sprites de 0x761D a 0xE265 y sus datos a 0xEB79); los enemigos pueden disparar (0xE0CE)
	ld a,(0eb74h)		;75ee   ; la espera
	dec a			;75f1
	ld (0eb74h),a		;75f2
	ret nz			;75f5
	ld hl,0761dh		;75f6   ; los sprites...
	ld de,0e265h		;75f9   ; ...a 0xE265
	ld bc,0000ch		;75fc   ; 12 bytes
	ldir		;75ff
	ld de,0eb79h		;7601   ; y sus datos a 0xEB79
	ld bc,0000ch		;7604
	ldir		;7607
	xor a			;7609   ; 0xEB76 y 0xEB77 a 0
	ld (0eb76h),a		;760a
	ld (0eb77h),a		;760d
	inc a			;7610   ; capsulas en marcha (0xEB75)
	ld (0eb75h),a		;7611
	ld (0e0ceh),a		;7614   ; los enemigos disparan
	call tarea_capsulas		;7617   ; la tarea 17
	jp estado_nada		;761a

; ----------------------------------------------------------------------
; DATOS capsulas_datos: Las tres capsulas: sus sprites (Y, X, dibujo, color) y
;   sus datos (el estado, la Y, la clase, la X)
;   0x761d..0x7635  (24 bytes)
DATA_capsulas_datos:
	defb 001h,058h,06ch,001h,001h,078h,06ch,001h,001h,098h,06ch,001h,000h,000h,001h,058h	; 761d  .Xl..xl...l....X
	defb 000h,000h,001h,078h,000h,000h,001h,098h	; 762d  ...x....

; ======================================================================
; CODIGO 0x7635..0x7907  (722 bytes)
; ======================================================================


tarea_capsulas:		; La tarea 17: las tres capsulas bajan con el scroll; cada disparo que les da cambia su clase (giran: dibujos 0x70-0x7C); cuando las tres estan paradas (estado 4), segun cuantas quedan en una clase u otra: las tres pares (el dibujo 0x70), una vida y disparos mas rapidos (0xE0CD = 8); las tres impares (0x78), los enemigos dejan de disparar
	call capsulas_sonido		;7635   ; el sonido
	ld a,001h		;7638   ; otra vez el cuadro siguiente
	ld (0ec3eh),a		;763a
	ld hl,0eb79h		;763d   ; las tres
	ld bc,00300h		;7640   ; B = 3, C = 0
capsula_mira:
	ld a,(hl)			;7643   ; parada (4 o mas)?
	cp 004h		;7644   ; parada?
	jr c,capsulas_bajan		;7646
	inc hl			;7648
	ld a,(hl)			;7649   ; su clase: impar, C - 1; par, C + 1
	dec c			;764a   ; impar: C - 1
	bit 0,a		;764b
	jr nz,capsula_mira_sig		;764d
	inc c			;764f   ; par: C + 1
	inc c			;7650
capsula_mira_sig:
	inc hl			;7651
	inc hl			;7652
	inc hl			;7653
	djnz capsula_mira		;7654
	call capsulas_premio		;7656   ; las tres paradas: el premio
capsulas_bajan:
	ld c,002h		;7659   ; 2 puntos abajo en los pasos 2, 5, 8 y 11 del scroll
	ld a,(0e425h)		;765b   ; el paso del scroll
	cp 002h		;765e
	jr z,capsulas_mueve		;7660   ; en estos pasos, abajo
	cp 005h		;7662
	jr z,capsulas_mueve		;7664
	cp 008h		;7666
	jr z,capsulas_mueve		;7668
	cp 00bh		;766a
	jr z,capsulas_mueve		;766c
	ld c,000h		;766e   ; los otros: quietas
capsulas_mueve:
	ld hl,0eb79h		;7670   ; sus datos
	ld ix,0e265h		;7673   ; sus sprites
	ld iy,0eb77h		;7677   ; cuantas girando
	ld de,00002h		;767b
	ld b,003h		;767e
capsula_una:
	ld a,(hl)			;7680   ; el estado 3?
	cp 003h		;7681
	jr z,capsula_para		;7683
	cp 001h		;7685   ; el 1?
	jr z,capsula_gira_empieza		;7687
	inc hl			;7689
	cp 002h		;768a   ; el 2?
	jr z,capsula_gira		;768c
capsula_baja:
	inc hl			;768e
	ld a,(hl)			;768f   ; la Y
	add a,c			;7690   ; + lo que baja
	cp 0c0h		;7691   ; abajo del todo?
	jr nc,capsulas_fin		;7693
	ld (hl),a			;7695   ; la Y
	ld (ix+000h),a		;7696
	add hl,de			;7699   ; la siguiente capsula
	add ix,de		;769a
	add ix,de		;769c
	djnz capsula_una		;769e
	ret			;76a0
capsula_gira_empieza:
	inc (iy+000h)		;76a1   ; una mas girando
	inc (hl)			;76a4
	inc hl			;76a5
capsula_gira:
	ld a,(hl)			;76a6   ; la clase siguiente (0-3)
	inc a			;76a7
	and 003h		;76a8   ; 0-3
	ld (hl),a			;76aa
	add a,a			;76ab   ; su dibujo: 0x70 + clase x 4
	add a,a			;76ac
	add a,070h		;76ad   ; 0x70 + clase x 4
	ld (ix+002h),a		;76af
	jr capsula_baja		;76b2
capsula_para:
	dec (iy+000h)		;76b4   ; una menos girando
	inc (hl)			;76b7
	inc hl			;76b8
	ld a,(0e0b5h)		;76b9   ; sin blancos rotos, la clase 0
	and a			;76bc
	jr nz,capsula_para_dibujo		;76bd
	ld (hl),a			;76bf
capsula_para_dibujo:
	bit 0,(hl)		;76c0   ; par: 0x70; impar: 0x78
	ld a,070h		;76c2
	jr z,capsula_para_pon		;76c4
	ld a,078h		;76c6
capsula_para_pon:
	ld (ix+002h),a		;76c8
	jr capsula_baja		;76cb
capsulas_fin:		; Abajo del todo: las capsulas fuera y acabadas
	ld hl,0e267h		;76cd   ; fuera
	ld de,0e00fh		;76d0   ; Y 0xE0, X 0x0F
	ld b,003h		;76d3
	call sprites_yx		;76d5
	xor a			;76d8   ; la tarea parada
	ld (0ec3eh),a		;76d9   ; la tarea parada
	ld (0eb75h),a		;76dc
	inc a			;76df
	ld (0ec32h),a		;76e0   ; la tarea de la oleada
sonido_vida_tarea:
	ld (0ec40h),a		;76e3
	ret			;76e6
capsulas_sonido:		; El sonido mientras alguna gira: el canal C a 0xD6, con volumen 0 o 10 cada 2 cuadros
	ld a,(0eb77h)		;76e7   ; alguna girando?
	and a			;76ea   ; girando?
	ld e,000h		;76eb
	jr z,capsulas_sonido_nada		;76ed
	xor a			;76ef   ; los efectos parados
	ld (0ec41h),a		;76f0
	ld (0ec40h),a		;76f3
	ld hl,0eb78h		;76f6   ; uno y otro
	inc (hl)			;76f9   ; la cuenta
	bit 1,(hl)		;76fa
	jr z,capsulas_sonido_pon		;76fc
	ld e,00ah		;76fe   ; volumen 10
capsulas_sonido_pon:
	call canal_c_volumen		;7700   ; el volumen
	ld a,004h		;7703   ; el tono 0xD6
	ld e,0d6h		;7705
	call 00093h		;7707
	ld a,005h		;770a
	ld e,000h		;770c
	call 00093h		;770e
	jp canal_b_calla		;7711   ; el canal B callado
capsulas_sonido_nada:
	ld a,(0ec40h)		;7714
	and a			;7717
	jr z,capsulas_sonido_pon		;7718
	ret			;771a
capsulas_premio:		; Las tres paradas: C = 3 (las tres pares) da una vida y disparos mas rapidos (0xE0CD = 8); C = -3 (las tres impares) para los disparos de los enemigos (la tarea 8); mezcladas, nada
	ld a,00fh		;771b   ; el efecto del canal C parado
	ld (0e3dbh),a		;771d
	ld hl,0eb76h		;7720   ; ya dado?
	ld a,(hl)			;7723
	and a			;7724
	ret nz			;7725
	inc (hl)			;7726
	ld a,c			;7727   ; las tres impares?
	cp 0fdh		;7728
	jr z,capsulas_sin_disparos		;772a
	cp 003h		;772c   ; las tres pares?
	ld a,001h		;772e
	jr nz,sonido_vida_tarea		;7730
	ld hl,0e0a9h		;7732   ; una vida mas
	inc (hl)			;7735
	call vidas_pinta		;7736   ; en el marcador
	ld a,008h		;7739   ; los disparos de la nave, 8 puntos por cuadro
	ld (0e0cdh),a		;773b
	jp vida_sonido		;773e   ; y el sonido de la vida
capsulas_sin_disparos:
	xor a			;7741   ; los enemigos dejan de disparar
	ld (0ec35h),a		;7742
	jp vida_sonido		;7745
sprites_y_espejo:		; B sprites de 16 x 16 de DE a la VRAM (SETWRT antes), y detras su espejo (los bits de cada byte al reves, en 0xED10)
	push bc			;7748
	ld hl,0ed10h		;7749   ; el espejo, en 0xED10
	ld b,010h		;774c   ; 16 bytes
sprite_byte:
	push bc			;774e
	ld a,(de)			;774f   ; un byte...
	out (098h),a		;7750   ; ...a la VRAM
	ld b,008h		;7752   ; sus 8 bits...
sprite_espejo_bit:
	rrca			;7754   ; ...al reves...
	rl (hl)		;7755   ; ...en (HL)
	djnz sprite_espejo_bit		;7757
	pop bc			;7759
	inc hl			;775a
	inc de			;775b
	djnz sprite_byte		;775c
	ld hl,0ed10h		;775e   ; y el espejo detras
	ld b,010h		;7761
	call vram_b		;7763   ; a la VRAM
	pop bc			;7766
	djnz sprites_y_espejo		;7767
	ret			;7769
sprites_32_espejo:		; B sprites de 32 bytes (las dos mitades cambiadas en el espejo: 0xED20 la izquierda, 0xED10 la derecha)
	push bc			;776a
	ld hl,0ed20h		;776b   ; la mitad de la izquierda del espejo
	ld b,010h		;776e
sprite32_izq:
	push bc			;7770
	call sprite_un_byte		;7771
	pop bc			;7774
	djnz sprite32_izq		;7775
	ld hl,0ed10h		;7777   ; la otra mitad
	ld b,010h		;777a
sprite32_der:
	push bc			;777c
	call sprite_un_byte		;777d   ; un byte y su espejo
	pop bc			;7780
	djnz sprite32_der		;7781
	ld hl,0ed10h		;7783   ; los 32 bytes del espejo...
	ld b,020h		;7786   ; los 32 del espejo
	call vram_b		;7788   ; ...a la VRAM
	pop bc			;778b
	djnz sprites_32_espejo		;778c
	ret			;778e
sprite_un_byte:		; Un byte de DE a la VRAM y al reves en (HL)
	ld a,(de)			;778f   ; un byte...
	out (098h),a		;7790   ; ...a la VRAM
	ld b,008h		;7792   ; sus 8 bits...
sprite_un_byte_bit:
	rrca			;7794
	rl (hl)		;7795   ; ...al reves
	djnz sprite_un_byte_bit		;7797
	inc hl			;7799
	inc de			;779a
	ret			;779b
sprites_volteados:		; Como 0x776A, y ademas las dos copias de arriba abajo (0x7939 lee hacia atras)
	push bc			;779c
	push de			;779d
	ld hl,0ed20h		;779e
	ld b,010h		;77a1
volteado_izq:
	push bc			;77a3
	call sprite_un_byte		;77a4   ; un byte y su espejo
	pop bc			;77a7
	djnz volteado_izq		;77a8
	ld hl,0ed10h		;77aa
	ld b,010h		;77ad
volteado_der:
	push bc			;77af
	call sprite_un_byte		;77b0   ; un byte y su espejo
	pop bc			;77b3
	djnz volteado_der		;77b4
	ld hl,0ed1fh		;77b6   ; la izquierda, de abajo arriba
	ld b,010h		;77b9
	call vram_b_atras		;77bb   ; a la VRAM
	ld hl,0ed2fh		;77be   ; la derecha, de abajo arriba
	ld b,010h		;77c1
	call vram_b_atras		;77c3
	ld hl,0ed10h		;77c6   ; el espejo
	ld b,020h		;77c9
	call vram_b		;77cb   ; los dos espejos
	pop de			;77ce
	ex de,hl			;77cf   ; el original...
	push hl			;77d0
	ld bc,0000fh		;77d1   ; ...de abajo arriba
	add hl,bc			;77d4
	ld b,010h		;77d5
	call vram_b_atras		;77d7   ; el original de abajo arriba
	pop hl			;77da
	ld bc,0001fh		;77db
	add hl,bc			;77de
	ld b,010h		;77df
	call vram_b_atras		;77e1   ; y su otra mitad
	pop bc			;77e4
	djnz sprites_32_espejo		;77e5
	ret			;77e7
mandos:		; La palanca (GTSTCK) en E y el boton (GTTRIG, solo el bit 0) en D, del mando de 0xE098 (0 el teclado, 1 el mando 1)
	ld a,(0e098h)		;77e8   ; el teclado o el mando
	call 000d5h		;77eb   ; GTSTCK
	ld e,a			;77ee
	ld a,(0e098h)		;77ef
	push de			;77f2
	call 000d8h		;77f3   ; GTTRIG
	pop de			;77f6
	and 001h		;77f7   ; pulsado: 1
	ld d,a			;77f9
	ret			;77fa
tareas_paradas:		; Las 23 cuentas de las tareas (0xEC2D) a cero
	ld hl,0ec2dh		;77fb   ; las 23 cuentas
	ld de,0ec2eh		;77fe   ; a cero
	ld bc,00016h		;7801
	ld (hl),000h		;7804
	ldir		;7806   ; LDIR
	ret			;7808
pantalla_borra:		; La pantalla en blanco: el sonido callado, las dos tablas de nombres (0x1800 y 0x1C00) a 0 y los sprites fuera (0x1F80, Y = 0xE0)
	call sonido_calla		;7809   ; el sonido callado
	ld hl,01800h		;780c   ; la tabla de nombres 0x1800...
	ld bc,00300h		;780f
	xor a			;7812
	call 00056h		;7813   ; FILVRM
	ld hl,01c00h		;7816   ; ...y la 0x1C00
	ld bc,00300h		;7819
	xor a			;781c
	call 00056h		;781d
	ld hl,01f80h		;7820   ; los 32 sprites...
	ld bc,00080h		;7823
	ld a,0e0h		;7826   ; ...con la Y 0xE0
	jp 00056h		;7828
llena:		; BC bytes de A desde HL
	ld d,a			;782b   ; el byte
llena_byte:
	ld (hl),d			;782c   ; un byte
	inc hl			;782d
	dec bc			;782e   ; uno menos
	ld a,b			;782f   ; los 16 bits...
	or c			;7830
	jr nz,llena_byte		;7831   ; ...hasta 0
	ret			;7833
pantalla_pon:		; La pantalla del juego: los registros del VDP (0x7907), la VRAM a cero, la RAM 0xE091-0xE890 a cero, los dibujos de los sprites (con sus espejos) y algunos de las casillas, el estado vacio, la interrupcion del VDP y 40 bloques desempaquetados a 0xE0D1
	call vdp_registros		;7834   ; los registros del VDP
	call 00041h		;7837   ; DISSCR
	ld hl,00000h		;783a   ; toda la VRAM...
	ld bc,04000h		;783d
	xor a			;7840
	call 00056h		;7841   ; ...a cero
	ld hl,0e091h		;7844   ; la RAM...
	ld de,0e092h		;7847
	ld bc,007ffh		;784a
	ld (hl),000h		;784d   ; ...a cero
	ldir		;784f
	ld hl,01f80h		;7851   ; los sprites fuera
	ld bc,00080h		;7854
	ld a,0e0h		;7857
	call 00056h		;7859
	ld hl,03800h		;785c   ; los dibujos de los sprites desde 0x3800
	call 00053h		;785f
	ld de,0794dh		;7862   ; ocho, de 0x794D, con su espejo
	ld b,008h		;7865
	call sprites_y_espejo		;7867
	ld hl,07a8dh		;786a   ; 0xA0 bytes de 0x7A8D...
	ld de,03ea0h		;786d   ; ...a 0x3EA0
	ld bc,000a0h		;7870
	call 0005ch		;7873
	ld hl,03b60h		;7876   ; y desde 0x3B60...
	call 00053h		;7879
	ld hl,07b2dh		;787c   ; ...0x40 bytes de 0x7B2D...
	ld b,040h		;787f
	call vram_b		;7881
	ld hl,07b55h		;7884   ; ...y trozos de 8 bytes
	call vram8		;7887
	ld hl,07b6dh		;788a
	call vram8		;788d
	ld hl,07b65h		;7890
	call vram8		;7893
	ld hl,07b7dh		;7896
	call vram8		;7899
	ld hl,07b6dh		;789c
	ld b,020h		;789f
	call vram_b		;78a1
	ld hl,07b75h		;78a4
	call vram8		;78a7
	ld hl,07b4dh		;78aa
	call vram8		;78ad
	ld hl,07b85h		;78b0
	call vram8		;78b3
	ld hl,07b5dh		;78b6
	call vram8		;78b9
	call redoble_pon		;78bc   ; la pieza de la RAM (0x7FAE)
	call estado_nada		;78bf   ; el estado vacio
	ld a,0e2h		;78c2   ; el registro 1 con la interrupcion del VDP (0xE2)
	ld (0e099h),a		;78c4
	call sonido_calla		;78c7   ; el sonido callado
	ld hl,04709h		;78ca   ; 40 bloques de 0x4709...
	ld de,0e0d1h		;78cd   ; ...desempaquetados a 0xE0D1
	ld b,028h		;78d0
	call desempaqueta		;78d2
	jp 00044h		;78d5   ; ENASCR
sprites_3c00:		; Mas dibujos de sprites desde 0x3C00: seis con espejo (0x79CD), dos de 32 bytes (0x7A2D) y uno volteado (0x7A6D)
	ld hl,03c00h		;78d8
	call 00053h		;78db   ; SETWRT
	ld de,079cdh		;78de   ; seis con espejo de 0x79CD
	ld b,006h		;78e1
	call sprites_y_espejo		;78e3
	ld de,07a2dh		;78e6   ; dos de 32 bytes de 0x7A2D
	ld b,002h		;78e9
	call sprites_32_espejo		;78eb
	ld de,07a6dh		;78ee   ; uno volteado de 0x7A6D
	ld b,001h		;78f1
	jp sprites_volteados		;78f3
vdp_registros:		; Los 8 registros del VDP de la tabla 0x7907
	ld hl,07907h		;78f6   ; la tabla
	ld bc,00800h		;78f9   ; 8 registros, desde el 0
vdp_registro:
	push bc			;78fc
	ld b,(hl)			;78fd   ; el valor
	call 00047h		;78fe   ; WRTVDP
	pop bc			;7901
	inc c			;7902
	inc hl			;7903
	djnz vdp_registro		;7904
	ret			;7906

; ----------------------------------------------------------------------
; DATOS vdp_tabla: SCREEN 2: R0 = 2, R1 = 0xE2 (16 KB, pantalla e
;   interrupcion, sprites de 16 x 16), nombres 0x1800, colores 0x2000, dibujos
;   0x0000, atributos de los sprites 0x1F80, sus dibujos 0x3800, el fondo
;   negro
;   0x7907..0x790f  (8 bytes)
DATA_vdp_tabla:
	defb 002h,0e2h,006h,0ffh,003h,03fh,007h,001h	; 7907  .....?..

; ======================================================================
; CODIGO 0x790f..0x794d  (62 bytes)
; ======================================================================


letras_vram:		; B letras de DE en la VRAM desde HL: cada una, los 8 bytes de la fuente de la BIOS (CGTABL, 0x0004)
	call 00053h		;790f   ; SETWRT
letra:
	push bc			;7912
	ld a,(de)			;7913   ; la letra
	inc de			;7914   ; la siguiente
	ld hl,(00004h)		;7915   ; la fuente de la BIOS
	ld b,000h		;7918   ; A x 8 en BC
	add a,a			;791a   ; x 8
	rl b		;791b
	add a,a			;791d
	rl b		;791e
	add a,a			;7920
	rl b		;7921
	ld c,a			;7923
	add hl,bc			;7924   ; su dibujo
	call vram8		;7925   ; a la VRAM
	pop bc			;7928
	djnz letra		;7929
	ret			;792b
vram8:		; 8 bytes de HL a la VRAM
	ld b,008h		;792c
vram_b:		; B bytes de HL a la VRAM (con una espera entre uno y otro)
	inc ix		;792e   ; espera: el VDP necesita tiempo
	dec ix		;7930
	ld a,(hl)			;7932   ; un byte...
	out (098h),a		;7933   ; ...al puerto de datos
	inc hl			;7935
	djnz vram_b		;7936
	ret			;7938
vram_b_atras:		; B bytes a la VRAM leyendo HL hacia atras
	inc ix		;7939
	dec ix		;793b
	ld a,(hl)			;793d   ; un byte
	out (098h),a		;793e
	dec hl			;7940
	djnz vram_b_atras		;7941
	ret			;7943
vram_relleno:		; B veces A en la VRAM
	inc ix		;7944   ; espera
	dec ix		;7946
	out (098h),a		;7948   ; A al puerto de datos
	djnz vram_relleno		;794a
	ret			;794c

; ----------------------------------------------------------------------
; DATOS sprites_casillas: Dibujos de sprites (los de 0x7834 y 0x78D8) y de
;   casillas, en bytes
;   0x794d..0x7b8d  (576 bytes)
DATA_sprites_casillas:
	defb 001h,003h,042h,0e3h,0c7h,0dfh,0bfh,07fh,0ech,0c3h,083h,007h,006h,006h,00eh,01eh	; 794d  ..B.............
	defb 000h,000h,001h,000h,000h,000h,040h,080h,003h,000h,000h,000h,000h,000h,000h,000h	; 795d  ......@.........
	defb 000h,000h,000h,000h,060h,060h,060h,060h,060h,060h,060h,060h,000h,000h,000h,000h	; 796d  ....````````....
	defb 000h,00ch,01ch,03eh,07fh,07dh,0fdh,0fdh,0fdh,0edh,06dh,076h,03fh,01fh,00fh,003h	; 797d  ...>.}....mv?...
	defb 000h,060h,0f0h,0f0h,0d1h,0d3h,0bbh,0bbh,0bdh,0f6h,0f3h,063h,002h,003h,003h,001h	; 798d  .`.........c....
	defb 008h,018h,038h,078h,0f8h,0dfh,0e7h,0f8h,0feh,0ffh,03fh,017h,019h,00eh,007h,001h	; 799d  ..8x......?.....
	defb 001h,007h,00fh,00bh,01bh,01bh,0fdh,0feh,0ffh,0cfh,0b6h,0b5h,0b7h,07bh,07bh,031h	; 79ad  .............{{1
	defb 003h,006h,00dh,01bh,01ah,07fh,0b5h,0b5h,0b5h,0b5h,0b5h,07fh,00dh,006h,003h,001h	; 79bd  ................
	defb 060h,0f0h,0f0h,060h,0e3h,0e0h,0e7h,0feh,0f8h,07bh,019h,008h,00dh,007h,007h,003h	; 79cd  `..`.....{......
	defb 008h,008h,00ch,00fh,00ch,01ch,01ch,01ch,00ch,01ch,01ch,01ch,01ch,01ch,01eh,01eh	; 79dd  ................
	defb 003h,004h,004h,000h,001h,007h,004h,006h,007h,002h,000h,000h,000h,007h,007h,003h	; 79ed  ................
	defb 005h,007h,004h,00eh,00fh,01dh,01ch,018h,03ch,07ch,0fch,0ech,0c0h,0f0h,0f8h,070h	; 79fd  ........<|.....p
	defb 07ch,07ch,038h,038h,038h,038h,038h,038h,018h,038h,038h,038h,03fh,03fh,03fh,01fh	; 7a0d  ||888888.888???.
	defb 002h,000h,003h,001h,000h,002h,083h,0c7h,0e3h,0e1h,001h,003h,003h,000h,000h,0e0h	; 7a1d  ................
	defb 060h,0f0h,0f0h,060h,0e3h,0e0h,0e7h,0feh,0f8h,07bh,019h,008h,00dh,007h,007h,003h	; 7a2d  `..`.....{......
	defb 009h,00fh,00fh,00fh,0cfh,00fh,0ffh,07eh,01eh,0dch,098h,010h,0b0h,0e0h,0e0h,0c0h	; 7a3d  .......~........
	defb 005h,007h,004h,00eh,00fh,01dh,01ch,018h,0ach,0dch,0fch,0fch,0f0h,0f0h,0f0h,0a0h	; 7a4d  ................
	defb 0a0h,0e0h,020h,070h,0f0h,0b8h,038h,018h,03ch,03eh,03fh,037h,003h,00fh,01fh,00eh	; 7a5d  .. p..8.<>?7....
	defb 000h,000h,003h,007h,00fh,00fh,00fh,00fh,007h,003h,000h,000h,000h,000h,000h,000h	; 7a6d  ................
	defb 000h,000h,0c0h,0e0h,0f0h,0f0h,0f8h,0fch,0f4h,0eeh,05eh,07eh,03fh,01fh,01fh,01fh	; 7a7d  ..........^~?...
	defb 000h,000h,000h,000h,001h,005h,003h,00fh,003h,005h,001h,000h,000h,000h,000h,000h	; 7a8d  ................
	defb 000h,000h,000h,000h,000h,040h,080h,0e0h,080h,040h,000h,000h,000h,000h,000h,000h	; 7a9d  .....@...@......
	defb 000h,000h,000h,000h,004h,002h,005h,00bh,001h,004h,00ah,004h,000h,000h,000h,000h	; 7aad  ................
	defb 000h,000h,000h,000h,0a0h,080h,0d0h,0e0h,090h,0c0h,090h,0a0h,000h,000h,000h,000h	; 7abd  ................
	defb 000h,008h,005h,010h,049h,015h,003h,06fh,007h,045h,011h,005h,028h,001h,000h,000h	; 7acd  ....I..o.E..(...
	defb 080h,008h,050h,000h,028h,044h,090h,040h,0f4h,040h,0aah,050h,028h,040h,000h,000h	; 7add  ..P.(D.@.@.P(@..
	defb 016h,0afh,049h,000h,095h,022h,049h,05fh,0b7h,023h,015h,05ah,084h,0c9h,064h,021h	; 7aed  ..I.."I_.#.Z..d!
	defb 044h,00bh,090h,0bah,06fh,0f5h,0a0h,0f4h,0feh,0c3h,0abh,096h,0b1h,062h,096h,04ch	; 7afd  D...o........b.L
	defb 000h,00ch,051h,012h,005h,002h,014h,024h,026h,013h,008h,02dh,007h,012h,000h,000h	; 7b0d  ..Q....$&..-....
	defb 060h,090h,024h,012h,08ah,058h,0c0h,010h,0c8h,094h,024h,088h,010h,000h,000h,000h	; 7b1d  `.$..X....$.....
	defb 0ffh,0ffh,0ffh,0feh,0feh,0fch,0fch,0c0h,0f0h,0f8h,0f8h,0f0h,0f1h,0e7h,0ffh,0ffh	; 7b2d  ................
	defb 0ffh,0ffh,0ffh,07fh,07fh,03fh,03fh,003h,00fh,01fh,01fh,00fh,08fh,0e7h,0ffh,0ffh	; 7b3d  .....??.........
	defb 0ffh,0ffh,0f3h,0e0h,0c0h,0c7h,0ffh,0ffh,0feh,0fch,0fch,0f8h,0f8h,0fch,0ffh,0ffh	; 7b4d  ................
	defb 0ffh,0ffh,0ffh,003h,007h,0c7h,08fh,01fh,07fh,07fh,07fh,07fh,07fh,0ffh,0ffh,0ffh	; 7b5d  ................
	defb 0ffh,0ffh,0ffh,0fch,0feh,0e1h,0e4h,0c8h,0c0h,0e0h,0e0h,0f8h,0fch,0ffh,0ffh,0ffh	; 7b6d  ................
	defb 0ffh,0ffh,0ffh,03fh,01fh,0e7h,037h,013h,003h,007h,007h,01fh,03fh,0ffh,0ffh,0ffh	; 7b7d  ...?..7.....?...

; ======================================================================
; CODIGO 0x7b8d..0x7b9f  (18 bytes)
; ======================================================================


sonido_calla:		; El PSG callado: los registros 13 a 0 a cero y el 7 (la mezcla) a 0xB8
	ld b,00eh		;7b8d   ; 14 registros
	ld e,000h		;7b8f   ; a 0
sonido_calla_reg:
	ld a,b			;7b91   ; el registro B - 1
	dec a			;7b92
	call 00093h		;7b93   ; WRTPSG
	djnz sonido_calla_reg		;7b96
	ld a,007h		;7b98   ; la mezcla: tono en A, B y C, sin ruido
	ld e,0b8h		;7b9a
	jp 00093h		;7b9c

; ----------------------------------------------------------------------
; DATOS codigo_7b9f: "call 0x7BA7 / call 0x7BAB / jr...": tres instrucciones a
;   las que no salta nadie
;   0x7b9f..0x7ba7  (8 bytes)
DATA_codigo_7b9f:
	defb 0cdh,0a7h,07bh,0cdh,0abh,07bh,018h,008h	; 7b9f  ..{..{..

; ======================================================================
; CODIGO 0x7ba7..0x7ca6  (255 bytes)
; ======================================================================


canal_a_calla:		; El volumen del canal A (registro 8) a 0
	ld a,008h		;7ba7
	jr psg_cero		;7ba9
canal_b_calla:		; El del canal B (9)
	ld a,009h		;7bab
	jr psg_cero		;7bad
canal_c_calla:		; El del canal C (10)
	ld a,00ah		;7baf
psg_cero:
	ld e,000h		;7bb1   ; el valor 0
	jr psg		;7bb3
efecto_a:		; Un efecto en el canal A (0xE3D5 = A con el bit 7): 0 y 1 con ruido (periodo de 0x7CA6/0x7CA8), 2 un tono que baja (0x7CAA), 3 ruido (0x7CAE)
	set 7,a		;7bb5   ; empezado
	ld (0e3d5h),a		;7bb7
	ld hl,07ca6h		;7bba   ; el 0
	and 00fh		;7bbd
	jr z,efecto_a_ruido		;7bbf
	ld hl,07ca8h		;7bc1   ; el 1
	cp 001h		;7bc4
	jr z,efecto_a_ruido		;7bc6
	ld hl,07caah		;7bc8   ; el 2: tono
	cp 002h		;7bcb
	jp z,efecto_a_tono		;7bcd
	ld hl,07caeh		;7bd0   ; el 3
	cp 003h		;7bd3   ; otro: nada
	ret nz			;7bd5
efecto_a_ruido:		; Con ruido: el tono del canal A callado, la mezcla con ruido en A (0xB0) y su periodo (registro 6)
	call canal_a_tono0		;7bd6   ; el tono a 0
	ld a,007h		;7bd9   ; la mezcla...
	ld e,0b0h		;7bdb   ; ...ruido en el canal A
	call 00093h		;7bdd
	ld a,(hl)			;7be0   ; el periodo del ruido...
	ld (0e3dah),a		;7be1
	ld e,a			;7be4
	ld a,006h		;7be5   ; ...registro 6
	call 00093h		;7be7
efecto_a_volumen:		; El volumen 15 (0xE3D6) y la cuenta del paso siguiente (0xE3D7)
	ld a,00fh		;7bea   ; volumen 15
	ld (0e3d6h),a		;7bec
	call canal_a_volumen		;7bef   ; al registro 8
efecto_a_cuenta:
	inc hl			;7bf2
	ld a,(hl)			;7bf3   ; cada cuantos cuadros
	ld (0e3d7h),a		;7bf4
	ret			;7bf7
canal_a_tono0:		; El tono del canal A (registros 0 y 1) a 0
	xor a			;7bf8   ; el registro 0
	ld e,a			;7bf9
	call 00093h		;7bfa
	ld a,001h		;7bfd   ; el 1
	ld e,000h		;7bff
	jr psg		;7c01
canal_a_volumen:		; El volumen del canal A (registro 8) = A
	ld e,a			;7c03
	ld a,008h		;7c04
psg:		; WRTPSG
	jp 00093h		;7c06
efecto_a_tono:		; El 2: un tono (dos bytes, 0xE3D9 y 0xE3DA), sin ruido, volumen 15 y cuanto baja (0xE3D8)
	ld a,(hl)			;7c09   ; el tono, bajo...
	ld (0e3d9h),a		;7c0a
	ld e,a			;7c0d
	xor a			;7c0e
	call 00093h		;7c0f   ; WRTPSG
	inc hl			;7c12
	ld a,(hl)			;7c13   ; ...y alto
	ld (0e3dah),a		;7c14
	ld e,a			;7c17
	ld a,001h		;7c18
	call 00093h		;7c1a   ; WRTPSG
	ld a,007h		;7c1d   ; la mezcla sin ruido
	ld e,0b8h		;7c1f
	call 00093h		;7c21   ; WRTPSG
	call efecto_a_volumen		;7c24   ; volumen 15
	ld (0e3d8h),a		;7c27   ; cuanto baja el tono cada paso
	jr efecto_a_cuenta		;7c2a
tarea_efecto_a:		; La tarea 18 (0x40B7): un paso del efecto del canal A: el volumen baja uno; en el 2, ademas, el tono; a 0, callado (0xE3D5 = 0x0F)
	ld a,001h		;7c2c   ; la cuenta de la tarea, a 1
	ld (0ec3fh),a		;7c2e
	ld a,(0e3d5h)		;7c31   ; ninguno?
	cp 00fh		;7c34
	ret z			;7c36
	call c,efecto_a		;7c37   ; uno nuevo: empieza
	ld a,(0e3d5h)		;7c3a
	and 00fh		;7c3d
	cp 002h		;7c3f   ; el 2?
	jr z,efecto_a_tono_baja		;7c41
	cp 004h		;7c43   ; 4 o mas: nada
	ret nc			;7c45
efecto_a_paso:
	ld a,(0e3d6h)		;7c46   ; el volumen
	and a			;7c49
	jr nz,efecto_a_baja		;7c4a   ; queda
efecto_a_fin:		; Acabado: 0xE3D5 = 0x0F y la mezcla sin ruido
	ld a,00fh		;7c4c   ; ninguno
	ld (0e3d5h),a		;7c4e
	ld a,007h		;7c51   ; la mezcla de siempre
	ld e,0b8h		;7c53
	jp 00093h		;7c55
efecto_a_baja:
	dec a			;7c58   ; un punto menos
	ld (0e3d6h),a		;7c59
	call canal_a_volumen		;7c5c   ; al PSG
	ld a,(0e3d7h)		;7c5f   ; y la cuenta del paso siguiente
	ld (0ec3fh),a		;7c62
	ret			;7c65
efecto_a_tono_baja:		; El 2: el tono, 0xE3D8 menos
	ld a,(0e3d8h)		;7c66
	ld b,a			;7c69
	ld a,(0e3d9h)		;7c6a
	sub b			;7c6d
	ld (0e3d9h),a		;7c6e   ; el tono nuevo...
	call canal_a_tono		;7c71   ; ...al PSG
	jr efecto_a_paso		;7c74
efecto_a_corta:		; Corta el efecto del canal A si su volumen ya baja de 8
	ld a,(0e3d5h)		;7c76   ; alguno?
	cp 00fh		;7c79
	ret z			;7c7b
	ld b,a			;7c7c
	ld a,(0e3d6h)		;7c7d
	cp 008h		;7c80   ; volumen 8 o mas?
	jr nc,efecto_a_corta_tono		;7c82
	xor a			;7c84   ; a 0 y acabado
	ld (0e3d6h),a		;7c85
	jr efecto_a_fin		;7c88
efecto_a_corta_tono:
	call canal_a_volumen		;7c8a   ; al PSG
	ld a,b			;7c8d
	and 00fh		;7c8e   ; el de tono?
	cp 002h		;7c90
	jp nz,canal_a_tono0		;7c92
	ld a,(0e3d9h)		;7c95
canal_a_tono:		; El tono del canal A: E el bajo (registro 0) y 0xE3DA el alto (1)
	ld e,a			;7c98
	xor a			;7c99
	call 00093h		;7c9a   ; WRTPSG
	ld a,(0e3dah)		;7c9d
	ld e,a			;7ca0
	ld a,001h		;7ca1
	jp 00093h		;7ca3   ; WRTPSG

; ----------------------------------------------------------------------
; DATOS efecto_a_datos: Los efectos del canal A: el periodo del ruido y la
;   cuenta (0 y 1), el tono, la cuenta y lo que baja (2), el ruido (3)
;   0x7ca6..0x7cb0  (10 bytes)
DATA_efecto_a_datos:
	defb 01fh,00ch,018h,003h,060h,000h,000h,002h,018h,001h	; 7ca6  ....`.....

; ======================================================================
; CODIGO 0x7cb0..0x7d3d  (141 bytes)
; ======================================================================


efecto_c:		; Un efecto en el canal C (0xE3DB, con el bit 7 al empezar): tres, con tono, de la tabla 0x7D3D (4 bytes: el tono, cuanto baja, la cuenta)
	ld hl,0e3dbh		;7cb0   ; el pedido...
	ld a,(hl)			;7cb3
	set 7,(hl)		;7cb4   ; ...empezado
	ld hl,07d3dh		;7cb6   ; el 0
	and a			;7cb9
	jr z,efecto_c_pon		;7cba
	ld hl,07d41h		;7cbc   ; el 1
	dec a			;7cbf
	jr z,efecto_c_pon		;7cc0
	ld hl,07d45h		;7cc2   ; el 2
	dec a			;7cc5
	ret nz			;7cc6
efecto_c_pon:
	ld a,(hl)			;7cc7   ; el tono, bajo...
	ld (0e3dfh),a		;7cc8
	ld e,a			;7ccb
	ld a,004h		;7ccc   ; ...registro 4
	call 00093h		;7cce
	inc hl			;7cd1
	ld a,(hl)			;7cd2   ; ...y alto
	ld (0e3e0h),a		;7cd3
	ld e,a			;7cd6
	ld a,005h		;7cd7   ; registro 5
	call 00093h		;7cd9
	ld a,00fh		;7cdc   ; volumen 15
	ld (0e3dch),a		;7cde
	ld e,a			;7ce1
	call canal_c_volumen		;7ce2   ; al registro 10
	inc hl			;7ce5
	ld a,(hl)			;7ce6   ; cuanto baja
	ld (0e3deh),a		;7ce7
	inc hl			;7cea
	ld a,(hl)			;7ceb   ; la cuenta del paso
	ld (0e3ddh),a		;7cec
	ret			;7cef
tarea_efecto_c:		; La tarea 20: un paso del efecto del canal C: el tono baja (0xE3DE) y el volumen uno; a 0, callado
	ld a,001h		;7cf0   ; la cuenta de la tarea, a 1
	ld (0ec41h),a		;7cf2
	ld a,(0e3dbh)		;7cf5   ; uno nuevo (sin el bit 7)?
	cp 00fh		;7cf8
	jr nc,efecto_c_paso		;7cfa
	ld a,(0ec3eh)		;7cfc   ; 0xEC3E?
	and a			;7cff
	ret nz			;7d00
	call efecto_c		;7d01   ; empieza
efecto_c_paso:
	ld a,(0e3dbh)		;7d04   ; el efecto
	and 00fh		;7d07   ; 0-2?
	cp 003h		;7d09   ; 0-2?
	ret nc			;7d0b
	ld a,(0e3deh)		;7d0c   ; el tono...
	ld b,a			;7d0f
	ld hl,0e3dfh		;7d10   ; el tono
	ld a,(hl)			;7d13
	sub b			;7d14   ; ...menos lo que baja
	ld (hl),a			;7d15   ; guardado
	ld e,a			;7d16
	ld a,004h		;7d17   ; registro 4
	call 00093h		;7d19   ; WRTPSG
	inc hl			;7d1c
	ld e,(hl)			;7d1d   ; el alto
	ld a,005h		;7d1e   ; registro 5
	call 00093h		;7d20   ; WRTPSG
	ld hl,0e3dch		;7d23   ; el volumen
	ld a,(hl)			;7d26   ; el volumen
	and a			;7d27
	jr nz,efecto_c_baja		;7d28
	ld a,00fh		;7d2a   ; a 0: acabado
	ld (0e3dbh),a		;7d2c   ; acabado: 0x0F
	ret			;7d2f
efecto_c_baja:
	dec (hl)			;7d30   ; uno menos
	ld e,(hl)			;7d31
	ld a,(0e3ddh)		;7d32   ; la cuenta del paso siguiente
	ld (0ec41h),a		;7d35
canal_c_volumen:		; El volumen del canal C (registro 10) = E
	ld a,00ah		;7d38
	jp 00093h		;7d3a

; ----------------------------------------------------------------------
; DATOS efecto_c_datos: Los tres efectos del canal C: el tono (dos bytes),
;   cuanto baja y la cuenta de cada paso
;   0x7d3d..0x7d49  (12 bytes)
DATA_efecto_c_datos:
	defb 030h,000h,0f0h,001h,010h,000h,0f0h,001h,000h,002h,020h,001h	; 7d3d  0......... .

; ======================================================================
; CODIGO 0x7d49..0x7e51  (264 bytes)
; ======================================================================


musica:		; La musica, en un canal (0xE404 su registro de volumen, 0xE405 el del tono): 0xE3E4 la pedida, 0xE3E5 la que suena; su lista de piezas desde (0xE407)
	ld a,(0e3e4h)		;7d49   ; una pedida?
	or a			;7d4c
	jp z,musica_calla		;7d4d
	ld b,a			;7d50   ; la que suena?
	ld a,(0e3e5h)		;7d51
	cp b			;7d54
	jp z,musica_cuadro		;7d55   ; sigue
	ld a,b			;7d58
	ld (0e3e5h),a		;7d59   ; una nueva
	push bc			;7d5c
	ld hl,0e3e1h		;7d5d   ; el volumen: 12...
	ld (hl),00ch		;7d60
	cp 002h		;7d62
	jr nz,musica_tempo		;7d64
	ld (hl),00ah		;7d66   ; ...10 en la 2
musica_tempo:
	inc hl			;7d68
	cp 001h		;7d69   ; el tempo: 10 en la 1...
	ld b,00ah		;7d6b
	jr z,musica_tempo_pon		;7d6d
	cp 003h		;7d6f   ; ...20 en la 3...
	ld b,014h		;7d71
	jr z,musica_tempo_pon		;7d73
	ld b,003h		;7d75   ; ...3 en las otras
musica_tempo_pon:
	ld (hl),b			;7d77
	inc hl			;7d78
	ld (hl),003h		;7d79
	pop bc			;7d7b
musica_busca:		; La pieza B de la lista: se salta hasta su principio (las piezas acaban en 0x0000)
	ld hl,(0e407h)		;7d7c
musica_busca_sig:
	dec b			;7d7f
	jp z,musica_pieza		;7d80
musica_busca_dir:
	ld e,(hl)			;7d83
	inc hl			;7d84   ; la palabra
	ld d,(hl)			;7d85
	inc hl			;7d86
	ld a,d			;7d87
	or e			;7d88   ; 0x0000: el final de una
	jr z,musica_busca_sig		;7d89   ; 0x0000: una pieza menos
	ld a,d			;7d8b
	and e			;7d8c
	inc a			;7d8d   ; 0xFFFF?
	jr z,musica_busca_sig		;7d8e
	jr musica_busca_dir		;7d90   ; sigue
musica_pieza:
	ld e,(hl)			;7d92
	inc hl			;7d93
	ld d,(hl)			;7d94
	inc hl			;7d95
musica_pieza_va:		; Una pieza: por donde va (0xE3E6), sus notas (0xE3E8), la primera nota ya y las cuentas
	ld (0e3e6h),hl		;7d96   ; la lista sigue aqui
	ex de,hl			;7d99
	ld (0e3e8h),hl		;7d9a   ; las notas
	ld a,001h		;7d9d   ; la primera, ya
	ld (0e3ebh),a		;7d9f
	ld a,(0e3e3h)		;7da2
	ld (0e3eah),a		;7da5
	ld a,(0e3e2h)		;7da8
	ld (0e3ech),a		;7dab
musica_cuadro:		; Un cuadro de la musica; acabada la pieza, la siguiente; con 0xFFFF, se acaba; con 0x0000, otra vez desde el principio
	call musica_nota		;7dae   ; la nota
	ret nz			;7db1   ; aun suena
	ld hl,(0e3e6h)		;7db2   ; la pieza siguiente
	ld e,(hl)			;7db5   ; la pieza siguiente
	inc hl			;7db6
	ld d,(hl)			;7db7
	inc hl			;7db8
	ld a,d			;7db9   ; 0xFFFF: se acaba
	and e			;7dba
	inc a			;7dbb
	jr z,musica_acaba		;7dbc
	ld a,d			;7dbe   ; 0x0000: vuelve a empezar
	or e			;7dbf
	jr nz,musica_pieza_va		;7dc0
	ld a,(0e3e5h)		;7dc2   ; la musica otra vez
	ld b,a			;7dc5
	jr musica_busca		;7dc6
musica_acaba:
	ld (0e3e4h),a		;7dc8   ; ninguna pedida
musica_calla:
	ld (0e3e5h),a		;7dcb
	ld a,(0e404h)		;7dce   ; el volumen del canal a 0
	ld e,000h		;7dd1
	jp 00093h		;7dd3
musica_nota:		; Un cuadro de la nota: el volumen baja (0x7E38), y cuando acaba la duracion, la nota siguiente: (duracion, nota); la nota 0 calla, las otras son el tono de 0x7E51
	ld a,(0e404h)		;7dd6   ; el volumen...
	call 00096h		;7dd9   ; RDPSG
	call musica_baja		;7ddc   ; ...baja?
	jp m,musica_nota_cuenta		;7ddf
	ld e,a			;7de2
	ld a,(0e404h)		;7de3   ; al PSG
	call 00093h		;7de6
musica_nota_cuenta:
	ld hl,0e3eah		;7de9   ; el tempo
	dec (hl)			;7dec
	ret nz			;7ded
	push af			;7dee
	ld a,(0e3e3h)		;7def
	ld (hl),a			;7df2
	pop af			;7df3
	ld hl,0e3ebh		;7df4   ; la duracion
	dec (hl)			;7df7
	ret nz			;7df8
	ld hl,(0e3e8h)		;7df9   ; la nota siguiente
	ld a,(hl)			;7dfc
	or a			;7dfd
	ret z			;7dfe   ; 0: el final de la pieza
	ld (0e3ebh),a		;7dff   ; la duracion
	inc hl			;7e02
	ld a,(hl)			;7e03   ; la nota
	inc hl			;7e04
	ld (0e3e8h),hl		;7e05
	or a			;7e08   ; 0: silencio
	jp z,musica_silencio		;7e09
	ld hl,07e51h		;7e0c   ; la tabla de tonos...
	dec a			;7e0f   ; ...(nota - 1) x 2
	add a,a			;7e10
	ld e,a			;7e11
	ld d,000h		;7e12
	add hl,de			;7e14
	ld e,(hl)			;7e15   ; el bajo...
	ld a,(0e405h)		;7e16
	call 00093h		;7e19   ; WRTPSG
	inc hl			;7e1c
	ld e,(hl)			;7e1d   ; ...el alto
	ld a,(0e405h)		;7e1e
	inc a			;7e21
	call 00093h		;7e22   ; WRTPSG
	ld a,(0e3e1h)		;7e25   ; el volumen
	ld e,a			;7e28
musica_volumen:
	ld a,(0e404h)		;7e29
	call 00093h		;7e2c   ; WRTPSG
	ld a,001h		;7e2f   ; NZ: suena
	or a			;7e31
	ret			;7e32
musica_silencio:
	ld e,000h		;7e33
	jp musica_volumen		;7e35
musica_baja:		; Cada tantos cuadros (0xE3E2) el volumen A baja uno
	push bc			;7e38
	push af			;7e39
	ld a,(0e3ech)		;7e3a   ; la cuenta
	ld b,000h		;7e3d
	dec a			;7e3f
	ld (0e3ech),a		;7e40
	jr nz,musica_baja_va		;7e43
	ld a,(0e3e2h)		;7e45   ; otra vez
	ld (0e3ech),a		;7e48
	ld b,001h		;7e4b   ; uno menos
musica_baja_va:
	pop af			;7e4d
	sub b			;7e4e
	pop bc			;7e4f
	ret			;7e50

; ----------------------------------------------------------------------
; DATOS tonos: Los periodos del tono de las 36 notas (0x357 la mas grave ...
;   0x71)
;   0x7e51..0x7e99  (72 bytes)
DATA_tonos:
	defw 00357h,00327h,002fah,002cfh,002a7h,00281h,0025dh,0023bh,0021bh,001fdh,001e0h,001c5h	; 7e51
	defw 001ach,00194h,0017dh,00168h,00153h,00140h,0012eh,0011dh,0010dh,000feh,000f0h,000e3h	; 7e69
	defw 000d6h,000cah,000beh,000b4h,000aah,000a0h,00097h,0008fh,00087h,0007fh,00078h,00071h	; 7e81

; ----------------------------------------------------------------------
; DATOS musicas_datos: Las listas de piezas (0x0000 al final de cada pieza,
;   0xFFFF al final) y las notas: parejas (duracion, nota)
;   0x7e99..0x7faa  (273 bytes)
DATA_musicas_datos:
	defb 056h,07fh,0ffh,0ffh,0c3h,07eh,0c3h,07eh,0cch,07eh,0cch,07eh,0d5h,07eh,0d5h,07eh	; 7e99  V....~.~.~.~.~.~
	defb 0deh,07eh,0deh,07eh,0e5h,07eh,000h,000h,004h,07fh,0ffh,0ffh,089h,07fh,000h,000h	; 7ea9  .~.~.~..........
	defb 0eah,07eh,0eah,07eh,0f7h,07eh,0f7h,07eh,000h,000h,003h,00dh,003h,014h,003h,00dh	; 7eb9  .~.~.~.~........
	defb 003h,014h,000h,003h,00fh,003h,016h,003h,00fh,003h,016h,000h,003h,011h,003h,018h	; 7ec9  ................
	defb 003h,011h,003h,018h,000h,003h,012h,003h,019h,003h,016h,000h,003h,012h,003h,00fh	; 7ed9  ................
	defb 000h,004h,00dh,004h,011h,004h,014h,004h,018h,004h,014h,004h,011h,000h,004h,00fh	; 7ee9  ................
	defb 004h,012h,004h,016h,004h,019h,004h,016h,004h,012h,000h,003h,00fh,001h,000h,001h	; 7ef9  ................
	defb 00fh,001h,000h,001h,00fh,001h,000h,008h,00fh,004h,010h,004h,00fh,004h,010h,003h	; 7f09  ................
	defb 012h,001h,000h,001h,012h,001h,000h,001h,012h,001h,000h,004h,014h,004h,012h,004h	; 7f19  ................
	defb 014h,010h,016h,000h,003h,014h,001h,000h,001h,014h,001h,000h,001h,014h,001h,000h	; 7f29  ................
	defb 008h,014h,004h,015h,004h,014h,004h,015h,003h,017h,001h,000h,001h,017h,001h,000h	; 7f39  ................
	defb 001h,017h,001h,000h,004h,019h,004h,017h,004h,019h,010h,01bh,000h,002h,00dh,004h	; 7f49  ................
	defb 000h,004h,012h,002h,012h,002h,00dh,004h,000h,002h,012h,004h,000h,002h,00bh,002h	; 7f59  ................
	defb 000h,010h,00dh,002h,00dh,004h,000h,003h,00fh,003h,00dh,003h,00bh,006h,00fh,006h	; 7f69  ................
	defb 00dh,003h,017h,002h,016h,004h,000h,010h,014h,004h,012h,002h,011h,010h,012h,000h	; 7f79  ................
	defb 002h,011h,002h,000h,002h,011h,00ch,000h,002h,00fh,002h,000h,002h,00fh,00ch,000h	; 7f89  ................
	defb 002h,00dh,002h,000h,002h,00dh,00ch,000h,002h,00fh,002h,000h,002h,00fh,00ch,000h	; 7f99  ................
	defb 000h	; 7fa9

; ----------------------------------------------------------------------
; DATOS redoble_notas: Las cuatro notas (5, 3, 1, 3) de los cuatro grupos de
;   0x7FAE
;   0x7faa..0x7fae  (4 bytes)
DATA_redoble_notas:
	defb 005h,003h,001h,003h	; 7faa

; ======================================================================
; CODIGO 0x7fae..0x7fc7  (25 bytes)
; ======================================================================


redoble_pon:		; Una pieza de musica hecha en la RAM (0xE000): cuatro grupos de 18 notas de un cuadro (duracion 1, la nota de 0x7FAA) y el 0 del final; la lista 0x7FC7 la toca
	ld de,07faah		;7fae   ; las cuatro notas
	ld hl,0e000h		;7fb1   ; desde 0xE000
	ld b,004h		;7fb4   ; cuatro grupos
redoble_grupo:
	push bc			;7fb6   ; un grupo
	ld b,012h		;7fb7   ; de 18
	ld a,(de)			;7fb9   ; la nota del grupo
	inc de			;7fba
redoble_nota:
	ld (hl),001h		;7fbb   ; duracion 1...
	inc hl			;7fbd
	ld (hl),a			;7fbe   ; ...y la nota
	inc hl			;7fbf
	djnz redoble_nota		;7fc0
	pop bc			;7fc2   ; el siguiente
	djnz redoble_grupo		;7fc3
	ld (hl),b			;7fc5   ; 0: el final de la pieza
	ret			;7fc6

; ----------------------------------------------------------------------
; DATOS musica_lista2: La lista de piezas de la segunda voz (0x7FC7: 0x7FD3,
;   0x7F2D... y 0xE000, la pieza de la RAM), mas notas y el final del cartucho
;   a 0xFF
;   0x7fc7..0x8000  (57 bytes)
DATA_musica_lista2:
	defb 0d3h,07fh,0ffh,0ffh,02dh,07fh,0ffh,0ffh,000h,0e0h,000h,000h,002h,001h,004h,000h	; 7fc7  ....-...........
	defb 004h,00ah,002h,00ah,002h,001h,004h,000h,003h,00ah,024h,000h,003h,017h,006h,012h	; 7fd7  ..........$.....
	defb 006h,011h,003h,00bh,002h,00ch,004h,000h,010h,00ch,004h,01eh,002h,01dh,010h,01eh	; 7fe7  ................
	defb 000h,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ff7  .........
