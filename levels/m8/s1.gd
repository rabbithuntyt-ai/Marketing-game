extends Sector
## M8 · Sector 2 · STRATEGY FLOOR — where the board plans Meridian. A glass war room in the middle;
## planning cells (open-front team rooms) along both sides; Voss's private study in the north-west
## corner, with the terminal that holds the board's plan.

func dims() -> Vector3: return Vector3(36, 6, 40)

func build() -> void:
	city_view(155.0)
	strategy_wall(17.3, 6.0, 270, 2.8)
	floor_rect(-18, 0, 18, 40, "", 0.0, Mats.flat(Color(0.25, 0.18, 0.12), 0.5))
	ceiling(-18, 0, 18, 40, 5.5)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallAstra", "TopAstra")
	wall(-18, 40, 18, 40, Vector2(0, 30), "WWWWDWWWW", "WallAstra", "TopAstra")
	wall(-18, 0, -18, 40, Vector2(0, 20), "GGGGGGGGGG", "WallAstra", "TopWindow")
	wall(18, 0, 18, 40, Vector2(0, 20), "GGGGGGGGGG", "WallAstra", "TopWindow")
	# war room
	glass_room(-5.0, 12.0, 5.0, 26.0, "s", 0.5)
	box(Vector3(3.0, 0.08, 9.0), 0, 19.0, 0.76, Mats.flat(Color(0.08, 0.08, 0.1), 0.3))
	box(Vector3(2.6, 0.72, 8.0), 0, 19.0, 0.36, Mats.flat(Color(0.07, 0.07, 0.08), 0.4))
	box(Vector3(2.8, 0.02, 8.6), 0, 19.0, 0.81, Mats.glow(Color(0.3, 0.6, 1.0), 0.9), false)
	label("MERIDIAN · PHASE 3", 0, 19.0, 0.83, 0, 70, Color(0.9, 0.95, 1.0)).rotation.x = -PI * 0.5
	for k in 4:
		piece("ph:modern_arm_chair_01", -2.2, 15.5 + k * 2.4, 90)
		piece("ph:modern_arm_chair_01", 2.2, 15.5 + k * 2.4, 270)
	cover_pt(0, 10.8); cover_pt(-6.2, 19.0); cover_pt(6.2, 19.0)
	# planning cells
	for s in [-1.0, 1.0]:
		for k2 in 3:
			var d0 := 4.0 + k2 * 9.0
			var xw: float = s * 18.0; var xi: float = s * 11.0
			partition(xi, d0, xw, d0, 2.8, Mats.flat(Color(0.88, 0.86, 0.82), 0.6), 0.2)
			box(Vector3(0.1, 2.0, 3.0), xi, d0 + 6.0, 1.2, Mats.flat(Color(0.95, 0.95, 0.95), 0.8), true)
			desk(s * 14.5, d0 + 4.0, -90.0 * s, "laptop")
	# Voss's study NW
	partition(-18, 31, -9, 31, 3.0, Mats.flat(Color(0.3, 0.2, 0.12), 0.5), 0.3)
	partition(-9, 31, -9, 33.5, 3.0, Mats.flat(Color(0.3, 0.2, 0.12), 0.5), 0.3)
	partition(-9, 35.5, -9, 40, 3.0, Mats.flat(Color(0.3, 0.2, 0.12), 0.5), 0.3)
	piece("ph:modern_wooden_cabinet", -17.4, 33.0, 90)
	piece("ph:mid_century_lounge_chair", -11.0, 38.0, 200)
	piece("ph:Shelf_01", -15.0, 39.4, 180)
	label("E. VOSS · CHAIR", -9.05, 37.5, 2.5, 270, 36, Color(0.95, 0.85, 0.6))
	fill(-13.5, 35.0, 2.6, Color(1.0, 0.8, 0.55), 0.8, 7.0)
	terminal(-13.5, 35.0, 90)
	note("Voss's study: the uplink", -13, 34)
	ceiling_lights(-10, 0, 10, 40, 5.5, 2, 4, 5.5, Color(1.0, 0.95, 0.88))
	guard(0.0, 9.0, 180, [[0, 9, 2, 90], [0, 29, 2, 270]])
	guard(-8.0, 20.0, 90, [[-8, 20, 2, 90], [-8, 34, 2, 90]])
	guard(8.0, 34.0, 180, [[8, 34, 2, 270], [8, 6, 2, 270]])
	guard(-12.0, 37.0, 90, [], "heavy", 0)
	guard(12.0, 26.0, 270, [], "css", 1)
	guard(0.0, 33.0, 180, [], "marksman", 2)
	for p in [[-4, 38], [6, 38], [14, 36], [0, 36], [14, 2]]: spawn(p[0], p[1])
