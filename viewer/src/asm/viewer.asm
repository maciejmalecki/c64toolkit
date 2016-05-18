.import source "../../../common/src/asm/c64common.asm"
.import source "../../../common/src/asm/vic.asm"
.import source "../../../common/src/asm/cia.asm"
.import source "../../../common/src/asm/actor.asm"
.import source "../../../common/src/asm/tiledBackground.asm"
.import source "level1.asm"


// memory location constants
.const CHARSET_0_MEM = $A000
.const SCREEN_0_MEM = $8000
.const SCREEN_1_MEM = $8400
.const SCREEN_2_MEM = $0400
// height of the playfield
.const SCREEN_HEIGHT = 20
.const START_X = 0
.const START_Y = 0
.const MAP_NUMBER = 0

// fixed raster positions
.const DASHBOARD_RASTER = vic.TOP_SCREEN_RASTER_POS + SCREEN_HEIGHT * 8 - 1
.const PLAYFIELD_RASTER = 251

// charset data
.var charset = LoadBinary("../gfx/charset.bin")
.pc = CHARSET_0_MEM	"Charset" .fill charset.getSize(), charset.get(i)

.pc = $0801 "Basic Upstart"
:BasicUpstart(start) // Basic start routine

// Main program
.pc = $0810 "Program"

start: {
	jsr initialize
	jsr initializeMap
	jsr clearScreen
	jsr displayDashboard
	jsr displayMap
loop:
	jsr handleJoyA
	jsr handleJoyB
	ldx #$FF
pause:
	nop
	nop
	nop
	nop
	dex
	bne pause
	jmp loop
}

initializeMap: {
	lda #MAP_NUMBER
	ldy #0
	jsr tile.initMap
	rts
}
	
initialize:

	sei
	lda #$7f
	sta $DC0D
	sta $DD0D
	lda $DC0D
	sta $DD0D
	lda #$01
	sta vic.IMR
	:vic_setRaster(DASHBOARD_RASTER)
	lda #<irqDashboard
	sta $FFFE
	lda #>irqDashboard
	sta $FFFF
	lda #<irqFreeze
	sta $FFFA
	lda #>irqFreeze
	sta $FFFB

	:c64_configureMemory(%101)
	:cia_setVICBank(vic.BANK_2)
	:vic_setMultiColorText(1)
	:vic_configureTextMemory(0, 1)
	:c64_setMem($0000, tile.rasterOffset)
	cli
	
	lda vic.CONTROL_2
	and #11110111
	sta vic.CONTROL_2
	// configure colors
	lda #WHITE
	sta vic.BORDER_COL
	// initialize map position to 0,0
	lda #START_X
	sta tile.mapPositionXTile
	lda #START_Y
	sta tile.mapPositionYTile
	rts
	
