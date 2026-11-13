class_name BoardArt
extends RefCounted
## Art for the science boards (docs/TABLES_SCIENCE.md), all drawn in code:
##
##   DECALS       a faint line drawing on the felt for each of the 40 boards, in
##                IconArt.paint's little script (about +-50 units; TableView draws
##                it at 6% white, scaled 4.6)
##   FELTS        each board's felt colour; RAILS, which boards get a textured rail
##   draw_shark   the six Sharks, seen from above, normal, hit or knocked out
##   draw_*       the moving parts: Sweeper, pendulum bob, shuttle post,
##                turntable, conveyor, Maxwell's Demon, see-saw, charged rail
##   draw_rail    the six rail materials
##
## Everything takes a CanvasItem to draw on, so the table view (or a preview)
## calls these from its own _draw. tools/board_preview.gd renders every piece
## into docs/table-art/.

const DECALS := {
	"local": "",   # The Local
	"benzene": "o 35 20 0 40 -35 20 -35 -20 0 -40 35 -20 35 20;c 0 0 24;l 35 20 47 27;l 0 40 0 54;l -35 20 -47 27;l -35 -20 -47 -27;l 0 -40 0 -54;l 35 -20 47 -27",   # Benzene Ring
	"hypotenuse": "o -30 26 30 26 -30 -18 -30 26;o -30 18 -22 18 -22 26;t 4 44 14 a² + b² = c²",   # The Hypotenuse
	"venturi": "o -50 -48 -45 -42 -40 -36 -35 -32 -30 -28 -25 -24 -20 -21 -15 -19 -10 -17 -5 -16 0 -16 5 -16 10 -17 15 -19 20 -21 25 -24 30 -28 35 -32 40 -36 45 -42 50 -48;o -50 -24 -45 -21 -40 -18 -35 -16 -30 -14 -25 -12 -20 -11 -15 -9 -10 -9 -5 -8 0 -8 5 -8 10 -9 15 -9 20 -11 25 -12 30 -14 35 -16 40 -18 45 -21 50 -24;o -50 24 -45 21 -40 18 -35 16 -30 14 -25 12 -20 11 -15 9 -10 9 -5 8 0 8 5 8 10 9 15 9 20 11 25 12 30 14 35 16 40 18 45 21 50 24;o -50 48 -45 42 -40 36 -35 32 -30 28 -25 24 -20 21 -15 19 -10 17 -5 16 0 16 5 16 10 17 15 19 20 21 25 24 30 28 35 32 40 36 45 42 50 48;l -40 -20 -28 -20;l -40 0 -28 0;l -40 20 -28 20;l -6 0 10 0",   # Venturi
	"erbridge": "o -12 -40 -12 -39 -14 -38 -16 -37 -19 -36 -23 -36 -27 -35 -31 -35 -35 -35 -39 -36 -42 -36 -45 -37 -47 -38 -48 -39 -48 -41 -47 -42 -45 -43 -42 -44 -39 -44 -35 -45 -31 -45 -27 -45 -23 -44 -19 -44 -16 -43 -14 -42 -12 -41 -12 -40 -12 -40;o -12 -40 -13 -37 -15 -34 -16 -31 -17 -28 -18 -25 -20 -21 -21 -18 -22 -15 -23 -12 -25 -9 -26 -6;o -48 -40 -47 -37 -45 -34 -44 -31 -43 -28 -42 -25 -40 -21 -39 -18 -38 -15 -37 -12 -35 -9 -34 -6;o 48 40 48 41 46 42 44 43 41 44 37 44 33 45 29 45 25 45 21 44 18 44 15 43 13 42 12 41 12 39 13 38 15 37 18 36 21 36 25 35 29 35 33 35 37 36 41 36 44 37 46 38 48 39 48 40 48 40;o 48 40 47 37 45 34 44 31 43 28 42 25 40 21 39 18 38 15 37 12 35 9 34 6;o 12 40 13 37 15 34 16 31 17 28 18 25 20 21 21 18 22 15 23 12 25 9 26 6;o -30 -6 -26 -4 -22 -2 -18 0 -14 2 -10 3 -6 5 -2 6 2 6 6 7 10 7 14 7 18 7 22 7 26 6 30 6",   # Einstein–Rosen Bridge
	"parlor": "o 0 -44 12 -14 44 -14 18 8 28 40 0 20 -28 40 -18 8 -44 -14 -12 -14 0 -44",   # Pinball Parlor
	"blackice": "l 0 -40 0 40;l -35 -20 35 20;l -35 20 35 -20;o -5 33 0 26 5 33;o -30 12 -23 13 -26 20;o -26 -20 -23 -13 -30 -12;o 5 -33 0 -26 -5 -33;o 30 -12 23 -13 26 -20;o 26 20 23 13 30 12",   # Superfluid
	"parabolic": "o -4 -40 2 -37 8 -33 14 -30 18 -27 22 -23 26 -20 29 -17 32 -13 34 -10 35 -7 36 -3 36 0 36 3 35 7 34 10 32 13 29 17 26 20 22 23 18 27 14 30 8 33 2 37 -4 40;C 16 0 4;l -46 -28 16 -28;l 16 -28 16 0;l -46 -14 31 -14;l 31 -14 16 0;l -46 14 31 14;l 31 14 16 0;l -46 28 16 28;l 16 28 16 0",   # Parabolic Mirror
	"whisper": "o 46 0 45 4 44 9 41 13 37 17 32 20 26 23 20 25 13 27 6 28 -2 28 -9 27 -16 26 -23 24 -29 22 -34 19 -39 15 -42 11 -45 7 -46 2 -46 -2 -45 -7 -42 -11 -39 -15 -34 -19 -29 -22 -23 -24 -16 -26 -9 -27 -2 -28 6 -28 13 -27 20 -25 26 -23 32 -20 37 -17 41 -13 44 -9 45 -4 46 0 46 0;C -36 0 3;C 36 0 3;l -36 0 6 27;l 6 27 36 0",   # Whispering Gallery
	"membrane": "o -8 -46 -6 -43 -3 -40 2 -36 5 -33 8 -30 8 -27 6 -24 2 -21 -2 -17 -6 -14 -8 -11 -8 -8 -6 -5 -2 -2 2 2 6 5 8 8 8 11 6 14 2 17 -2 21 -6 24 -8 27 -8 30 -5 33 -2 36 3 40 6 43 8 46;c -3 -40 3;c 6 -24 3;c -8 -8 3;c 8 8 3;c -6 24 3;c 3 40 3;l -34 0 -10 0;o -16 -6 -10 0 -16 6",   # Semipermeable Membrane
	"spring_st": "l -46 0 -8 0;l -8 -22 -8 22;l 8 -22 8 22;l 8 0 46 0;t -20 -32 14 +;t 20 -32 14 −",   # Capacitor
	"magnet": "o 48 0 47 4 46 8 43 12 40 16 36 19 31 21 25 23 19 25 13 26 6 26 0 25 -6 24 -12 23 -17 20 -22 17 -26 14 -29 10 -31 6 -32 2 -32 -2 -31 -6 -29 -10 -26 -14 -22 -17 -17 -20 -12 -23 -6 -24 0 -25 6 -26 13 -26 19 -25 25 -23 31 -21 36 -19 40 -16 43 -12 46 -8 47 -4 48 0 48 0;C -24 0 7;C 48 0 4",   # Kepler Orbit
	"drift": "o 6 0 6 2 5 4 4 6 2 7 0 8 -2 8 -5 7 -7 5 -9 3 -10 0 -10 -3 -9 -6 -7 -8 -4 -10 -1 -12 3 -12 7 -10 10 -8 12 -5 13 -1 13 3 12 7 10 11 6 14 1 15 -3 15 -8 14 -12 11 -15 7;o -3 5 -5 4 -6 3 -7 1 -7 -1 -7 -4 -6 -6 -4 -8 -1 -9 2 -9 5 -9 7 -7 9 -5 11 -2 11 2 10 5 9 8 6 11 2 13 -2 13 -6 12 -9 10 -12 7 -14 3 -15 -2 -14 -6 -12 -11 -8 -14 -3 -16 2 -17;o -3 -5 -1 -6 1 -7 3 -7 5 -6 7 -4 8 -2 9 1 8 3 7 6 5 8 3 10 -1 10 -4 10 -7 9 -10 6 -12 3 -12 0 -12 -4 -10 -8 -8 -11 -4 -13 0 -14 5 -14 9 -12 12 -9 15 -5 16 0 16 5 14 10;c 0 0 5",   # Coriolis
	"tilted": "l -46 0 46 0;o -40 -40 0 0;o 0 0 22 40;a 0 0 14 225 270;a 0 0 18 60 90",   # Snell's Law
	"posts": "o -50 0 -48 15 -45 25 -42 25 -40 15 -38 0 -35 -15 -32 -25 -30 -25 -28 -15 -25 0 -22 15 -20 25 -18 25 -15 15 -12 0 -10 -15 -8 -25 -5 -25 -2 -15 0 0 2 15 5 25 8 25 10 15 12 0 15 -15 18 -25 20 -25 22 -15 25 0 28 15 30 25 32 25 35 15 38 0 40 -15 42 -25 45 -25 48 -15 50 0;l -50 0 50 0",   # Harmonic Oscillator
	"smoke": "o -40 10 -30 -14 -22 10;o -6 14 4 -22 14 14;o 26 10 34 -10 42 10;o -50 26 -47 24 -43 21 -40 20 -36 21 -33 23 -29 26 -26 28 -22 28 -19 26 -16 24 -12 21 -9 20 -5 21 -2 23 2 25 5 27 9 28 12 27 16 24 19 22 22 20 26 20 29 22 33 25 36 27 40 28 43 27 47 24 50 22",   # Lotka–Volterra
	"cramped": "o -40 -34 40 -34 40 34 -40 34 -40 -34;l -24 -34 -24 34;l -8 -34 -8 34;l 8 -34 8 34;l 24 -34 24 34;l -40 0 40 0",   # Faraday Cage
	"lshell": "C 0 0 6;c 0 0 18;c 0 0 32;c 0 0 46;C 18 0 3;C -16 15 3;C 0 -32 3;C 32 0 3;C -23 23 3;C -32 -2 3",   # The L-Shell
	"pentagon": "o 0 -38 40 -9 25 38 -25 38 -40 -9 0 -38;o 0 -38 25 38 -40 -9 40 -9 -25 38 0 -38",   # Golden Pentagon
	"sierpinski": "o 0 -40 10 -23 -10 -23 0 -40;o -10 -23 0 -6 -20 -6 -10 -23;o 10 -23 20 -6 0 -6 10 -23;o -20 -6 -10 12 -30 12 -20 -6;o -30 12 -20 29 -40 29 -30 12;o -10 12 0 29 -20 29 -10 12;o 20 -6 30 12 10 12 20 -6;o 10 12 20 29 0 29 10 12;o 30 12 40 29 20 29 30 12",   # Sierpinski Triangle
	"mobius": "o 0 6 5 9 11 11 16 13 20 15 25 15 29 15 32 14 35 12 37 10 39 6 40 3 40 -1 39 -5 38 -8 36 -11 34 -13 31 -15 27 -15 23 -15 18 -14 13 -12 8 -10 3 -7 -3 -5 -8 -2 -13 1 -18 4 -23 5 -27 6 -31 7 -34 7 -36 6 -38 4 -39 3 -40 1 -40 -2 -39 -4 -37 -5 -35 -6 -32 -7 -29 -7 -25 -6 -20 -4 -16 -2 -11 0 -5 3 0 6 0 6;o 0 -4 5 -2 9 0 13 2 17 4 21 5 24 5 27 5 30 5 32 4 33 3 34 1 34 0 34 -2 32 -3 31 -4 29 -5 26 -5 23 -5 19 -4 15 -3 11 -1 7 1 2 3 -2 5 -7 7 -11 9 -15 10 -19 11 -23 11 -26 10 -29 9 -31 8 -32 6 -34 3 -34 1 -34 -2 -33 -5 -32 -7 -30 -9 -27 -10 -24 -11 -21 -11 -17 -10 -13 -9 -9 -8 -5 -6 0 -4 0 -4",   # Möbius Strip
	"maxwell": "l 0 -46 0 -12;l 0 12 0 46;a 0 0 12 -90 90;c -14 -26 6;o -18 -32 -16 -38 -14 -32;o -12 -32 -10 -38 -8 -32;o -14 -20 -14 -6 -20 2;l -30 20 -14 20;l 14 20 34 20;o 28 14 34 20 28 26",   # Maxwell's Demon
	"chain": "a 0 0 40 -120 -60;a 0 0 14 -120 -60;l -7 -12 -20 -35;l 7 -12 20 -35;a 0 0 40 0 60;a 0 0 14 0 60;l 14 0 40 0;l 7 12 20 35;a 0 0 40 120 180;a 0 0 14 120 180;l -7 12 -20 35;l -14 0 -40 0;C 0 0 6",   # Chain Reaction
	"closing": "l -44 -36 -44 36;l -44 36 46 36;o -44 -32 -41 -24 -38 -18 -35 -12 -32 -6 -28 -1 -25 3 -22 7 -19 10 -16 13 -13 15 -10 18 -7 20 -4 22 -1 23 3 25 6 26 9 27 12 28 15 29 18 30 21 30 24 31 27 32 30 32 34 33 37 33 40 33 43 34 46 34;l -26 32 -26 40;l -8 32 -8 40;l 10 32 10 40;l 28 32 28 40",   # Radioactive Decay
	"lorentz": "o -48 -23 -44 -23 -40 -22 -35 -22 -31 -23 -27 -24 -23 -25 -19 -27 -15 -29 -10 -30 -6 -32 -2 -33 2 -34 6 -34 10 -34 15 -33 19 -32 23 -30 27 -28 31 -27 35 -25 40 -24 44 -23 48 -22;o -48 -8 -44 -9 -40 -10 -35 -12 -31 -13 -27 -15 -23 -17 -19 -18 -15 -19 -10 -20 -6 -20 -2 -19 2 -19 6 -17 10 -16 15 -14 19 -12 23 -10 27 -9 31 -8 35 -8 40 -8 44 -9 48 -10;o -48 2 -44 0 -40 -2 -35 -3 -31 -5 -27 -6 -23 -6 -19 -6 -15 -5 -10 -4 -6 -3 -2 -1 2 1 6 3 10 4 15 5 19 6 23 6 27 6 31 5 35 3 40 2 44 0 48 -2;o -48 10 -44 9 -40 8 -35 8 -31 8 -27 9 -23 10 -19 12 -15 14 -10 16 -6 17 -2 19 2 19 6 20 10 20 15 19 19 18 23 17 27 15 31 13 35 12 40 10 44 9 48 8;o -48 22 -44 23 -40 24 -35 25 -31 27 -27 28 -23 30 -19 32 -15 33 -10 34 -6 34 -2 34 2 33 6 32 10 30 15 29 19 27 23 25 27 24 31 23 35 22 40 22 44 23 48 23;o 36 -18 42 -9 36 -6;o 36 10 42 9 36 22",   # Lorentz Field
	"two": "t 0 0 70 Ψ",   # Quantum Pockets
	"foucault": "l 0 -46 -24 26;l 0 -46 0 30;l 0 -46 24 26;c 0 34 6;a 0 -46 74 60 120;C 0 -46 3",   # Foucault's Pendulum
	"sinkhole": "o 46 0 45 2 44 4 41 7 37 8 32 10 26 12 20 13 13 13 6 14 -2 14 -9 14 -16 13 -23 12 -29 11 -34 9 -39 7 -42 5 -45 3 -46 1 -46 -1 -45 -3 -42 -5 -39 -7 -34 -9 -29 -11 -23 -12 -16 -13 -9 -14 -2 -14 6 -14 13 -13 20 -13 26 -12 32 -10 37 -8 41 -7 44 -4 45 -2 46 0 46 0;o 30 0 29 2 28 4 25 5 21 7 16 8 10 8 5 9 -2 9 -8 9 -13 8 -18 7 -23 6 -26 4 -29 3 -30 1 -30 -1 -29 -3 -26 -4 -23 -6 -18 -7 -13 -8 -8 -9 -2 -9 5 -9 10 -8 16 -8 21 -7 25 -5 28 -4 29 -2 30 0 30 0;C 0 0 9",   # Event Horizon
	"elements": "c 0 0 44;C 0 0 3;l 0 0 0 -30;l 0 0 20 8;l 0 -32 0 -42;l 18 -31 21 -36;l 31 -18 36 -21;l 32 0 42 0;l 31 18 36 21;l 18 31 21 36;l 0 32 0 42;l -18 31 -21 36;l -31 18 -36 21;l -32 0 -42 0;l -31 -18 -36 -21;l -18 -31 -21 -36",   # The Clockwork Table
	"final": "o -46 -20 46 -20;o -46 20 46 20;o -42 -20 -35 -6 -28 -20;o -35 20 -28 6 -21 20;o -28 -20 -21 -6 -14 -20;o -21 20 -14 6 -7 20;o -14 -20 -7 -6 0 -20;o -7 20 0 6 7 20;o 0 -20 7 -6 14 -20;o 7 20 14 6 21 20;o 14 -20 21 -6 28 -20;o 21 20 28 6 35 20;o 28 -20 35 -6 42 -20;o 35 20 42 6 49 20;o 42 -20 49 -6 56 -20;o 49 20 56 6 63 20",   # Apex Predator
	"galton": "o -48 30 -45 30 -41 30 -38 29 -35 29 -31 28 -28 26 -25 23 -22 18 -18 12 -15 5 -12 -3 -8 -10 -5 -16 -2 -20 2 -20 5 -16 8 -10 12 -3 15 5 18 12 22 18 25 23 28 26 31 28 35 29 38 29 41 30 45 30 48 30;C 0 -44 2;C -7 -34 2;C 7 -34 2;C -14 -24 2;C 0 -24 2;C 14 -24 2;C -21 -14 2;C -7 -14 2;C 7 -14 2;C 21 -14 2",   # Galton Board
	"spiral": "o 2 0 2 0 2 1 2 1 2 2 2 2 2 2 1 3 1 3 0 3 0 4 -1 4 -1 4 -2 4 -3 3 -3 3 -4 3 -5 2 -5 1 -6 1 -6 0 -6 -1 -6 -2 -6 -3 -5 -5 -5 -6 -4 -7 -3 -8 -2 -8 -1 -9 1 -10 2 -10 4 -10 6 -9 8 -9 9 -8 11 -6 13 -5 14 -3 15 -1 15 2 16 4 16 7 15 10 14 13 12 16 10 18 7 21 4 23 1 24 -3 25 -8 25 -12 25 -17 24 -21 22 -26 19 -30 16 -34 11 -37 6 -39 0",   # Golden Spiral
	"tesla": "o -6 -46 8 -12 -4 -10 10 26 -2 22 6 46;o -26 -30 -16 -10 -28 -2 -18 22;o 24 -30 32 -12 22 -4 34 18",   # Tesla Coil
	"gulf": "l -46 -24 30 -24;o 24 -30 32 -24 24 -18;l -46 0 30 0;o 24 -6 32 0 24 6;l -46 24 30 24;o 24 18 32 24 24 30",   # Gulf Stream
	"meissner": "o -20 -26 20 -26 20 -10 -20 -10 -20 -26;l -46 22 46 22;o -30 -18 -33 -14 -36 -11 -38 -7 -40 -3 -41 0 -41 4 -40 7 -38 11 -36 15 -33 18 -30 22;o -20 -18 -23 -14 -26 -11 -28 -7 -30 -3 -31 0 -31 4 -30 7 -28 11 -26 15 -23 18 -20 22;o 20 -18 23 -14 26 -11 28 -7 30 -3 31 0 31 4 30 7 28 11 26 15 23 18 20 22;o 30 -18 33 -14 36 -11 38 -7 40 -3 41 0 41 4 40 7 38 11 36 15 33 18 30 22",   # Meissner Effect
	"tectonic": "o -10 -46 4 -20 -6 0 8 22 -2 46;o -34 -12 -24 -12 -28 -4;o 24 12 34 12 30 4;l -40 30 -18 30;l 18 -30 40 -30",   # Tectonic Plates
	"lattice": "C -54 -30 2;l -51 -30 -39 -30;l -52 -27 -46 -18;C -45 -15 2;l -42 -15 -30 -15;l -44 -12 -38 -3;C -36 0 2;l -33 0 -21 0;l -34 3 -28 12;C -27 15 2;l -24 15 -12 15;l -26 18 -20 27;C -18 30 2;l -15 30 -3 30;C -36 -30 2;l -33 -30 -21 -30;l -34 -27 -28 -18;C -27 -15 2;l -24 -15 -12 -15;l -26 -12 -20 -3;C -18 0 2;l -15 0 -3 0;l -16 3 -10 12;C -9 15 2;l -6 15 6 15;l -8 18 -2 27;C 0 30 2;l 3 30 15 30;C -18 -30 2;l -15 -30 -3 -30;l -16 -27 -10 -18;C -9 -15 2;l -6 -15 6 -15;l -8 -12 -2 -3;C 0 0 2;l 3 0 15 0;l 2 3 8 12;C 9 15 2;l 12 15 24 15;l 10 18 16 27;C 18 30 2;l 21 30 33 30;C 0 -30 2;l 3 -30 15 -30;l 2 -27 8 -18;C 9 -15 2;l 12 -15 24 -15;l 10 -12 16 -3;C 18 0 2;l 21 0 33 0;l 20 3 26 12;C 27 15 2;l 30 15 42 15;l 28 18 34 27;C 36 30 2;l 39 30 51 30;C 18 -30 2;l 20 -27 26 -18;C 27 -15 2;l 28 -12 34 -3;C 36 0 2;l 38 3 44 12;C 45 15 2;l 46 18 52 27;C 54 30 2",   # Crystal Lattice
	"stellated": "o 0 -46 13 -23 40 -23 26 0 40 23 13 23 0 46 -13 23 -40 23 -26 0 -40 -23 -13 -23 0 -46",   # Stellated Star
	"lever": "o -46 -8 46 8;o -10 30 0 6 10 30 -10 30;c -36 -16 6;c 30 -4 9",   # The Lever
	"escape": "C -22 6 7;C 24 -8 9;o -46 40 -42 38 -39 37 -35 35 -32 33 -28 31 -25 30 -21 28 -18 26 -14 25 -11 24 -7 22 -4 21 0 20;o -27 21 -30 20 -33 18 -35 15 -37 12 -38 9 -38 5 -37 2 -36 -2 -34 -4 -32 -7 -29 -9 -25 -10 -22 -10 -18 -10 -15 -8 -12 -7 -10 -4 -8 -1 -6 2 -6 6 -6 9 -7 12 -9 15;o 8 -20 10 -23 13 -25 17 -27 20 -28 24 -28 28 -28 32 -26 35 -25 38 -22 40 -19 42 -16 44 -12 44 -9 44 -5 43 -1 41 2 39 5 36 8 33 10 29 11 25 12 22 12 18 11;o 44 -24 46 -26 48 -27 50 -29",   # Escape Velocity
}
const BOARD_NAMES := {
	"local": "The Local",
	"benzene": "Benzene Ring",
	"hypotenuse": "The Hypotenuse",
	"venturi": "Venturi",
	"erbridge": "Einstein–Rosen Bridge",
	"parlor": "Pinball Parlor",
	"blackice": "Superfluid",
	"parabolic": "Parabolic Mirror",
	"whisper": "Whispering Gallery",
	"membrane": "Semipermeable Membrane",
	"spring_st": "Capacitor",
	"magnet": "Kepler Orbit",
	"drift": "Coriolis",
	"tilted": "Snell's Law",
	"posts": "Harmonic Oscillator",
	"smoke": "Lotka–Volterra",
	"cramped": "Faraday Cage",
	"lshell": "The L-Shell",
	"pentagon": "Golden Pentagon",
	"sierpinski": "Sierpinski Triangle",
	"mobius": "Möbius Strip",
	"maxwell": "Maxwell's Demon",
	"chain": "Chain Reaction",
	"closing": "Radioactive Decay",
	"lorentz": "Lorentz Field",
	"two": "Quantum Pockets",
	"foucault": "Foucault's Pendulum",
	"sinkhole": "Event Horizon",
	"elements": "The Clockwork Table",
	"final": "Apex Predator",
	"galton": "Galton Board",
	"spiral": "Golden Spiral",
	"tesla": "Tesla Coil",
	"gulf": "Gulf Stream",
	"meissner": "Meissner Effect",
	"tectonic": "Tectonic Plates",
	"lattice": "Crystal Lattice",
	"stellated": "Stellated Star",
	"lever": "The Lever",
	"escape": "Escape Velocity",
}


