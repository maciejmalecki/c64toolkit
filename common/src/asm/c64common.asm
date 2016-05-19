.importonce
.filenamespace c64

.label MOS_6510_DIRECTION 	= $00
.label MOS_6510_IO 			= $01

// 16 temporary byte registers for common use
.label temp0			= $F0
.label temp1			= $F1
.label temp2			= $F2
.label temp3			= $F3
.label temp4			= $F4
.label temp5			= $F5
.label temp6			= $F6
.label temp7			= $F7
.label temp8			= $F8
.label temp9			= $F9
.label temp10			= $FA
.label temp11			= $FB
.label temp12			= $FC
.label temp13			= $FD
.label temp14			= $FE
.label temp15			= $FF

.macro c64_configureMemory(config) {
	lda c64.MOS_6510_IO
	and #%11111000
	ora #[config & %00000111]
	sta c64.MOS_6510_IO
}

/* ---------------------------------------------
 * Various memory operations
 * --------------------------------------------- */

.macro addConstToMem(value, low) {
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
	clc			// 2
	asl low		// 5
	bcc next	// 2
	lda low + 1	// 3
	asl			// 2
	ora #%1		// 2
	sta low + 1	// 3
next:			// =19
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