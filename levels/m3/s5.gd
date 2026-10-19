extends Sector
## M3 · Sector 6 · CUSTOMS HALL — where seized Meridian cargo is inspected.
## Read: the west wall is the X-ray tunnel (a dark covered lane you can move through unseen).
## Opened Meridian containers sit in the middle with goods spilled out; inspection tables run in
## two lines; seized-goods cages line the east wall. Two intel docs: one on an inspection table,
## one in the supervisor's cage.

func dims() -> Vector3: return Vector3(36, 9, 40)

func build() -> void:
	strategy_wall(17.3, 34.0, 270, 3.0)
	floor_rect(-18, 0, 18, 40, "", 0.0, b.mat("CONCRETE"))
	ceiling(-18, 0, 18, 40, 9.0)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallBand", "TopCables")
	wall(-18, 40, 18, 40, Vector2(0, 35), "WWWWDWWWW", "WallBand", "TopCables")
	wall(-18, 0, -18, 40, Vector2(0, 20), "", "WallBand", "TopCables")
	wall(18, 0, 18, 40, Vector2(0, 20), "", "WallBand", "TopCables")
	for s in [0.0, 40.0]: wall(-18, s, 18, s, Vector2(0, 20), "", "WallBand", "", 5.0)
	wall(-18, 0, -18, 40, Vector2(0, 20), "", "WallBand", "", 5.0)
	wall(18, 0, 18, 40, Vector2(0, 20), "", "WallBand", "", 5.0)
	# X-ray tunnel (west)
	box(Vector3(0.3, 3.2, 26.0), -11.0, 20.0, 1.6, b.mat("techc", 2.0))
	box(Vector3(4.3, 0.3, 26.0), -13.0, 20.0, 3.35, b.mat("techc", 2.0))
	conveyor(-13.0, 8.0, -13.0, 32.0, 0.6, 5)
	for d in [12.0, 20.0, 28.0]:
		box(Vector3(4.0, 0.08, 0.3), -13.0, d, 3.1, Mats.glow(Color(0.4, 1.0, 0.6), 2.0), false)
	label("X-RAY · LANE 2", -11.0, 7.0, 2.6, 180, 48, Color(0.5, 1.0, 0.6))
	dark(-15, 7, -11, 33)
	note("X-ray tunnel: dark lane", -13, 6)
	# opened Meridian containers
	containers(-3.0, 14.0, 0.0, 1, 0)
	containers(4.0, 26.0, 0.0, 1, 1)
	label("MERIDIAN LOGISTICS", -3.0, 10.85, 2.5, 180, 64, Color(0.9, 0.9, 0.9))
	label("MERIDIAN LOGISTICS", 4.0, 22.85, 2.5, 180, 64, Color(0.9, 0.9, 0.9))
	for k in 5:
		piece("ph:cardboard_box_01", -3.5 + k * 0.6, 9.4 - (k % 2) * 0.5, k * 20.0)
		piece("ph:cardboard_box_01", 3.6 + k * 0.5, 21.6 - (k % 2) * 0.5, k * 25.0)
	# inspection tables
	for d2 in [8.0, 16.0, 24.0, 32.0]:
		box(Vector3(3.0, 0.92, 1.2), 9.0, d2, 0.46, b.mat("steel", 1.0))
		piece("ph:plastic_crate_02", 8.6, d2, 15, 0.92, "none")
		piece("ph:clipboard", 9.8, d2, 0, 0.92, "none")
		cover_pt(9.0, d2 - 1.3); cover_pt(9.0, d2 + 1.3)
	intel(0, 9.6, 16.0, 0, 0.94)
	# seized cages (east)
	for d3 in [6.0, 14.0, 22.0, 30.0]:
		piece("ph:modular_chainlink_fence", 13.6, d3, 90, 0, "box")
		shelf(16.6, d3, 270, int(d3))
	glass_room(12.0, 33.0, 17.6, 39.6, "w", 0.5)
	desk(15.0, 37.5, 180, "monitor")
	intel(1, 15.0, 37.6, 180, 0.79)
	label("SEIZED · HOLD FOR REVIEW", 17.8, 18.0, 4.0, 270, 56, Color(1.0, 0.45, 0.35))
	for d4 in [8.0, 20.0, 32.0]: lamp(0.0, d4, 8.8, 7.0, 62, Color(1.0, 0.9, 0.75), "q:Prop_Light_Wide")
	for d5 in [10.0, 26.0]: lamp(9.0, d5, 8.8, 5.0, 60, Color(0.95, 0.97, 1.0), "")
	fill(0, 20, 6.0, Color(0.55, 0.6, 0.72), 0.35, 30.0)
	terminal(-6.0, 38.0, 180)
	guard(0.5, 4.0, 0, [[0.5, 4, 2, 90], [0.5, 34, 3, 270]])
	guard(9.0, 28.0, 180, [[9, 28, 2, 270], [9, 4, 2, 270]])
	guard(-13.0, 36.0, 180)
	guard(14.0, 35.0, 250, [], "heavy", 1)
	guard(-6.0, 26.0, 90, [], "css", 1)
	guard(5.0, 36.0, 200, [], "marksman", 2)
	for p in [[-6, 38], [6, 38], [0, 37], [-15, 37], [-8, 4]]: spawn(p[0], p[1])
