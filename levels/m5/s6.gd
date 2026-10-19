extends Sector
## M5 · Sector 7 · B2B EXCHANGE — a private trade floor where Castellan's buying centre meets
## suppliers. Silent start: delegates mingle, security watches; get spotted and it goes loud.
## Read: three vendor stands (west, centre, east) with counters and backdrop walls; a bar along the
## north wall; high tables scattered between. Stands are cover; the bar is the defenders' line.

func dims() -> Vector3: return Vector3(36, 8, 40)

func build() -> void:
	strategy_wall(-17.3, 6.0, 90, 3.0)
	floor_rect(-18, 0, 18, 40, "", 0.0, Mats.flat(Color(0.12, 0.13, 0.17), 0.7))
	ceiling(-18, 0, 18, 40, 8.0)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallAstra", "TopAstra")
	wall(-18, 40, 18, 40, Vector2(0, 30), "WWWWDWWWW", "WallAstra", "TopAstra")
	wall(-18, 0, -18, 40, Vector2(0, 20), "", "WallAstra", "TopAstra")
	wall(18, 0, 18, 40, Vector2(0, 20), "", "WallAstra", "TopAstra")
	for s in [0.0, 40.0]: wall(-18, s, 18, s, Vector2(0, 20), "", "WallAstra", "", 5.0)
	wall(-18, 0, -18, 40, Vector2(0, 20), "", "WallAstra", "", 5.0)
	wall(18, 0, 18, 40, Vector2(0, 20), "", "WallAstra", "", 5.0)
	var stands := [[-11.0, 16.0, "HALDANE SUPPLY", Color(0.3, 0.8, 1.0)], [0.0, 22.0, "NORTHLINE PACKAGING", Color(1.0, 0.7, 0.3)], [11.0, 16.0, "VERIDIAN FLEET", Color(0.45, 1.0, 0.55)]]
	for st in stands:
		var x: float = st[0]; var d: float = st[1]
		floor_rect(x - 4.0, d - 3.0, x + 4.0, d + 3.0, "", 0.06, Mats.flat(Color(0.85, 0.85, 0.85), 0.4))
		box(Vector3(8.0, 3.6, 0.2), x, d + 3.0, 1.8, Mats.flat(Color(0.95, 0.95, 0.95), 0.4))
		label(String(st[2]), x, d + 2.88, 3.0, 180, 72, st[3])
		box(Vector3(8.0, 0.1, 0.06), x, d + 2.88, 3.5, Mats.glow(st[3], 3.0), false)
		box(Vector3(3.0, 1.05, 0.8), x, d - 1.5, 0.52, Mats.flat(Color(0.1, 0.1, 0.12), 0.4))
		piece("ph:classic_laptop", x, d - 1.5, 180, 1.05, "none")
		piece("ph:Television_01", x + 2.6, d + 2.3, 180, 0.0, "box")
		cover_pt(x, d - 2.7); cover_pt(x - 4.7, d); cover_pt(x + 4.7, d)
		fill(x, d, 3.5, st[3].lerp(Color.WHITE, 0.6), 0.8, 7.0)
	# bar north
	box(Vector3(14.0, 1.1, 1.0), 0, 35.0, 0.55, Mats.flat(Color(0.25, 0.16, 0.1), 0.5))
	box(Vector3(14.2, 0.06, 1.2), 0, 35.0, 1.12, b.mat("MARBLE"), false)
	box(Vector3(14.0, 2.4, 0.3), 0, 39.4, 1.6, Mats.flat(Color(0.2, 0.13, 0.08), 0.5))
	for k in 6: piece("ph:metal_stool_01", -6.0 + k * 2.4, 34.0, 0)
	glow_strip(0, 39.2, 2.9, 14.0, 90.0, Color(1.0, 0.6, 0.3), 3.0)
	# high tables
	for p in [[-6.0, 8.0], [5.0, 9.0], [-4.0, 29.0], [6.0, 29.5], [-12.0, 28.0], [13.0, 27.0]]:
		b.cyl(geo, 0.4, 0.05, P(p[0], p[1], 1.08), Mats.flat(Color(0.95, 0.95, 0.95), 0.3))
		b.cyl(geo, 0.05, 1.08, P(p[0], p[1], 0.54), b.mat("steel", 1.0), Vector3.ZERO, true)
	intel(0, -11.0, 14.5, 180, 1.07)
	intel(1, 6.0, 35.0, 0, 1.15)
	for d2 in [8.0, 20.0, 32.0]:
		for x2 in [-10.0, 0.0, 10.0]: lamp(x2, d2, 7.8, 4.0, 50, Color(1.0, 0.9, 0.78), "")
	fill(0, 20, 6.0, Color(0.6, 0.55, 0.7), 0.4, 28.0)
	terminal(-14.0, 38.0, 180)
	guard(-6.0, 12.0, 0, [[-6, 12, 3, 90], [6, 12, 3, 270]])
	guard(0.0, 33.5, 180)
	guard(-15.0, 22.0, 90, [[-15, 22, 3, 90], [-15, 6, 3, 90]])
	guard(15.0, 8.0, 270, [[15, 8, 3, 270], [15, 30, 3, 270]])
	guard(-9.0, 34.0, 160, [], "css", 1)
	guard(9.0, 34.0, 200, [], "heavy", 1)
	guard(0.0, 15.0, 0, [], "css", 2)
	for p in [[-6, 38], [6, 38], [-14, 34], [14, 34], [0, 30]]: spawn(p[0], p[1])
