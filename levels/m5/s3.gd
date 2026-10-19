extends Sector
## M5 · Sector 4 · LAB RANGE — a stimulus-testing lab turned range: target slots between display
## plinths and rolling partitions, bright white.

func dims() -> Vector3: return Vector3(20, 6, 32)

func build() -> void:
	floor_rect(-10, 0, 10, 32, "", 0.0, Mats.flat(Color(0.9, 0.9, 0.92), 0.35))
	ceiling(-10, 0, 10, 32, 5.5)
	wall(-10, 0, 10, 0, Vector2(0, 5), "WWDWW", "WallAstra", "TopPlastic")
	wall(-10, 32, 10, 32, Vector2(0, 28), "WWDWW", "WallAstra", "TopPlastic")
	wall(-10, 0, -10, 32, Vector2(0, 16), "", "WallAstra", "TopPlastic")
	wall(10, 0, 10, 32, Vector2(0, 16), "", "WallAstra", "TopPlastic")
	range_kit(6.0, 4.0, [[-6, 11], [0, 12], [6, 11.5], [-3, 17], [4, 18], [-7, 22], [1, 24], [7, 24.5], [-4, 28], [3, 29], [-7.5, 30], [7, 30]])
	for p in [[-4.5, 14.5], [5.0, 20.5], [-1.0, 21.0], [-6.0, 25.5], [5.0, 26.5]]:
		box(Vector3(1.2, 1.1, 1.2), p[0], p[1], 0.55, Mats.flat(Color(0.95, 0.95, 0.95), 0.3))
		piece("ph:cardboard_box_01", p[0], p[1], 20.0, 1.1, "none")
	for p2 in [[2.0, 15.0], [-6.5, 19.0]]:
		box(Vector3(2.4, 2.2, 0.08), p2[0], p2[1], 1.1, Mats.flat(Color(0.3, 0.42, 0.55), 0.8))
	for x in [-6.0, 6.0]: desk(x, 2.6, 180, "monitor", false)
	label("STIMULUS LAB 3", 0, 31.8, 4.6, 180, 56, Color(0.4, 0.6, 1.0))
	ceiling_lights(-10, 0, 10, 32, 5.5, 2, 4, 6.0, Color(0.95, 0.97, 1.0))
