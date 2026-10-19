extends Sector
## M4 · Sector 4 · SIMULATION DECK — Castellan Security's VR training deck. Marr hijacks it for drills.
## Read: firing line behind a glass-fronted control booth; a white grid floor with staggered half
## walls so targets pop up at different depths and angles, some peeking from behind cover.

func dims() -> Vector3: return Vector3(20, 6, 32)

func build() -> void:
	floor_rect(-10, 0, 10, 32, "q:Platform_Squares")
	ceiling(-10, 0, 10, 32, 5.0)
	wall(-10, 0, 10, 0, Vector2(0, 5), "WWDWW", "WallAstra", "TopPlastic")
	wall(-10, 32, 10, 32, Vector2(0, 28), "WWDWW", "WallAstra", "TopPlastic")
	wall(-10, 0, -10, 32, Vector2(0, 16), "", "WallAstra", "TopPlastic")
	wall(10, 0, 10, 32, Vector2(0, 16), "", "WallAstra", "TopPlastic")
	desk(-6.5, 3.0, 180, "monitor", true)
	desk(6.5, 3.0, 180, "monitor", true)
	for x in [-8.5, -4.5, 4.5, 8.5]: box(Vector3(0.1, 2.6, 0.1), x, 6.2, 1.3, b.mat("gunmetal", 1.0), false)
	box(Vector3(5.5, 2.4, 0.05), -6.5, 6.2, 1.4, Mats.glass(), true)
	box(Vector3(5.5, 2.4, 0.05), 6.5, 6.2, 1.4, Mats.glass(), true)
	range_kit(7.0, 3.6, [[-6, 12], [-2, 14], [3, 12.5], [7, 15], [-7.5, 19], [-1, 20], [5, 21], [8, 25], [-4, 26], [1, 28], [-8, 29], [4.5, 29]])
	for p in [[-5.0, 15.5, 0], [6.0, 17.5, 0], [-2.0, 23.0, 0], [5.0, 26.5, 0], [-7.0, 27.0, 0]]:
		box(Vector3(2.4, 1.0, 0.3), p[0], p[1], 0.5, b.mat("tech", 1.0))
		box(Vector3(2.4, 0.05, 0.32), p[0], p[1], 1.02, Mats.glow(accent, 2.5), false)
	for k in 5: paint(-9.5, 10.0 + k * 4.5, 9.5, 10.0 + k * 4.5, Color(0.55, 0.5, 1.0, 1.0), 0.04)
	label("SIM DECK 2 · ACTIVE SCENARIO", 0, 31.8, 4.6, 180, 48, Color(0.75, 0.7, 1.0), "IBMPlexMono-Medium")
	ceiling_lights(-10, 0, 10, 32, 5.0, 2, 4, 6.0, Color(0.85, 0.85, 1.0))
	fill(0, 18, 3.0, Color(0.6, 0.55, 1.0), 0.5, 22.0)
