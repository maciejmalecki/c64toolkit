/*
 * Set of variables, functions and macros 
 * for handling VIC-II graphic processor.
 * 
 * Written for Kick Assembler v3.42
 * (c) 2016 Maciej Malecki
 */
.importonce
.filenamespace vic 

/* ------------------------------------
 * VIC-II memory registers.
 * ------------------------------------ */
.label BASE = $D000
.label SPRITE_MSB_X = BASE + 16
.label CONTROL_1 = BASE + 17
.label RASTER = BASE + 18
.label SPRITE_ENABLE = BASE + 21
.label CONTROL_2 = BASE + 22
.label SPRITE_EXPAND_Y = BASE + 23
.label MEMORY_CONTROL = BASE + 24
.label IRR = BASE + 25
.label IMR = BASE + 26
.label BORDER_COL = BASE + 32
.label BG_COL_0 = BASE + 33
.label BG_COL_1 = BASE + 34
.label BG_COL_2 = BASE + 35
.label SPRITE_COLOR = BASE + 39
.label COLOR_RAM = $D800

.label BANK_0 = %00000011
.label BANK_1 = %00000010
.label BANK_2 = %00000001
.label BANK_3 = %00000000

/* ------------------------------------
 * VIC-II configuration handling.
 * ------------------------------------ */
.macro vic_configureTextMemory(video, charSet) {
	lda #[charSet*2 + video*16]
	sta vic.MEMORY_CONTROL
}

.macro vic_configureBitmapMemory(bitmap) {
	lda #[bitmap*8]
	sta vic.MEMORY_CONTROL
}

.macro vic_setMultiColorText(on) {
	lda vic.CONTROL_2
	.if (on == 1) {
		ora #%00010000
	} else {
		and #%11101111
	}
	sta vic.CONTROL_2
}

.macro vic_setRaster(rasterLine) {
	lda #<rasterLine
	sta vic.RASTER
	lda vic.CONTROL_1
	.if (rasterLine > 255) {
		ora #%10000000
	} else {
		and #%01111111
	}
	sta vic.CONTROL_1
}

.macro vic_IRQ_ENTER() {
	pha
	tya
	pha
	txa
	pha
}

.macro vic_IRQ_EXIT(intVector, rasterLine, memory) {
	ldx #>intVector
	ldy #<intVector
	stx $FFFF
	sty $FFFE
	.if (memory) {
		lda rasterLine
		sta vic.RASTER
		lda vic.CONTROL_1
		ror rasterLine+1
		bcc doAnd
		ora #%10000000
		jmp next
	doAnd:
		and #%01111111
	next:
		sta vic.CONTROL_1
	} else {
		:vic_setRaster(rasterLine)
	}
	sec
	dec vic.IRR
	pla
	tax
	pla
	tay
	pla
	rti
}

/* ------------------------------------
 * Sprite handling.
 * ------------------------------------ */

.function vic_spriteX(spriteNo) {
	.return vic.BASE + spriteNo * 2
}

.function vic_spriteY(spriteNo) {
	.return vic_spriteX(spriteNo) + 1
}

.function vic_spriteMask(spriteNo) {
	.return pow(2, spriteNo)
}

.function vic_spriteColor(spriteNo) {
	.return vic.SPRITE_COLOR + spriteNo
}

.macro vic_locateSpriteX(x, spriteNo) {
	.if (x > 255) {
		lda #<x
		sta vic_spriteX(spriteNo)
		lda vic.SPRITE_MSB_X
		ora vic_spriteMask(spriteNo)
		sta vic.SPRITE_MSB_X
	} else {
		lda #x
		sta vic_spriteX(spriteNo)
	}
}

.macro vic_locateSpriteY(y, spriteNo) {
	lda #y
	sta vic_spriteY(spriteNo)
}

.macro vic_locateSprite(x, y, spriteNo) {
	:vic_locateSpriteX(x, spriteNo)
	:vic_locateSpriteY(y, spriteNo)
}


.macro c64_clearScreen(screenAddress, clearChar) {
	lda #clearChar
	ldx #$00
loop:
	sta screenAddress, x				// this is in fact clever trick
	sta screenAddress + $0100, x     // to clear screen which is 1kB
	sta screenAddress + $0200, x		// using just one 8 bit X register
	sta screenAddress + $0300, x
	inx
	bne loop
}

/*
 * Text pointer ended with $FF and up to 255 characters.
 */
.macro vic_outText(textPointer, screenMemPointer, xPos, yPos, col) {
	ldx #$00
	lda textPointer, x
loop:
	sta [screenMemPointer + xPos + 40*yPos], x
	lda #col
	sta [vic.COLOR_RAM + xPos + 40*yPos], x
	inx
	lda textPointer, x
	cmp #$FF
	bne loop
}

hexChars:
	.text "0123456789abcdef"
	
.macro vic_outByteHex(bytePointer, screenMemPointer, xPos, yPos, col) {
	ldx #$00
	lda bytePointer
	:vic_outAHex([screenMemPointer + xPos + 40*yPos])
	lda #col
	sta [vic.COLOR_RAM + xPos + 40*yPos]
	sta [vic.COLOR_RAM + xPos + 40*yPos + 1]
}

.macro vic_outAHex(screenLocPointer) {
		sta ldx1 + 1
		clc
		ror
		clc
		ror
		clc
		ror
		clc
		ror
		sta ldx0 + 1
		lda ldx1 + 1
		and #%1111
		sta ldx1 + 1
		jsr ldx0
		jsr ldx1
		jmp end
	ldx0:
		ldy #$00
		jmp out
	ldx1:
		ldy #$00
		jmp out
	out:
		lda vic.hexChars, y
		sta screenLocPointer, x
		inx
		rts
	end:
}