extends Sector
## M7 · Sector 8 · EXECUTIVE FLOOR — Kessler's floor, top of the tower. He's waiting for you.
## Read: glass offices down both sides (each a pocket of cover); a lounge in the middle with sofas
## and low tables; the boardroom table across the north end where Kessler makes his stand with the
## city behind him.

func dims() -> Vector3: return Vector3(36, 7, 44)

func build() -> void:
	city_view(150.0)
	floor_rect(-18, 0, 18, 44, "", 0.0, Mats.flat(Color(0.3, 0.2, 0.13), 0.5))
	ceiling(-18, 0, 18, 44, 7.0)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallAstra", "TopAstra")
	wall(-18, 44, 18, 44, Vector2(0, 30), "GGGGDGGGG", "WallAstra", "TopWindow")
	wall(-18, 0, -18, 44, Vector2(0, 22), "GGGGGGGGGGG", "WallAstra", "TopWindow")
	wall(18, 0, 18, 44, Vector2(0, 22), "GGGGGGGGGGG", "WallAstra", "TopWindow")
	for s in [-1.0, 1.0]:
		for k in 3:
			var d0 := 3.0 + k * 9.0
			var x0 := -17.6 if s < 0 else 10.0
			glass_room(x0, d0, x0 + 7.6, d0 + 8.0, "e" if s < 0 else "w", 0.5)
			desk(x0 + 3.8, d0 + 4.0, 90.0 * -s, "monitor")
			piece("ph:modern_arm_chair_01", x0 + 3.8 + s * 2.0, d0 + 6.5, 0)
	label("C. KESSLER · CHIEF OPERATING OFFICER", 13.8, 21.0, 2.6, 270, 32, Color(0.9, 0.9, 1.0))
	# lounge
	for p in [[-3.0, 14.0, 90.0], [3.0, 14.0, 270.0], [-3.0, 22.0, 90.0], [3.0, 22.0, 270.0]]: piece("ph:sofa_03", p[0], p[1], p[2])
	for d in [14.0, 22.0]: piece("ph:modern_coffee_table_01", 0, d, 0)
	piece("ph:CoffeeCart_01", 0, 30.0, 0)
	planter(-6.0, 30.0, 1.6, 1.6); planter(6.0, 30.0, 1.6, 1.6)
	# boardroom table
	box(Vector3(12.0, 0.08, 2.4), 0, 38.0, 0.76, Mats.flat(Color(0.12, 0.08, 0.05), 0.3))
	box(Vector3(11.0, 0.74, 1.6), 0, 38.0, 0.37, Mats.flat(Color(0.1, 0.07, 0.04), 0.5))
	for k2 in 5:
		piece("ph:modern_arm_chair_01", -4.8 + k2 * 2.4, 36.4, 180)
		piece("ph:modern_arm_chair_01", -4.8 + k2 * 2.4, 39.6, 0)
	cover_pt(0, 36.2); cover_pt(-7.2, 38.0); cover_pt(7.2, 38.0)
	anchor("boss", P(0, 37))
	note("Kessler: boardroom end", 0, 41)
	intel(0, -13.8, 16.0, 90, 0.79)
	for d2 in [8.0, 20.0, 32.0, 40.0]: lamp(0.0, d2, 6.8, 5.0, 60, Color(1.0, 0.88, 0.7), "")
	fill(0, 22, 5.0, Color(0.9, 0.8, 0.7), 0.4, 30.0)
	terminal(-12.0, 42.0, 180)
	for p2 in [[-12, 40], [12, 40], [-6, 42], [6, 42], [0, 30]]: spawn(p2[0], p2[1])
