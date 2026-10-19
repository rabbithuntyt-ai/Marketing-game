extends Sector
## M7 · Sector 4 · FLOOR 30 RANGE — Castellan's executive range: walnut, brass and leather.

func dims() -> Vector3: return Vector3(20, 6, 32)

func build() -> void:
	city_view(150.0)
	floor_rect(-10, 0, 10, 32, "", 0.0, Mats.flat(Color(0.32, 0.2, 0.12), 0.5))
	ceiling(-10, 0, 10, 32, 5.5)
	wall(-10, 0, 10, 0, Vector2(0, 5), "WWDWW", "WallAstra", "TopAstra")
	wall(-10, 32, 10, 32, Vector2(0, 28), "WWDWW", "WallAstra", "TopAstra")
	wall(-10, 0, -10, 32, Vector2(0, 16), "", "WallAstra", "TopAstra")
	wall(10, 0, 10, 32, Vector2(0, 16), "", "WallAstra", "TopAstra")
	range_kit(6.0, 4.0, [[-6, 11], [0, 12], [6, 11.5], [-3, 17], [4, 18.5], [-7, 22], [1, 24], [7, 25], [-4, 28], [3, 29], [-7.5, 30], [7, 30]])
	for p in [[-4.0, 15.0], [5.5, 20.0], [-1.5, 22.0], [-6.5, 26.0], [5.5, 27.5]]:
		box(Vector3(2.0, 1.1, 0.5), p[0], p[1], 0.55, Mats.flat(Color(0.35, 0.22, 0.13), 0.4))
		box(Vector3(2.05, 0.04, 0.55), p[0], p[1], 1.12, Mats.flat(Color(0.75, 0.6, 0.3), 0.3, 0.9), false)
	for x in [-6.0, 6.0]: piece("ph:mid_century_lounge_chair", x, 2.4, 180)
	piece("ph:modern_wooden_cabinet", 9.3, 3.5, 270)
	label("CASTELLAN · MEMBERS' RANGE", 0, 31.8, 4.6, 180, 48, Color(0.95, 0.8, 0.5))
	for d in [9.0, 18.0, 27.0]: lamp(0.0, d, 5.4, 6.0, 64, Color(1.0, 0.86, 0.66), "")
	fill(0, 16, 4.0, Color(1.0, 0.8, 0.6), 0.4, 20.0)
