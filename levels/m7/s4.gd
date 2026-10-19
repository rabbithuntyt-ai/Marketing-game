extends Sector
## M7 · Sector 5 · PRODUCT LINE OFFICE — the product-line managers' floor. Three "streets" of desks,
## one per product line, each colour-coded; tall storage walls between them with cross-cuts every
## 8 m, so fights are about which cut you hold. The manager's glass office closes the north-east.

func dims() -> Vector3: return Vector3(36, 6, 40)

func build() -> void:
	city_view(150.0)
	strategy_wall(-17.3, 6.0, 90, 2.8)
	floor_rect(-18, 0, 18, 40, "", 0.0, Mats.flat(Color(0.2, 0.21, 0.24), 0.8))
	ceiling(-18, 0, 18, 40, 5.5)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallAstra", "TopSimple")
	wall(-18, 40, 18, 40, Vector2(0, 30), "WWWWDWWWW", "WallAstra", "TopSimple")
	wall(-18, 0, -18, 40, Vector2(0, 20), "GGGGGGGGGG", "WallAstra", "TopWindow")
	wall(18, 0, 18, 40, Vector2(0, 20), "GGGGGGGGGG", "WallAstra", "TopWindow")
	var lines := [[-12.0, "LINE A · ASSURE HOME", Color(1.0, 0.45, 0.35)], [0.0, "LINE B · ASSURE AUTO", Color(0.35, 0.75, 1.0)], [12.0, "LINE C · ASSURE LIFE", Color(0.45, 1.0, 0.6)]]
	for ln in lines:
		var x: float = ln[0]
		paint(x, 3.0, x, 32.0, ln[2].darkened(0.3), 1.2)
		for d in [6.0, 12.0, 20.0, 26.0]:
			desk(x - 1.6, d, 90, "monitor")
			desk(x + 1.6, d, 270, "monitor" if int(d) % 4 == 0 else "laptop")
		label(String(ln[1]), x, 3.0, 3.6, 180, 42, ln[2])
	# storage walls between streets, cross-cuts at d 9, 17, 25
	for wx in [-6.0, 6.0]:
		for seg in [[2.0, 8.0], [10.0, 16.0], [18.0, 24.0], [26.0, 32.0]]:
			box(Vector3(1.0, 2.6, seg[1] - seg[0]), wx, (seg[0] + seg[1]) * 0.5, 1.3, Mats.flat(Color(0.88, 0.86, 0.82), 0.5))
			cover_pt(wx + 1.0, (seg[0] + seg[1]) * 0.5); cover_pt(wx - 1.0, (seg[0] + seg[1]) * 0.5)
	note("Cross-cuts every 8 m", 6, 9)
	# manager's office
	glass_room(6.5, 34.5, 15.5, 39.6, "w", 0.5)
	desk(11.0, 37.8, 180, "monitor")
	piece("ph:modern_wooden_cabinet", 15.0, 36.5, 270)
	intel(0, 11.0, 37.9, 180, 0.79)
	label("PORTFOLIO DIRECTOR", 11.0, 34.5, 2.6, 180, 38, Color(0.9, 0.9, 1.0))
	piece("ph:CoffeeCart_01", -16.0, 36.0, 90)
	piece("ph:sofa_02", -10.0, 37.5, 180)
	ceiling_lights(-18, 0, 18, 40, 5.5, 3, 4, 5.5, Color(0.95, 0.97, 1.0))
	terminal(-4.0, 38.0, 180)
	guard(-9.0, 4.0, 0, [[-9, 4, 2, 0], [-9, 33, 2, 180]])
	guard(9.0, 33.0, 180, [[9, 33, 2, 180], [9, 4, 2, 0]])
	guard(0.0, 17.0, 180, [[0, 17, 2, 270], [-12, 17, 2, 90]])
	guard(12.0, 30.0, 200, [], "heavy", 1)
	guard(-12.0, 28.0, 160, [], "css", 1)
	guard(10.0, 36.0, 180, [], "css", 2)
	for p in [[-6, 38], [4, 36], [-14, 34], [16, 30], [0, 35]]: spawn(p[0], p[1])