## Felt colour for each board (docs/TABLES_SCIENCE.md, "Felt").
const FELTS := {
	"local": Color(0.06, 0.42, 0.28), "benzene": Color(0.05, 0.4, 0.42), "hypotenuse": Color(0.2, 0.3, 0.45),
	"venturi": Color(0.32, 0.35, 0.38), "erbridge": Color(0.26, 0.14, 0.42), "parlor": Color(0.5, 0.1, 0.12),
	"blackice": Color(0.62, 0.78, 0.88), "parabolic": Color(0.48, 0.5, 0.54), "whisper": Color(0.36, 0.16, 0.34),
	"membrane": Color(0.1, 0.42, 0.34), "spring_st": Color(0.08, 0.12, 0.3), "magnet": Color(0.06, 0.08, 0.22),
	"drift": Color(0.3, 0.32, 0.36), "tilted": Color(0.1, 0.5, 0.52), "posts": Color(0.4, 0.55, 0.12),
	"smoke": Color(0.08, 0.28, 0.5), "cramped": Color(0.14, 0.14, 0.15), "lshell": Color(0.6, 0.3, 0.06),
	"pentagon": Color(0.42, 0.3, 0.1), "sierpinski": Color(0.07, 0.07, 0.08), "mobius": Color(0.08, 0.36, 0.36),
	"maxwell": Color(0.45, 0.06, 0.1), "chain": Color(0.45, 0.52, 0.06), "closing": Color(0.27, 0.3, 0.1),
	"lorentz": Color(0.08, 0.28, 0.66), "two": Color(0.24, 0.1, 0.38), "foucault": Color(0.36, 0.08, 0.14),
	"sinkhole": Color(0.03, 0.03, 0.04), "elements": Color(0.78, 0.74, 0.62), "final": Color(0.42, 0.04, 0.06),
	"galton": Color(0.8, 0.74, 0.58), "spiral": Color(0.6, 0.38, 0.06), "tesla": Color(0.14, 0.08, 0.2),
	"gulf": Color(0.06, 0.24, 0.46), "meissner": Color(0.5, 0.68, 0.82), "tectonic": Color(0.34, 0.24, 0.16),
	"lattice": Color(0.72, 0.52, 0.56), "stellated": Color(0.08, 0.1, 0.26), "lever": Color(0.7, 0.6, 0.4),
	"escape": Color(0.03, 0.03, 0.06),
}

