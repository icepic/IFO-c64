BasicUpstart2(start)

.const tmpmul=$02
	
.const coordx=$fe
.const coordy=$ff

.pseudocommand mul8by8 arg1 : arg2 {
	lda #$00
	tay
	sty tmpmul  //; remove this line for 16*8=16bit multiply
	beq enterLoop

doAdd:
	clc
	adc arg1
	tax

	tya
	adc tmpmul
	tay
	txa

loop:
	asl arg1
	rol tmpmul
enterLoop:
// accumulating multiply entry point (enter with .A=lo, .Y=hi)
	lsr arg2
	bcs doAdd
	bne loop

}

.function a16bitnextArgument(arg) {
	.if (arg.getType()==AT_IMMEDIATE)
		.return CmdArgument(arg.getType(),>arg.getValue())
	.return CmdArgument(arg.getType(),arg.getValue()+1)
}
.pseudocommand inc16 arg {
	inc arg
	bne over
	inc a16bitnextArgument(arg)
over:
}
.pseudocommand mov16 src:tar {
	lda src
	sta tar
	lda a16bitnextArgument(src)
	sta a16bitnextArgument(tar)
}
.pseudocommand add16 arg1 : arg2 : tar {
	.if (tar.getType()==AT_NONE) .eval tar=arg1
	clc
	lda arg1
	adc arg2
	sta tar
	lda a16bitnextArgument(arg1)
	adc a16bitnextArgument(arg2)
	sta a16bitnextArgument(tar)
}

	
	* = $0810 "Main"
start:

	jsr	init
	jsr	loadmap
main:	
	jsr	paintmap
	jsr	sleep
	ldx	coordy
	inx
	txa
	and	#15
	sta	coordy

readkey:
	jsr	$F142   // returns 0 if no key
	beq	readkey //  pressed since last time

	sta	$0400 // to see what bytes come out
	
	jmp	main
	
	rts

sleep:	ldx #200
s1:	cpx $d012
	bne s1
	dex
s2:	cpx $d012
	bne s2
	rts

paintmap:

// restore map painting code to defaults, otherwise
// the self-modifying code will race through memory

	lda #<$1000
	sta paint + 1
	lda #>$1000
	sta paint + 2
	lda #<($0480+41)
	sta pdest + 1
	lda #>($0480+41)
	sta pdest + 2
	
	ldy #0
	lda coordy
	beq nomul
	mul8by8 coordy : 32
nomul:	sta $fc
	sty $fd
	add16 $fc : coordx
	add16 paint + 1 : $fc

	ldy #15
ploop:	ldx #16

paint:
	lda $1000,x
pdest:	
	sta [$0480+41],x
	dex
	bpl paint

	add16 paint+1 : #32
	add16 pdest+1 : #40

	dey
	bpl	ploop

	rts
	
init:
	ldx #0
	stx coordx
	ldx #0
	stx coordy
	
	ldx #0
	lda #' '
clearscr:
	sta $0400,x
	sta $0500,x
	sta $0600,x
	sta $06e8,x
	dex
	bne clearscr

	// draw square for map
	ldx #18
	lda #$23
square:	
	sta $0480,x
	sta $0480+(40*17),x

ptr1:	sta $0480
ptr2:	sta [$0480 + 18]
	tay
	add16 ptr1+1 : #40
	add16 ptr2+1 : #40
	tya
	dex
	bne square
	rts
	
loadmap:
		lda #fname_end-fname
		ldx #<fname
		ldy #>fname
		jsr $FFBD	 // call SETNAM
		lda #$01
		ldx $BA
// last used dev number
		bne skip
		ldx #$08	  // default to device 8
skip:  ldy #$00	  // $00 means: load to new address
		jsr $FFBA	 // call SETLFS
		ldx #<$1000
		ldy #>$1000
		lda #$00	  // $00 means: load to memory (not verify)
		jsr $FFD5	 // call LOAD
		bcs error	// if carry set, a load error has happened
		rts
error:	

//	; Accumulator contains BASIC error code
//		; most likely errors:
//		; A = $05 (DEVICE NOT PRESENT)
//		; A = $04 (FILE NOT FOUND)
//		; A = $1D (LOAD ERROR)
//		; A = $00 (BREAK, RUN/STOP has been pressed during loading)
//		... error handling ...
	sta $d020
		rts

fname:  .text "MAP1A"
fname_end:

* = $1000 "map data section"
map:	
	.fill 1000,0
mapend:	
