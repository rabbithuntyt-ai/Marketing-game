extends Sector
## M7 · Sector 7 · BRAND VAULT — Castellan's brand equity archive: trademarks, master artwork,
## valuation. Defend the console while Marr pulls the brand valuation files.
## Read: the console sits on the middle of three tiers rising toward the north wall; ramps on
## each side of the tiers; museum display cases hold the brand history (cover). Attackers come
## from both doors and down the side galleries.

func dims() -> Vector3: return Vector3(32, 8, 36)

func build() -> void:
	city_view(150.0)
	strategy_wall(-15.3, 4.0, 90, 3.0)
	floor_rect(-16, 0, 16, 36, "", 0.0, b.mat("MARBLE", 3.0, Color(0.55, 0.55, 0.6)))
	ceiling(-16, 0, 16, 36, 8.0)
	wall(-16, 0, 16, 0, Vector2(0, 5), "WWWWDWWW", "WallAstra", "TopAstra")
	wall(-16, 36, 16, 36, Vector2(0, 30), "WWWWDWWW", "WallAstra", "TopAstra")
	wall(-16, 0, -16, 36, Vector2(0, 18), "", "WallAstra", "TopAstra")
	wall(16, 0, 16, 36, Vector2(0, 18), "", "WallAstra", "TopAstra")
	for s in [0.0, 36.0]: wall(-16, s, 16, s, Vector2(0, 18), "", "WallAstra", "", 5.0)
	wall(-16, 0, -16, 36, Vector2(0, 18), "", "WallAstra", "", 5.0)
	wall(16, 0, 16, 36, Vector2(0, 18), "", "WallAstra", "", 5.0)
	# tiers (0.5, 1.0) with the console on tier 1
	box(Vector3(18.0, 0.5, 8.0), 0, 18.0, 0.25, Mats.flat(Color(0.1, 0.1, 0.12), 0.3))
	box(Vector3(18.0, 1.0, 6.0), 0, 25.0, 0.5, Mats.flat(Color(0.1, 0.1, 0.12), 0.3))
	box(Vector3(18.0, 0.04, 0.1), 0, 14.0, 0.51, Mats.glow(Color(1.0, 0.85, 0.5), 2.5), false)
	box(Vector3(18.0, 0.04, 0.1), 0, 22.0, 1.01, Mats.glow(Color(1.0, 0.85, 0.5), 2.5), false)
	for s2 in [-1.0, 1.0]:
		ramp(s2 * 11.0, 16.0, -90.0 * s2, 0.5, 2.0, 2.5)
		ramp(s2 * 11.0, 24.0, -90.0 * s2, 1.0, 2.0, 2.5)
	anchor("console", P(0, 18, 0.5))
	note("Vault console: hold here", 0, 18)
	# display cases
	for p in [[-6.0, 7.0], [6.0, 7.0], [-12.0, 10.0], [12.0, 10.0], [-6.0, 25.0], [6.0, 25.0]]:
		var yb := 1.0 if p[1] > 21.0 else 0.0
		box(Vector3(1.4, 1.0, 1.4), p[0], p[1], yb + 0.5, Mats.flat(Color(0.12, 0.12, 0.14), 0.3))
		box(Vector3(1.3, 1.2, 1.3), p[0], p[1], yb + 1.6, Mats.glass(), true)
		box(Vector3(0.5, 0.5, 0.05), p[0], p[1], yb + 1.5, Mats.glow(Color(1.0, 0.85, 0.5), 1.5), false)
		cover_pt(p[0], p[1] - 1.3)
	for k in 5:
		box(Vector3(2.4, 1.6, 0.06), -10.0 + k * 5.0, 35.85, 3.6, Mats.flat(Color(0.08, 0.08, 0.09), 0.3), false)
		label(["1962", "1979", "1994", "2008", "2026"][k], -10.0 + k * 5.0, 35.8, 4.0, 180, 56, Color(0.95, 0.85, 0.6))
	label("BRAND EQUITY", 0, 35.8, 6.0, 180, 120, Color(0.95, 0.88, 0.7))
	intel(0, 12.0, 10.0, 0, 2.2)
	for d in [8.0, 18.0, 28.0]: lamp(0.0, d, 7.8, 6.0, 58, Color(1.0, 0.9, 0.75), "")
	for p2 in [[-12.0, 30.0], [12.0, 30.0]]: lamp(p2[0], p2[1], 7.8, 3.5, 50, Color(1.0, 0.85, 0.6), "")
	fill(0, 18, 5.0, Color(1.0, 0.85, 0.65), 0.4, 24.0)
	for p3 in [[-6, 35], [6, 35], [0, 35], [-6, 1], [6, 1], [-15, 18], [15, 18]]: spawn(p3[0], p3[1])
