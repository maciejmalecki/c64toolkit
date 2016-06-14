.import source "../../../common/src/asm/c64common.asm"
.import source "../../../common/src/asm/vic.asm"
.import source "../../../common/src/asm/cia.asm"
.import source "../../../common/src/asm/tiled4x4Background.asm"
.import source "level4x4.asm"


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
.var charset = LoadBinary("../gfx/charset4x4.bin")
.pc = CHARSET_0_MEM	"Charset"; .fill charset.getSize(), charset.get(i)

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
	jmp loop
}

initializeMap: {
	ldx #$00
	ldy #$30
	jsr t44.initializeMap4x4
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
	vic_setRaster(DASHBOARD_RASTER)
	lda #<irqDashboard
	sta $FFFE
	lda #>irqDashboard
	sta $FFFF
	lda #<irqFreeze
	sta $FFFA
	lda #>irqFreeze
	sta $FFFB

	:configureMemory(%101)
	:cia_setVICBank(vic.BANK_2)
	:vic_setMultiColorText(1)
	:vic_configureTextMemory(0, 1)
	cli
	
	lda vic.CONTROL_2
	and #11110111
	sta vic.CONTROL_2
	// configure colors
	lda #WHITE
	sta vic.BORDER_COL
	lda #LIGHT_BLUE
	sta vic.BG_COL_0
	lda #GREY
	sta vic.BG_COL_1
	lda #GREEN
	sta vic.BG_COL_2
	rts
	
displayMap: {
	:set16(SCREEN_0_MEM, t44.screen0)
	jsr t44.displayMap4x4
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
	sta c64.temp0
	lda #cia.JOY_DOWN
	and c64.temp0
	bne checkUp
	inc t44.mapY + 1
checkUp:
	lda #cia.JOY_UP
	and c64.temp0
	bne checkLeft
	dec t44.mapY + 1
checkLeft:
	lda #cia.JOY_LEFT
	and c64.temp0
	bne checkRight
	dec t44.mapX + 1
checkRight:
	lda #cia.JOY_RIGHT
	and c64.temp0
	bne next3
	inc t44.mapX + 1
next3:
!:	lda vic.RASTER
	cmp #150
	bne !-
	inc vic.BORDER_COL
	jsr displayMap
	dec vic.BORDER_COL
	jsr displayDashboardVars
next4:
	rts
}

irqPlayfield: {
	:vic_IRQ_ENTER()
	:cia_setVICBank(vic.BANK_2)
	:vic_configureTextMemory(0, 4)
	:vic_setMultiColorText(1)
	dec vic.BORDER_COL
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
	:vic_outByteHex(t44.mapX + 1, SCREEN_2_MEM, 11, 21, WHITE)
	:vic_outByteHex(t44.mapY + 1, SCREEN_2_MEM, 15, 21, WHITE)
	:vic_outByteHex(t44.mapStructPtr + 1, SCREEN_2_MEM, 32, 20, WHITE)
	:vic_outByteHex(t44.mapStructPtr, SCREEN_2_MEM, 34, 20, WHITE)
	:vic_outByteHex(t44.tileDefPtr + 1, SCREEN_2_MEM, 32, 21, WHITE)
	:vic_outByteHex(t44.tileDefPtr, SCREEN_2_MEM, 34, 21, WHITE)
	:vic_outByteHex(t44.tileAttrDefPtr + 1, SCREEN_2_MEM, 32, 22, WHITE)
	:vic_outByteHex(t44.tileAttrDefPtr, SCREEN_2_MEM, 34, 22, WHITE)
	:vic_outByteHex(t44.mapDefPtr + 1, SCREEN_2_MEM, 32, 23, WHITE)
	:vic_outByteHex(t44.mapDefPtr, SCREEN_2_MEM, 34, 23, WHITE)
//	:vic_outByteHex(tile.color2SwitchTablePointerHi, SCREEN_2_MEM, 32, 24, WHITE)
//	:vic_outByteHex(tile.color2SwitchTablePointerLo, SCREEN_2_MEM, 34, 24, WHITE)
	:vic_outByteHex(t44.mapWidth, SCREEN_2_MEM, 11, 22, WHITE)
	:vic_outByteHex(t44.mapHeight, SCREEN_2_MEM, 15, 22, WHITE)
	rts
}

dashboardLabel:
	.text "                           STR:$____    "
	.text " Tile X,Y:$__,$__          TIL:$____    "
	.text " Map  W,H:$__,$__          TAD:$____    "
	.text "                           MAP:$____  by"
	.text "Use joy 2 to scroll        CST:$____  mm"
	.byte $FF
