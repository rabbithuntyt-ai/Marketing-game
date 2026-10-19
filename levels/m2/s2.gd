extends Sector
## M2 · Sector 3 · STRATEGY TRAINING FLOOR — bunker range. Sandbag positions downrange.

func dims() -> Vector3: return Vector3(20, 6, 36)

func build() -> void:
	floor_rect(-10, 0, 10, 36, "", 0.0, b.mat("CONCRETE"))
	concrete_shell(6.0, 6.0)
	range_kit(6.0, 4.0, [[-6, 11], [0, 12.5], [6, 11], [-3, 17], [4, 18.5], [-7, 22], [1, 24], [7, 25], [-4, 29], [3, 30], [-7, 33], [6, 33]])
	for p in [[-4.5, 15.0], [5.0, 16.0], [-1.0, 21.0], [-6.0, 26.0], [5.0, 27.5]]:
		for k in 3: box(Vector3(1.0, 0.35, 0.55), p[0] - 1.0 + k * 1.0, p[1], 0.18, Mats.flat(Color(0.5, 0.44, 0.32), 0.95))
		for k2 in 2: box(Vector3(1.0, 0.35, 0.55), p[0] - 0.5 + k2 * 1.0, p[1], 0.53, Mats.flat(Color(0.47, 0.41, 0.3), 0.95))
	for x in [-6.0, 6.0]: desk(x, 2.6, 180, "bare", false)
	piece("ph:ammo_box", 6.0, 2.6, 0, 0.78, "none")
	label("KINGSWAY · LIVE FIRE", 0, 35.6, 5.0, 180, 48, Color(1.0, 0.8, 0.3))
	for d in [9.0, 18.0, 27.0]: lamp(0.0, d, 5.8, 6.0, 70, Color(1.0, 0.85, 0.65), "q:Prop_Light_Small")
	fill(0, 18, 4.0, Color(0.6, 0.55, 0.5), 0.4, 20.0)