## Rail material per board: the six textured ones are drawn by draw_rail();
## the rest are a plain colour (see LAB_ART in catalog.gd).
const RAILS := {
	"benzene": "chrome", "venturi": "copper", "erbridge": "black_glass", "parabolic": "chrome",
	"sierpinski": "marble", "pentagon": "gilded", "sinkhole": "obsidian", "stellated": "gilded",
	"meissner": "chrome", "cramped": "copper", "tesla": "copper", "escape": "chrome",
}
const RAIL_MATERIALS := ["chrome", "copper", "black_glass", "marble", "gilded", "obsidian"]
## A plain colour for each material, for the parts of a rail that are filled flat
## (a shaped table's frame).
const RAIL_BASE := {"chrome": Color(0.56, 0.59, 0.64), "copper": Color(0.62, 0.32, 0.17), "black_glass": Color(0.06, 0.06, 0.09),
	"marble": Color(0.84, 0.83, 0.79), "gilded": Color(0.7, 0.52, 0.17), "obsidian": Color(0.07, 0.05, 0.09)}


## True when the game's board with this id is the board this art was drawn
## for. Several old boards keep an id that a planned science board will take
## over (the Smoke Room's id is "smoke", the future Lotka–Volterra), so their
## art waits until the board is renamed.
static func same_board(id: String) -> bool:
	return BOARD_NAMES.has(id) and Catalog.BOSSES.has(id) and String(BOARD_NAMES[id]) == String(Catalog.BOSSES[id].name)


