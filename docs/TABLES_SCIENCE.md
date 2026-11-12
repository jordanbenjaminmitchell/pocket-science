# The science tables: 40 boards

**Design plan, not the current playable roster.** The game currently has 26 boards: the original 22 plus the four shaped boards (Benzene Ring, The Hypotenuse, Golden Pentagon and The L-Shell). The remaining science boards below have concepts, art or music in progress, but their gameplay rules are not yet implemented. The current roster is defined in `src/game/catalog.gd`.

In this plan, every board is named for a real idea in maths, physics or chemistry, and **that idea is the physical twist**. Shapes are polygons with exactly **6 holes** (some may be boarded up). Nine boards make a run, drawn from early, middle and late pools. The Pro Shop already names the next table, so you can plan for it.

**Rules kept from the brainstorm:** the prediction line tells the truth (movers follow fixed patterns in shot time, Sharks are solid), and pausing freezes everything.

From the other AI's proposal, these ideas are adopted here under science names: The Funnel (**Venturi**), The Shortcut (**Einstein–Rosen Bridge**), The Split (**Semipermeable Membrane**), Rail Relay (**Capacitor**), Moving Target (**Kepler Orbit**), Aftershock (**Chain Reaction**), Spin Cycle (**Coriolis**) and Corner Case (**The L-Shell**). Its playtest note stands: early boards are too easy (one break cleared a whole table), so the balance pass should raise tables 1–3.

## Early boards (tables 1–3): one idea each

| # | Board | Shape | The twist | Builds on |
|---|---|---|---|---|
| 1 | **The Local** | Rectangle | Plain table; your first miss is forgiven. The tutorial | Keep |
| 2 | **Benzene Ring** | Hexagon | A pocket at each of the six corners. Banks off six angled rails | New shape |
| 3 | **The Hypotenuse** | Right triangle (3-4-5) | Three corner pockets plus one in the middle of each side. Every bank angle is new | New shape (the triangle) |
| 4 | **Venturi** | Rectangle | Two angled rails form a narrowing channel; balls squeezed through it come out faster | The Funnel |
| 5 | **Einstein–Rosen Bridge** | Rectangle | Two fixed linked portals. Plan the entry angle to set up the exit | The Shortcut, portals |
| 6 | **Pinball Parlor** | Rectangle | Four bumpers plus a boost-pad lane | Keep, upgraded |
| 7 | **Black Ice → Superfluid** | Rectangle | No friction, lively cushions; balls never quite stop until a cushion slows them | Black Ice |

## Middle boards (tables 4–6): movers, terrain and the first Sharks

| # | Board | Shape | The twist | Shark |
|---|---|---|---|---|
| 8 | **Parabolic Mirror** | Rectangle with one curved (many-sided) end | Any ball rolling straight at the curve bounces to its focus, where a pocket sits | — |
| 9 | **Whispering Gallery** | Ellipse (polygon) | A pocket sits at one focus inside the table: a ball sent through the other focus always rolls to it | — |
| 10 | **Semipermeable Membrane** | Rectangle | A wall across the middle that balls pass through one way only | — |
| 11 | **Capacitor** | Rectangle | Hitting a marked rail charges the opposite rail; the next ball off it gets a speed boost | Rail Relay |
| 12 | **Kepler Orbit** | Rectangle | One pocket travels a fixed orbit round the middle, a step per shot and smoothly while balls roll | Moving Target |
| 13 | **Coriolis** | Rectangle | A spinning disc in the middle curves every ball that crosses it | Spin Cycle |
| 14 | **Snell's Law** | Rectangle | A band of thick cloth across the middle bends balls as they cross it, like light in water | — |
| 15 | **Harmonic Oscillator** | Rectangle | Two posts slide back and forth on springs, on a beat | Shuttles |
| 16 | **Lotka–Volterra** | Pentagon | A **Pool Shark** swallows a ball every 3 shots, and a second Shark appears if the first survives 4 shots | Pool Shark |
| 17 | **Faraday Cage** | Rectangle | A **Card Sharp** blocks the best pocket, inside a ring of posts; knock it out to open it | Card Sharp |
| 18 | **The L-Shell** | L-shape | An inner corner and unfamiliar banks, still six pockets | Corner Case |

## Late boards (tables 7–8): two ideas at once, wilder shapes

