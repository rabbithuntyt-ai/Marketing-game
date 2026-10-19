extends Sector
## M7 · Sector 3 · DESIGN STUDIO — packaging and product design.
## Read: long design tables in rows; free-standing mood-board partitions split the room into
## pockets; a photo studio in the north-east (white cyclorama, lights on stands); a print room
## (west, behind a wall) holds the intel. The partitions are soft cover: they stop sight, not bullets.

func dims() -> Vector3: return Vector3(32, 6, 36)

func build() -> void:
	city_view(150.0)
	strategy_wall(15.3, 6.0, 270, 2.8)
	floor_rect(-16, 0, 16, 36, "", 0.0, Mats.flat(Color(0.55, 0.42, 0.3), 0.6))
	ceiling(-16, 0, 16, 36, 5.5)
	wall(-16, 0, 16, 0, Vector2(0, 5), "WWWWDWWW", "WallAstra", "TopSimple")
	wall(-16, 36, 16, 36, Vector2(0, 30), "WWWWDWWW", "WallAstra", "TopSimple")
	wall(-16, 0, -16, 36, Vector2(0, 18), "GGGGGGGGG", "WallAstra", "TopWindow")
	wall(16, 0, 16, 36, Vector2(0, 18), "GGGGGGGGG", "WallAstra", "TopWindow")
	for d in [7.0, 15.0, 23.0]:
		for x in [-4.0, 4.5]:
			box(Vector3(5.0, 0.9, 1.6), x, d, 0.45, Mats.flat(Color(0.95, 0.95, 0.93), 0.4))
			piece("ph:classic_laptop", x - 1.4, d, 180, 0.9, "none")
			piece("ph:office_notepads", x + 0.8, d, 20, 0.9, "none")
			piece("ph:desk_lamp_arm_01", x + 2.0, d + 0.4, 200, 0.9, "none")
			cover_pt(x, d - 1.3); cover_pt(x, d + 1.3)
	for p in [[0.2, 11.0, 0.0], [-8.5, 19.0, 90.0], [8.5, 11.0, 90.0], [0.2, 27.0, 0.0]]:
		box(Vector3(0.1, 2.2, 3.6), p[0], p[1], 1.2, Mats.flat(Color(0.92, 0.9, 0.85), 0.9), true, p[2])
		for k in 4: box(Vector3(0.02, 0.5, 0.6), p[0] + 0.07, p[1] - 1.2 + k * 0.8, 1.4 + (k % 2) * 0.5, Mats.flat(Color.from_hsv(k * 0.23, 0.5, 0.9), 0.8), false, p[2])
	# photo studio NE
	box(Vector3(8.0, 4.0, 0.1), 11.5, 35.6, 2.0, Mats.flat(Color(0.97, 0.97, 0.97), 0.5))
	floor_rect(7.5, 29, 15.5, 35.6, "", 0.02, Mats.flat(Color(0.97, 0.97, 0.97), 0.5))
	for x2 in [8.5, 14.5]: piece("tps:prop_tripodlight", x2, 30.0, 150.0 if x2 < 10 else 210.0)
	box(Vector3(0.8, 0.8, 0.8), 11.5, 33.5, 0.4, Mats.flat(Color(1.0, 0.45, 0.35), 0.4))
	fill(11.5, 33.0, 3.0, Color(1.0, 1.0, 1.0), 1.2, 7.0)
	# print room west
	partition(-16, 28, -8, 28, 3.0)
	partition(-8, 28, -8, 30.5, 3.0)
	partition(-8, 32.5, -8, 36, 3.0)
	for k2 in 2: box(Vector3(1.6, 1.2, 1.0), -13.5 + k2 * 2.6, 34.8, 0.6, Mats.flat(Color(0.85, 0.85, 0.86), 0.5))
	shelf(-15.2, 31.0, 90, 2)
	intel(0, -12.2, 34.8, 180, 1.22)
	label("PRINT", -8.1, 31.5, 2.5, 270, 40, Color(0.3, 0.3, 0.35))
	ceiling_lights(-16, 0, 16, 36, 5.5, 3, 3, 6.0, Color(1.0, 0.96, 0.9))
	terminal(-4.0, 34.5, 180)
	guard(-12.0, 4.0, 0, [[-12, 4, 2, 90], [-12, 25, 2, 90]])
	guard(12.0, 24.0, 180, [[12, 24, 2, 270], [12, 4, 2, 270]])
	guard(0.0, 19.0, 180)
	guard(-10.5, 32.0, 90, [], "css", 1)
	guard(11.0, 31.0, 180, [], "heavy", 1)
	guard(4.0, 31.0, 160, [], "css", 2)
	for p in [[-6, 34], [6, 27], [0, 33], [14, 26], [-14, 24]]: spawn(p[0], p[1])
