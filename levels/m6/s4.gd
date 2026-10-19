extends Sector
## M6 · Sector 5 · TARGETING ARRAY — defend the array console while Marr re-points Castellan's
## targeting model. Read: concrete shell with glass along the north wall (the dish array outside);
## the console sits in a ring of operator consoles in the middle; server rows on both flanks give
## the attackers cover and you flanking lanes.

func dims() -> Vector3: return Vector3(28, 7, 32)

func build() -> void:
	strategy_wall(-13.3, 4.0, 90, 3.0)
	floor_rect(-14, 0, 14, 32, "q:Platform_DarkPlates")
	concrete_shell(7.0, 8.0, true, b.mat("CONCRETE", 4.0, Color(0.7, 0.72, 0.76)))
	box(Vector3(16.0, 3.4, 0.12), 0, 31.4, 3.2, Mats.flat(Color(0.02, 0.03, 0.05), 0.3), false)
	for k in 3:
		var dc := b.cyl(geo, 1.2, 0.05, P(-5.0 + k * 5.0, 31.3, 3.3), Mats.glow(Color(0.3, 0.75, 1.0), 1.2))
		dc.rotation = Vector3(PI * 0.5, 0, 0)
		label("DISH %d · TRACKING" % (k + 1), -5.0 + k * 5.0, 31.3, 1.8, 180, 30, Color(0.6, 0.85, 1.0))
	anchor("console", P(0, 17))
	note("Array console: hold here", 0, 17)
	for k2 in 6:
		var a := TAU * k2 / 6.0 + 0.5
		var cx := sin(a) * 3.6; var cd := 17.0 + cos(a) * 3.6
		box(Vector3(1.3, 1.0, 0.7), cx, cd, 0.5, b.mat("gunmetal", 1.0), true, rad_to_deg(a))
		box(Vector3(1.1, 0.5, 0.04), cx, cd, 1.3, Mats.glow(Color(0.3, 0.75, 1.0), 1.4), false, rad_to_deg(a))
		cover_pt(sin(a) * 4.6, 17.0 + cos(a) * 4.6)
	for x in [-10.0, 10.0]:
		server_row(x, 10.0, 0, 7)
		server_row(x, 23.0, 0, 7)
	label("TARGETING ARRAY · NG-3", 0, 31.4, 5.2, 180, 56, Color(0.6, 0.85, 1.0))
	intel(0, -12.5, 30.0, 90, 0.79, "ph:metal_office_desk")
	for p in [[-5.0, 6.0, 0], [5.0, 6.0, 1], [-5.0, 28.0, 1], [5.0, 28.0, 0]]: crates(p[0], p[1], 0.0, p[2])
	ceiling_lights(-12, 2, 12, 30, 7.0, 3, 3, 6.0, Color(0.85, 0.9, 1.0))
	fill(0, 17, 4.0, Color(0.4, 0.55, 0.9), 0.5, 22.0)
	for p in [[-6, 30], [6, 30], [0, 30], [-12, 2], [12, 2], [-12, 16], [12, 16]]: spawn(p[0], p[1])
