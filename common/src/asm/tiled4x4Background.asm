.importonce
.filenamespace t44
.import source "vic.asm"
.import source "c64common.asm"

.const O_CONTROL		= $0
.const O_WIDTH 			= $1
.const O_HEIGHT 		= $2
.const O_MAP_DEF_OFFSET = $7

.label screen0			= $02
.label screen1			= $04
.label mapX				= $06
.label mapY				= $08	
.label tileDefPtr		= $0A	
.label tileAttrDefPtr	= $0C
.label mapDefPtr		= $0E	
.label mapStructPtr		= $10	
.label scrollX			= $12	
.label scrollY			= $13	

.label temp0			= $F0
.label temp1			= $F1
.label temp2			= $F2
.label temp3			= $F3
.label temp4			= $F4
.label temp5			= $F5
.label temp6			= $F6
.label temp7			= $F7

/*
 * For faster processing we will precalculate offset of each map row
 */
t44_mapRowOffsets:
	.fill 512, 0
	
/*
 * SUBROUTINE:
 * Precalculates content of t44_mapRowOffsets based on following settings:
 * - mapStructPtr
 * 
 * Uses following registers:
 * - A - internally
 * - X - internally
 */
t44_precalcMapRowOffsets: {
	ldx #0 														// X <- current map row number
	:c64_copyWord(mapStructPtr + O_MAP_DEF_OFFSET, t44.temp0) 	
	:c64_addMemToMem(mapStructPtr, t44.temp0)					// temp0, temp1 <- current pointer to the map row
	:c64_copyWord(t44_mapRowOffsets, t44.temp2)					// temp2, temp3 <- current map row offsets cell
	:c64_copyByte(mapStructPtr + O_WIDTH, t44.temp4)			// temp4 <- WIDTH of map
	:c64_copyByte(mapStructPtr + O_HEIGHT, t44.temp5)			// temp5 <- HEIGHT of map
loop:
	:c64_copyWord(t44.temp0, t44.temp2)
	:c64_addMemByteToMem(t44.temp4, t44.temp0)
	:c64_incWord(t44.temp2)
	inx
	cpx t44.temp5
	bne loop
	rts
}