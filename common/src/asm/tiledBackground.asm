.importonce
.filenamespace tile
.import source "vic.asm"
.import source "c64common.asm"

/*
 * Map structure
 * -------------
 * $0000				Control
 * $0001				Width  
 * $0002				Height
 * $0003				Color0
 * $0004				Color1
 * $0005				Color2
 * $0006				Charset Number
 * $0007, $0008			Tile attribute def offset
 * $0009, $000A			Map def offset
 * $000B, $000C			Map entry def offset
 * $000D, $000E			BG_COLOR_2 switch table offset
 * 
 * Color switch table
 * ------------------
 * This table is used to alternate BG_COL_2 using raster interrupt. Table end is marked with $FF.
 * Each table row is two byte: first byte denotes tile X position of the map, low nibble 
 * of second byte denotes color used for switching.
 */

.label screenPointerLo = $02
.label screenPointerHi = $03
.label tilePointerLo = $04
.label tilePointerHi = $05
.label mapPointerLo = $06
.label mapPointerHi = $07
.label mapPositionXTile = $08
.label mapPositionYTile = $0A
.label temp0 = $0B
.label temp1 = $0C
.label temp2 = $0D
.label colorRamPointerLo = $0E
.label colorRamPointerHi = $0F
.label mapStructurePointerLo = $10
.label mapStructurePointerHi = $11
.label tileAttributePointerLo = $12
.label tileAttributePointerHi = $13
.label mapWidth = $14
.label mapHeight = $15
.label tempMapPointerLo = $16
.label tempMapPointerHi = $17
.label color2SwitchTablePointerLo = $18
.label color2SwitchTablePointerHi = $19
.label mapEntryPointerLo = $1A
.label mapEntryPointerHi = $1B
.label color2SwitchPosition = $1C
.label nextColor2 = $1D
.label nextTileSwitchingColor2Lo = $1E
.label nextTileSwitchingColor2Hi = $1F
.label nextRasterSwitchingColorLo = $20
.label nextRasterSwitchingColorHi = $21
.label rasterOffset = $22
.label currentRasterTemp = $24
.label nextColor0	=	$26

.label MAP_POINTERS = $3000

.label HEADER_SIZE = 15

/*
 * Initializes Map data.
 * Input:
 *  A - map number
 *  Y - map entry position ID
 */
initMap: {
	// initialize map structure pointer
	asl
	tax
	lda tile.mapPointers, x
	sta	tile.mapStructurePointerLo
	inx
	lda tile.mapPointers, x
	sta tile.mapStructurePointerHi
	// initialize tile def pointer
	clc
	lda tile.mapStructurePointerLo
	adc #HEADER_SIZE
	sta tile.tilePointerLo
	lda tile.mapStructurePointerHi
	sta tile.tilePointerHi
	adc #0
	// initialize zero page variables with structure data
	ldy #0
	:tile_skipByte()
	:tile_readByte(tile.mapWidth)
	:tile_readByte(tile.mapHeight)
	:tile_readByte(vic.BG_COL_0)
	:tile_readByte(vic.BG_COL_1)
	:tile_readByte(vic.BG_COL_2)
	:tile_skipByte()
	:tile_readOffset(tile.mapStructurePointerLo, tile.tileAttributePointerLo)
	:tile_readOffset(tile.mapStructurePointerLo, tile.mapPointerLo)
	:tile_readOffset(tile.mapStructurePointerLo, tile.mapEntryPointerLo)
	:tile_readOffset(tile.mapStructurePointerLo, tile.color2SwitchTablePointerLo)
	rts
	
}

.pc = MAP_POINTERS "Map pointers" virtual
mapPointers:  

.macro tile_readByte(to) {
	lda (tile.mapStructurePointerLo),y
	sta to
	iny
}
.macro tile_readOffset(source, target) {
	lda (tile.mapStructurePointerLo),y
	sta target
	iny
	lda (tile.mapStructurePointerLo),y
	sta [target + 1]
	clc
	lda source
	adc target
	sta target
	lda [source + 1]
	adc [target + 1]
	sta [target + 1]
	iny
}
.macro tile_skipByte() {
	iny
}

.macro @tile_nextColor2Switch() {
	lda tile.color2SwitchPosition
	asl
	asl
	tay
	lda (tile.color2SwitchTablePointerLo), y
	sta tile.nextTileSwitchingColor2Lo
	iny
	lda (tile.color2SwitchTablePointerLo), y
	sta tile.nextTileSwitchingColor2Hi
	iny
	lda (tile.color2SwitchTablePointerLo), y
	sta tile.nextColor0
	iny
	lda (tile.color2SwitchTablePointerLo), y
	sta tile.nextColor2
	inc tile.color2SwitchPosition
}

.function @tile_calcRaster(tileY) {
	.return tileY * 16 + vic.TOP_SCREEN_RASTER_POS
}