## The felt to use for a board: its own colour when it has one and balls stay
## easy to see on it (a light felt such as ivory would hide the cue ball).
static func felt_for(id: String, fallback: Color) -> Color:
	if same_board(id) and FELTS.has(id) and (FELTS[id] as Color).get_luminance() < 0.45:
		return FELTS[id]
	return fallback


static func _h(i: int, k: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(k) * 78.233) * 43758.5453, 1.0)


# --- Sharks ---------------------------------------------------------------------------
# Seen from above, nose along +x. One unit = size / 100 pixels; a shark is about
# 110 units long. state: "normal", "hit" (a white flash, then the colour comes
# back) or "ko" (knocked out: rolled belly-up, pale, with crosses for eyes).
# t drives the tail's swish; health (0-1) fills the Great White's bar.

const SHARKS := ["pool", "sharp", "loan", "hammer", "leech", "white"]
const SHARK_NAMES := {"pool": "Pool Shark", "sharp": "Card Sharp", "loan": "Loan Shark", "hammer": "Hammerhead", "leech": "Leech", "white": "Great White"}


static func draw_shark(ci: CanvasItem, kind: String, pos: Vector2, heading: float, size: float, state := "normal", t := 0.0, health := 1.0, pips := 0) -> void:
	var s := size / 100.0
	var ko := state == "ko"
	var hit := state == "hit"
	var skin := {"pool": Color(0.38, 0.47, 0.56), "sharp": Color(0.27, 0.42, 0.45), "loan": Color(0.13, 0.15, 0.26),
		"hammer": Color(0.42, 0.46, 0.33), "leech": Color(0.42, 0.13, 0.2), "white": Color(0.46, 0.52, 0.6)}.get(kind, Color.GRAY) as Color
	var accent := {"pool": Color(0.35, 0.7, 1.0), "sharp": Color(0.25, 0.9, 0.45), "loan": Color(1.0, 0.8, 0.25),
		"hammer": Color(0.95, 0.65, 0.25), "leech": Color(1.0, 0.35, 0.45), "white": Color(1.0, 0.3, 0.28)}.get(kind, Color.WHITE) as Color
	var belly := skin.lerp(Color(0.96, 0.95, 0.9), 0.78)
	if ko:
		skin = skin.lerp(Color(0.78, 0.8, 0.8), 0.5)
		accent = accent.lerp(Color(0.6, 0.6, 0.6), 0.7)
	var swish := 0.0 if ko else sin(t * 6.0) * 0.22
	# Danger ring on the cloth: the solid part a ball bounces off.
	if not ko and kind != "leech":
		var rr := 24.0 * s
		var pulse := 0.5 + 0.5 * sin(t * 3.0)
		ci.draw_circle(pos, rr, Color(accent, 0.06 + 0.04 * pulse), true, -1.0, true)
		ci.draw_arc(pos, rr, 0, TAU, 48, Color(accent, 0.3 + 0.15 * pulse), maxf(1.0, 1.6 * s), true)
	ci.draw_set_transform(pos, heading, Vector2(s, s))
	# Wake: ripples trailing off the tail.
	if not ko:
		for k in 3:
			var f := fmod(t * 0.9 + k / 3.0, 1.0)
			var c := Vector2(-60.0 - f * 30.0, 0)
			ci.draw_arc(c, 8.0 + f * 20.0, PI * 0.6, PI * 1.4, 16, Color(0.8, 1.0, 0.95, 0.16 * (1.0 - f)), 1.4, true)
	# Soft shadow, two layers for a blurred edge.
	var shadow := _shark_body(kind, 0.0)
	ci.draw_set_transform(pos + Vector2(5, 8) * s, heading, Vector2(s, s) * 1.04)
	ci.draw_colored_polygon(shadow, Color(0, 0, 0, 0.16))
	ci.draw_set_transform(pos + Vector2(4, 6) * s, heading, Vector2(s, s))
	ci.draw_colored_polygon(shadow, Color(0, 0, 0, 0.22))
	ci.draw_set_transform(pos, heading, Vector2(s, s))
	if kind == "leech":
		_draw_leech(ci, skin, belly, ko, t)
	else:
		var back := skin.darkened(0.28)
		# Tail: a tall upper lobe and a short lower one, swishing from the root.
		var root := Vector2(-42, 0)
		var tail := PackedVector2Array([Vector2(-38, -4), Vector2(-60, -10), Vector2(-74, -24), Vector2(-66, -3), Vector2(-64, 2), Vector2(-68, 14), Vector2(-56, 6), Vector2(-38, 4)])
		var tl := PackedVector2Array()
		for p in tail:
			tl.append(root + (p - root).rotated(swish))
		ci.draw_colored_polygon(tl, back)
		ci.draw_polyline(_closed(tl), Color(0, 0, 0, 0.5), 1.4, true)
		ci.draw_line(root + (Vector2(-44, -2) - root).rotated(swish), root + (Vector2(-70, -20) - root).rotated(swish), skin.lightened(0.1), 1.2, true)
		# Pectoral fins, swept back; pelvic fins small, further back.
		for side in [-1.0, 1.0]:
			var fl := 1.0 if not ko else 0.8
			var pec := PackedVector2Array([Vector2(20, side * 10), Vector2(8, side * 30 * fl), Vector2(-8, side * 38 * fl), Vector2(-4, side * 26 * fl), Vector2(4, side * 11)])
			ci.draw_colored_polygon(pec, back if not ko else belly.darkened(0.1))
			ci.draw_polyline(_closed(pec), Color(0, 0, 0, 0.45), 1.2, true)
			ci.draw_line(Vector2(18, side * 11), Vector2(-6, side * 36 * fl), skin.lightened(0.18), 1.2, true)
			var pel := PackedVector2Array([Vector2(-20, side * 7), Vector2(-30, side * 15), Vector2(-33, side * 13), Vector2(-28, side * 6)])
			ci.draw_colored_polygon(pel, back)
		# Body, countershaded: a dark back down the middle, paler flanks, and a
		# highlight along the lit side.
		var body := _shark_body(kind, swish * 0.3)
		ci.draw_colored_polygon(body, belly if ko else skin)
		if not ko:
			ci.draw_colored_polygon(_shark_band(kind, swish * 0.3, 0.5), back)
			ci.draw_colored_polygon(_shark_band(kind, swish * 0.3, 0.22), back.darkened(0.25))
			var hl := PackedVector2Array()
			for i in 12:
				var f := 0.15 + 0.7 * i / 11.0
				var x := lerpf(-44.0, 56.0, f)
				hl.append(Vector2(x, -_half_w(kind, f) * 0.62 + sin(f * PI) * swish * 6.0 * (1.0 - f)))
			ci.draw_polyline(hl, Color(1, 1, 1, 0.28), 2.2, true)
			# Dorsal fin from above: a raised ridge with its shadow on the far side.
			ci.draw_colored_polygon(PackedVector2Array([Vector2(8, 0), Vector2(-16, 6), Vector2(-20, 1)]), Color(0, 0, 0, 0.35))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(8, 0), Vector2(-14, -5), Vector2(-20, 1)]), back.darkened(0.15))
			ci.draw_line(Vector2(8, 0), Vector2(-14, -5), skin.lightened(0.25), 1.2, true)
		else:
			# Belly up: a pale underside and a seam down the middle.
			ci.draw_line(Vector2(-40, 0), Vector2(44, 0), skin.darkened(0.1), 1.2, true)
		# Gill slits.
		for side in [-1.0, 1.0]:
			for k in 4:
				var gx := 24.0 - k * 3.6
				var gw := _half_w(kind, (gx + 44.0) / 100.0)
				ci.draw_line(Vector2(gx, side * gw * 0.74), Vector2(gx - 1.6, side * gw * 0.94), Color(0, 0, 0, 0.32), 1.0, true)
		body.append(body[0])
		ci.draw_polyline(body, Color(0, 0, 0, 0.55), 1.6, true)
		_shark_extras(ci, kind, skin, ko, t)
		# Eyes: small, dark and mean, with a glint and a hard brow.
		var ew := _half_w(kind, (36.0 + 44.0) / 100.0) * 0.62
		var eyes: Array = [Vector2(36, -ew), Vector2(36, ew)] if kind != "hammer" else [Vector2(51, -27), Vector2(51, 27)]
		for e: Vector2 in eyes:
			var sd := signf(e.y)
			if ko:
				ci.draw_line(e + Vector2(-3, -3), e + Vector2(3, 3), Color(0.1, 0.1, 0.1), 1.8, true)
				ci.draw_line(e + Vector2(-3, 3), e + Vector2(3, -3), Color(0.1, 0.1, 0.1), 1.8, true)
			else:
				ci.draw_circle(e, 3.4, Color(0.02, 0.02, 0.03), true, -1.0, true)
				ci.draw_circle(e + Vector2(1.0, -1.0), 1.1, Color(1, 1, 1, 0.95), true, -1.0, true)
				ci.draw_line(e + Vector2(-5, -sd * 1.5), e + Vector2(4, -sd * 4.5), skin.darkened(0.5), 1.8, true)
	if hit:
		# A white flash, a shock ring and sparks where it was struck.
		var flash := _shark_body(kind, 0.0) if kind != "leech" else PackedVector2Array()
		if not flash.is_empty():
			ci.draw_colored_polygon(flash, Color(1, 1, 1, 0.55))
		for k in 3:
			ci.draw_arc(Vector2(4, 0), 46.0 + k * 7.0, 0, TAU, 48, Color(1, 1, 1, 0.55 - 0.16 * k), 2.4, true)
		for k in 8:
			var a := TAU * k / 8.0 + 0.2
			ci.draw_line(Vector2.from_angle(a) * 34.0, Vector2.from_angle(a) * (44.0 + (k % 2) * 8.0), Color(1.0, 0.95, 0.6, 0.9), 2.0, true)
	ci.draw_set_transform(Vector2.ZERO)
	if ko:
		# Dizzy: stars circling over the head, in screen space so they stay upright.
		for k in 3:
			var a := t * 2.2 + TAU * k / 3.0
			_star(ci, pos + Vector2(cos(a) * 24.0, sin(a) * 8.0 - 22.0) * s, 5.5 * s, Color(1, 0.88, 0.35))
	if kind == "white":
		_health_bar(ci, pos + Vector2(0, -50) * s, s, health, ko)
	elif pips > 0:
		_hp_pips(ci, pos + Vector2(0, -44) * s, s, pips, int(round(health * pips)), accent, ko)