| # | Board | Shape | The twist | Shark |
|---|---|---|---|---|
| 19 | **Golden Pentagon** | Pentagon in golden-ratio proportions | Five corner pockets and a drain in the centre that grows each shot | — |
| 20 | **Sierpinski Triangle** | Triangle | Triangular islands inside the table to bank around | — |
| 21 | **Möbius Strip** | Rectangle | A gap in the left rail leads out of a gap in the right rail, upside down | — |
| 22 | **Maxwell's Demon** | Rectangle | A gate in the middle lets only fast balls through one way, sorting the table | — |
| 23 | **Chain Reaction** | Hexagon | Every sink sends a pulse from its pocket that pushes nearby balls: plan chains | Aftershock |
| 24 | **Radioactive Decay** | Rectangle | One pocket boards up after each shot, round the table; a cleared rack reopens them | — |
| 25 | **Lorentz Field** | Rectangle | Inside a marked zone, moving balls curve sideways (faster balls curve less) | — |
| 26 | **Quantum Pockets** | Rectangle | Pockets come in linked pairs; after each shot every pair swaps places | Swapping pockets |
| 27 | **Foucault's Pendulum** | Octagon | A heavy bob swings across the table, and its swing turns a little each shot | **Hammerhead** charges between shots |
| 28 | **Event Horizon** | Rectangle | A black hole in the centre pulls balls in and grows each shot; sinking into it scores ×2 but costs Heat | The Sinkhole |

## Boss boards

| # | Board | The twist |
|---|---|---|
| 29 | **The Clockwork Table** | Pockets in clock order, plus a Sweeper bar that turns one step per shot like a clock hand |
| 30 | **Apex Predator** (final) | The 8 goes last, against the **Great White** (8 hits): it swallows a ball every 2 shots, and the **Loan Shark** and **Leech** join it at half health |

## Ten more boards (31–40)

| # | Board | Shape | The twist | Pool |
|---|---|---|---|---|
| 31 | **Galton Board** | Triangle, apex up | Rows of pegs in Pascal's-triangle order; balls clatter down through them like a bean machine | Early |
| 32 | **Golden Spiral** | Rectangle | A spiral rail arm winds into a drain in the middle; a ball caught on the arm rides it in | Middle |
| 33 | **Tesla Coil** | Hexagon | Every third shot, a pulse from the centre pushes every ball outwards; the line shows the coming pulse | Middle |
| 34 | **Gulf Stream** | Rectangle | A conveyor current runs across the table and carries any ball in it sideways | Middle |
| 35 | **Meissner Effect** | Rectangle | Magnetic posts repel balls before they touch, so balls curve round them | Middle |
| 36 | **Tectonic Plates** | Rectangle split in two | The two halves of the table slide past each other one step after every shot, so the rails don't line up | Late |
| 37 | **Crystal Lattice** | Rhombus | A grid of small posts like atoms in a crystal; shots weave through the gaps | Late |
| 38 | **Stellated Star** | Six-pointed star (concave) | A pocket at every point; the inner corners make wild banks | Late |
| 39 | **The Lever** | Trapezoid | A see-saw rail on a fulcrum in the middle tips towards whichever end a ball hits | Late |
| 40 | **Escape Velocity** | 16-sided near-circle | Two gravity wells slingshot balls round them; get the speed right to escape or orbit in | Late |

## How every board looks different

Each board gets its own **felt colour**, **rail material** and a faint **decal** on the felt that shows the idea, so you know where you are at a glance.

