extends Sector
## M3 · Sector 3 · HARBOUR OFFICE — the terminal's admin floor. Loud: the yard alarm is already up.
## Read: glass offices line the west wall; the map room in the middle is a glass box around a glowing
## chart table (the PESTEL forces pinned on the walls); window counters run along the east wall
## looking out at the storm. Desks and filing between them give mid-height cover.

func dims() -> Vector3: return Vector3(36, 6, 36)

func build() -> void:
	strategy_wall(17.3, 6.0, 270, 2.8)
	floor_rect(-18, 0, 18, 36, "", 0.0, Mats.flat(Color(0.2, 0.22, 0.25), 0.85))
	ceiling(-18, 0, 18, 36, 5.0)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallBand", "TopSimple")
	wall(-18, 36, 18, 36, Vector2(0, 30), "WWWWDWWWW", "WallBand", "TopSimple")
	wall(-18, 0, -18, 36, Vector2(0, 18), "", "WallBand", "TopSimple")
	wall(18, 0, 18, 36, Vector2(0, 18), "WGGGGGGGW", "WallBand", "TopWindow")
	# west glass offices
	for k in 4:
		var d0 := 3.0 + k * 8.0
		glass_room(-17.6, d0, -10.0, d0 + 7.0, "e", 0.5)
		desk(-15.0, d0 + 3.5, 90, "monitor" if k % 2 == 0 else "laptop")
		piece("ph:drawer_cabinet", -17.2, d0 + 6.2, 90)
	label("HARBOUR MASTER", -13.8, 27.0, 2.6, 270, 36, Color(0.85, 0.9, 1.0))
	# map room
	glass_room(-3.0, 14.0, 9.0, 26.0, "s", 0.5)
	box(Vector3(5.0, 0.9, 3.0), 3.0, 20.0, 0.45, b.mat("gunmetal", 1.0))
	box(Vector3(4.8, 0.04, 2.8), 3.0, 20.0, 0.92, Mats.glow(Color(0.25, 0.6, 1.0), 1.4), false)
	label("SOUTH END TERMINAL · BERTHS 1–9", 3.0, 20.0, 0.95, 0, 40, Color(0.9, 0.95, 1.0)).rotation.x = -PI * 0.5
	for k2 in 6:
		var fx := -2.5 + k2 * 2.2
		box(Vector3(1.6, 1.0, 0.03), fx, 14.1, 2.0, Mats.flat(Color(0.9, 0.88, 0.8), 0.9), false)
		label(["POLITICAL", "ECONOMIC", "SOCIAL", "TECH", "ENVIRON.", "LEGAL"][k2], fx, 14.14, 2.35, 0, 26, Color(0.1, 0.1, 0.1))
	intel(0, 1.0, 20.5, 0, 0.94)
	fill(3.0, 20.0, 2.0, Color(0.3, 0.6, 1.0), 1.0, 7.0)
	# east window counters
	for d in [4.0, 10.0, 28.0, 32.0]:
		box(Vector3(1.0, 1.05, 4.0), 16.8, d, 0.52, Mats.flat(Color(0.82, 0.8, 0.76), 0.5))
		piece("ph:metal_stool_01", 15.6, d - 1.0, 90)
		cover_pt(15.4, d)
	piece("ph:CoffeeCart_01", 15.5, 17.0, 270)
	# open desks
	for p in [[-6.0, 6.0, 0.0], [-6.0, 30.0, 180.0], [12.0, 20.0, 270.0], [12.0, 14.0, 270.0]]: desk(p[0], p[1], p[2], "monitor")
	for p in [[2.0, 4.0], [-2.0, 31.0], [8.0, 31.0]]: piece("ph:drawer_cabinet", p[0], p[1], 0)
	ceiling_lights(-18, 0, 18, 36, 5.0, 3, 3, 6.0, Color(0.92, 0.95, 1.0))
	fill(0, 18, 4.0, Color(0.5, 0.58, 0.72), 0.35, 26.0)
	terminal(-6.0, 34.5, 180)
	for p in [[-6, 33], [6, 33], [0, 33], [-14, 34], [14, 34], [12, 6], [0, 10], [8, 28]]: spawn(p[0], p[1])