displayMap: {
	lda #00
	sta tile.temp0 // current X pos in the map
	sta tile.temp1 // current X pos in the screen
	sta tile.temp2 // current Y pos in the screen
	// initialize screen pointer
	:c64_setMem(SCREEN_0_MEM, tile.screenPointerLo)
	// initialize map pointer
	:copyWord(tile.mapPointerLo, tile.tempMapPointerLo)
	// initialize color ram ptr
	:c64_setMem(vic.COLOR_RAM, tile.colorRamPointerLo)
	// rewind map to start position
	:addMemToMem8(tile.mapPositionXTile, tile.tempMapPointerLo)	
	lda tile.mapPositionYTile
	beq drawRow
	tax
rewindMap:
	:addMemToMem8(tile.mapWidth, tile.tempMapPointerLo)
	dex
	bne rewindMap
	// initialize screen memory in transfers
drawRow:
	lda tile.screenPointerLo
	sta transfer0 + 1
	lda tile.screenPointerHi
	sta transfer0 + 2
	clc
	lda tile.screenPointerLo	
	adc #1	
	sta transfer1 + 1	
	lda tile.screenPointerHi	
	adc #0	
	sta transfer1 + 2	
	clc	
	lda tile.screenPointerLo	
	adc #40	
	sta transfer2 + 1	
	lda tile.screenPointerHi	
	adc #0	
	sta transfer2 + 2	
	clc	
	lda tile.screenPointerLo	
	adc #41	
	sta transfer3 + 1	
	lda tile.screenPointerHi	
	adc #0	
	sta transfer3 + 2	
	
	// reading map...
	ldy #$00
	lda (tile.tempMapPointerLo), y // A <- ID of the block
	tax
	rol
	rol
	tay
	lda (tile.tilePointerLo), y // A <- first char of choosen tile
transfer0:
	sta SCREEN_0_MEM
	iny
	lda (tile.tilePointerLo), y
transfer1:
	sta SCREEN_0_MEM
	iny
	lda (tile.tilePointerLo), y
transfer2:
	sta SCREEN_0_MEM
	iny
	lda (tile.tilePointerLo), y
transfer3:	
	sta SCREEN_0_MEM

	txa	
	tay	
	lda (tile.tileAttributePointerLo), y // A <- tile distinct color
	ldy #00
	sta (tile.colorRamPointerLo), y
	iny
	sta (tile.colorRamPointerLo), y
	ldy #40
	sta (tile.colorRamPointerLo), y
	iny
	sta (tile.colorRamPointerLo), y
	
	// advance pointers...
	// -> map pointer
	inc tile.temp0
	lda tile.temp0
	cmp #20
	beq if1
	:c64_addConstToMem(1, tile.tempMapPointerLo)
	jmp if2
if1:
	lda #$00
	sta tile.temp0
	sec
	lda tile.mapWidth
	sbc #19
	clc
	adc tile.tempMapPointerLo
	sta tile.tempMapPointerLo
	lda tile.tempMapPointerHi
	adc #0
	sta tile.tempMapPointerHi
if2:
	// -> screen pointer & color RAM pointer
	inc tile.temp1
	inc tile.temp1
	lda tile.temp1
	cmp #40
	beq if3
	:c64_addConstToMem(2, tile.screenPointerLo)
	:c64_addConstToMem(2, tile.colorRamPointerLo)
	jmp if4
if3:
	inc tile.temp2
	inc tile.temp2
	lda #$00
	sta tile.temp1
	:c64_addConstToMem(42, tile.screenPointerLo)
	:c64_addConstToMem(42, tile.colorRamPointerLo)
if4:
	lda tile.temp2
	cmp #SCREEN_HEIGHT
	beq if5
	jmp drawRow
if5:
	
	rts
}
	
clearScreen: {
	:c64_clearScreen(SCREEN_0_MEM, $20)
	:c64_clearScreen(SCREEN_1_MEM, $20)
	:c64_clearScreen(SCREEN_2_MEM, $20)
	rts
}	

handleJoyA: {
	lda cia.CIA1_DATA_PORT_A
	sta tile.temp0
	lda #cia.JOY_DOWN
	and tile.temp0
	bne checkUp
	inc tile.mapPositionYTile
	:c64_addConstToMem(16, tile.rasterOffset)
checkUp:
	lda #cia.JOY_UP
	and tile.temp0
	bne checkLeft
	dec tile.mapPositionYTile
	:c64_subConstFromMem(16, tile.rasterOffset)
checkLeft:
	lda #cia.JOY_LEFT
	and tile.temp0
	bne checkRight
	dec tile.mapPositionXTile
checkRight:
	lda #cia.JOY_RIGHT
	and tile.temp0
	bne next3
	inc tile.mapPositionXTile
next3:
	jsr displayMap
	jsr displayDashboardVars
next4:
	rts
}

handleJoyB: {
	lda cia.CIA1_DATA_PORT_B
	sta tile.temp0
	lda #cia.JOY_DOWN
	and tile.temp0
	bne next0
	
	:incrementBits(%111, vic.CONTROL_1)
	
next0:
	lda #cia.JOY_UP
	and tile.temp0
	bne next1
	:decrementBits(%111, vic.CONTROL_1)
next1:
	lda #cia.JOY_LEFT
	and tile.temp0
	bne next2
	:incrementBits(%111, vic.CONTROL_2)
next2:
	lda #cia.JOY_RIGHT
	and tile.temp0
	bne next3
	:decrementBits(%111, vic.CONTROL_2)
next3:
	rts
}

irqPlayfield: {
	:vic_IRQ_ENTER()
	:cia_setVICBank(vic.BANK_2)
	:vic_configureTextMemory(0, 4)
	:vic_setMultiColorText(1)
	dec vic.BORDER_COL
	lda #0
	sta tile.color2SwitchPosition
nextCol:
	:tile_nextColor2Switch()
	lda tile.nextColor2
	cmp #$FF
	beq fireDashboard
	:copyWord(tile.nextTileSwitchingColor2Lo, tile.nextRasterSwitchingColorLo)
	:c64_subMemFromMem(tile.rasterOffset, tile.nextRasterSwitchingColorLo)
	bmi nextCol
	:copyWord(tile.nextRasterSwitchingColorLo, tile.currentRasterTemp)
	:c64_subConstFromMem(DASHBOARD_RASTER, tile.currentRasterTemp)
	bpl fireDashboard
	:vic_IRQ_EXIT(irqSwitchColor, tile.nextRasterSwitchingColorLo, true)
fireDashboard:
	:vic_IRQ_EXIT(irqDashboard, DASHBOARD_RASTER, false)
}

