extends Sector
## M8 · Sector 1 · SKY LOBBY — floor 55, the board levels. Glass on three sides, the city below.
## Read: the lift core stands in the middle (big cover block, you go round it either way); art
## plinths and low benches on the flanks; a reception counter at the far end in front of the exit.

func dims() -> Vector3: return Vector3(36, 9, 40)

func build() -> void:
	city_view(150.0)
	strategy_wall(-17.3, 34.0, 90, 3.0)
	floor_rect(-18, 0, 18, 40, "", 0.0, b.mat("MARBLE", 3.0, Color(0.75, 0.75, 0.78)))
	ceiling(-18, 0, 18, 40, 9.0)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallAstra", "TopAstra")
	wall(-18, 40, 18, 40, Vector2(0, 30), "GGGGDGGGG", "WallAstra", "TopWindow")
	wall(-18, 0, -18, 40, Vector2(0, 20), "GGGGGGGGGG", "WallAstra", "TopWindow")
	wall(18, 0, 18, 40, Vector2(0, 20), "GGGGGGGGGG", "WallAstra", "TopWindow")
	for s in [-1.0, 1.0]: wall(s * 18.0, 0, s * 18.0, 40, Vector2(0, 20), "GGGGGGGGGG", "WallAstra", "", 5.0)
	# lift core
	box(Vector3(8.0, 9.0, 8.0), 0, 18.0, 4.5, b.mat("MARBLE", 2.0, Color(0.62, 0.6, 0.58)))
	for cx in [-4.0, 4.0]:
		for cd in [14.0, 22.0]:
			box(Vector3(0.5, 9.0, 0.5), cx, cd, 4.5, b.mat("gunmetal", 1.0), false)
			box(Vector3(0.06, 8.6, 0.06), cx + (0.27 if cx > 0 else -0.27), cd + (-0.27 if cd < 18 else 0.27), 4.5, Mats.glow(Color(1.0, 0.85, 0.55), 2.5), false)
	for y in [3.4, 6.2]:
		box(Vector3(8.1, 0.12, 8.1), 0, 18.0, y, b.mat("gunmetal", 1.0), false)
	for face in [[13.97, 180.0], [22.03, 0.0]]:
		for k in 2:
			var lx := -2.0 + k * 4.0
			box(Vector3(1.9, 3.0, 0.08), lx, face[0], 1.5, b.mat("gunmetal", 1.0), false)
			box(Vector3(1.6, 2.8, 0.05), lx, face[0] + (-0.05 if face[1] > 90.0 else 0.05), 1.4, b.mat("steel", 1.0), false)
			box(Vector3(0.02, 2.8, 0.06), lx, face[0] + (-0.08 if face[1] > 90.0 else 0.08), 1.4, Mats.flat(Color(0.05, 0.05, 0.05), 0.5), false)
			label("▲ %d" % (56 + k), lx, face[0] + (-0.1 if face[1] > 90.0 else 0.1), 3.15, face[1], 40, Color(1.0, 0.85, 0.5))
	label("BOARD LEVELS 55–60", 0, 13.9, 5.0, 180, 70, Color(0.15, 0.13, 0.1))
	cover_pt(-4.8, 14.0); cover_pt(4.8, 14.0); cover_pt(-4.8, 22.0); cover_pt(4.8, 22.0)
	# plinths + benches
	for p in [[-11.0, 8.0], [11.0, 10.0], [-12.0, 26.0], [12.0, 28.0]]:
		box(Vector3(1.2, 1.1, 1.2), p[0], p[1], 0.55, Mats.flat(Color(0.95, 0.95, 0.95), 0.3))
		box(Vector3(0.5, 1.4, 0.5), p[0], p[1], 1.8, Mats.flat(Color(0.8, 0.6, 0.3), 0.3, 0.9), false, 30.0)
		cover_pt(p[0], p[1] - 1.2)
	for p2 in [[-8.0, 17.0], [8.0, 19.0]]: box(Vector3(1.0, 0.5, 4.0), p2[0], p2[1], 0.25, Mats.flat(Color(0.12, 0.12, 0.14), 0.4))
	box(Vector3(8.0, 1.15, 1.2), 0, 33.0, 0.57, Mats.flat(Color(0.12, 0.12, 0.14), 0.3))
	box(Vector3(8.2, 0.05, 1.4), 0, 33.0, 1.17, Mats.flat(Color(0.8, 0.65, 0.35), 0.3, 0.9), false)
	label("CASTELLAN GROUP · BOARD LEVEL", 0, 32.38, 0.8, 180, 40, Color(0.95, 0.85, 0.6))
	cover_pt(0, 31.8)
	for p3 in [[-14.0, 37.0], [14.0, 37.0]]: planter(p3[0], p3[1], 1.6, 1.6)
	for d in [6.0, 18.0, 30.0]:
		lamp(-9.0, d, 8.8, 5.0, 55, Color(1.0, 0.9, 0.75), "")
		lamp(9.0, d, 8.8, 5.0, 55, Color(1.0, 0.9, 0.75), "")
	fill(0, 20, 6.0, Color(0.85, 0.82, 0.8), 0.4, 30.0)
	terminal(-6.0, 38.0, 180)
	guard(0.0, 30.0, 180)
	guard(-9.0, 6.0, 0, [[-9, 6, 2, 90], [-9, 30, 2, 90]])
	guard(9.0, 30.0, 180, [[9, 30, 2, 270], [9, 6, 2, 270]])
	guard(-4.0, 34.0, 180, [], "heavy", 0)
	guard(6.0, 36.0, 200, [], "marksman", 1)
	guard(12.0, 20.0, 270, [], "css", 2)
	for p in [[-8, 38], [8, 38], [-15, 34], [15, 34], [0, 36]]: spawn(p[0], p[1])
