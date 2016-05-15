.import source "../../../common/src/asm/tiledBackground.asm"

.pc = tile.MAP_POINTERS "Map pointers"
	.word map0

/*
 * Map 0 definition.
 */
.var ts0 = LoadBinary("../gfx/tileset.bin")
.var ta0 = LoadBinary("../gfx/tilesetAttributes.bin")
.var md0 = LoadBinary("../gfx/map.bin")
map0:
	.byte 	0			// control
	.byte 	40			// width
	.byte 	40			// height
	.byte	DARK_GREY	// color 0
	.byte	LIGHT_GREY	// color 1
	.byte	LIGHT_BLUE	// color 2
	.byte	4			// charset number
	.word	tile.HEADER_SIZE + ts0.getSize()	// tile attr def offset
	.word 	tile.HEADER_SIZE + ts0.getSize() + ta0.getSize()	// map def offset
	.word	tile.HEADER_SIZE + ts0.getSize() + ta0.getSize() + md0.getSize()	// map entry def offset
	.fill 	ts0.getSize(), ts0.get(i)
	.fill 	ta0.getSize(), ta0.get(i)
	.fill 	md0.getSize(), md0.get(i)
