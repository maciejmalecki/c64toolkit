.importonce
.filenamespace t44
.import source "vic.asm"
.import source "c64common.asm"

.const O_CONTROL		= $0
.const O_WIDTH 			= $1
.const O_HEIGHT 		= $2
.const O_MAP_DEF_OFFSET = $7

.const SCREEN_HEIGHT	= 20

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
 * Temporary variables:
 * - temp0, temp1
 * - temp2, temp3
 * - temp4
 * - temp5
 * - temp6
 * - temp7
 * - temp8, temp9
 */
.macro displayMap(screenPtr) {
	.const currentMapPtr = c64.temp0
	.const currentTileDefPtr = c64.temp2
	.const tileXCounterB = c64.temp4
	.const tileYCounterB = c64.temp5
	.const rightEdgeB = c64.temp6
	.const bottomEdgeB = c64.temp7
	.const tileScreenPtr = c64.temp8
	
// initial checking...
	lda t44.mapY + 1									
	cmp t44.mapHeight										// should we display at all
	bpl toEnd
	lda t44.mapX + 1
	cmp t44.mapWidth										// should we display at all
	bpl	toEnd
	jmp !+
toEnd:
	jmp end
!:

// find right edge
	lda t44.mapWidth
	sec
	sbc t44.mapX
	cmp #10
	bpl !+
	lda #10
!:
	sta t44.rightEdgeB
	
// find bottom edge
	lda t44.mapHeight
	sec
	sbc t44.mapY
	cmp #[SCREEN_HEIGHT / 4]
	bpl !+
	lda #[SCREEN_HEIGHT / 4]
!:
	sta t44.bottomEdgeB

// do the needful, find tile definition to be drawn
	:c64_clearScreen(screenPtr, EMPTY_CHAR)
	:copyWord(screenPtr, tileScreenPtr)
	:copyWord(screenPtr, currentScreenPtr + 1)					// temp4, temp5 <- initalized with top left char of the screen
	:zero8(tileXCounterB)
	:zero8(tileYCounterB)
	:copyByte(t44.mapY + 1, currentMapPtr)
	:zero8(currentMapPtr + 1)
	:fetchPrecalculatedPtr(mapRowOffsets, currentMapPtr)
	:addMemToMem8(t44.mapX + 1, currentMapPtr)				// temp0, temp1 <- address of tile number that should be rendered
nextTile:
	ldy tileXCounterB
	lda (currentMapPtr), y									// A <- id of the tile number to be displayed
	sta currentTileDefPtr
	:zero8(currentTileDefPtr + 1)
	:fetchPrecalculatedPtr(tileOffsets, currentTileDefPtr)	// temp2, temp3 <- address of tile definition that should be rendered
	ldx #0
	ldy #0
!loop:
	lda (currentTileDefPtr), y
currentScreenPtr:											// code anchor for self-modified
	sta $FFFF, x
	iny
	tya
	cmp #16
	beq !+
	inx
	txa
	cmp #4
	bne !loop-
	ldx #0
	:addConstToMem(40, currentScreenPtr)
	jmp !loop-
!:
	inc tileXCounterB
	lda tileXCounterB
	cmp rightEdgeB
	beq nextRow
	
	:addConstToMem(4, tileScreenPtr)						// progress tile screen pointer to draw new tile
	:copyWord(tileScreenPtr, currentScreenPtr)				// reset current drawing pointer to new tile
	
	jmp nextTile
	
nextRow:
	inc tileYCounterB
	lda tileYCounterB
	cmp bottomEdgeB
	beq end
	
	:addMemToMem8(mapWidth, currentMapPtr)
	:zero8(tileXCounterB)
	:addConstToMem(4 + 3*40, tileScreenPtr)
	jmp nextTile
	
end:
}