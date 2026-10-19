extends Sector
## M1 · Sector 6 · RECORDS OFFICE — customer files and the CRM back office. Already loud: the alarm
## from the mezzanine is still ringing when you enter.
## Read: a long filing-room spine down the middle (walls at x ±4, d 8–28) with doorways in its side
## walls; open-plan desk pods either side; the regional manager's glass office in the north-east;
## a shredder room in the north-west where someone has been destroying files.

func dims() -> Vector3: return Vector3(36, 6, 36)

func build() -> void:
	strategy_wall(-17.3, 6.0, 90, 2.8)
	floor_rect(-18, 0, 18, 36, "", 0.0, Mats.flat(Color(0.25, 0.23, 0.22), 0.85))
	ceiling(-18, 0, 18, 36, 5.0)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallBand", "TopSimple")
	wall(-18, 36, 18, 36, Vector2(0, 30), "WWWWDWWWW", "WallBand", "TopSimple")
	wall(-18, 0, -18, 36, Vector2(0, 18), "WGGWWWGGW", "WallBand", "TopSimple")
	wall(18, 0, 18, 36, Vector2(0, 18), "WGGWWWGGW", "WallBand", "TopSimple")
	# filing spine
	for s in [-1.0, 1.0]:
		partition(s * 4.0, 8.0, s * 4.0, 13.0, 3.2)
		partition(s * 4.0, 15.0, s * 4.0, 21.0, 3.2)
		partition(s * 4.0, 23.0, s * 4.0, 28.0, 3.2)
	partition(-4.0, 28.0, -1.0, 28.0, 3.2)
	partition(1.0, 28.0, 4.0, 28.0, 3.2)
	for k in 4:
		piece("ph:drawer_cabinet", -3.3, 9.5 + k * 1.1, 90)
		piece("ph:drawer_cabinet", 3.3, 9.5 + k * 1.1, 270)
		piece("ph:drawer_cabinet", -3.3, 23.5 + k * 1.1, 90)
		piece("ph:drawer_cabinet", 3.3, 23.5 + k * 1.1, 270)
	shelf(-1.5, 18.0, 0, 1); shelf(1.5, 18.0, 0, 2)
	label("CUSTOMER RECORDS · A–Z", 0, 8.0, 3.4, 180, 48, Color(0.9, 0.85, 0.7))
	intel(0, -2.0, 22.0, 90, 0.8, "ph:metal_office_desk")
	# desk pods
	for x in [-12.0, -8.0, 8.0, 12.0]:
		for d in [6.0, 12.0, 18.0, 24.0]:
			desk(x, d, 0 if int(d) % 12 == 0 else 180, "monitor" if int(x + d) % 3 != 0 else "laptop")
	box(Vector3(0.08, 1.3, 22.0), -10.0, 15.0, 0.65, Mats.flat(Color(0.32, 0.35, 0.4), 0.8))
	box(Vector3(0.08, 1.3, 22.0), 10.0, 15.0, 0.65, Mats.flat(Color(0.32, 0.35, 0.4), 0.8))
	# manager's office NE
	glass_room(8, 26, 18, 35.6, "w", 0.35)
	desk(13.0, 32.0, 180, "monitor")
	piece("ph:modern_wooden_cabinet", 17.4, 30.0, 270)
	piece("ph:modern_arm_chair_01", 10.0, 33.5, 120)
	intel(1, 13.0, 31.6, 180, 0.8)
	label("REGIONAL MANAGER", 13.0, 26.0, 2.6, 180, 40, Color(0.85, 0.9, 1.0))
	# shredder room NW
	partition(-18, 28, -8, 28, 3.2)
	partition(-8, 28, -8, 31, 3.2)
	partition(-8, 33, -8, 36, 3.2)
	for k in 3: box(Vector3(0.7, 1.0, 0.6), -16.5 + k * 1.2, 35.2, 0.5, b.mat("gunmetal", 1.0))
	for k in 5: piece("ph:cardboard_box_01", -15.0 + k * 1.1, 30.0 + (k % 2) * 0.7, k * 17.0)
	piece("ph:plastic_crate_01", -10.0, 34.0, 10)
	label("SHRED · CONFIDENTIAL", -13.0, 35.8, 2.4, 180, 40, Color(1.0, 0.45, 0.35))
	ceiling_lights(-18, 0, 18, 36, 5.0, 3, 3, 6.5, Color(0.95, 0.96, 1.0))
	fill(0, 18, 4.0, Color(0.6, 0.62, 0.7), 0.4, 26.0)
	terminal(-15.5, 33.0, 90)
	for p in [[-6, 32], [6, 32], [0, 33], [-14, 22], [14, 22], [-6, 4], [6, 4], [0, 30]]: spawn(p[0], p[1])
