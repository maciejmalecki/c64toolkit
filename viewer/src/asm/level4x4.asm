.import source "../../../common/src/asm/tiled4x4Background.asm"

/*
 * Map 0 definition.
 */
.var ts0 = LoadBinary("../gfx/tileset4x4.bin")
.var ta0 = LoadBinary("../gfx/tilesetAttributes4x4.bin")
.var md0 = LoadBinary("../gfx/map4x4.bin")

.pc = $3000 "MapStruct"

map0:
	.byte 	0			// control
	.byte 	20			// width
	.byte 	10			// height
	.byte	GREY		// color 2
	.byte	4			// charset number
	.word	t44.HEADER_SIZE + ts0.getSize()	// tile attr def offset
	.word 	t44.HEADER_SIZE + ts0.getSize() + ta0.getSize()	// map def offset
	.word	t44.HEADER_SIZE + ts0.getSize() + ta0.getSize() + md0.getSize()	// map entry def offset
	.word	t44.HEADER_SIZE + ts0.getSize() + ta0.getSize() + md0.getSize() + 0 // color 2 switch table offset (TODO)
	.fill 	ts0.getSize(), ts0.get(i)
	.fill 	ta0.getSize(), ta0.get(i)
	.fill 	md0.getSize(), md0.get(i)
