extends Sector
## M1 · Sector 4 · SECURITY TRAINING FLOOR — Castellan's guards train here. Marr's first drill.
## Read: firing line at 6.5 m; plywood partitions and tyre stacks downrange so targets appear in
## gaps, behind cover and at the back wall; the scoreboard is on the far wall.

func dims() -> Vector3: return Vector3(20, 8, 32)

func build() -> void:
	floor_rect(-10, 0, 10, 32, "", 0.0, b.mat("CONCRETE"))
	ceiling(-10, 0, 10, 32, 7.0)
	wall(-10, 0, 10, 0, Vector2(0, 5), "WWDWW", "WallBand", "TopSimple")
	wall(-10, 32, 10, 32, Vector2(0, 28), "WWDWW", "WallBand", "TopSimple")
	wall(-10, 0, -10, 32, Vector2(0, 16), "", "WallBand", "TopSimple")
	wall(10, 0, 10, 32, Vector2(0, 16), "", "WallBand", "TopSimple")
	for s in [0.0, 32.0]: wall(-10, s, 10, s, Vector2(0, 16), "SSSSS", "WallBand", "", 5.0)
	range_kit(6.5, 4.6, [[-6, 11], [-1, 13], [4, 11.5], [7.5, 15], [-7.5, 18], [-2.5, 20], [3, 21], [7, 24], [-5, 25.5], [0.5, 28], [-8, 29], [5, 29.5]])
	for p in [[-4.5, 14.0, 0.0], [5.5, 17.0, 0.0], [-1.0, 22.5, 0.0], [6.0, 26.0, 0.0], [-6.5, 27.0, 0.0]]:
		box(Vector3(2.4, 2.0, 0.06), p[0], p[1], 1.0, Mats.flat(Color(0.72, 0.58, 0.4), 0.9), true, p[2])
		box(Vector3(0.1, 2.0, 0.1), p[0] - 1.2, p[1], 1.0, Mats.flat(Color(0.5, 0.4, 0.28), 0.9), false)
		box(Vector3(0.1, 2.0, 0.1), p[0] + 1.2, p[1], 1.0, Mats.flat(Color(0.5, 0.4, 0.28), 0.9), false)
	for p in [[-8.5, 12.0], [8.5, 21.0], [1.5, 17.5]]:
		for k in 3: piece("ph:old_tyre", p[0], p[1], k * 30.0, k * 0.24, "box" if k == 0 else "none")
	for x in [-6.0, 6.0]: desk(x, 2.8, 180, "bare", false)
	piece("ph:ammo_box", -6.0, 2.8, 20, 0.78, "none")
	piece("ph:ammo_box", 6.0, 2.8, -15, 0.78, "none")
	piece("ph:metal_jerrycan", 9.0, 2.0, 0)
	label("CASTELLAN SECURITY · QUALIFICATION RANGE", 0, 31.8, 6.0, 180, 48, Color(1.0, 0.85, 0.4))
	for d in [10.0, 18.0, 26.0]: lamp(0.0, d, 6.9, 6.0, 70, Color(1.0, 0.92, 0.78), "q:Prop_Light_Wide")
	fill(0, 16, 4.0, Color(0.6, 0.62, 0.7), 0.4, 20.0)
