extends Sector
## M6 · Sector 4 · CAMPUS RANGE — set up inside a vehicle shed: a snowcat and fuel drums downrange.

func dims() -> Vector3: return Vector3(20, 8, 32)

func build() -> void:
	floor_rect(-10, 0, 10, 32, "", 0.0, b.mat("CONCRETE"))
	ceiling(-10, 0, 10, 32, 7.5)
	wall(-10, 0, 10, 0, Vector2(0, 5), "WWDWW", "WallBand", "TopCables")
	wall(-10, 32, 10, 32, Vector2(0, 28), "WWDWW", "WallBand", "TopCables")
	wall(-10, 0, -10, 32, Vector2(0, 16), "", "WallBand", "TopCables")
	wall(10, 0, 10, 32, Vector2(0, 16), "", "WallBand", "TopCables")
	for s in [0.0, 32.0]: wall(-10, s, 10, s, Vector2(0, 16), "SSSSS", "WallBand", "", 5.0)
	range_kit(6.0, 4.6, [[-6, 11], [0, 12], [6, 11], [-3, 17], [3.5, 18], [-7, 21.5], [1, 23], [7, 24], [-4, 27], [3, 28.5], [-7.5, 29.5], [7, 29.5]])
	cover("ph:covered_car", -5.0, 19.0, 10)
	cover("ph:covered_car", 5.0, 25.5, -8)
	for p in [[2.0, 14.5], [-1.5, 25.0]]:
		for k in 3: piece("ph:Barrel_01", p[0] + (k % 2) * 0.7, p[1] + int(k / 2) * 0.7, k * 40.0)
	piece("ph:metal_tool_chest", 9.3, 14.0, 270)
	for x in [-6.0, 6.0]: desk(x, 2.6, 180, "bare", false)
	label("NORTHGATE VEHICLE SHED · RANGE", 0, 31.8, 5.6, 180, 48, Color(1.0, 0.85, 0.4))
	for d in [9.0, 18.0, 27.0]: lamp(0.0, d, 7.3, 6.0, 70, Color(1.0, 0.9, 0.75), "q:Prop_Light_Wide")
	fill(0, 16, 4.0, Color(0.6, 0.65, 0.75), 0.4, 20.0)
