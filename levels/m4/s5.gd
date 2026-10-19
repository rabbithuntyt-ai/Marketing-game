extends Sector
## M4 · Sector 6 · CONTACT CENTRE — Castellan Insight's survey and telephone-interview floor.
## Read: four pods of call desks fill the room in a grid with lanes between them; the supervisor's
## glass office sits up two steps in the north-east corner; a live stats wall on the north wall shows
## response rates. The break room (west) is a side route. The DIALER on the east wall is where Marr's
## questions get answered: walk to the console that routes the right survey method.

func dims() -> Vector3: return Vector3(36, 6, 36)

func build() -> void:
	strategy_wall(-17.3, 30.0, 90, 2.8)
	floor_rect(-18, 0, 18, 36, "", 0.0, Mats.flat(Color(0.16, 0.18, 0.22), 0.85))
	for k in 9: paint(-17.5, 2.0 + k * 4.0, 17.5, 2.0 + k * 4.0, Color(0.2, 0.22, 0.27), 1.2)
	ceiling(-18, 0, 18, 36, 5.0)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallBand", "TopSimple")
	wall(-18, 36, 18, 36, Vector2(0, 30), "WWWWDWWWW", "WallBand", "TopSimple")
	wall(-18, 0, -18, 36, Vector2(0, 18), "WGGWWWWWW", "WallBand", "TopSimple")
	wall(18, 0, 18, 36, Vector2(0, 18), "", "WallBand", "TopSimple")
	# --- call pods: 2x2 grid, each a cross of 4 desks with low dividers
	for c in [[-7.5, 10.0], [3.5, 10.0], [-7.5, 22.0], [3.5, 22.0]]:
		var cx: float = c[0]; var cd: float = c[1]
		for q in [[-1.3, -1.0, 0.0], [1.3, -1.0, 0.0], [-1.3, 1.0, 180.0], [1.3, 1.0, 180.0]]:
			desk(cx + q[0] * 1.25, cd + q[1] * 1.3, q[2], "monitor")
		box(Vector3(5.6, 1.3, 0.08), cx, cd, 0.65, Mats.flat(Color(0.3, 0.42, 0.55), 0.8))
		box(Vector3(0.08, 1.3, 4.6), cx, cd, 0.65, Mats.flat(Color(0.3, 0.42, 0.55), 0.8))
		lamp(cx, cd, 4.9, 5.5, 64, Color(0.95, 0.97, 1.0), "q:Prop_Light_Wide")
		cover_pt(cx - 3.4, cd); cover_pt(cx + 3.4, cd)
	note("Call pods: lanes at x −13, −2, 9", -2, 4)
	# --- supervisor office (raised, glass)
	floor_rect(4, 29, 13, 35.6, "", 0.25, b.mat("metal", 2.0))
	ramp(8.5, 27.0, 0.0, 0.25, 2.0, 2.0)
	glass_room(4, 29, 13, 35.6, "s", 0.5)
	desk(8.5, 33.5, 180, "monitor")
	piece("ph:drawer_cabinet", 12.4, 34.8, 270, 0.25)
	piece("ph:modern_arm_chair_01", 5.2, 31.0, 90, 0.25)
	intel(0, 8.5, 33.6, 180, 1.04)
	label("SUPERVISOR", 8.5, 29.0, 3.0, 180, 46, Color(0.85, 0.9, 1.0))
	# --- stats wall
	box(Vector3(10.0, 2.4, 0.1), -6.0, 35.8, 3.3, Mats.flat(Color(0.02, 0.03, 0.04), 0.4), false)
	for k in 5:
		box(Vector3(1.2, 0.3 + k * 0.32, 0.04), -10.0 + k * 2.0, 35.72, 2.4 + (0.3 + k * 0.32) * 0.5, Mats.glow(Color(0.3, 0.85, 1.0).lerp(Color(1.0, 0.45, 0.3), k / 4.0), 2.5), false)
	label("RESPONSE RATE · TODAY", -6.0, 35.7, 4.3, 180, 52, Color(0.8, 0.9, 1.0), "IBMPlexMono-Medium")
	# --- break room (west)
	partition(-18, 28, -11, 28, 3.0)
	partition(-11, 28, -11, 32.4, 3.0)
	partition(-11, 34.0, -11, 36, 3.0)
	piece("ph:CoffeeCart_01", -16.5, 34.6, 90)
	piece("ph:sofa_02", -14.0, 29.0, 0)
	piece("ph:dining_table", -14.5, 32.5, 0)
	piece("ph:metal_trash_can", -12.0, 35.2, 0)
	intel(1, -14.5, 32.5, 20, 0.78)
	fill(-14.5, 32.0, 2.5, Color(1.0, 0.85, 0.6), 0.8, 6.0)
	# --- dialer (routing consoles) on the east wall
	call_panels([17.6, 18.0, 270], [[14.0, 12.0, 270], [14.0, 16.0, 270], [14.0, 20.0, 270], [14.0, 24.0, 270]])
	label("DIALER · ROUTE THE STUDY", 17.6, 18.0, 4.5, 270, 44, Color(0.6, 0.85, 1.0))
	for d in [4.0, 30.0]: piece("ph:Shelf_01", 17.2, d, 270)
	piece("ph:WetFloorSign_01", -2.0, 16.0, 30)
	fill(0, 18, 4.0, Color(0.55, 0.62, 0.8), 0.4, 26.0)
	camera(-17.4, 35.4, 4.2, 135, 30, 9.0, 18.0)
	# --- gameplay
	guard(-2.0, 6.0, 0, [[-2, 6, 2, 270], [-2, 28, 3, 90]])
	guard(9.5, 16.0, 0, [[9.5, 16, 3, 90], [9.5, 4, 2, 270]])
	guard(8.5, 31.0, 180, [], "css", 0, 0.25)
	guard(-13.0, 16.0, 90, [[-13, 16, 3, 0], [-13, 4, 2, 90]])
	guard(-14.0, 30.5, 120, [], "css", 1)
	guard(14.5, 28.0, 250, [], "heavy", 1)
	guard(3.5, 16.0, 0, [], "css", 2)
	for p in [[-6, 33], [0, 33], [6, 26], [-15, 24], [15, 6]]: spawn(p[0], p[1])
