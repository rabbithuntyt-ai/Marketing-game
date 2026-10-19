extends Sector
## M8 · Sector 5 · BOARD RANGE — Marr's last drill, on the board's private range. Black glass and steel.

func dims() -> Vector3: return Vector3(20, 6, 32)

func build() -> void:
	city_view(170.0)
	floor_rect(-10, 0, 10, 32, "", 0.0, Mats.flat(Color(0.08, 0.08, 0.1), 0.3))
	ceiling(-10, 0, 10, 32, 5.5)
	wall(-10, 0, 10, 0, Vector2(0, 5), "WWDWW", "WallAstra", "TopAstra")
	wall(-10, 32, 10, 32, Vector2(0, 28), "WWDWW", "WallAstra", "TopAstra")
	wall(-10, 0, -10, 32, Vector2(0, 16), "GGGGGGGG", "WallAstra", "TopWindow")
	wall(10, 0, 10, 32, Vector2(0, 16), "GGGGGGGG", "WallAstra", "TopWindow")
	range_kit(6.0, 4.0, [[-6, 11], [0, 12], [6, 11.5], [-3, 17], [4, 18.5], [-7, 22], [1, 24], [7, 25], [-4, 28], [3, 29], [-7.5, 30], [7, 30]])
	for p in [[-4.0, 15.0], [5.5, 20.0], [-1.0, 22.0], [-6.5, 26.0], [5.0, 27.5]]:
		box(Vector3(2.2, 1.2, 0.3), p[0], p[1], 0.6, Mats.flat(Color(0.05, 0.05, 0.06), 0.2, 0.6))
		box(Vector3(2.2, 0.04, 0.32), p[0], p[1], 1.22, Mats.glow(Color(1.0, 0.8, 0.5), 2.0), false)
	for x in [-6.0, 6.0]: piece("ph:modern_arm_chair_01", x, 2.4, 180)
	label("THE BOARD · FINAL REVIEW", 0, 31.8, 4.6, 180, 52, Color(0.95, 0.85, 0.6))
	for d in [9.0, 18.0, 27.0]: lamp(0.0, d, 5.4, 6.0, 64, Color(1.0, 0.9, 0.75), "")
	fill(0, 16, 4.0, Color(0.8, 0.75, 0.7), 0.3, 20.0)