| # | Board | Felt | Rails | Decal |
|---|---|---|---|---|
| 1 | The Local | Classic green | Walnut | None |
| 2 | Benzene Ring | Teal | Brushed chrome | Hexagon with a ring inside |
| 3 | The Hypotenuse | Slate blue | Pale maple | a² + b² = c² |
| 4 | Venturi | Steel grey | Copper pipe | Flow lines narrowing |
| 5 | Einstein–Rosen Bridge | Deep violet | Black glass | Two linked funnels |
| 6 | Pinball Parlor | Arcade red | Neon-lit chrome | Starburst |
| 7 | Superfluid | Ice white-blue | Frosted glass | Snow crystal |
| 8 | Parabolic Mirror | Silver-grey | Mirror chrome | Parabola and its focus |
| 9 | Whispering Gallery | Plum | Carved stone | Ellipse with two foci |
| 10 | Semipermeable Membrane | Sea green | Rubber | Cell wall with an arrow |
| 11 | Capacitor | Navy | Gold-plated | Capacitor symbol ⊣⊢ |
| 12 | Kepler Orbit | Midnight blue | Brass | Planet's orbit |
| 13 | Coriolis | Storm grey | Weathered steel | Hurricane swirl |
| 14 | Snell's Law | Aqua | Glass | Light ray bending |
| 15 | Harmonic Oscillator | Lime | Spring steel | Sine wave |
| 16 | Lotka–Volterra | Ocean blue | Driftwood | Fish and shark fins |
| 17 | Faraday Cage | Charcoal | Copper mesh | Cage bars |
| 18 | The L-Shell | Orange | Bakelite | Electron shells |
| 19 | Golden Pentagon | Gold-brown | Gilded | Pentagram of golden ratios |
| 20 | Sierpinski Triangle | Black | White marble | Sierpinski fractal |
| 21 | Möbius Strip | Two-tone green and blue | Twisted chrome | Möbius loop |
| 22 | Maxwell's Demon | Crimson | Iron | Little demon at a gate |
| 23 | Chain Reaction | Toxic yellow-green | Lead grey | Radiation trefoil |
| 24 | Radioactive Decay | Dark olive | Hazard stripes | Half-life curve |
| 25 | Lorentz Field | Electric blue | Magnet red and grey | Field lines |
| 26 | Quantum Pockets | Deep purple | Holographic | Ψ (psi) |
| 27 | Foucault's Pendulum | Museum burgundy | Mahogany | Pendulum arcs |
| 28 | Event Horizon | Pure black | Obsidian | Accretion disc |
| 29 | The Clockwork Table | Ivory | Brass gears | Clock face |
| 30 | Apex Predator | Blood red | Shark-skin grey | Jaws |
| 31 | Galton Board | Cream | Pine | Bell curve |
| 32 | Golden Spiral | Amber | Bronze | Fibonacci spiral |
| 33 | Tesla Coil | Violet-black | Copper coil | Lightning |
| 34 | Gulf Stream | Atlantic blue | Ship's teak | Current arrows |
| 35 | Meissner Effect | Frost blue | Superconductor silver | Levitating magnet |
| 36 | Tectonic Plates | Rock brown | Basalt | Fault lines |
| 37 | Crystal Lattice | Pale pink quartz | Crystal | Lattice grid |
| 38 | Stellated Star | Navy with gold flecks | Gold | Star outline |
| 39 | The Lever | Sand | Oak beam | Fulcrum triangle |
| 40 | Escape Velocity | Starfield black | Titanium | Rocket's path |

**Music:** tracks for the planned boards exist as assets. Only implemented boards play in the current game.

## What the existing 22 become

- **Kept as they are:** The Local, Pinball Parlor, Clockwork.
- **Reworked into a science board:** Black Ice (Superfluid), Twin Posts (Harmonic Oscillator), The Sinkhole (Event Horizon), The Magnet Room (Kepler Orbit), The Smoke Room (Lotka–Volterra), The Back Room (Faraday Cage), Spring Street (Capacitor), The Drift (Coriolis), The Tilted Table (Snell's Law), Two Pockets (Quantum Pockets), Closing Time (Radioactive Decay), The Grand Final (Apex Predator).
- **Retired, their rule moving onto a science board** or into a side bet: Frozen Lake, Old Slate, The Hump, Rotation Night, The Iron Rack, Lights Out, The Hustler (the Loan Shark carries its skim).

## Build order (cheapest proof first)

1. **Shapes:** a polygon table system with 6 pockets anywhere. This unlocks Benzene Ring, The Hypotenuse, Golden Pentagon, The L-Shell, Sierpinski and Foucault's octagon.
2. **Fixed geometry:** Venturi, Einstein–Rosen Bridge, Semipermeable Membrane, Möbius Strip, Parabolic Mirror and Whispering Gallery.
3. **Sharks:** Pool Shark, Card Sharp, Hammerhead, Loan Shark, Leech, and the Great White final.
4. **Movers and fields:** Kepler Orbit, Harmonic Oscillator, Coriolis, Lorentz Field, Snell's Law, Foucault's Pendulum, Sweeper, Chain Reaction, Capacitor and Maxwell's Demon.

## Open question

**Path choice (as in Slay the Spire):** after each shop, pick between two next boards. With 30 boards and named tables it would let you steer towards your build. You said "maybe not", so it stays off unless you want it.
