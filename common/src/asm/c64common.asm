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

.macro c64_setMem(value, low, high) {
	lda #<value
	sta low
	lda #>value
	sta high
}

.macro c64_addConstToMem(value, low, high) {
	clc
	lda low
	adc #<value
	sta low
	lda high
	adc #>value
	sta high
}

.macro c64_addMemByteToMem(byte, low, high) {
	clc
	lda low
	adc byte
	sta low
	lda high
	adc #$00
	sta high
}

.macro c64_copyWord(source, destination) {
	lda source
	sta destination
	lda source+1
	sta destination+1
}
