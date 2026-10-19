extends Sector
## M4 · Sector 5 · RESEARCH LAB — where Castellan Insight runs its observational and experimental
## research. Read, left to right:
##   WEST  — a mock "home" living room (ethnographic study) behind a one-way mirror, with a dark
##           observation booth beside it. Researchers watch families use products.
##   CENTRE— lab benches (experimental research): two lines of benches with sample cases, cover.
##   EAST  — focus-group room in glass, chairs in a ring, a moderator's camera on a tripod.
##   NORTH — a mezzanine over the home set (west) with the data desk and the intel; stairs at x −4.
## Silent start: the room is guarded; get spotted and the whole lab goes loud.

func dims() -> Vector3: return Vector3(28, 7, 36)

func build() -> void:
	strategy_wall(13.3, 8.0, 270, 3.0)
	floor_rect(-14, 0, 14, 36, "q:Platform_Squares")
	ceiling(-14, 0, 14, 36, 7.0)
	wall(-14, 0, 14, 0, Vector2(0, 5), "WWWDWWW", "WallAstra", "TopPlastic")
	wall(-14, 36, 14, 36, Vector2(0, 30), "WWWDWWW", "WallAstra", "TopPlastic")
	wall(-14, 0, -14, 36, Vector2(0, 18), "", "WallAstra", "TopPlastic")
	wall(14, 0, 14, 36, Vector2(0, 18), "", "WallAstra", "TopPlastic")
	for s in [0.0, 36.0]: wall(-14, s, 14, s, Vector2(0, 18), "", "WallAstra", "", 5.0)
	wall(-14, 0, -14, 36, Vector2(0, 18), "", "WallAstra", "", 5.0)
	wall(14, 0, 14, 36, Vector2(0, 18), "", "WallAstra", "", 5.0)
	# --- WEST: home set (living room) + one-way mirror + dark observation booth
	floor_rect(-13.6, 6, -6.2, 18, "", 0.02, Mats.flat(Color(0.42, 0.3, 0.2), 0.7))
	piece("ph:sofa_03", -11.5, 15.8, 180)
	piece("ph:modern_coffee_table_01", -11.0, 13.2, 0)
	piece("ph:ArmChair_01", -8.0, 13.0, 250)
	piece("ph:Television_01", -11.2, 7.0, 0, 0.0, "box")
	piece("ph:side_table_01", -13.0, 9.0, 0)
	piece("ph:wall_clock", -13.7, 12.0, 90, 2.2, "none")
	piece("ph:CoffeeTable_01", -8.0, 8.0, 0)
	piece("ph:Shelf_01", -13.4, 16.8, 90)
	label("STUDY H-3 · \"HOME\" · DAY 11", -10, 6.2, 2.6, 0, 40, Color(1.0, 0.9, 0.7))
	fill(-10.0, 12.0, 2.6, Color(1.0, 0.82, 0.6), 0.9, 8.0)
	box(Vector3(0.06, 2.8, 12.0), -6.0, 12.0, 1.4, Mats.glass(), true)     # one-way mirror
	box(Vector3(0.12, 0.2, 12.0), -6.0, 12.0, 2.9, b.mat("gunmetal", 1.0), false)
	partition(-6.0, 18.0, -2.0, 18.0, 3.0)
	partition(-6.0, 6.0, -4.2, 6.0, 3.0)
	for k in 3: piece("ph:metal_stool_02", -5.0, 9.0 + k * 3.0, 270)
	desk(-3.4, 12.0, 270, "monitor", false)
	piece("ph:clipboard", -3.3, 13.0, 0, 0.78, "none")
	dark(-6, 6, -2, 18)
	note("Observation booth: dark, overlooks the home set", -4, 7)
	# --- mezzanine over the home set (data desk)
	catwalk(-14, 24, -2, 36, 3.0, "")
	stairs(-4.0, 17.9, 0.0, true)
	box(Vector3(12.0, 1.1, 0.05), -8.0, 24.0, 3.55, Mats.glass(), true)
	box(Vector3(0.05, 1.1, 6.0), -2.0, 30.0 + 3.0, 3.55, Mats.glass(), true)
	desk(-9.0, 33.5, 180, "monitor")
	desk(-6.5, 33.5, 180, "laptop")
	piece("ph:drawer_cabinet", -13.2, 34.8, 90, 3.0)
	intel(0, -9.0, 33.6, 180, 3.79)
	label("BEHAVIOURAL DATA · RESTRICTED", -8, 35.8, 5.6, 180, 48, Color(1.0, 0.4, 0.35))
	partition(-14, 24, -2, 24, 3.0, b.mat("techc", 2.0), 0.3)            # under-mezzanine back wall
	for x in [-11.0, -6.0]: piece("ph:steel_frame_shelves_02", x, 25.0, 180)
	# --- CENTRE: lab benches
	for d in [9.0, 15.0, 21.0, 27.0]:
		for x in [1.0, 5.0]:
			box(Vector3(3.2, 0.92, 1.1), x, d, 0.46, Mats.flat(Color(0.88, 0.9, 0.92), 0.35, 0.1))
			box(Vector3(3.3, 0.05, 1.2), x, d, 0.94, b.mat("gunmetal", 1.0), false)
			piece("q:Prop_Computer", x - 0.9, d, 180, 0.95, "none")
			piece("ph:circuit_board", x + 0.6, d, 30, 0.95, "none")
			cover_pt(x, d - 1.2); cover_pt(x, d + 1.2)
	glow_strip(3.0, 18.0, 6.8, 22.0, 0.0, Color(0.6, 0.85, 1.0), 3.0)
	piece("ph:industrial_storage_cart", 3.0, 31.0, 90)
	note("Experiment benches: low cover lanes", 3, 4)
	# --- EAST: focus-group glass room
	glass_room(7.5, 22.0, 13.6, 33.5, "w", 0.25)
	for k in 8:
		var a := TAU * k / 8.0
		piece("ph:plastic_monobloc_chair_01", 10.6 + sin(a) * 2.2, 28.0 + cos(a) * 2.2, rad_to_deg(a) + 180.0, 0.0, "none")
	piece("ph:CoffeeTable_01", 10.6, 28.0, 0)
	piece("ph:projector_screen", 13.2, 28.0, 270, 0.0, "none")
	label("FOCUS GROUP B · 19:00", 10.6, 22.0, 2.6, 180, 40, Color(0.7, 0.9, 1.0))
	fill(10.6, 28.0, 2.6, Color(0.9, 0.95, 1.0), 0.8, 7.0)
	for d2 in [8.0, 13.0]: crates(11.5, d2, 90, 1)
	piece("ph:tool_cart", 12.5, 17.5, 270)
	# --- light
	ceiling_lights(-1, 4, 13, 34, 7.0, 2, 3, 7.0, Color(0.9, 0.95, 1.0))
	lamp(-8.0, 30.0, 6.8, 5.0, 60.0, Color(0.9, 0.95, 1.0), "")
	fill(0, 18, 5.0, Color(0.5, 0.6, 0.8), 0.35, 26.0)
	camera(13.4, 2.0, 5.0, 330, 30, 8.0, 18.0)
	intel(1, 12.0, 30.5, 270, 0.4)
	terminal(6.0, 35.0, 180)
	# --- gameplay
	guard(-8.0, 30.0, 180, [[-8, 30, 3, 180], [-12, 30, 3, 270]], "css", 0, 3.0)
	guard(3.0, 12.0, 0, [[3, 12, 2, 270], [3, 30, 2, 90]])
	guard(-4.0, 9.0, 90)
	guard(9.5, 20.0, 180, [[9.5, 20, 3, 270], [9.5, 4, 3, 90]])
	guard(-9.0, 10.0, 20, [], "css", 1)
	guard(11.0, 34.0, 200, [], "heavy", 1)
	guard(0.0, 33.0, 180, [], "css", 2)
	for p in [[-4, 33], [4, 33], [0, 31], [12, 6], [-12, 21]]: spawn(p[0], p[1])
