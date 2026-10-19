extends Sector
## M1 · Sector 7 · DATA CAGE — the centre's server cage where order and customer data lives.
## Read: a chain-link cage encloses three server rows in the middle (aisles are tight, short sight
## lines). Chillers line the west wall. A raised platform on the east wall (2 m, stairs at the south
## end) overlooks the cage; one intel sits up there, the other on a cart in the north aisle. The
## breaker on the east wall drops the lights.

func dims() -> Vector3: return Vector3(36, 7, 40)

func build() -> void:
	strategy_wall(-17.3, 30.0, 90, 3.0)
	floor_rect(-18, 0, 18, 40, "q:Platform_DarkPlates")
	ceiling(-18, 0, 18, 40, 7.0)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallBand", "TopCables")
	wall(-18, 40, 18, 40, Vector2(0, 35), "WWWWDWWWW", "WallBand", "TopCables")
	wall(-18, 0, -18, 40, Vector2(0, 20), "", "WallBand", "TopCables")
	wall(18, 0, 18, 40, Vector2(0, 20), "", "WallBand", "TopCables")
	for s in [0.0, 40.0]: wall(-18, s, 18, s, Vector2(0, 20), "", "WallBand", "", 5.0)
	wall(-18, 0, -18, 40, Vector2(0, 20), "", "WallBand", "", 5.0)
	wall(18, 0, 18, 40, Vector2(0, 20), "", "WallBand", "", 5.0)
	# cage fence (open at the south-centre and north-centre gates)
	for k in 3:
		piece("ph:modular_chainlink_fence", -10.0, 10.0 + k * 8.0 + 2.0, 90, 0, "box")
		piece("ph:modular_chainlink_fence", 7.5, 10.0 + k * 8.0 + 2.0, 90, 0, "box")
	for x in [-6.5, 4.0]:
		piece("ph:modular_chainlink_fence", x, 8.0, 0, 0, "box")
		piece("ph:modular_chainlink_fence", x, 34.0, 0, 0, "box")
	for x in [-6.0, -1.5, 3.0]: server_row(x, 20.0, 0, 18)
	label("CAGE A · ORDER DATA", -1.5, 8.0, 3.0, 180, 54, Color(0.7, 0.9, 1.0))
	note("Cage gates: south + north centre", -1, 7)
	# chillers west
	for d in [8.0, 20.0, 32.0]: chiller(-15.5, d, 0, 6.0)
	# east platform
	catwalk(12, 14, 18, 30, 2.0, "w")
	stairs(15.0, 10.0, 0.0, false, true)
	desk(16.0, 22.0, 270, "monitor")
	intel(0, 16.2, 22.0, 270, 2.79)
	intel(1, -1.5, 31.0, 0, 1.0)
	piece("ph:industrial_storage_cart", -1.5, 31.0, 0)
	power_box(17.6, 6.0, 270)
	pipes(-18, 4, 18, 4, 6.2, 3)
	pipes(-18, 36, 18, 36, 6.2, 3)
	for p in [[12.0, 36.0, 0], [-12.0, 37.0, 1], [11.0, 6.0, 2]]: crates(p[0], p[1], 10.0, p[2])
	for d2 in [6.0, 14.0, 22.0, 30.0, 38.0]: lamp(-1.5, d2, 6.8, 4.5, 58, Color(0.65, 0.82, 1.0), "")
	fill(0, 20, 5.0, Color(0.45, 0.55, 0.85), 0.4, 26.0)
	terminal(13.0, 38.5, 180)
	guard(-3.7, 10.0, 0, [[-3.7, 10, 2, 0], [-3.7, 30, 3, 180]])
	guard(0.7, 30.0, 180, [[0.7, 30, 2, 180], [0.7, 10, 3, 0]])
	guard(15.5, 20.0, 270, [], "marksman", 0, 2.0)
	guard(-12.5, 14.0, 0, [[-12.5, 14, 2, 90], [-12.5, 34, 2, 90]])
	guard(10.0, 32.0, 200, [], "heavy", 1)
	guard(-9.0, 38.0, 160, [], "css", 2)
	for p in [[-6, 38], [6, 38], [0, 37], [-12, 2], [12, 34], [9, 20]]: spawn(p[0], p[1])
