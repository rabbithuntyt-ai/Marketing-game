extends Sector
## M1 · Sector 3 · SORTING HALL — the heart of the fulfilment centre: parcels in, sorted, out.
## Read: a conveyor spine runs up the middle with three branch lines to chutes on each side (the
## branches are low cover and split the hall into bays). A gantry bridge crosses the spine at 21 m
## (overwatch). The glass SORT CONTROL room in the north-east holds the routing consoles: Marr's
## calls about the value chain are answered by walking to the right console.

func dims() -> Vector3: return Vector3(36, 9, 44)

func build() -> void:
	strategy_wall(-17.3, 12.0, 90, 3.0)
	floor_rect(-18, 0, 18, 44, "", 0.0, b.mat("CONCRETE"))
	ceiling(-18, 0, 18, 44, 9.0)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallBand", "TopCables")
	wall(-18, 44, 18, 44, Vector2(0, 30), "WWWWDWWWW", "WallBand", "TopCables")
	wall(-18, 0, -18, 44, Vector2(0, 22), "", "WallBand", "TopCables")
	wall(18, 0, 18, 44, Vector2(0, 22), "", "WallBand", "TopCables")
	for s in [0.0, 44.0]: wall(-18, s, 18, s, Vector2(0, 22), "", "WallBand", "", 5.0)
	wall(-18, 0, -18, 44, Vector2(0, 22), "", "WallBand", "", 5.0)
	wall(18, 0, 18, 44, Vector2(0, 22), "", "WallBand", "", 5.0)
	# conveyor spine + branches
	conveyor(0, 6, 0, 13, 0.95, 3)
	conveyor(0, 15.5, 0, 26.5, 0.95, 4)
	conveyor(0, 29, 0, 36, 0.95, 3)
	for d in [8.0, 20.0, 33.0]:
		conveyor(-11, d, -1.2, d, 0.95, 3)
		conveyor(1.2, d, 11, d, 0.95, 3)
		for s in [-1.0, 1.0]:
			box(Vector3(2.0, 1.6, 2.0), s * 13.0, d, 0.8, b.mat("steel", 1.0))
			box(Vector3(1.6, 0.05, 1.6), s * 13.0, d, 1.62, Mats.flat(Color(0.05, 0.05, 0.05), 0.9), false)
			label("CHUTE %s%d" % ["W" if s < 0 else "E", 1 + int(d / 12.0)], s * 13.0, d - 1.05, 1.9, 180, 40, Color(1.0, 0.85, 0.35))
			cover_pt(s * 13.0, d - 1.8); cover_pt(s * 13.0, d + 1.8)
	for p in [[-6.0, 14.0], [6.5, 26.0], [-15.6, 35.2], [9.0, 4.0]]: piece("ph:industrial_storage_cart", p[0], p[1], 90)
	# gantry over the spine
	catwalk(-6, 21, 6, 23.5, 4.0, "ns")
	stairs(-8.0, 28.0, 180.0, false, true)
	rail(-6, 21, -6, 23.5, 4.0)
	# sort control (NE)
	glass_room(5, 36.5, 17.6, 43.6, "w", 0.4)
	call_panels([11.5, 43.4, 180], [[7.5, 39.5, 180], [10.0, 39.5, 180], [12.5, 39.5, 180], [15.0, 39.5, 180]])
	label("SORT CONTROL", 11.3, 36.5, 3.3, 180, 56, Color(0.7, 0.9, 1.0))
	note("Sort control: routing consoles", 11, 38)
	# west supervisor nook
	desk(-14.0, 40.0, 180, "monitor")
	piece("ph:Shelf_01", -17.3, 41.0, 90)
	intel(0, 13.0, 20.0, 0, 1.65)
	intel(1, -15.6, 35.2, 90, 1.0)
	for p in [[-6.0, 40.0, 0], [3.0, 40.0, 1], [-15.0, 4.0, 1], [15.0, 28.0, 0]]: crates(p[0], p[1], 15.0, p[2])
	for d2 in [6.0, 16.0, 26.0, 36.0]:
		lamp(-7.0, d2, 8.8, 6.0, 62, Color(1.0, 0.9, 0.72), "q:Prop_Light_Wide")
		lamp(7.0, d2, 8.8, 6.0, 62, Color(1.0, 0.9, 0.72), "q:Prop_Light_Wide")
	fill(0, 22, 6.0, Color(0.55, 0.6, 0.75), 0.35, 30.0)
	pipes(-18, 22, 18, 22, 7.6, 3)
	guard(-6.0, 4.0, 0, [[-6, 4, 2, 90], [-6, 38, 3, 90]])
	guard(6.0, 38.0, 180, [[6, 38, 2, 270], [6, 4, 3, 270]])
	guard(0.0, 22.2, 180, [], "css", 0, 4.0)
	guard(-13.0, 26.0, 90, [[-13, 26, 3, 90], [-13, 14, 2, 90]])
	guard(13.5, 30.0, 220, [], "marksman", 1)
	guard(-3.0, 40.0, 180, [], "heavy", 1)
	guard(9.0, 12.0, 300, [], "css", 2)
	for p in [[-6, 42], [0, 40], [-12, 42], [3, 31], [-3, 18]]: spawn(p[0], p[1])
