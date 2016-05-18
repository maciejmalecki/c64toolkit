.importonce
.filenamespace t44
.import source "vic.asm"
.import source "c64common.asm"

.const O_CONTROL		= $0
.const O_WIDTH 			= $1
.const O_HEIGHT 		= $2
.const O_MAP_DEF_OFFSET = $7

.const EMPTY_CHAR		= $00	// will be used to draw this part of screen where no background should be rendered

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
.label mapWidth			= $14	
.label mapHeight		= $15	

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
	ldx #0 													// X <- current map row number
	:copyWord(mapStructPtr + O_MAP_DEF_OFFSET, t44.temp0) 	
	:addMemToMem16(mapStructPtr, t44.temp0)					// temp0, temp1 <- current pointer to the map row
	:copyWord(mapRowOffsets, t44.temp2)						// temp2, temp3 <- current map row offsets cell
	:copyByte(mapStructPtr + O_WIDTH, t44.temp4)			// temp4 <- WIDTH of map
	:copyByte(mapStructPtr + O_HEIGHT, t44.temp5)			// temp5 <- HEIGHT of map
loop:
	:copyWord(t44.temp0, t44.temp2)
	:addMemToMem8(t44.temp4, t44.temp0)
	:incWord(t44.temp2)
	inx
	cpx t44.temp5
	bne loop
	rts
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

// do the needful
	:copyByte(t44.mapY + 1, t44.temp0)
	:zero8(t44.temp1)
	:mul2Mem16(t44.temp0)									// temp0, temp1 <- current index of first map row to be displayed
	ldx t44.temp0
	lda #%00000001
	bit t44.temp1
	bne less256
	lda mapRowOffsets + 256, x
	sta t44.temp0
	lda mapRowOffsets + 257, x
	sta t44.temp1											// temp0, temp1 <- current Y based pointer to start row of the map
	jmp do1
less256:
	lda mapRowOffsets, x
	sta t44.temp0
	lda mapRowOffsets + 1, x
	sta t44.temp1											// temp0, temp1 <- current Y based pointer to start row of the map
do1:
	:addMemToMem8(t44.mapX + 1, t44.temp0)					// temp0, temp1 <- address of tile number that should be rendered first
end:
}