extends Sector
## M5 · Sector 6 · DECISION LAB — five rooms, one per stage of the buyer decision process
## (NEED → SEARCH → EVALUATE → PURCHASE → POST-PURCHASE), linked by a corridor along the west.
## The journey wall on the east holds the routing consoles for Marr's calls about buyer behaviour.
## Read: rooms are 6 m deep cells off the corridor; each has two doors so fights flow room to room.

func dims() -> Vector3: return Vector3(36, 6, 40)

func build() -> void:
	strategy_wall(-17.3, 36.0, 90, 2.8)
	floor_rect(-18, 0, 18, 40, "", 0.0, Mats.flat(Color(0.18, 0.2, 0.24), 0.8))
	ceiling(-18, 0, 18, 40, 5.0)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallBand", "TopSimple")
	wall(-18, 40, 18, 40, Vector2(0, 30), "WWWWDWWWW", "WallBand", "TopSimple")
	wall(-18, 0, -18, 40, Vector2(0, 20), "", "WallBand", "TopSimple")
	wall(18, 0, 18, 40, Vector2(0, 20), "", "WallBand", "TopSimple")
	var names := ["NEED", "SEARCH", "EVALUATE", "PURCHASE", "POST-PURCHASE"]
	var cols := [Color(1.0, 0.5, 0.35), Color(1.0, 0.8, 0.3), Color(0.4, 1.0, 0.6), Color(0.35, 0.75, 1.0), Color(0.75, 0.5, 1.0)]
	for k in 5:
		var d0 := 2.0 + k * 7.0
		# room spans x -10..8, d d0..d0+6; corridor west at x -18..-10
		if k == 0: partition(-10, d0, 8, d0, 3.0, b.mat("tech", 2.0), 0.2)
		partition(-10, d0 + 6.5, -1, d0 + 6.5, 3.0, b.mat("tech", 2.0), 0.2)
		partition(1.5, d0 + 6.5, 8, d0 + 6.5, 3.0, b.mat("tech", 2.0), 0.2)
		partition(-10, d0, -10, d0 + 1.8, 3.0, b.mat("tech", 2.0), 0.2)
		partition(-10, d0 + 3.6, -10, d0 + 6.5, 3.0, b.mat("tech", 2.0), 0.2)
		label("%d · %s" % [k + 1, names[k]], -10.1, d0 + 4.8, 2.4, 270, 40, cols[k])
		box(Vector3(17.5, 0.05, 0.12), -1.0, d0 + 0.3, 2.95, Mats.glow(cols[k], 2.0), false)
		fill(-1.0, d0 + 3.0, 2.6, cols[k].lerp(Color.WHITE, 0.5), 0.7, 7.0)
		match k:
			0:
				piece("ph:sofa_03", -4.0, d0 + 4.5, 180); piece("ph:Television_01", -4.0, d0 + 1.0, 0, 0.0, "box")
			1:
				desk(-5.0, d0 + 3.0, 180, "laptop"); desk(-1.0, d0 + 3.0, 180, "monitor"); shelf(4.0, d0 + 5.5, 180, 1)
			2:
				for kk in 3: box(Vector3(1.0, 1.1, 1.0), -6.0 + kk * 3.5, d0 + 3.0, 0.55, Mats.flat(Color(0.95, 0.95, 0.95), 0.3))
			3:
				box(Vector3(4.0, 1.05, 1.0), -3.0, d0 + 3.0, 0.52, Mats.flat(Color(0.2, 0.22, 0.25), 0.4)); piece("ph:classic_laptop", -3.0, d0 + 3.0, 180, 1.05, "none")
			4:
				piece("ph:ArmChair_01", -5.0, d0 + 3.0, 90); piece("ph:CoffeeTable_01", -2.5, d0 + 3.0, 0); piece("ph:cardboard_box_01", 2.0, d0 + 4.0, 30)
	# east journey wall + consoles
	call_panels([17.6, 20.0, 270], [[13.5, 14.0, 270], [13.5, 18.0, 270], [13.5, 22.0, 270], [13.5, 26.0, 270]])
	label("THE BUYER JOURNEY", 17.6, 20.0, 4.5, 270, 54, Color(0.8, 0.9, 1.0))
	for k2 in 5: box(Vector3(0.05, 0.3, 2.0), 17.9, 6.0 + k2 * 7.0, 3.6, Mats.glow(cols[k2], 2.5), false)
	intel(0, -1.0, 12.0, 180, 0.79)
	intel(1, -15.0, 37.0, 90, 0.79, "ph:metal_office_desk")
	for d in [6.0, 14.0, 22.0, 30.0, 38.0]: lamp(-14.0, d, 4.9, 4.5, 60, Color(0.95, 0.95, 1.0), "q:Prop_Light_Small")
	ceiling_lights(9, 0, 17, 40, 5.0, 1, 4, 5.0, Color(0.95, 0.97, 1.0))
	for p in [[-6, 38], [6, 38], [0, 38], [-14, 30], [14, 36], [14, 4], [-14, 8]]: spawn(p[0], p[1])