irqSwitchColor: {
	:vic_IRQ_ENTER()
	lda tile.nextColor2
	sta vic.BG_COL_2
	lda tile.nextColor0
	sta vic.BG_COL_0
nextCol:
	:tile_nextColor2Switch()
	lda tile.nextColor2
	cmp #$FF
	beq fireDashboard
	:copyWord(tile.nextTileSwitchingColor2Lo, tile.nextRasterSwitchingColorLo)
	:c64_subMemFromMem(tile.rasterOffset, tile.nextRasterSwitchingColorLo)
	bmi nextCol
	:copyWord(tile.nextRasterSwitchingColorLo, tile.currentRasterTemp)
	:c64_subConstFromMem(DASHBOARD_RASTER, tile.currentRasterTemp)
	bpl fireDashboard
	:vic_IRQ_EXIT(irqSwitchColor, tile.nextRasterSwitchingColorLo, true)
fireDashboard:
	:vic_IRQ_EXIT(irqDashboard, DASHBOARD_RASTER, false)
}

irqDashboard: {
	:vic_IRQ_ENTER()
	:vic_setMultiColorText(0)
	:vic_configureTextMemory(1, 3)
	:cia_setVICBank(vic.BANK_0)
	lda #BLACK
	sta vic.BG_COL_0
	inc vic.BORDER_COL
	:vic_IRQ_EXIT(irqPlayfield, PLAYFIELD_RASTER, false)
}

irqFreeze: {
	rti
}

displayDashboard: {
	:vic_outText(dashboardLabel, SCREEN_2_MEM, 0, 20, LIGHT_GREY)
	jsr displayDashboardVars
	rts
}

displayDashboardVars: {
	:vic_outByteHex(tile.mapPositionXTile, SCREEN_2_MEM, 11, 21, WHITE)
	:vic_outByteHex(tile.mapPositionYTile, SCREEN_2_MEM, 15, 21, WHITE)
	:vic_outByteHex(tile.mapStructurePointerHi, SCREEN_2_MEM, 32, 20, WHITE)
	:vic_outByteHex(tile.mapStructurePointerLo, SCREEN_2_MEM, 34, 20, WHITE)
	:vic_outByteHex(tile.tilePointerHi, SCREEN_2_MEM, 32, 21, WHITE)
	:vic_outByteHex(tile.tilePointerLo, SCREEN_2_MEM, 34, 21, WHITE)
	:vic_outByteHex(tile.tileAttributePointerHi, SCREEN_2_MEM, 32, 22, WHITE)
	:vic_outByteHex(tile.tileAttributePointerLo, SCREEN_2_MEM, 34, 22, WHITE)
	:vic_outByteHex(tile.mapPointerHi, SCREEN_2_MEM, 32, 23, WHITE)
	:vic_outByteHex(tile.mapPointerLo, SCREEN_2_MEM, 34, 23, WHITE)
	:vic_outByteHex(tile.color2SwitchTablePointerHi, SCREEN_2_MEM, 32, 24, WHITE)
	:vic_outByteHex(tile.color2SwitchTablePointerLo, SCREEN_2_MEM, 34, 24, WHITE)
	:vic_outByteHex(tile.mapWidth, SCREEN_2_MEM, 11, 22, WHITE)
	:vic_outByteHex(tile.mapHeight, SCREEN_2_MEM, 15, 22, WHITE)
	rts
}

dashboardLabel:
	.text "                           MSD:$____    "
	.text " Tile X,Y:$__,$__          TSD:$____    "
	.text " Map  W,H:$__,$__          TAD:$____    "
	.text "                           MAP:$____  by"
	.text "Use joy 2 to scroll        CST:$____  mm"
	.byte $FF

// various macros
.macro incrementBits(mask, address) {
	lda address
	and #mask
	sta tile.temp1
	inc tile.temp1
	lda tile.temp1
	and #mask
	sta tile.temp1
	lda address
	and #[mask ^ $FF]
	ora tile.temp1
	sta address
}
.macro decrementBits(mask, address) {
	lda address
	and #mask
	sta tile.temp1
	dec tile.temp1
	lda tile.temp1
	and #mask
	sta tile.temp1
	lda address
	and #[mask ^ $FF]
	ora tile.temp1
	sta address
}