## Hit points left, as a row of pips above a Shark.
static func _hp_pips(ci: CanvasItem, c: Vector2, s: float, total: int, left: int, col: Color, ko: bool) -> void:
	var gap := 11.0 * maxf(s, 0.7)
	var x0 := c.x - gap * (total - 1) * 0.5
	for i in total:
		var p := Vector2(x0 + gap * i, c.y)
		ci.draw_circle(p, 4.2 * maxf(s, 0.7), Color(0, 0, 0, 0.6), true, -1.0, true)
		if i < left and not ko:
			ci.draw_circle(p, 3.0 * maxf(s, 0.7), col, true, -1.0, true)
			ci.draw_circle(p + Vector2(-0.8, -0.8), 1.0 * maxf(s, 0.7), Color(1, 1, 1, 0.7), true, -1.0, true)
		else:
			ci.draw_arc(p, 3.0 * maxf(s, 0.7), 0, TAU, 12, Color(0.6, 0.6, 0.6, 0.6), 1.0, true)


## Half the body's width at f (0 = tail root, 1 = snout).
static func _half_w(kind: String, f: float) -> float:
	var width := {"white": 38.0, "loan": 32.0, "hammer": 27.0}.get(kind, 30.0) as float
	# Full shoulders about two-thirds along, a blunt rounded snout, a slim tail stock.
	return width * 0.5 * pow(sin(PI * pow(clampf(f, 0.0, 1.0), 0.66)), 0.55) * (0.5 + 0.5 * smoothstep(0.0, 0.4, f))


