extends Sector
## M4 · Sector 1 · PERIMETER YARD — Castellan Insight, Mirabel. 01:30, fog, −2°C.
## Beat: you cut through the fence into the service yard in front of the data centre. The yard is a
## stealth puzzle with three readable lanes:
##   WEST  — staff car park. Unlit (shadow), cars for cover, one guard pacing the rows.
##   APRON — floodlit concrete in the middle; a roof searchlight sweeps it. The fast, risky line.
##   EAST  — generator compound and guard booth. The booth holds the intel; the booth guard watches
##           the apron, so you come at him from behind through the generator row.
## The uplink sits in the dark lee of the building's west wall, next to the staff door.

func dims() -> Vector3: return Vector3(36, 6, 48)
func outdoor() -> bool: return true

func build() -> void:
	strategy_wall(-13.5, 47.3, 180, 3.4)
	floor_rect(-18, 0, 18, 37, "", 0.0, b.mat("ASPHALT"))
	floor_rect(-18, 37, 18, 48, "", 0.0, b.mat("CONCRETE"))
	for k in 4: paint(-17.5, 9.0 + k * 6.5, -6.5, 9.0 + k * 6.5, Color(0.85, 0.85, 0.8))
	paint(-17.5, 37.2, 17.5, 37.2, Color(0.9, 0.2, 0.15), 0.2)
	paint(-17.5, 38.0, 17.5, 38.0, Color(0.9, 0.2, 0.15), 0.2)
	# --- perimeter fence (west, east, and the south line you came through)
	for k in 6:
		piece("ph:modular_chainlink_fence", -18.4, 4.0 + k * 8.0, 90, 0, "box")
		piece("ph:modular_chainlink_fence", 18.4, 4.0 + k * 8.0, 90, 0, "box")
	for x in [-14.0, -6.2, 6.2, 14.0]: piece("ph:modular_chainlink_fence", x, -0.4, 0, 0, "box")
	note("Fence cut: you enter here", 0, 1)
	# --- data centre facade: two storeys, exit door centre
	wall(-18, 48, 18, 48, Vector2(0, 40), "WWWWDWWWW", "WallAstra", "TopAstra")
	wall(-18, 48, 18, 48, Vector2(0, 40), "GGGWWWGGG", "WallAstra", "TopAstra", 5.0)
	label("CASTELLAN INSIGHT", 8, 47.4, 7.4, 180, 200, Color(0.85, 0.82, 1.0))
	for x in [-15.0, -11.0, 9.0, 13.0]: piece("ph:exterior_aircon_unit", x, 47.4, 180, 1.2, "none")
	piece("ph:rollershutter_door", 14.0, 47.7, 180, 0, "box")
	paint(11.5, 44, 16.5, 44, Color(0.95, 0.75, 0.15), 0.25)
	# --- WEST lane: staff car park in shadow
	dark(-18, 6, -6, 40)
	for row in [[-14.5, 12.0, 0.0], [-9.5, 12.0, 0.0], [-14.5, 18.5, 180.0], [-9.5, 25.0, 175.0], [-14.5, 31.5, 0.0]]:
		cover("ph:covered_car", row[0], row[1], row[2])
	for d in [15.5, 28.2]: piece("ph:concrete_road_barrier", -12.0, d, 90)
	piece("ph:street_lamp_01", -6.5, 8.0, 90)            # dead lamp: no light, sells the shadow
	note("Car park: unlit. Guards only see you up close.", -12, 5)
	# --- APRON: floodlit, searchlight on the roof
	for p in [[-2.0, 18.0], [4.5, 30.0]]:
		piece("ph:street_lamp_01", p[0], p[1], 0)
		lamp(p[0], p[1] + 0.3, 3.8, 9.0, 70.0, Color(1.0, 0.92, 0.78), "")
	for x in [-3.0, 0.0, 3.0]: cover("ph:concrete_road_barrier_02", x, 8.0, 0)
	cover("ph:wooden_military_crate", 1.5, 24.0, 20)
	piece("ph:hand_truck", 2.6, 24.8, 200)
	piece("ph:water_manhole_cover", 0.0, 34.0, 0, 0.0, "none")
	camera(3.0, 46.6, 9.5, 180, 38, 9.0, 30.0, true)
	note("Roof searchlight sweeps the apron every 9 s", 3, 44)
	# --- EAST: generator compound + guard booth
	for d in [20.0, 24.0, 28.0]: cover("ph:portable_generator", 15.8, d, 270)
	cover("ph:utility_box_02", 17.2, 32.0, 270)
	cover("ph:utility_box_01", 17.2, 34.0, 270)
	cover("ph:small_lpg_tank", 13.5, 33.0, 0)
	cover("ph:wooden_military_crate", 10.5, 36.0, 90)
	pipes(17.6, 18, 17.6, 36, 0.35, 2)
	_booth(12.5, 12.0)
	dark(9, 18, 18, 38)
	# --- building front
	cover("ph:concrete_road_barrier", -4.0, 40.5, 0)
	cover("ph:concrete_road_barrier", 4.0, 40.5, 0)
	piece("ph:fire_hydrant", -6.5, 44.0, 0)
	piece("ph:metal_trash_can", -8.0, 46.8, 180)
	dark(-18, 40, -5, 48)
	lamp(-1.0, 46.6, 4.4, 5.0, 60, Color(1.0, 0.85, 0.65), "q:Prop_Light_Small")
	lamp(7.0, 46.6, 4.4, 5.0, 60, Color(1.0, 0.85, 0.65), "q:Prop_Light_Small")
	# --- gameplay
	terminal(-9.5, 45.6, 0)
	intel(0, 11.4, 12.9, 270, 0.79)
	guard(12.5, 11.2, 270)                                            # booth guard watches the apron
	guard(4.0, 16.0, 0, [[4, 16, 3, 270], [4, 32, 4, 0], [-4, 32, 2, 270], [-4, 16, 3, 180]])
	guard(-12.0, 9.0, 0, [[-12, 9, 4, 90], [-12, 34, 4, 90]])
	guard(-11.0, 42.0, 90, [[-11, 42, 3, 180], [11, 42, 3, 180]], "css", 1)
	guard(15.0, 30.0, 220, [], "css", 2)                              # veteran: generator watch
	for p in [[-6, 44], [6, 44], [0, 42], [-12, 44], [12, 43]]: spawn(p[0], p[1])
	fill(0, 24, 9.0, Color(0.55, 0.62, 0.8), 0.25, 40.0)

