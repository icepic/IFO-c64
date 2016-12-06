BasicUpstart2(start)

	* = $0810 "Main"
start:
	jsr	loadmap


	rts

loadmap:
        lda #fname_end-fname
        ldx #<fname
        ldy #>fname
        jsr $FFBD     //; call SETNAM
        lda #$01
        ldx $BA
//#; last used dev number
        bne skip
        ldx #$08      //; default to device 8
skip:  ldy #$00      //; $00 means: load to new address
        jsr $FFBA     //; call SETLFS

        ldx #<$1000
        ldy #>$1000
        lda #$00      //; $00 means: load to memory (not verify)
        jsr $FFD5     //; call LOAD
        bcs error    //; if carry set, a load error has happened
        rts
error:	


//	; Accumulator contains BASIC error code

//        ; most likely errors:
//        ; A = $05 (DEVICE NOT PRESENT)
//        ; A = $04 (FILE NOT FOUND)
//        ; A = $1D (LOAD ERROR)
//        ; A = $00 (BREAK, RUN/STOP has been pressed during loading)

//        ... error handling ...
	sta $d020
        rts

fname:  .text "MAP1A"
fname_end:

* = $1000 "map data section"
map:	
	.fill 1000,0
mapend:	
