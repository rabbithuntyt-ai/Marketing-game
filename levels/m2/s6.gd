extends Sector
## M2 · Sector 7 · COMMAND OPS — the bunker's operations room, built in three tiers like a theatre.
## Read: a sandbag/barricade line at 9 m is the first cover. Behind it the floor steps up three
## times (0.5 · 1.0 · 1.5 m) through rows of consoles facing the big tactical wall on the south
## side. The glass command office sits on the top tier. Attackers fight uphill; ramps at the sides.

func dims() -> Vector3: return Vector3(32, 8, 40)

func build() -> void:
	strategy_wall(15.3, 6.0, 270, 3.0)
	floor_rect(-16, 0, 16, 40, "q:Platform_DarkPlates")
	concrete_shell(8.0, 8.0, true, b.mat("CONCRETE", 4.0, Color(0.62, 0.64, 0.68)))
	# barricade
	for x in [-10.0, -5.0, 5.0, 10.0]:
		cover("ph:concrete_road_barrier", x, 9.0, 0)
	for x2 in [-13.5, 13.5]: crates(x2, 9.0, 0.0, 0)
	# tiers
	var tiers := [[16.0, 24.0, 0.5], [24.0, 30.0, 1.0], [30.0, 40.0, 1.5]]
	for t in tiers:
		box(Vector3(26.0, t[2], t[1] - t[0]), 0, (t[0] + t[1]) * 0.5, t[2] * 0.5, b.mat("metal", 2.0, Color(0.5, 0.52, 0.56)))
		box(Vector3(26.0, 0.04, 0.12), 0, t[0], t[2] + 0.01, Mats.glow(accent, 2.0), false)
	for s in [-1.0, 1.0]:
		ramp(s * 14.5, 13.0, 0.0, 0.5, 3.0, 3.0)
		ramp(s * 14.5, 21.0, 0.0, 0.5, 3.0, 3.0)
		box(Vector3(3.0, 0.5, 5.0), s * 14.5, 18.5, 0.25, b.mat("metal", 2.0))
		ramp(s * 14.5, 27.0, 0.0, 0.5, 3.0, 3.0)
		box(Vector3(3.0, 1.0, 3.0), s * 14.5, 25.5, 0.5, b.mat("metal", 2.0))
	for x3 in [-12.0, -8.0, -4.0, 4.0, 8.0, 12.0]:
		piece("ph:metal_office_desk", x3, 19.0, 0, 0.5)
		piece("ph:metal_office_desk", x3 * 0.9, 26.5, 0, 1.0)
		box(Vector3(0.6, 0.35, 0.03), x3, 19.3, 1.6, Mats.glow(Color(0.3, 0.7, 1.0), 1.2), false)
		box(Vector3(0.6, 0.35, 0.03), x3 * 0.9, 26.8, 2.1, Mats.glow(Color(0.3, 0.7, 1.0), 1.2), false)
		cover_pt(x3, 18.0); cover_pt(x3 * 0.9, 25.5)
	# tactical wall (south, faces the tiers)
	box(Vector3(14.0, 3.6, 0.15), 0, 13.0, 4.6, b.mat("gunmetal", 1.0))
	box(Vector3(13.4, 3.2, 0.04), 0, 13.08, 4.6, Mats.flat(Color(0.02, 0.04, 0.06), 0.3), false)
	label("KINGSWAY OPS · MERIDIAN STRATEGY", 0, 13.1, 5.9, 0, 64, Color(0.6, 0.85, 1.0))
	for k in 6: box(Vector3(1.8, 0.2 + k * 0.35, 0.03), -5.0 + k * 2.0, 13.1, 3.2 + (0.2 + k * 0.35) * 0.5, Mats.glow(Color(0.3, 0.8, 1.0).lerp(Color(1.0, 0.4, 0.3), k / 5.0), 2.0), false)
	for x4 in [-4.0, 4.0]: box(Vector3(0.3, 2.6, 0.3), x4, 13.0, 1.4, b.mat("steel", 1.0))
	# command office (top tier)
	glass_room(-8.0, 32.0, 8.0, 39.6, "n", 0.5)
	for p in [[-3.0, 37.6], [3.0, 37.6]]: piece("ph:metal_office_desk", p[0], p[1], 180, 1.5)
	piece("ph:modern_arm_chair_01", -6.5, 34.0, 90, 1.5)
	intel(0, -3.0, 37.6, 180, 2.29)
	intel(1, 12.0, 35.0, 270, 2.29, "ph:metal_office_desk")
	ceiling_lights(-14, 14, 14, 40, 8.0, 3, 3, 6.0, Color(0.8, 0.88, 1.0))
	lamp(0, 6.0, 7.8, 6.0, 60, Color(1.0, 0.85, 0.6), "")
	fill(0, 20, 5.0, Color(0.45, 0.55, 0.8), 0.4, 28.0)
	terminal(-12.0, 38.0, 90)
	guard(-6.0, 21.0, 180, [[-6, 21, 2, 180], [6, 21, 2, 180]], "css", 0, 0.5)
	guard(0.0, 28.0, 180, [], "marksman", 0, 1.0)
	guard(0.0, 36.0, 180, [], "css", 0, 1.5)
	guard(-12.0, 11.0, 0)
	guard(10.0, 28.0, 200, [], "heavy", 1, 1.0)
	guard(-10.0, 34.0, 150, [], "css", 2, 1.5)
	for p in [[-6, 38, 1.5], [6, 38, 1.5], [12, 38], [-14, 34], [0, 33]]: spawn(p[0], p[1])
