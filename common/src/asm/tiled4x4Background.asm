.importonce
.filenamespace t44
.import source "vic.asm"
.import source "c64common.asm"

.label HEADER_SIZE	= 13	// size of map structure definition header

.const O_CONTROL				= 0
.const O_WIDTH 					= 1
.const O_HEIGHT 				= 2
.const O_BG_COLOR_2				= 3
.const O_CHARSET				= 4
.const O_TILE_ATTR_OFFSET 		= 5
.const O_MAP_DEF_OFFSET 		= 7
.const O_ENTRY_DEF_OFFSET		= 9
.const O_COLOR_SWITCH_OFFSET	= 11

.label SCREEN_HEIGHT	= 20	// 20 rows of playfield
.label EMPTY_CHAR		= $00	// will be used to draw this part of screen where no background should be rendered

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
 * SUBROUTINE:
 * Initialize map structure using given map structure definition pointer.
 * 
 * In:
 * - X - low address of map structure
 * - Y - hi address of map structure
 */
initializeMap4x4: {

	txa
	sta t44.mapStructPtr
	tya
	sta t44.mapStructPtr + 1					
	
	:zero16(t44.mapX)
	:zero16(t44.mapY)
	:headerRewind()
	:headerSkip8()		// CONTROL
	:read8(mapWidth)
	:read8(mapHeight)
	:read8(vic.BG_COL_2)
	:headerSkip8()		// Charset not used for now...
	:readAndCalculateAddress(t44.tileAttrDefPtr)
	:readAndCalculateAddress(t44.mapDefPtr)
	
	:copyWord(t44.mapStructPtr, t44.tileDefPtr)
	:addConstToMem(HEADER_SIZE, t44.tileDefPtr)
	
	jsr precalcMapRowOffsets
	jsr precalculateTileOffsets
	
	rts
}

/*
 * For faster processing we will precalculate offset of each map row
 */
mapRowOffsets:
	.fill 512, 0
	
.print mapRowOffsets
	
/*
 * SUBROUTINE:
 * Precalculates content of t44_mapRowOffsets based on following settings:
 * - mapStructPtr
 * 
 * Uses following registers:
 * - A - internally
 * - X - internally
 *
 * Used temps:
 * temp0, 1, 2, 3, 4, 5
 */
precalcMapRowOffsets: {
	.const mapPtr = c64.temp0		
	.const offsetsPtr = c64.temp2	
	.const mapWidthB = c64.temp4	
	.const mapHeightB = c64.temp5	
	
	ldx #0 												// X <- current map row number
	:copyWord(t44.mapDefPtr, mapPtr) 	
	:set16(offsetsPtr, mapRowOffsets)					// temp2, temp3 <- current map row offsets cell
	:copyByte(t44.mapWidth, mapWidthB)					// temp4 <- WIDTH of map
	:copyByte(t44.mapHeight, mapHeightB)				// temp5 <- HEIGHT of map
!:
	:copyWordIndirect(mapPtr, offsetsPtr)
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
	
.print tileOffsets
	
/*
 * SUBROUTINE:
 * Precalculates addresses of each tile.
 * - mapStructPtr
 * Uses following registers:
 * - A - internally
 * - X - internally
 * Used temps:
 * temp0, 1, 2, 3
 */
precalculateTileOffsets: {
	.const tilePtr = c64.temp0
	.const offsetsPtr = c64.temp2

	ldx #0
	:copyWord(t44.tileDefPtr, tilePtr)						// temp0, temp1 <- pointer to tile definition structure
	:set16(offsetsPtr, tileOffsets)							// temp2, temp3 <- current ptr to tileOffets array element
!:
	:copyWordIndirect(tilePtr, offsetsPtr)
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
	beq !+
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
.macro displayMap4x4(screenPtr) {
	.const currentMapPtr = c64.temp0
	.const currentTileDefPtr = c64.temp2
	.const tileXCounterB = c64.temp4
	.const tileYCounterB = c64.temp5
	.const rightEdgeB = c64.temp6
	.const bottomEdgeB = c64.temp7
	.const tileScreenPtr = c64.temp8
	.const tileNumber = c64.temp10
	.const colorRamPtr = c64.temp11
	
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
	bmi !+
	lda #10
!:
	sta rightEdgeB
	
// find bottom edge
	lda t44.mapHeight
	sec
	sbc t44.mapY
	cmp #[SCREEN_HEIGHT / 4]
	bmi !+
	lda #[SCREEN_HEIGHT / 4]
!:
	sta bottomEdgeB



// do the needful, find tile definition to be drawn
	:set16(colorRamPtr, vic.COLOR_RAM)
	:set16(tileScreenPtr, screenPtr)
	:set16(currentScreenPtr + 1, screenPtr)					// temp4, temp5 <- initalized with top left char of the screen
	:zero8(tileXCounterB)
	:zero8(tileYCounterB)
	:copyByte(t44.mapY + 1, currentMapPtr)
	:zero8(currentMapPtr + 1)
	:fetchPrecalculatedPtr(t44.mapRowOffsets, currentMapPtr)
	:addMemToMem8(t44.mapX + 1, currentMapPtr)				// temp0, temp1 <- address of tile number that should be rendered
nextTile:
	ldy tileXCounterB
	lda (currentMapPtr), y									// A <- id of the tile number to be displayed
	sta tileNumber
	sta currentTileDefPtr
	:zero8(currentTileDefPtr + 1)
	:fetchPrecalculatedPtr(t44.tileOffsets, currentTileDefPtr)	// temp2, temp3 <- address of tile definition that should be rendered
	ldx #0
	ldy #0
!loop:
	lda (currentTileDefPtr), y
currentScreenPtr:											// code anchor for self-modified
	sta $FFFF, x
	iny
	tya
	cmp #16
	beq next
	inx
	txa                     
	cmp #4
	bne !loop-
	ldx #0
	:addConstToMem(40, currentScreenPtr + 1)
	jmp !loop-
next:
	// fill color RAM
	ldy tileNumber
	lda (t44.tileAttrDefPtr), y
	.for (var j = 0; j < 4; j++) {
		ldy #[j * 40]
		.for (var i = 0; i < 4; i++) {
			sta (colorRamPtr), y
			iny
		}
	}
	:addConstToMem(4, colorRamPtr)
	// advance to the next tile
	:addConstToMem(4, tileScreenPtr)						// progress tile screen pointer to draw new tile
	:copyWord(tileScreenPtr, currentScreenPtr + 1)				// reset current drawing pointer to new tile
	ldy #0
	inc tileXCounterB
	lda tileXCounterB
	cmp rightEdgeB
	beq nextRow
	jmp nextTile
	
nextRow:
	inc tileYCounterB
	lda tileYCounterB
	cmp bottomEdgeB
	beq end
	
	:addConstToMem(3*40, colorRamPtr)
	:addMemToMem8(t44.mapWidth, currentMapPtr)
	:zero8(tileXCounterB)
	:addConstToMem(3*40, tileScreenPtr)
	:copyWord(tileScreenPtr, currentScreenPtr + 1)
	jmp nextTile
	
end:
}

// HEADER MANIPULATION
.macro headerRewind() {
	ldy #0
}

.macro headerSkip8() {
	iny 
}

.macro read8(target) {
	lda (t44.mapStructPtr), y
	sta target
	iny
}

.macro read16(target) {
	:read8(target)
	:read8(target+1)
}

.macro readAndCalculateAddress(target) {
	lda (t44.mapStructPtr), y
	sta target
	iny
	lda (t44.mapStructPtr), y
	sta target + 1
	iny
	:addMemToMem16(t44.mapStructPtr, target)
}