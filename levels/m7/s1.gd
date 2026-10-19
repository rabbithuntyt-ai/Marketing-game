extends Sector
## M7 · Sector 2 · SHOWROOM — floor 12. Castellan's product showroom.
## Read: a raised runway down the centre with product plinths; glass product cases either side;
## four "brand worlds" in the corners, each a different product line with its own colour and
## furniture; the routing consoles at the north wall take Marr's product/brand calls.

func dims() -> Vector3: return Vector3(36, 7, 40)

func build() -> void:
	city_view(150.0)
	strategy_wall(-17.3, 20.0, 90, 3.0)
	floor_rect(-18, 0, 18, 40, "", 0.0, Mats.flat(Color(0.9, 0.9, 0.9), 0.3))
	ceiling(-18, 0, 18, 40, 7.0)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallAstra", "TopAstra")
	wall(-18, 40, 18, 40, Vector2(0, 30), "WWWWDWWWW", "WallAstra", "TopAstra")
	wall(-18, 0, -18, 40, Vector2(0, 20), "GGGGGGGGGG", "WallAstra", "TopWindow")
	wall(18, 0, 18, 40, Vector2(0, 20), "GGGGGGGGGG", "WallAstra", "TopWindow")
	for s in [0.0, 40.0]: wall(-18, s, 18, s, Vector2(0, 20), "", "WallAstra", "", 5.0)
	# runway
	box(Vector3(4.0, 0.4, 22.0), 0, 18.0, 0.2, Mats.flat(Color(0.08, 0.08, 0.09), 0.3))
	glow_strip(-2.0, 18.0, 0.41, 22.0, 0.0, Color(1.0, 0.9, 0.7), 3.0)
	glow_strip(2.0, 18.0, 0.41, 22.0, 0.0, Color(1.0, 0.9, 0.7), 3.0)
	for d in [10.0, 18.0, 26.0]:
		b.cyl(geo, 0.6, 1.0, P(0, d, 0.9), Mats.flat(Color(0.95, 0.95, 0.95), 0.3), Vector3.ZERO, true)
		piece(["ph:classic_laptop", "ph:desk_lamp_arm_01", "ph:wall_clock"][int(d) % 3], 0, d, 30.0, 1.4, "none")
	# glass cases
	for x in [-6.0, 6.0]:
		for d2 in [9.0, 17.0, 25.0]:
			box(Vector3(1.4, 1.0, 1.4), x, d2, 0.5, Mats.flat(Color(0.95, 0.95, 0.95), 0.3))
			box(Vector3(1.3, 1.0, 1.3), x, d2, 1.5, Mats.glass(), true)
			piece("ph:circuit_board", x, d2, 45, 1.02, "none")
			cover_pt(x, d2 - 1.2); cover_pt(x, d2 + 1.2)
	# brand worlds
	var worlds := [[-12.5, 6.0, "ASSURE HOME", Color(1.0, 0.45, 0.35)], [12.5, 6.0, "ASSURE AUTO", Color(0.35, 0.75, 1.0)], [-12.5, 29.0, "ASSURE LIFE", Color(0.45, 1.0, 0.6)], [12.5, 29.0, "ASSURE PRO", Color(1.0, 0.8, 0.3)]]
	for w in worlds:
		var x0: float = w[0]; var d0: float = w[1]
		floor_rect(x0 - 5.0, d0 - 4.0, x0 + 5.0, d0 + 4.0, "", 0.03, Mats.flat(w[3].darkened(0.7), 0.6))
		box(Vector3(0.2, 3.2, 8.0), x0 + (5.0 if x0 < 0 else -5.0), d0, 1.6, Mats.flat(Color(0.95, 0.95, 0.95), 0.4))
		label(String(w[2]), x0 + (4.88 if x0 < 0 else -4.88), d0, 2.6, 90.0 if x0 < 0 else 270.0, 64, w[3])
		piece("ph:sofa_02" if d0 < 20 else "ph:ArmChair_01", x0, d0 + 1.0, 180)
		piece("ph:modern_coffee_table_01", x0, d0 - 1.0, 0)
		fill(x0, d0, 3.0, w[3].lerp(Color.WHITE, 0.5), 0.9, 7.0)
		cover_pt(x0 + (5.8 if x0 < 0 else -5.8), d0)
	call_panels([0, 39.4, 180], [[-6.0, 34.5, 180], [-2.0, 34.5, 180], [2.0, 34.5, 180], [6.0, 34.5, 180]])
	intel(0, -12.5, 5.0, 0, 0.45)
	ceiling_lights(-18, 0, 18, 40, 7.0, 3, 4, 6.0, Color(1.0, 0.97, 0.92))
	guard(0.0, 30.0, 180, [[0, 30, 3, 180], [0, 6, 3, 0]])
	guard(-9.0, 18.0, 90, [[-9, 18, 2, 90], [9, 18, 2, 270]])
	guard(12.5, 28.0, 220)
	guard(-12.5, 31.0, 150, [], "heavy", 1)
	guard(9.0, 36.0, 200, [], "css", 1)
	guard(-3.0, 37.0, 180, [], "marksman", 2)
	for p in [[-12, 38], [12, 38], [-16, 34], [16, 34], [0, 31]]: spawn(p[0], p[1])
