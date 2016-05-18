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

.macro addMemToMem8(byte, low) {
	clc
	lda low
	adc byte
	sta low
	lda low + 1
	adc #$00
	sta low + 1
}

.macro addMemToMem16(source, destination) {
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

.macro mul2Mem16(low) {
	clc
	asl low
	bcc next
	lda low + 1
	asl
	ora #%1
	sta low + 1
next:
}

.macro copyWord(source, destination) {
	lda source
	sta destination
	lda source+1
	sta destination+1
}

.macro copyByte(source, destination) {
	lda source
	sta destination
}

.macro incWord(destination) {
	inc destination
	bne over
	inc destination + 1
over:
}

.macro set8(mem, value) {
	lda #value
	sta mem
}

.macro zero8(mem) {
	:set8(mem, 0)
}

.macro set16(mem, value) {
	lda #<value
	sta mem
	lda #>value
	sta mem + 1
}

.macro zero16(mem) {
	:set16(mem, $0000)
}