extends Sector
## M7 · Sector 1 · TOWER LOBBY — Castellan Tower, Financial District, Toronto. 23:40.
## Read: a three-storey glass lobby. The giant logo wall faces you; security turnstiles cross the
## floor at 12 m; the reception desk sits behind them; marble columns in two rows; a glass bridge at
## 6 m spans the lobby from the west stair to the east stair — the guards up there see everything.

func dims() -> Vector3: return Vector3(36, 13, 44)

func build() -> void:
	city_view(-100.0)
	strategy_wall(-17.3, 38.0, 90, 3.0)
	floor_rect(-18, 0, 18, 44, "", 0.0, b.mat("MARBLE"))
	ceiling(-18, 0, 18, 44, 13.0)
	wall(-18, 0, 18, 0, Vector2(0, 5), "GGGGDGGGG", "WallAstra", "TopWindow")
	wall(-18, 44, 18, 44, Vector2(0, 30), "WWWWDWWWW", "WallAstra", "TopAstra")
	wall(-18, 0, -18, 44, Vector2(0, 22), "GGGGGGGGGGG", "WallAstra", "TopWindow")
	wall(18, 0, 18, 44, Vector2(0, 22), "GGGGGGGGGGG", "WallAstra", "TopWindow")
	for y in [5.0, 9.0]:
		wall(-18, 0, -18, 44, Vector2(0, 22), "GGGGGGGGGGG", "WallAstra", "", y)
		wall(18, 0, 18, 44, Vector2(0, 22), "GGGGGGGGGGG", "WallAstra", "", y)
		wall(-18, 44, 18, 44, Vector2(0, 30), "", "WallAstra", "", y)
		wall(-18, 0, 18, 0, Vector2(0, 5), "GGGGGGGGG", "WallAstra", "", y)
	# logo wall
	box(Vector3(14.0, 7.0, 0.4), 0, 43.5, 8.5, Mats.flat(Color(0.06, 0.06, 0.07), 0.3))
	label("CASTELLAN", 0, 43.25, 9.6, 180, 420, Color(0.95, 0.88, 0.7))
	label("VALUE, DELIVERED.", 0, 43.25, 7.6, 180, 120, Color(0.8, 0.75, 0.6))
	glow_strip(0, 43.2, 6.4, 14.0, 90.0, Color(1.0, 0.85, 0.55), 3.0)
	turnstiles(-14.0, 14.0, 12.0)
	note("Security gates: low cover", 0, 11)
	# reception
	box(Vector3(8.0, 1.15, 1.2), 0, 22.0, 0.57, Mats.flat(Color(0.9, 0.88, 0.84), 0.25))
	box(Vector3(8.2, 0.06, 1.4), 0, 22.0, 1.17, b.mat("gunmetal", 1.0), false)
	for x in [-2.0, 2.0]: piece("ph:Television_01", x, 22.4, 180, 1.17, "none")
	cover_pt(0, 20.7)
	intel(0, 3.2, 22.0, 180, 1.2)
	# columns
	for d in [8.0, 18.0, 28.0, 38.0]:
		for x2 in [-10.0, 10.0]:
			b.cyl(geo, 0.7, 13.0, P(x2, d, 6.5), b.mat("MARBLE", 1.0, Color(0.85, 0.85, 0.85)), Vector3.ZERO, true)
			cover_pt(x2 + 1.3, d); cover_pt(x2 - 1.3, d)
	# glass bridge at 6 m
	catwalk(-18, 30, 18, 33, 6.0, "")
	box(Vector3(36.0, 1.1, 0.05), 0, 30.0, 6.55, Mats.glass(), true)
	box(Vector3(36.0, 1.1, 0.05), 0, 33.0, 6.55, Mats.glass(), true)
	for sx in [-15.5, 15.5]:
		ramp(sx, 14.0, 0.0, 6.0, 16.0, 3.0, b.mat("MARBLE", 1.0))
		box(Vector3(0.05, 1.0, 16.6), sx + (1.55 if sx < 0 else -1.55), 22.0, 3.5, Mats.glass(), false)
	for p in [[-6.0, 34.0], [6.0, 34.0]]: piece("ph:sofa_03", p[0], p[1], 180)
	for p2 in [[-14.0, 4.0], [14.0, 4.0], [-14.0, 40.0], [14.0, 40.0]]: planter(p2[0], p2[1], 2.0, 2.0)
	for d3 in [6.0, 18.0, 30.0, 40.0]: lamp(0.0, d3, 12.8, 8.0, 55, Color(1.0, 0.9, 0.75), "")
	fill(0, 22, 9.0, Color(0.9, 0.85, 0.75), 0.5, 36.0)
	terminal(-6.0, 42.0, 180)
	guard(-12.0, 31.5, 90, [[-12, 31.5, 3, 180], [12, 31.5, 3, 180]], "marksman", 0, 6.0)
	guard(0.0, 23.5, 180)
	guard(-6.0, 14.0, 180, [[-6, 14, 2, 180], [6, 14, 2, 180]])
	guard(12.0, 38.0, 200, [], "heavy", 1)
	guard(-12.0, 20.0, 120, [], "css", 1)
	guard(0.0, 40.0, 180, [], "css", 2)
	for p in [[-6, 42], [6, 42], [-14, 36], [14, 36], [0, 36]]: spawn(p[0], p[1])
