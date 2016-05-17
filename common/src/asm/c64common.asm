.importonce
.filenamespace c64

.label MOS_6510_DIRECTION 	= $00
.label MOS_6510_IO 			= $01

.macro c64_configureMemory(config) {
	lda c64.MOS_6510_IO
	and #%11111000
	ora #[config & %00000111]
	sta c64.MOS_6510_IO
}

/* ---------------------------------------------
 * Various memory operations
 * --------------------------------------------- */

.macro c64_setMem(value, low) {
	lda #<value
	sta low
	lda #>value
	sta low+1
}

.macro c64_addConstToMem(value, low) {
	clc
	lda low
	adc #<value
	sta low
	lda low + 1
	adc #>value
	sta low + 1
}

.macro c64_subConstFromMem(value, low) {
	sec
	lda low
	sbc	#<value
	sta low
	lda low + 1
	sbc #>value
	sta low + 1
}

.macro c64_addMemByteToMem(byte, low) {
	clc
	lda low
	adc byte
	sta low
	lda low + 1
	adc #$00
	sta low + 1
}

.macro c64_addMemToMem(source, destination) {
	clc
	lda source
	adc destination
	sta destination
	lda source + 1
	adc destination + 1
	sta destination + 1
}

.macro c64_subMemFromMem(source, destination) {
	sec
	lda destination
	sbc source
	sta destination
	lda destination + 1
	sbc source + 1
	sta destination + 1
}

.macro c64_multiple2Mem(low) {
	clc
	asl low
	bcc next
	lda low + 1
	asl
	ora #%1
	sta low + 1
next:
}

.macro c64_copyWord(source, destination) {
	lda source
	sta destination
	lda source+1
	sta destination+1
}

.macro c64_copyByte(source, destination) {
	lda source
	sta destination
}

.macro c64_incWord(destination) {
	inc destination
	bne over
	inc destination + 1
over:
}