.importonce
.filenamespace t44
.import source "vic.asm"
.import source "c64common.asm"

.const O_CONTROL		= $0
.const O_WIDTH 			= $1
.const O_HEIGHT 		= $2
.const O_MAP_DEF_OFFSET = $7

.const EMPTY_CHAR		= $00	// will be used to draw this part of screen where no background should be rendered

.const HEADER_SIZE		= 13	// size of map structure definition header
.const GLOBAL			= $02	// starting offset for global zero page registers reserved for background

.label screen0			= GLOBAL + 0
.label screen1			= GLOBAL + 2
.label mapX				= GLOBAL + 4
.label mapY				= GLOBAL + 6
.label tileDefPtr		= GLOBAL + 8	
.label tileAttrDefPtr	= GLOBAL + 10
.label mapDefPtr		= GLOBAL + 12
.label mapStructPtr		= GLOBAL + 14
.label scrollX			= GLOBAL + 16
.label scrollY			= GLOBAL + 17
.label mapWidth			= GLOBAL + 18
.label mapHeight		= GLOBAL + 19

/*
 * For faster processing we will precalculate offset of each map row
 */
mapRowOffsets:
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
precalcMapRowOffsets: {
	.const mapPtr = c64.temp0		
	.const offsetsPtr = c64.temp2	
	.const mapWidthB = c64.temp4	
	.const mapHeightB = c64.temp5	

	ldx #0 												// X <- current map row number
	:copyWord(mapStructPtr + O_MAP_DEF_OFFSET, mapPtr) 	
	:addMemToMem16(mapStructPtr, mapPtr)					
	:addConstToMem(HEADER_SIZE, mapPtr)					// temp0, temp1 <- current pointer to the map row
	:copyWord(mapRowOffsets, offsetsPtr)				// temp2, temp3 <- current map row offsets cell
	:copyByte(mapStructPtr + O_WIDTH, mapWidthB)			// temp4 <- WIDTH of map
	:copyByte(mapStructPtr + O_HEIGHT, mapHeightB)		// temp5 <- HEIGHT of map
!:
	:copyWord(mapPtr, offsetsPtr)
	:addMemToMem8(mapWidthB, mapPtr)
	:incWord(offsetsPtr)
	:incWord(offsetsPtr)
	inx
	cpx mapHeightB
	bne !-
	rts
}

/*
 * Precalculated addresses of each tile.
 */
tileOffsets:
	.fill 521, 0
	
/*
 * SUBROUTINE:
 * Precalculates addresses of each tile.
 * - mapStructPtr
 * Uses following registers:
 * - A - internally
 * - X - internally
 */
precalculateTileOffsets: {
	.const tilePtr = c64.temp0
	.const offsetsPtr = c64.temp2

	ldx #0
	:copyWord(mapStructPtr + HEADER_SIZE, tilePtr)	// temp0, temp1 <- pointer to tile definition structure
	:copyWord(tileOffsets, offsetsPtr)						// temp2, temp3 <- current ptr to tileOffets array element
!:
	:copyWord(tilePtr, offsetsPtr)
	:addConstToMem(16, tilePtr)
	:incWord(offsetsPtr)
	:incWord(offsetsPtr)
	inx
	bne !-
	rts
}

/*
 * Fetches one byte value according to lookup table (bufferPtr). Index within the table is specified
 * tempPtr. After execution, tempPtr will contain word size relative pointer inside lookup table and
 */
.macro fetchPrecalculatedPtr(bufferPtr, tempPtr) {
	:mul2Mem16(tempPtr)
	ldx tempPtr
	lda #%00000001
	bit tempPtr + 1
	bne !+
	lda bufferPtr + 256, x
	sta tempPtr
	lda bufferPtr + 257, x
	sta tempPtr + 1
	jmp do
!:
	lda bufferPtr, x
	sta tempPtr
	lda bufferPtr + 1, x
	sta tempPtr + 1
do:
}

/*
 * Uses:
 * - mapX
 * - mapWidth
 * - mapHeight
 */
.macro displayMap(screenPtr) {
	:c64_clearScreen(screenPtr, EMPTY_CHAR)
	
// initial checking...
	lda t44.mapY + 1									
	cmp t44.mapHeight										// should we display at all
	bpl end
	lda t44.mapX + 1
	cmp t44.mapWidth										// should we display at all
	bpl	end

// do the needful, find tile definition to be drawn
	:copyByte(t44.mapY + 1, t44.temp0)
	:zero8(t44.temp1)
	:fetchPrecalculatedPtr(mapRowOffsets, t44.temp0)
	:addMemToMem8(t44.mapX + 1, t44.temp0)					// temp0, temp1 <- address of tile number that should be rendered
	ldy #0
	lda (t44.temp0), y										// A <- id of the tile number to be displayed
	sta t44.temp2
	:zero8(t44.temp3)
	:fetchPrecalculatedPtr(tileOffsets, t44.temp2)			// temp2, temp3 <- address of tile definition that should be rendered
// todo
end:
}