static func _shark_body(kind: String, bend: float) -> PackedVector2Array:
	return _shark_band(kind, bend, 1.0)


## The body outline scaled across its width by k (1 = the whole body), for the
## countershading bands down the back.
static func _shark_band(kind: String, bend: float, k: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for side in [-1.0, 1.0]:
		var half := PackedVector2Array()
		for i in 25:
			var f := i / 24.0
			var x := lerpf(-44.0, 56.0, f)
			half.append(Vector2(x, side * _half_w(kind, f) * k + sin(f * PI) * bend * 20.0 * (1.0 - f)))
		if side < 0:
			pts.append_array(half)
		else:
			half.reverse()
			pts.append_array(half)
	return pts


static func _shark_extras(ci: CanvasItem, kind: String, skin: Color, ko: bool, t: float) -> void:
	match kind:
		"hammer":
			# The cephalofoil: a broad, rounded hammer across the head.
			var head := PackedVector2Array([Vector2(36, -9), Vector2(46, -24), Vector2(50, -31), Vector2(56, -32), Vector2(60, -22), Vector2(61, 0),
				Vector2(60, 22), Vector2(56, 32), Vector2(50, 31), Vector2(46, 24), Vector2(36, 9)])
			ci.draw_colored_polygon(head, skin.darkened(0.12) if not ko else skin)
			ci.draw_polyline(_closed(head), Color(0, 0, 0, 0.55), 1.6, true)
			ci.draw_line(Vector2(58, -26), Vector2(59, 26), Color(1, 1, 1, 0.22), 1.6, true)
		"pool":
			# A cue tucked under a fin, its tip chalked blue, and chalk dust on the nose.
			ci.draw_line(Vector2(-34, 30), Vector2(44, 38), Color(0.12, 0.08, 0.05), 4.2, true)
			ci.draw_line(Vector2(-34, 30), Vector2(44, 38), Color(0.86, 0.68, 0.42), 2.8, true)
			ci.draw_line(Vector2(-34, 30), Vector2(-14, 32), Color(0.25, 0.12, 0.08), 2.8, true)
			ci.draw_line(Vector2(40, 37.6), Vector2(44, 38), Color(0.3, 0.6, 1.0), 3.0, true)
			for k in 4:
				ci.draw_circle(Vector2(54 + (k % 2) * 3, -3 + k * 2), 1.4, Color(0.45, 0.7, 1.0, 0.75), true, -1.0, true)
		"sharp":
			# Green dealer's eyeshade, and a fan of cards held in a fin.
			ci.draw_arc(Vector2(32, 0), 15, -1.25, 1.25, 18, Color(0.05, 0.25, 0.1, 0.6), 8.0, true)
			ci.draw_arc(Vector2(32, 0), 15, -1.2, 1.2, 18, Color(0.2, 0.8, 0.4, 0.95), 5.0, true)
			for k in 4:
				var c := Vector2(-12 + k * 5, -34 - k * 1.2)
				var rot := -0.35 + k * 0.22
				var card := PackedVector2Array()
				for q in [Vector2(0, 0), Vector2(9, 0), Vector2(9, 13), Vector2(0, 13)]:
					card.append(c + (q as Vector2).rotated(rot))
				ci.draw_colored_polygon(card, Color(0.98, 0.97, 0.93))
				ci.draw_polyline(_closed(card), Color(0.15, 0.15, 0.15), 0.9, true)
				ci.draw_circle(c + Vector2(4.5, 6.5).rotated(rot), 1.8, Color(0.85, 0.12, 0.18) if k % 2 == 0 else Color(0.08, 0.08, 0.1), true, -1.0, true)
		"loan":
			# A pinstripe suit, a white collar, a gold watch chain and a $ on the back.
			for k in range(-3, 4):
				ci.draw_line(Vector2(-36, k * 3.4), Vector2(40, k * 3.4 * 0.7), Color(0.85, 0.85, 0.95, 0.28), 0.8, true)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(28, -3), Vector2(14, -11), Vector2(19, 0), Vector2(14, 11), Vector2(28, 3)]), Color(0.96, 0.96, 0.96))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(22, 0), Vector2(17, -3), Vector2(17, 3)]), Color(0.75, 0.12, 0.15))
			var chain := PackedVector2Array()
			for k in 9:
				chain.append(Vector2(10 - k * 3.0, 6 + sin(k * 0.6) * 4.0))
			ci.draw_polyline(chain, Color(1.0, 0.82, 0.3), 1.2, true)
			ci.draw_circle(Vector2(-8, 0), 7.5, Color(0.55, 0.42, 0.08), true, -1.0, true)
			ci.draw_circle(Vector2(-8, 0), 6.5, Color(1.0, 0.82, 0.28), true, -1.0, true)
			ci.draw_string(TileArt.F_SEMI, Vector2(-11.5, 4.5), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.25, 0.17, 0.03))
		"white":
			# Gaping jaws full of teeth, and old scars along the back.
			if not ko:
				var open := 0.8 + 0.2 * sin(t * 4.0)
				var mouth := PackedVector2Array([Vector2(57, 0), Vector2(38, -12 * open), Vector2(31, 0), Vector2(38, 12 * open)])
				ci.draw_colored_polygon(mouth, Color(0.35, 0.03, 0.05))
				ci.draw_colored_polygon(PackedVector2Array([Vector2(50, 0), Vector2(38, -7 * open), Vector2(34, 0), Vector2(38, 7 * open)]), Color(0.6, 0.08, 0.1))
				for k in 6:
					var a := Vector2(38, -12 * open).lerp(Vector2(57, 0), k / 5.0)
					var b := Vector2(38, 12 * open).lerp(Vector2(57, 0), k / 5.0)
					ci.draw_colored_polygon(PackedVector2Array([a, a + Vector2(2.6, 0.4), a + Vector2(0.8, 4.2)]), Color(1, 1, 0.95))
					ci.draw_colored_polygon(PackedVector2Array([b, b + Vector2(2.6, -0.4), b + Vector2(0.8, -4.2)]), Color(1, 1, 0.95))
			for sc in [[Vector2(-6, -12), Vector2(6, -5)], [Vector2(-11, -8), Vector2(1, -1)], [Vector2(14, 6), Vector2(24, 12)]]:
				ci.draw_line(sc[0], sc[1], Color(0.92, 0.9, 0.88, 0.75), 1.4, true)


static func _draw_leech(ci: CanvasItem, skin: Color, belly: Color, ko: bool, t: float) -> void:
	# A glossy, ringed body that inches along, with a round toothed sucker at the front.
	var pts := PackedVector2Array()
	for i in 11:
		var x := lerpf(-32.0, 32.0, i / 10.0)
		pts.append(Vector2(x, sin(i * 0.8 + t * (0.0 if ko else 5.0)) * 4.0))
	for i in pts.size():
		var r := 10.0 - absf(i - 5.0) * 0.8
		ci.draw_circle(pts[i] + Vector2(0, 1.5), r, skin.darkened(0.35), true, -1.0, true)
	for i in pts.size():
		var r := 10.0 - absf(i - 5.0) * 0.8
		ci.draw_circle(pts[i], r, skin if i % 2 == 0 else skin.lightened(0.1), true, -1.0, true)
		ci.draw_arc(pts[i], r, PI * 1.1, PI * 1.6, 8, Color(1, 1, 1, 0.3), 1.4, true)
	for i in range(1, pts.size() - 1, 2):
		ci.draw_circle(pts[i] + Vector2(0, -2), 1.4, Color(1.0, 0.75, 0.3, 0.8), true, -1.0, true)
	var head := pts[10] + Vector2(7, 0)
	ci.draw_circle(head, 7.0, belly if not ko else skin, true, -1.0, true)
	ci.draw_arc(head, 5.0, 0, TAU, 18, Color(0.5, 0.08, 0.14), 1.8, true)
	for k in 3:
		ci.draw_line(head, head + Vector2.from_angle(TAU * k / 3.0 + t * (0.0 if ko else 2.0)) * 3.6, Color(1, 1, 1, 0.9), 1.2, true)


