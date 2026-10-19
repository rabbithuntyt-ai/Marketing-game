extends Sector
## M5 · Sector 3 · EVALUATION LAB — Castellan's "shopper lab" behind the mall: interview booths,
## a mock supermarket aisle and a dark observation gallery. The courier meets the profilers here.
## Read: concrete service level. Interview booths down the west, the mock aisle in the middle
## (shelves you can hide between), the observation gallery north (dark, glass toward the aisle),
## the profiling desk on the east side where the courier ends up.

func dims() -> Vector3: return Vector3(28, 6, 40)

func build() -> void:
	strategy_wall(13.3, 8.0, 270, 2.6)
	floor_rect(-14, 0, 14, 40, "", 0.0, b.mat("CONCRETE"))
	concrete_shell(6.0, 8.0, true, b.mat("CONCRETE", 4.0, Color(0.78, 0.78, 0.8)))
	# interview booths west
	for k in 4:
		var d0 := 3.0 + k * 6.0
		partition(-14, d0, -9, d0, 2.6, b.mat("tech", 2.0), 0.15)
		piece("ph:SchoolChair_01", -12.5, d0 + 2.5, 90)
		piece("ph:SchoolChair_01", -10.5, d0 + 2.5, 270)
		box(Vector3(1.0, 0.75, 0.8), -11.5, d0 + 2.5, 0.37, Mats.flat(Color(0.85, 0.85, 0.82), 0.5))
	partition(-14, 27, -9, 27, 2.6, b.mat("tech", 2.0), 0.15)
	label("INTERVIEW 1–4", -9.0, 2.6, 2.4, 270, 36, Color(0.9, 0.9, 0.95))
	# mock supermarket aisle
	for x in [-3.0, 1.0]:
		for d in [8.0, 12.0, 16.0, 20.0, 24.0]: shelf(x, d, 0.0, int(d) + int(x))
	label("AISLE 7 · SNACKS · EYE-LEVEL PAID PLACEMENT", -1.0, 6.4, 2.6, 180, 32, Color(1.0, 0.85, 0.4))
	piece("ph:industrial_storage_cart", 2.5, 4.0, 0)
	# observation gallery north (dark)
	partition(-14, 32, -8, 32, 3.0)
	box(Vector3(12.0, 2.2, 0.06), -2.0, 32.0, 1.6, Mats.glass(), true)
	partition(4, 32, 4, 34.5, 3.0)
	for k2 in 4: piece("ph:metal_stool_02", -10.0 + k2 * 3.0, 33.5, 180)
	desk(-6.0, 36.5, 180, "monitor")
	intel(0, -6.0, 36.6, 180, 0.79)
	dark(-14, 32, 4, 40)
	note("Observation gallery: dark", -5, 34)
	# profiling desk east
	for d2 in [24.0, 28.0]: desk(7.5, d2, 270, "monitor")
	box(Vector3(0.1, 2.0, 6.0), 9.5, 26.0, 1.5, Mats.flat(Color(0.9, 0.9, 0.86), 0.8), false)
	label("PROFILE · HOUSEHOLD 2241", 9.44, 26.0, 2.3, 270, 32, Color(0.1, 0.1, 0.1))
	for p in [[10.0, 6.0, 1], [11.0, 14.0, 0], [8.0, 36.0, 2]]: crates(p[0], p[1], 0.0, p[2])
	anchor("path", [P(-5.5, 6), P(-5.5, 30), P(6, 30), P(6, 37.5)])
	note("Courier route", -5.5, 18)
	for d3 in [6.0, 14.0, 22.0, 30.0]: lamp(-1.0, d3, 5.8, 5.0, 62, Color(1.0, 0.95, 0.85), "")
	fill(0, 20, 4.0, Color(0.6, 0.62, 0.68), 0.35, 24.0)
	terminal(10.0, 38.5, 180)
	guard(7.5, 22.0, 180)
	guard(-11.5, 30.0, 0, [[-11.5, 30, 3, 90], [-11.5, 2, 3, 90]])
	guard(4.0, 12.0, 0, [[4, 12, 2, 270], [4, 22, 2, 270]], "css", 1)
	guard(-2.0, 38.0, 180, [], "css", 2)
	for p in [[-6, 39], [6, 38], [0, 36], [12, 30], [12, 2]]: spawn(p[0], p[1])
