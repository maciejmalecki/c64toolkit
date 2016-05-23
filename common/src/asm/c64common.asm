.importonce
.filenamespace c64

.label MOS_6510_DIRECTION 	= $00
.label MOS_6510_IO 			= $01

/* 
 * 4 temporary byte registers for subroutine call arguments.
 * Each subroutine is required to copy these variables to its 
 * local variable space before processing unless not calling
 * another function. Do not use this mechanism in interrupt 
 * handlers.
 */
.const FUNC_OFFSET		= $EC
.label func0			= FUNC_OFFSET + 0
.label func1			= FUNC_OFFSET + 1
.label func2			= FUNC_OFFSET + 2
.label func3			= FUNC_OFFSET + 3

/* 
 * 16 temporary byte registers for common use.
 * This memory should be used for temporary, local
 * variables for macros or subroutines.
 *
 * WARNING: this data space is not stored when calling
 * subroutine or macro thus it is not a real local variable
 * space.
 */
.const TEMP_OFFSET		= $F0
.label temp0			= TEMP_OFFSET + 0
.label temp1			= TEMP_OFFSET + 1
.label temp2			= TEMP_OFFSET + 2
.label temp3			= TEMP_OFFSET + 3
.label temp4			= TEMP_OFFSET + 4
.label temp5			= TEMP_OFFSET + 5
.label temp6			= TEMP_OFFSET + 6
.label temp7			= TEMP_OFFSET + 7
.label temp8			= TEMP_OFFSET + 8
.label temp9			= TEMP_OFFSET + 9
.label temp10			= TEMP_OFFSET + 10
.label temp11			= TEMP_OFFSET + 11
.label temp12			= TEMP_OFFSET + 12
.label temp13			= TEMP_OFFSET + 13
.label temp14			= TEMP_OFFSET + 14
.label temp15			= TEMP_OFFSET + 15

.macro configureMemory(config) {
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

.macro subConstFromMem(value, low) {
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

.macro subMemFromMem(source, destination) {
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
	bcc !+		// 2
	lda low + 1	// 3
	asl			// 2
	ora #%1		// 2
	sta low + 1	// 3
!:				// =19
}

.macro copyWord(source, destination) {
	lda source
	sta destination
	lda source+1
	sta destination+1
}

.macro copyWordIndirect(source, destinationPointer) {
	ldy #0
	lda source
	sta (destinationPointer), y
	iny
	lda source + 1
	sta (destinationPointer), y
}

.macro copyByte(source, destination) {
	lda source
	sta destination
}

.macro incWord(destination) {
	inc destination
	bne !+
	inc destination + 1
!:
}

.macro set8(value, mem) {
	lda #value
	sta mem
}

.macro zero8(mem) {
	:set8(0, mem)
}

.macro set16(value, mem) {
	lda #<value
	sta mem
	lda #>value
	sta mem + 1
}

.macro zero16(mem) {
	:set16($0000, mem)
}