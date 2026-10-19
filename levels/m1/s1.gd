extends Sector
## M1 · Sector 2 · LOADING DOCKS — inbound side of the fulfilment centre.
## Read: the west wall is a raised dock platform with three truck bays (roller doors, crates);
## a ramp at the far end gets you up. The east half is pallet racking in two rows that blocks sight;
## above the racks, a mezzanine office (north-east) looks down on the floor — a guard up there has
## the long view, intel on his desk. Centre floor is open: fast but exposed.

func dims() -> Vector3: return Vector3(36, 9, 36)

func build() -> void:
	strategy_wall(17.3, 9.0, 270, 3.0)
	floor_rect(-18, 0, 18, 36, "", 0.0, b.mat("CONCRETE"))
	ceiling(-18, 0, 18, 36, 9.0)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallBand", "TopCables")
	wall(-18, 36, 18, 36, Vector2(0, 30), "WWWWDWWWW", "WallBand", "TopCables")
	wall(-18, 0, -18, 36, Vector2(0, 18), "", "WallBand", "TopCables")
	wall(18, 0, 18, 36, Vector2(0, 18), "", "WallBand", "TopCables")
	for s in [0.0, 36.0]: wall(-18, s, 18, s, Vector2(0, 18), "", "WallBand", "", 5.0)
	wall(-18, 0, -18, 36, Vector2(0, 18), "", "WallBand", "", 5.0)
	wall(18, 0, 18, 36, Vector2(0, 18), "", "WallBand", "", 5.0)
	# west dock platform with bays
	box(Vector3(5.0, 1.2, 36.0), -15.5, 18.0, 0.6, b.mat("CONCRETE", 2.0))
	box(Vector3(0.2, 0.15, 36.0), -13.0, 18.0, 1.25, b._hazard(), false)
	for d in [7.0, 18.0, 29.0]:
		piece("ph:rollershutter_door", -17.7, d, 90, 1.2, "box")
		label("BAY %d" % (1 + int(d / 11.0)), -17.8, d, 5.0, 90, 64, Color(1.0, 0.85, 0.35))
		crates(-15.0, d + 2.2, 5.0, 1)
		cover("ph:wooden_military_crate", -15.5, d - 2.0, 85.0, 1.2)
		lamp(-15.0, d, 6.5, 5.0, 60, Color(1.0, 0.85, 0.6), "q:Prop_Light_Wide")
	ramp(-9.4, 33.5, 270.0, 1.2, 3.6, 2.6)
	piece("tps:prop_cargolift", -10.5, 12.0, 90)
	piece("tps:prop_cargolift", -10.5, 24.0, 90)
	# pallet racks east
	for p in [[7.0, 12.0], [7.0, 25.0], [13.5, 12.0], [13.5, 25.0]]: pallet_rack(p[0], p[1], 0.0, 3, 3)
	# mezzanine office NE
	catwalk(4, 30, 18, 36, 3.0, "n")
	rail(4, 30, 4, 36, 3.0)
	stairs(16.0, 23.9, 0.0, true)
	for x in [4.3, 10.0]: box(Vector3(0.25, 3.0, 0.25), x, 30.3, 1.5, b.mat("steel", 1.0))
	piece("ph:metal_office_desk", 9.0, 34.6, 180, 3.0)
	piece("ph:Television_01", 8.2, 35.5, 180, 3.79, "none")
	piece("ph:drawer_cabinet", 14.0, 35.4, 180, 3.0)
	intel(0, 9.6, 34.6, 180, 3.79)
	intel(1, -15.5, 9.6, 90, 1.95)
	label("SHIPPING OFFICE", 11.0, 36.0, 5.6, 180, 54, Color(0.85, 0.9, 1.0))
	# floor clutter
	for p in [[-4.0, 8.0, 0], [2.0, 15.0, 1], [-5.0, 22.0, 2], [1.0, 28.0, 0]]: crates(p[0], p[1], 20.0 * p[2], p[2])
	piece("ph:hand_truck", -7.0, 18.0, 40)
	piece("ph:industrial_storage_cart", 3.0, 5.0, 90)
	piece("tps:prop_barrelcart", -2.0, 33.0, 0)
	for d2 in [8.0, 18.0, 28.0]: lamp(0.0, d2, 8.8, 7.0, 64, Color(1.0, 0.88, 0.7), "q:Prop_Light_Wide")
	fill(0, 18, 6.0, Color(0.55, 0.6, 0.75), 0.35, 28.0)
	dark(4, 6, 16, 31)
	terminal(-1.0, 3.0, 180)
	guard(-14.5, 4.0, 0, [[-14.5, 4, 2, 90], [-14.5, 31, 3, 90]], "css", 0, 1.2)
	guard(10.3, 6.0, 0, [[10.3, 6, 2, 270], [10.3, 30, 3, 270]])
	guard(9.0, 33.0, 180, [], "css", 0, 3.0)
	guard(-2.0, 10.0, 0, [[-2, 10, 2, 0], [-2, 26, 3, 180]])
	guard(-6.0, 33.0, 160, [], "heavy", 1)
	guard(14.0, 18.5, 270, [], "css", 2)
	for p in [[-6, 34], [6, 28], [0, 32], [-12, 33], [-1, 20]]: spawn(p[0], p[1])
