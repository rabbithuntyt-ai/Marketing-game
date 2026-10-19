extends Sector
## M5 · Sector 1 · ATRIUM — Castellan Commons, Toronto. Saturday crowd, skylight, piano music.
## Tail the courier through the mall without being made. He window-shops (need recognition), walks
## past the fountain, and heads for the kiosk.
## Read: six storefronts down the two long walls; a fountain and planters in the middle give you
## breaks in his line of sight; a mezzanine along the east wall (3 m) with a security guard who
## looks down on the floor. Keep to the planters and the shop fronts.

func dims() -> Vector3: return Vector3(36, 12, 48)

func build() -> void:
	strategy_wall(-17.3, 44.0, 90, 3.0)
	floor_rect(-18, 0, 18, 48, "", 0.0, b.mat("MARBLE"))
	ceiling(-18, 0, 18, 48, 12.0)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallAstra", "TopAstra")
	wall(-18, 48, 18, 48, Vector2(0, 30), "WWWWDWWWW", "WallAstra", "TopAstra")
	wall(-18, 0, -18, 48, Vector2(0, 24), "", "WallAstra", "TopAstra")
	wall(18, 0, 18, 48, Vector2(0, 24), "", "WallAstra", "TopAstra")
	for s in [0.0, 48.0]: wall(-18, s, 18, s, Vector2(0, 24), "", "WallAstra", "TopWindow", 5.0)
	wall(-18, 0, -18, 48, Vector2(0, 24), "", "WallAstra", "TopWindow", 5.0)
	wall(18, 0, 18, 48, Vector2(0, 24), "", "WallAstra", "TopWindow", 5.0)
	# skylight
	box(Vector3(12.0, 0.1, 36.0), 0, 24.0, 11.9, Mats.glow(Color(0.55, 0.65, 0.85), 0.6), false)
	# storefronts (west faces east, yaw 90; east faces west, yaw 270) — fronts at x ±13.6
	var shops := [[-13.6, 9.0, 90.0, "NORTHSHORE", Color(0.4, 0.8, 1.0), 0], [-13.6, 21.0, 90.0, "VELA HOME", Color(1.0, 0.75, 0.45), 1], [-13.6, 33.0, 90.0, "PIXELFRONT", Color(0.6, 0.5, 1.0), 2],
		[13.6, 5.5, 270.0, "MARIGOLD", Color(1.0, 0.85, 0.3), 0], [13.6, 17.0, 270.0, "OAK & IRON", Color(0.85, 0.65, 0.45), 1], [13.6, 30.0, 270.0, "LUMEN", Color(0.5, 1.0, 0.8), 2]]
	for sh in shops: storefront(sh[0], sh[1], sh[2], 8.0, sh[3], sh[4], sh[5])
	# fountain
	b.cyl(geo, 3.0, 0.6, P(2.0, 21.0, 0.3), b.mat("MARBLE"), Vector3.ZERO, true)
	b.cyl(geo, 2.7, 0.05, P(2.0, 21.0, 0.58), Mats.glow(Color(0.3, 0.6, 0.9), 0.6))
	b.cyl(geo, 0.4, 2.2, P(2.0, 21.0, 1.4), b.mat("MARBLE"), Vector3.ZERO, true)
	fill(2.0, 21.0, 1.2, Color(0.4, 0.7, 1.0), 0.8, 5.0)
	cover_pt(2.0, 17.3); cover_pt(2.0, 24.7); cover_pt(-1.7, 21.0)
	for p in [[-6.0, 12.0], [5.5, 30.0], [-3.0, 27.0], [7.0, 11.0]]: planter(p[0], p[1], 2.4, 1.4)
	for d in [15.0, 25.0, 35.0]: piece("ph:sofa_02", 5.0, d, 270)
	# kiosk
	box(Vector3(2.6, 1.1, 1.4), 4.2, 39.0, 0.55, Mats.flat(Color(0.9, 0.88, 0.84), 0.4))
	box(Vector3(2.8, 0.1, 1.6), 4.2, 39.0, 2.6, Mats.glow(Color(1.0, 0.5, 0.3), 2.0), false)
	for x in [3.0, 5.4]: box(Vector3(0.1, 1.5, 0.1), x, 39.0, 1.85, b.mat("steel", 1.0), false)
	label("PHONE REPAIR", 4.2, 38.25, 2.75, 180, 40, Color(1.0, 0.95, 0.9))
	intel(0, 4.2, 39.2, 180, 1.12)
	# east mezzanine
	catwalk(9, 13, 13, 44, 3.0, "w")
	stairs(11.0, 6.9, 0.0, true)
	for d2 in [16.0, 28.0, 40.0]: box(Vector3(0.3, 3.0, 0.3), 9.2, d2, 1.5, b.mat("steel", 1.0))
	anchor("path", [P(0, 8), P(-8, 20), P(-7, 31), P(1.5, 37)])
	note("Courier route", -8, 20)
	for k in 6: lamp(0.0 if k % 2 == 0 else -6.0, 6.0 + k * 7.0, 11.8, 6.0, 60, Color(1.0, 0.92, 0.8), "")
	fill(0, 24, 9.0, Color(0.8, 0.85, 1.0), 0.6, 36.0)
	terminal(-9.0, 46.0, 180)
	guard(11.0, 20.0, 270, [[11, 20, 4, 270], [11, 40, 4, 270]], "css", 0, 3.0)
	guard(-9.0, 40.0, 180)
	guard(8.0, 44.0, 200, [], "css", 1)
	guard(-10.0, 4.0, 30, [], "css", 2)
	for p in [[-6, 46], [6, 46], [0, 45], [-12, 44], [12, 46]]: spawn(p[0], p[1])
