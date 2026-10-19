extends Sector
## M4 · Sector 8 · EXFIL — the loading dock under the data centre. Ruiz has the van; you hold the dock.
## Read: a raised dock platform along the east wall with three box trucks backed in (cover, and the
## platform is the high ground). Pallets and cages break up the floor. A dispatch catwalk on the
## west wall gives defenders a firing line, reached by stairs at either end. Red beacons pulse.

func dims() -> Vector3: return Vector3(36, 8, 44)

func build() -> void:
	strategy_wall(-17.3, 6.0, 90, 2.6)
	floor_rect(-18, 0, 18, 44, "", 0.0, b.mat("CONCRETE"))
	concrete_shell(8.0, 8.0)
	for d in [6.0, 20.0, 34.0]:
		paint(-10, d, 4, d, Color(0.95, 0.75, 0.15), 0.2)
	# dock platform east with trucks
	box(Vector3(6.0, 1.2, 40.0), 15.0, 22.0, 0.6, b.mat("CONCRETE", 2.0))
	box(Vector3(0.2, 0.15, 40.0), 11.9, 22.0, 1.25, b._hazard(), false)
	ramp(9.0, 40.0, 90.0, 1.2, 2.8, 3.0)
	for d2 in [10.0, 22.0, 34.0]:
		truck(9.5, d2)
		piece("ph:rollershutter_door", 17.7, d2, 270, 1.2, "box")
		box(Vector3(0.3, 0.3, 0.3), 17.5, d2 - 2.5, 5.2, Mats.glow(Color(1.0, 0.1, 0.05), 5.0), false)
		fill(16.0, d2 - 2.5, 5.0, Color(1.0, 0.15, 0.1), 1.2, 7.0)
	# floor clutter
	for p in [[-3.0, 9.0, 0], [-8.0, 15.0, 1], [1.0, 18.0, 2], [-5.0, 26.0, 0], [2.0, 30.0, 1], [-9.0, 34.0, 2]]:
		crates(p[0], p[1], 15.0 * p[2], p[2])
	pallet_rack(-9.0, 22.0, 0.0, 3, 2)
	piece("ph:hand_truck", 4.0, 12.0, 60)
	piece("ph:industrial_storage_cart", -1.0, 36.0, 90)
	for d3 in [5.0, 39.0]: piece("tps:prop_barrelcart", 4.0, d3, 0)
	# dispatch catwalk west
	catwalk(-18, 4, -14, 40, 3.0, "e")
	stairs(-7.9, 6.0, 270.0, true)
	stairs(-7.9, 34.0, 270.0, true)
	desk(-16.5, 20.0, 90, "monitor", false)
	label("DISPATCH", -17.8, 30.0, 5.0, 90, 64, Color(1.0, 0.8, 0.3))
	for d4 in [8.0, 18.0, 28.0, 38.0]: lamp(0.0, d4, 7.8, 6.0, 62, Color(1.0, 0.86, 0.66), "q:Prop_Light_Wide")
	fill(0, 22, 6.0, Color(0.6, 0.6, 0.7), 0.4, 30.0)
	terminal(0.0, 42.0, 180)
	for p in [[-6, 40], [6, 40], [0, 41], [15, 6], [15, 40], [-16, 12, 3.0], [-16, 32, 3.0], [-10, 42], [10, 42]]: spawn(p[0], p[1])
