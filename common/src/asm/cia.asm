.importonce
.filenamespace cia

.label CIA1_BASE 			= $DC00 
.label CIA2_BASE 			= $DD00
.label CIA1_DATA_PORT_A 	= CIA1_BASE + 0
.label CIA1_DATA_PORT_B		= CIA1_BASE + 1
.label CIA2_DATA_PORT_A 	= CIA2_BASE + 0

.label JOY_UP 				= %00001
.label JOY_DOWN 			= %00010
.label JOY_LEFT 			= %00100
.label JOY_RIGHT 			= %01000
.label JOY_FIRE 			= %10000

.macro @cia_setVICBank(bank) {
	lda cia.CIA2_DATA_PORT_A
	and #%11111100
	ora #[bank & %00000011]
	sta cia.CIA2_DATA_PORT_A
}
