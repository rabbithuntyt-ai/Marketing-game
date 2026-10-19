extends Sector
## M6 · Sector 7 · VALUE PROPOSITION HALL — Castellan's launch auditorium, staged for the
## "CASTELLAN ASSURE" reveal. Read: rows of seating fill the floor (low cover); a stage across
## the north end with ramps at both sides and a huge screen above the exit; press risers on either side (1.8 m)
## hold guards with a view over the seats. The aisles are the lanes.

func dims() -> Vector3: return Vector3(36, 9, 44)

func build() -> void:
	strategy_wall(-17.3, 6.0, 90, 3.4)
	floor_rect(-18, 0, 18, 44, "", 0.0, Mats.flat(Color(0.1, 0.1, 0.13), 0.8))
	ceiling(-18, 0, 18, 44, 9.0)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallAstra", "TopAstra")
	wall(-18, 44, 18, 44, Vector2(0, 30), "WWWWDWWWW", "WallAstra", "TopAstra")
	wall(-18, 0, -18, 44, Vector2(0, 22), "", "WallAstra", "TopAstra")
	wall(18, 0, 18, 44, Vector2(0, 22), "", "WallAstra", "TopAstra")
	for s in [0.0, 44.0]: wall(-18, s, 18, s, Vector2(0, 22), "", "WallAstra", "", 5.0)
	wall(-18, 0, -18, 44, Vector2(0, 22), "", "WallAstra", "", 5.0)
	wall(18, 0, 18, 44, Vector2(0, 22), "", "WallAstra", "", 5.0)
	# seating blocks (aisles at x -9.5, 0, 9.5)
	for row in 7:
		var d := 9.0 + row * 2.6
		for blk in [[-14.5, -11.0], [-7.5, -2.0], [2.0, 7.5], [11.0, 14.5]]:
			box(Vector3(blk[1] - blk[0], 0.5, 0.6), (blk[0] + blk[1]) * 0.5, d, 0.25, Mats.flat(Color(0.35, 0.08, 0.1), 0.8))
			box(Vector3(blk[1] - blk[0], 0.9, 0.12), (blk[0] + blk[1]) * 0.5, d + 0.35, 0.45, Mats.flat(Color(0.3, 0.06, 0.08), 0.8))
		cover_pt(-9.5, d + 1.3); cover_pt(9.5, d + 1.3); cover_pt(0, d + 1.3)
	# stage
	box(Vector3(30.0, 1.2, 7.0), 0, 37.5, 0.6, Mats.flat(Color(0.08, 0.08, 0.1), 0.4))
	box(Vector3(30.0, 0.05, 0.1), 0, 34.0, 1.21, Mats.glow(accent, 3.0), false)
	for s2 in [-1.0, 1.0]: ramp(s2 * 16.0, 29.5, 0.0, 1.2, 4.5, 2.2)
	box(Vector3(20.0, 4.6, 0.2), 0, 43.6, 6.7, Mats.flat(Color(0.02, 0.02, 0.03), 0.3))
	label("CASTELLAN ASSURE", 0, 43.45, 7.6, 180, 260, Color(1.0, 0.92, 0.85))
	label("Peace of mind, priced for you.", 0, 43.45, 5.6, 180, 90, Color(1.0, 0.45, 0.35))
	box(Vector3(1.2, 1.2, 0.6), 0, 36.0, 1.8, Mats.flat(Color(0.85, 0.85, 0.85), 0.3))
	for x in [-8.0, 8.0]: piece("tps:prop_tripodlight", x, 35.0, 0, 1.2)
	# press risers
	for s3 in [-1.0, 1.0]:
		box(Vector3(4.0, 1.8, 8.0), s3 * 15.5, 16.0, 0.9, b.mat("metal", 2.0))
		rail(s3 * 13.5, 12.0, s3 * 13.5, 20.0, 1.8)
		ramp(s3 * 15.5, 6.0, 0.0, 1.8, 6.0, 2.0)
		piece("tps:prop_tripodlight", s3 * 15.5, 17.0, 180, 1.8)
	intel(0, 0.0, 36.0, 180, 2.42)
	for x2 in [-12.0, -4.0, 4.0, 12.0]: lamp(x2, 38.0, 8.8, 9.0, 45, Color(1.0, 0.95, 0.88), "")
	for d2 in [10.0, 20.0, 28.0]: lamp(0.0, d2, 8.8, 3.5, 70, Color(0.7, 0.75, 1.0), "")
	fill(0, 40, 5.0, Color(1.0, 0.9, 0.8), 0.6, 18.0)
	fill(0, 18, 6.0, Color(0.4, 0.4, 0.6), 0.25, 26.0)
	dark(-18, 6, 18, 28)
	terminal(-12.0, 41.0, 180)
	guard(-15.5, 16.0, 90, [], "marksman", 0, 1.8)
	guard(15.5, 16.0, 270, [], "css", 0, 1.8)
	guard(0.0, 30.0, 180, [[0, 30, 3, 180], [0, 8, 3, 0]])
	guard(-6.0, 36.0, 180, [], "heavy", 1, 1.2)
	guard(9.5, 26.0, 200, [], "css", 1)
	guard(6.0, 37.0, 180, [], "css", 2, 1.2)
	for p in [[-16, 36], [16, 36], [0, 31], [-12, 31], [12, 31]]: spawn(p[0], p[1])