static func _health_bar(ci: CanvasItem, c: Vector2, s: float, health: float, ko: bool) -> void:
	var w := 90.0 * s
	var h := maxf(4.0, 8.0 * s)
	var r := Rect2(c - Vector2(w * 0.5, h * 0.5), Vector2(w, h))
	ci.draw_rect(r.grow(1.5), Color(0, 0, 0, 0.7))
	ci.draw_rect(Rect2(r.position, Vector2(w * clampf(health, 0.0, 1.0), h)), Color(0.95, 0.25, 0.25) if not ko else Color(0.5, 0.5, 0.5))
	for k in range(1, 8):
		ci.draw_line(r.position + Vector2(w * k / 8.0, 0), r.position + Vector2(w * k / 8.0, h), Color(0, 0, 0, 0.6), 1.0)


static func _star(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		pts.append(c + Vector2.from_angle(-PI * 0.5 + PI * i / 5.0) * (r if i % 2 == 0 else r * 0.45))
	ci.draw_colored_polygon(pts, col)


# --- Moving parts ------------------------------------------------------------------

## The Clockwork Table's Sweeper: a brass clock hand turning about c.
static func draw_sweeper(ci: CanvasItem, c: Vector2, angle: float, length: float, t := 0.0) -> void:
	var brass := Color(0.86, 0.66, 0.28)
	var d := Vector2.from_angle(angle)
	var n := d.orthogonal()
	var tip := c + d * length
	var hand := PackedVector2Array([c - d * length * 0.18 + n * 5, c + d * length * 0.7 + n * 7, tip, c + d * length * 0.7 - n * 7, c - d * length * 0.18 - n * 5])
	ci.draw_colored_polygon(_offset(hand, Vector2(3, 4)), Color(0, 0, 0, 0.3))
	ci.draw_colored_polygon(hand, brass)
	ci.draw_polyline(_closed(hand), brass.darkened(0.45), 1.5, true)
	ci.draw_line(c, tip - d * 8, brass.lightened(0.35), 1.5, true)
	# Hub: a little gear.
	var gear := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0 + t * 0.2
		gear.append(c + Vector2.from_angle(a) * (13.0 if i % 2 == 0 else 10.0))
	ci.draw_colored_polygon(gear, brass.darkened(0.15))
	ci.draw_circle(c, 5.0, Color(0.2, 0.15, 0.08), true, -1.0, true)
	ci.draw_circle(c - d * length * 0.18, 7.0, brass, true, -1.0, true)


## Foucault's pendulum bob, hanging from pivot (drawn as a cable shadow), seen from above.
static func draw_pendulum(ci: CanvasItem, pivot: Vector2, bob: Vector2, r: float, t := 0.0) -> void:
	ci.draw_line(pivot, bob, Color(0, 0, 0, 0.25), 2.0, true)
	ci.draw_circle(pivot, 4.0, Color(0.3, 0.3, 0.32), true, -1.0, true)
	ci.draw_circle(bob + Vector2(5, 7), r, Color(0, 0, 0, 0.35), true, -1.0, true)
	ci.draw_circle(bob, r, Color(0.72, 0.52, 0.2), true, -1.0, true)
	ci.draw_arc(bob, r * 0.7, 0, TAU, 32, Color(0.95, 0.8, 0.45, 0.8), 2.0, true)
	ci.draw_circle(bob + Vector2(-r * 0.35, -r * 0.4), r * 0.25, Color(1, 0.95, 0.8, 0.8), true, -1.0, true)
	ci.draw_circle(bob, 2.5, Color(0.25, 0.18, 0.08), true, -1.0, true)


## A post sliding on a slot between a and b, with a spring at each end.
static func draw_shuttle(ci: CanvasItem, a: Vector2, b: Vector2, f: float, r := 12.0) -> void:
	var d := (b - a).normalized()
	var n := d.orthogonal()
	ci.draw_line(a, b, Color(0, 0, 0, 0.55), 8.0, true)
	ci.draw_line(a, b, Color(0.35, 0.35, 0.38), 2.0, true)
	var p := a.lerp(b, f)
	for end in [[a, p - d * r], [b, p + d * r]]:
		var pts := PackedVector2Array()
		for i in 13:
			var q: Vector2 = (end[0] as Vector2).lerp(end[1], i / 12.0)
			pts.append(q + n * (5.0 if i % 2 else -5.0) * (0.0 if i == 0 or i == 12 else 1.0))
		ci.draw_polyline(pts, Color(0.75, 0.78, 0.8), 1.6, true)
	ci.draw_circle(p + Vector2(3, 4), r, Color(0, 0, 0, 0.35), true, -1.0, true)
	ci.draw_circle(p, r, Color(0.85, 0.3, 0.25), true, -1.0, true)
	ci.draw_circle(p, r * 0.55, Color(0.98, 0.9, 0.85), true, -1.0, true)


## Coriolis turntable: a disc with grooves and arrows, turned to angle.
static func draw_turntable(ci: CanvasItem, c: Vector2, r: float, angle: float) -> void:
	ci.draw_circle(c, r, Color(0, 0, 0, 0.22), true, -1.0, true)
	for k in 5:
		ci.draw_arc(c, r * (0.3 + 0.17 * k), 0, TAU, 48, Color(1, 1, 1, 0.08), 1.0, true)
	for k in 3:
		var a := angle + TAU * k / 3.0
		var pts := PackedVector2Array()
		for i in 9:
			pts.append(c + Vector2.from_angle(a + i * 0.08) * r * 0.82)
		ci.draw_polyline(pts, Color(1, 1, 1, 0.4), 2.0, true)
		var tip := pts[8]
		var dir := (pts[8] - pts[7]).normalized()
		ci.draw_colored_polygon(PackedVector2Array([tip + dir * 6, tip + dir.orthogonal() * 4, tip - dir.orthogonal() * 4]), Color(1, 1, 1, 0.45))
	ci.draw_arc(c, r, 0, TAU, 64, Color(1, 1, 1, 0.25), 2.0, true)
	ci.draw_circle(c, 6.0, Color(0.7, 0.72, 0.75), true, -1.0, true)


## Gulf Stream conveyor: a strip of current with chevrons moving along dir.
static func draw_conveyor(ci: CanvasItem, r: Rect2, dir: Vector2, t := 0.0) -> void:
	ci.draw_rect(r, Color(0.2, 0.5, 0.75, 0.22))
	ci.draw_line(r.position, Vector2(r.end.x, r.position.y), Color(0.6, 0.85, 1.0, 0.35), 1.5)
	ci.draw_line(Vector2(r.position.x, r.end.y), r.end, Color(0.6, 0.85, 1.0, 0.35), 1.5)
	var gap := 26.0
	var off := fposmod(t * 40.0, gap)
	var x := r.position.x - gap + off
	while x < r.end.x:
		if x > r.position.x + 4:
			var cy := r.get_center().y
			var h := r.size.y * 0.32
			var tip := Vector2(x + 8 * signf(dir.x if dir.x != 0 else 1.0), cy)
			ci.draw_polyline(PackedVector2Array([Vector2(x, cy - h), tip, Vector2(x, cy + h)]), Color(0.75, 0.92, 1.0, 0.5), 2.0, true)
		x += gap


## Maxwell's Demon at its gate: a little red imp beside a gate that is open or shut.
static func draw_demon(ci: CanvasItem, gate: Vector2, open: float, t := 0.0) -> void:
	var post := Color(0.55, 0.55, 0.58)
	ci.draw_circle(gate + Vector2(0, -22), 4.0, post, true, -1.0, true)
	ci.draw_circle(gate + Vector2(0, 22), 4.0, post, true, -1.0, true)
	var a := lerpf(PI * 0.5, PI * 0.05, open)
	ci.draw_line(gate + Vector2(0, -22), gate + Vector2(0, -22) + Vector2.from_angle(a) * 40.0, Color(0.9, 0.85, 0.35), 4.0, true)
	var d := gate + Vector2(-26, 4 + sin(t * 4.0) * 2.0)
	var red := Color(0.85, 0.18, 0.15)
	ci.draw_circle(d + Vector2(2, 3), 9.0, Color(0, 0, 0, 0.3), true, -1.0, true)
	ci.draw_circle(d, 9.0, red, true, -1.0, true)
	for side in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([d + Vector2(side * 4, -6), d + Vector2(side * 9, -15), d + Vector2(side * 7, -4)]), red.darkened(0.3))
		ci.draw_circle(d + Vector2(side * 3.5, -1), 1.8, Color(1, 0.95, 0.4), true, -1.0, true)
	ci.draw_arc(d + Vector2(0, 2), 4.0, 0.3, PI - 0.3, 8, Color(0.2, 0.05, 0.05), 1.4, true)
	var tail := PackedVector2Array()
	for i in 10:
		tail.append(d + Vector2(-8 - i * 1.6, 6 + sin(i * 0.8 + t * 3.0) * 3.0))
	ci.draw_polyline(tail, red.darkened(0.2), 1.6, true)


