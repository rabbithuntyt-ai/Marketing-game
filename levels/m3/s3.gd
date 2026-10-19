extends Sector
## M3 · Sector 4 · PORT SECURITY RANGE — in a corrugated maintenance shed. Containers and drums downrange.

func dims() -> Vector3: return Vector3(20, 8, 36)

func build() -> void:
	floor_rect(-10, 0, 10, 36, "", 0.0, b.mat("CONCRETE"))
	ceiling(-10, 0, 10, 36, 7.5)
	wall(-10, 0, 10, 0, Vector2(0, 5), "WWDWW", "WallBand", "TopCables")
	wall(-10, 36, 10, 36, Vector2(0, 30), "WWDWW", "WallBand", "TopCables")
	wall(-10, 0, -10, 36, Vector2(0, 18), "", "WallBand", "TopCables")
	wall(10, 0, 10, 36, Vector2(0, 18), "", "WallBand", "TopCables")
	for s in [0.0, 36.0]: wall(-10, s, 10, s, Vector2(0, 18), "SSSSS", "WallBand", "", 5.0)
	range_kit(6.0, 4.6, [[-6, 12], [0, 13], [6, 11.5], [-3, 18], [4, 19.5], [-7, 23], [1, 25], [7, 26], [-4, 30], [3, 31], [-7, 33], [6, 33.5]])
	containers(-6.5, 21.0, 90.0, 1, 0)
	containers(6.0, 15.0, 90.0, 1, 1)
	for p in [[1.5, 27.0], [-2.0, 15.5], [7.0, 29.0]]:
		piece("ph:Barrel_01", p[0], p[1], 0)
		piece("ph:Barrel_01", p[0] + 0.7, p[1] + 0.3, 30)
	for x in [-6.0, 6.0]: desk(x, 2.6, 180, "bare", false)
	piece("ph:ammo_box", -6.0, 2.6, 10, 0.78, "none")
	label("HALIFAX PORT AUTHORITY · RANGE B", 0, 35.8, 5.5, 180, 48, Color(1.0, 0.85, 0.4))
	for d in [9.0, 18.0, 27.0]: lamp(0.0, d, 7.3, 6.0, 70, Color(1.0, 0.9, 0.75), "q:Prop_Light_Wide")
	fill(0, 18, 4.0, Color(0.55, 0.6, 0.7), 0.4, 22.0)
