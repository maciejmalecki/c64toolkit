 *** Theoretical foundation of multidimensional background scrolling ***
               for Commodore 64 Personal Computer.
 
                  by Maciej Malecki, May, 2016
                  
1. Assumptions

a) Free scrolling in both X and Y directions.
b) Usage of two frames and double buffered screens
c) 4x4 tile size
d) separate color per tile
e) BG color 0 and BG color 1 raster based swithing (at tile granularity)
f) ready to use with sprite multiplexing routine
g) at least 20 lines of scrollable playfield supported
h) up to 4 pixel / frame scrolling speed supported in both directions

2. Data structures

$0000	byte	*Control* byte reserved for future use, should contain $00
$0001	byte	*Width* of the map (in tiles)  
$0002	byte	*Height* of the map (in tiles)
$0003	byte	*Background Color 2* which is fixed for whole map
$0004	byte	*Charset Number* of the bank which will be used for rendering maps
$0005	word	Tile attribute definition offset
$0007	word	Map definition offset
$0009	word	Map entry definition offset
$000B	word	Color switch table offset
 
Color switch table

This table is used to alternate BG_COL_0 and BG_COL_1 using raster interrupt. Table 
end is marked with $FFFF. Each table row is four bytes: first word denotes raster 
position of the map, next byte denotes color 0, last byte specifies color 1.

3. Zero page variables

MapX		word	Leftmost position of the map relatively to the viewport. Hi byte 
					for tile number, Lo byte for pixels
MapY		word	Topmost position of the map relatively to the viewport
Screen0		word	Screen0 pointer
Screen1		word	Screen1 pointer