## The Lever: a see-saw rail tipped by tilt (radians) on its fulcrum.
static func draw_seesaw(ci: CanvasItem, c: Vector2, length: float, tilt: float) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-14, 18), c + Vector2(0, -2), c + Vector2(14, 18)]), Color(0.45, 0.3, 0.15))
	var d := Vector2.from_angle(tilt)
	var a := c - d * length * 0.5
	var b := c + d * length * 0.5
	ci.draw_line(a + Vector2(3, 5), b + Vector2(3, 5), Color(0, 0, 0, 0.3), 10.0, true)
	ci.draw_line(a, b, Color(0.62, 0.42, 0.2), 10.0, true)
	ci.draw_line(a, b, Color(0.8, 0.6, 0.32), 3.0, true)
	ci.draw_circle(c, 4.0, Color(0.3, 0.22, 0.12), true, -1.0, true)


## Capacitor: a rail segment glowing with its charge (0-1), sparks running along it.
static func draw_charged_rail(ci: CanvasItem, a: Vector2, b: Vector2, charge: float, t := 0.0) -> void:
	var glow := Color(0.45, 0.8, 1.0)
	for k in 3:
		ci.draw_line(a, b, Color(glow, (0.08 + 0.12 * k) * charge), (14.0 - 4.0 * k), true)
	ci.draw_line(a, b, Color(0.9, 0.97, 1.0, 0.4 + 0.6 * charge), 2.0, true)
	if charge > 0.05:
		for i in 4:
			var f := fposmod(t * 0.8 + i / 4.0, 1.0)
			var p := a.lerp(b, f)
			var n := (b - a).normalized().orthogonal()
			var pts := PackedVector2Array([p, p + n * 6.0 + (b - a).normalized() * 3.0, p - n * 2.0 + (b - a).normalized() * 6.0, p + n * 5.0 + (b - a).normalized() * 10.0])
			ci.draw_polyline(pts, Color(1, 1, 1, charge * sin(f * PI)), 1.2, true)


static func _closed(p: PackedVector2Array) -> PackedVector2Array:
	var q := p.duplicate()
	q.append(p[0])
	return q


static func _offset(p: PackedVector2Array, o: Vector2) -> PackedVector2Array:
	var q := PackedVector2Array()
	for v in p:
		q.append(v + o)
	return q


# --- Rail materials ----------------------------------------------------------------

## Fills a rail rectangle with one of RAIL_MATERIALS. Long side along x if wide.
static func draw_rail(ci: CanvasItem, r: Rect2, material: String, t := 0.0) -> void:
	var horiz := r.size.x >= r.size.y
	var length := r.size.x if horiz else r.size.y
	var depth := r.size.y if horiz else r.size.x
	var at := func(along: float, across: float) -> Vector2:
		along = clampf(along, 0.0, length)
		across = clampf(across, 0.0, depth)
		return r.position + (Vector2(along, across) if horiz else Vector2(across, along))
	match material:
		"chrome":
			var bands := [Color(0.42, 0.45, 0.5), Color(0.95, 0.97, 1.0), Color(0.7, 0.73, 0.78), Color(0.3, 0.32, 0.36), Color(0.82, 0.85, 0.9)]
			for k in bands.size():
				var a: Vector2 = at.call(0.0, depth * k / bands.size())
				ci.draw_rect(Rect2(a, Vector2(length, depth / bands.size())) if horiz else Rect2(a, Vector2(depth / bands.size(), length)), bands[k])
			var x := fposmod(t * 120.0, length + 80.0) - 40.0
			ci.draw_colored_polygon(PackedVector2Array([at.call(x, 0.0), at.call(x + 18, 0.0), at.call(x + 8, depth), at.call(x - 10, depth)]), Color(1, 1, 1, 0.35))
		"copper":
			ci.draw_rect(r, Color(0.72, 0.38, 0.2))
			ci.draw_line(at.call(0.0, depth * 0.3), at.call(length, depth * 0.3), Color(1, 0.72, 0.5, 0.8), depth * 0.18)
			ci.draw_line(at.call(0.0, depth * 0.8), at.call(length, depth * 0.8), Color(0.4, 0.18, 0.08, 0.7), depth * 0.15)
			var x := 40.0
			while x < length:
				ci.draw_rect(Rect2(at.call(x - 4, -1.0), Vector2(8, depth + 2)) if horiz else Rect2(at.call(x - 4, -1.0), Vector2(depth + 2, 8)), Color(0.55, 0.28, 0.14))
				ci.draw_line(at.call(x - 4, 0.0), at.call(x - 4, depth), Color(1, 0.75, 0.55, 0.6), 1.0)
				x += 90.0
			for i in 6:
				ci.draw_circle(at.call(length * _h(i, 3), depth * _h(i, 4)), 2.0 + 2.0 * _h(i, 5), Color(0.35, 0.6, 0.5, 0.5), true, -1.0, true)
		"black_glass":
			ci.draw_rect(r, Color(0.04, 0.04, 0.07))
			for i in 5:
				var x := length * _h(i, 7)
				ci.draw_colored_polygon(PackedVector2Array([at.call(x, 0.0), at.call(x + 10, 0.0), at.call(x + 2, depth), at.call(x - 8, depth)]), Color(0.6, 0.7, 1.0, 0.1 + 0.08 * _h(i, 8)))
			ci.draw_line(at.call(0.0, 1.0), at.call(length, 1.0), Color(0.7, 0.8, 1.0, 0.5), 1.0)
		"marble":
			ci.draw_rect(r, Color(0.92, 0.91, 0.88))
			for i in 7:
				var pts := PackedVector2Array()
				var y := depth * _h(i, 11)
				var x := length * _h(i, 12) - 40.0
				for k in 12:
					pts.append(at.call(x + k * 12.0, clampf(y + sin(k * 0.9 + i) * depth * 0.25, 0.0, depth)))
				ci.draw_polyline(pts, Color(0.5, 0.5, 0.55, 0.35 + 0.25 * _h(i, 13)), 1.0 + _h(i, 14), true)
		"gilded":
			ci.draw_rect(r, Color(0.78, 0.58, 0.18))
			ci.draw_line(at.call(0.0, depth * 0.25), at.call(length, depth * 0.25), Color(1, 0.9, 0.55, 0.85), depth * 0.15)
			var x := 10.0
			var i := 0
			while x < length:
				ci.draw_circle(at.call(x, depth * 0.65), depth * 0.12, Color(1, 0.88, 0.5) if i % 2 == 0 else Color(0.55, 0.38, 0.08), true, -1.0, true)
				x += depth * 0.55
				i += 1
		"obsidian":
			ci.draw_rect(r, Color(0.05, 0.03, 0.06))
			for i in 9:
				var x := length * _h(i, 21)
				var w := 10.0 + 22.0 * _h(i, 22)
				ci.draw_colored_polygon(PackedVector2Array([at.call(x, 0.0), at.call(x + w, depth * 0.5), at.call(x + w * 0.3, depth)]), Color(0.45, 0.3, 0.6, 0.12 + 0.12 * _h(i, 23)))
			ci.draw_line(at.call(0.0, 1.0), at.call(length, 1.0), Color(0.8, 0.7, 1.0, 0.35), 1.0)
		_:
			ci.draw_rect(r, Color(0.3, 0.15, 0.07))
	ci.draw_rect(r, Color(0, 0, 0, 0.5), false, 1.0)
