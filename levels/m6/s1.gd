extends Sector
## M6 · Sector 2 · SEGMENTATION FLOOR — Castellan's targeting analysts split the market here.
## Read: the floor is painted as a coloured grid of segments (geographic, demographic,
## psychographic, behavioural), each with a labelled pillar. Analyst desks sit in arcs facing the
## north screen wall, where the routing consoles take Marr's segmentation calls.

func dims() -> Vector3: return Vector3(36, 6, 40)

func build() -> void:
	strategy_wall(-17.3, 6.0, 90, 2.8)
	floor_rect(-18, 0, 18, 40, "", 0.0, Mats.flat(Color(0.15, 0.16, 0.19), 0.8))
	ceiling(-18, 0, 18, 40, 5.5)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallAstra", "TopSimple")
	wall(-18, 40, 18, 40, Vector2(0, 30), "WWWWDWWWW", "WallAstra", "TopSimple")
	wall(-18, 0, -18, 40, Vector2(0, 20), "", "WallAstra", "TopSimple")
	wall(18, 0, 18, 40, Vector2(0, 20), "", "WallAstra", "TopSimple")
	var segs := [["GEOGRAPHIC", Color(0.3, 0.7, 1.0)], ["DEMOGRAPHIC", Color(1.0, 0.65, 0.25)], ["PSYCHOGRAPHIC", Color(0.75, 0.45, 1.0)], ["BEHAVIOURAL", Color(0.35, 1.0, 0.55)]]
	for i in 4:
		var x0 := -16.0 + i * 8.0
		for j in 3:
			var d0 := 4.0 + j * 8.0
			box(Vector3(7.6, 0.02, 7.6), x0 + 4.0, d0 + 4.0, 0.012, Mats.flat(segs[i][1].darkened(0.55 + 0.1 * j), 0.8), false)
		box(Vector3(0.8, 5.5, 0.8), x0 + 4.0, 16.0, 2.75, Mats.flat(Color(0.1, 0.1, 0.12), 0.5))
		box(Vector3(0.82, 0.2, 0.82), x0 + 4.0, 16.0, 3.4, Mats.glow(segs[i][1], 3.0), false)
		label(segs[i][0], x0 + 4.0, 15.58, 2.6, 180, 36, segs[i][1])
		cover_pt(x0 + 4.0, 14.9); cover_pt(x0 + 4.0, 17.1)
	# desk arcs facing north
	for row in 2:
		var rad := 9.0 + row * 6.0
		for k in 5:
			var a := deg_to_rad(-40.0 + k * 20.0)
			desk(sin(a) * rad, 36.0 - cos(a) * rad, rad_to_deg(-a), "monitor")
	call_panels([0, 39.4, 180], [[-6.0, 34.5, 180], [-2.0, 34.5, 180], [2.0, 34.5, 180], [6.0, 34.5, 180]])
	label("SEGMENT · TARGET · POSITION", 0, 39.8, 4.6, 180, 48, Color(0.8, 0.9, 1.0))
	piece("ph:CoffeeCart_01", 16.0, 4.0, 270)
	piece("ph:Shelf_01", -17.3, 30.0, 90)
	intel(0, sin(deg_to_rad(-40.0)) * 15.0, 36.0 - cos(deg_to_rad(-40.0)) * 15.0, 40, 0.79)
	ceiling_lights(-18, 0, 18, 40, 5.5, 3, 4, 5.5, Color(0.9, 0.93, 1.0))
	guard(-12.0, 6.0, 0, [[-12, 6, 2, 90], [-12, 30, 2, 90]])
	guard(12.0, 30.0, 180, [[12, 30, 2, 270], [12, 6, 2, 270]])
	guard(0.0, 24.0, 180)
	guard(-8.0, 33.0, 160, [], "heavy", 1)
	guard(8.0, 33.0, 200, [], "css", 1)
	guard(0.0, 8.0, 0, [], "marksman", 2)
	for p in [[-12, 38], [12, 38], [-16, 34], [16, 34], [0, 30]]: spawn(p[0], p[1])