func _booth(x: float, d: float) -> void:
	var m := b.mat("tech", 2.0)
	floor_rect(x - 2, d - 2, x + 2, d + 2, "q:Platform_Simple", 0.02)
	partition(x - 2, d - 2, x + 2, d - 2, 2.6, m, 0.15)
	partition(x - 2, d - 2, x - 2, d - 0.6, 2.6, m, 0.15)
	partition(x - 2, d + 1.4, x - 2, d + 2, 2.6, m, 0.15)
	box(Vector3(0.15, 0.9, 2.0), x - 2, d + 0.4, 0.45, m)
	box(Vector3(0.15, 0.5, 2.0), x - 2, d + 0.4, 2.35, m)
	box(Vector3(0.04, 1.2, 2.0), x - 2, d + 0.4, 1.5, Mats.glass(), false)
	partition(x - 2, d + 2, x + 2, d + 2, 2.6, m, 0.15)
	partition(x + 2, d - 2, x + 2, d - 0.5, 2.6, m, 0.15)
	partition(x + 2, d + 1.0, x + 2, d + 2, 2.6, m, 0.15)
	box(Vector3(4.3, 0.15, 4.3), x, d, 2.68, b.mat("metal", 2.0))
	piece("ph:metal_office_desk", x - 1.1, d + 0.6, 270)
	piece("ph:Television_01", x - 1.3, d + 1.4, 270, 0.78, "none")
	piece("ph:metal_stool_01", x - 0.2, d + 0.2, 0)
	label("SECURITY", x, d - 2.1, 2.3, 180, 60, Color(1.0, 0.85, 0.4))
	lamp(x, d, 2.55, 2.0, 80, Color(1.0, 0.9, 0.7), "")
