extends Sector
## M5 · Sector 5 · PSYCH LAB — where Castellan tests motivation and perception on paid subjects.
## The courier blew your cover: the lab is loud when you enter.
## Read: a row of testing cells along the west (small rooms, each with a chair and a screen);
## a tiered eye-tracking theatre in the north-east (three steps of seats facing a screen) that
## defenders use as high ground; open lab floor between, broken up by equipment carts.

func dims() -> Vector3: return Vector3(32, 7, 36)

func build() -> void:
	strategy_wall(15.3, 6.0, 270, 3.0)
	floor_rect(-16, 0, 16, 36, "q:Platform_Squares")
	ceiling(-16, 0, 16, 36, 7.0)
	wall(-16, 0, 16, 0, Vector2(0, 5), "WWWWDWWW", "WallAstra", "TopPlastic")
	wall(-16, 36, 16, 36, Vector2(0, 30), "WWWWDWWW", "WallAstra", "TopPlastic")
	wall(-16, 0, -16, 36, Vector2(0, 18), "", "WallAstra", "TopPlastic")
	wall(16, 0, 16, 36, Vector2(0, 18), "", "WallAstra", "TopPlastic")
	for s in [0.0, 36.0]: wall(-16, s, 16, s, Vector2(0, 18), "", "WallAstra", "", 5.0)
	# testing cells west
	for k in 5:
		var d0 := 3.0 + k * 6.0
		partition(-16, d0, -10, d0, 3.0, b.mat("techc", 2.0), 0.2)
		partition(-10, d0, -10, d0 + 2.0, 3.0, b.mat("techc", 2.0), 0.2)
		box(Vector3(0.06, 1.2, 2.0), -10.0, d0 + 3.6, 1.6, Mats.glass(), true)
		partition(-10, d0 + 4.6, -10, d0 + 6.0, 3.0, b.mat("techc", 2.0), 0.2)
		piece("ph:modern_arm_chair_01", -13.5, d0 + 3.0, 270)
		piece("ph:Television_01", -15.5, d0 + 3.0, 90, 0.8, "none")
		label("CELL %d" % (k + 1), -9.9, d0 + 1.0, 2.6, 270, 36, Color(0.85, 0.9, 1.0))
	partition(-16, 33, -10, 33, 3.0, b.mat("techc", 2.0), 0.2)
	# eye-tracking theatre NE (three tiers facing south toward a screen at d 19)
	for t in 3:
		var dd := 26.0 + t * 3.0; var y := 0.5 * (t + 1)
		box(Vector3(14.0, y, 3.0), 8.0, dd + 1.5, y * 0.5, b.mat("metal", 2.0, Color(0.4, 0.42, 0.46)))
		for k2 in 5: piece("ph:SchoolChair_01", 3.0 + k2 * 2.5, dd + 1.8, 180, y)
		box(Vector3(14.0, 0.04, 0.1), 8.0, dd, y + 0.01, Mats.glow(accent, 2.0), false)
	ramp(0.2, 25.8, 0.0, 1.5, 9.0, 1.6)
	box(Vector3(10.0, 3.0, 0.15), 8.0, 20.0, 2.6, Mats.flat(Color(0.02, 0.03, 0.04), 0.3))
	label("EYE-TRACKING · AD 14B · GAZE HEATMAP", 8.0, 20.1, 2.6, 0, 48, Color(1.0, 0.5, 0.35))
	for k3 in 4: box(Vector3(1.2 + k3 * 0.3, 0.6, 0.03), 5.0 + k3 * 2.0, 20.1, 1.6 + (k3 % 2) * 0.6, Mats.glow(Color(1.0, 0.3 + k3 * 0.15, 0.1), 2.0), false)
	# lab floor carts
	for p in [[-4.0, 8.0], [3.0, 12.0], [-3.0, 22.0], [9.0, 6.0]]:
		piece("ph:industrial_storage_cart", p[0], p[1], 30.0 * (int(p[0]) % 3))
		cover_pt(p[0] + 1.5, p[1]); cover_pt(p[0] - 1.5, p[1])
	for p2 in [[-4.0, 14.5], [12.0, 14.0]]: desk(p2[0], p2[1], 180, "monitor")
	intel(0, 12.0, 14.0, 180, 0.79)
	ceiling_lights(-9, 0, 16, 36, 7.0, 3, 3, 6.5, Color(0.95, 0.97, 1.0))
	fill(-13, 18, 2.6, Color(0.9, 0.85, 1.0), 0.5, 18.0)
	terminal(-6.0, 34.5, 180)
	for p3 in [[-6, 34], [6, 34], [0, 33], [12, 33, 1.5], [3, 33, 1.5], [-13, 34], [14, 2], [-6, 2]]: spawn(p3[0], p3[1])
