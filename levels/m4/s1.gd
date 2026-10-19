extends Sector
## M4 · Sector 2 · COOLING PLANT — the chiller hall under the server floors. Loud fans.
## Read: two rows of chillers split the hall into three lanes. A catwalk runs the west wall (high
## route, one guard on it). A crawl duct runs the east side behind the chillers (hidden route, dark).
## The control desk at the far end has a guard watching the centre lane. The breaker on the west
## wall by the entry kills the lights (emergency red) if you'd rather work in the dark.
## Intel: one on the catwalk desk, one in the maintenance office (glass room, east, far end).

func dims() -> Vector3: return Vector3(36, 8, 40)

func build() -> void:
	strategy_wall(17.3, 12.0, 270, 3.2)
	floor_rect(-18, 0, 18, 40, "q:Platform_DarkPlates")
	ceiling(-18, 0, 18, 40, 8.0)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallBand", "TopCables")
	wall(-18, 40, 18, 40, Vector2(0, 35), "WWWWDWWWW", "WallBand", "TopCables")
	wall(-18, 0, -18, 40, Vector2(0, 20), "WWWWWWWWWW", "WallBand", "TopCables")
	wall(18, 0, 18, 40, Vector2(0, 20), "WWWWWWWWWW", "WallBand", "TopCables")
	for s in [-1.0, 1.0]:
		wall(-18, 0 if s < 0 else 40, 18, 0 if s < 0 else 40, Vector2(0, 20), "", "WallBand", "", 5.0)
	wall(-18, 0, -18, 40, Vector2(0, 20), "", "WallBand", "", 5.0)
	wall(18, 0, 18, 40, Vector2(0, 20), "", "WallBand", "", 5.0)
	# chillers: two rows, three lanes
	for d in [11.0, 25.0]:
		chiller(-7.0, d, 0, 8.0)
		chiller(5.5, d, 0, 8.0)
	pipes(-7, 4, -7, 34, 6.2, 3)
	pipes(5.5, 4, 5.5, 34, 6.2, 3)
	pipes(-16, 20, 16, 20, 7.0, 2)
	for p in [[-11.0, 18.0], [9.5, 18.0], [-1.5, 22.0]]: pillar(p[0], p[1])
	# west catwalk (high route) with stairs at both ends
	catwalk(-18, 6, -13, 34, 3.0, "e")
	stairs(-15.5, 0.1, 0.0, true)
	stairs(-15.5, 39.9, 180.0, true)
	piece("ph:metal_office_desk", -16.6, 20.0, 90, 3.0)
	intel(0, -16.4, 20.0, 90, 3.78)
	piece("ph:ladder_sectioned_01", -13.5, 12.0, 90, 3.0, "none")
	note("Catwalk: high route, one guard", -15, 8)
	# east crawl duct behind the chillers (hidden route)
	duct(15.6, 8, 15.6, 32, 1.8)
	piece("q:Prop_Vent_Big", 15.6, 7.6, 0, 1.2, "none")
	note("Crawl duct: crouch through, unseen", 13, 10)
	# maintenance office (glass), far east
	glass_room(8.5, 33, 17.5, 39.5, "w", 0.4)
	desk(14.0, 36.5, 180, "monitor")
	intel(1, 14.0, 37.0, 180, 0.78)
	piece("ph:metal_tool_chest", 16.8, 34.2, 270)
	piece("ph:tool_cart", 10.0, 38.5, 0)
	# control desk (far centre) with the overseer
	desk(-1.0, 34.5, 180, "monitor", false)
	desk(1.2, 34.5, 180, "monitor", false)
	piece("ph:metal_stool_02", 0.0, 33.4, 0)
	label("COOLING · CH-1 TO CH-4", 0, 39.8, 3.6, 180, 72, Color(0.6, 0.85, 1.0))
	for p in [[-12.0, 30.0, 0], [11.5, 8.0, 1], [-3.5, 3.5, 0]]: crates(p[0], p[1], 15.0 * p[2], p[2])
	piece("ph:korean_fire_extinguisher_01", -17.5, 3.0, 90)
	piece("ph:propane_tank", 11.0, 30.5, 0)
	piece("ph:industrial_storage_cart", -1.0, 9.0, 90)
	power_box(-17.6, 8.5, 90)
	ceiling_lights(-18, 0, 18, 40, 8.0, 3, 4, 8.0, Color(0.82, 0.9, 1.0))
	fill(0, 20, 6.0, Color(0.5, 0.6, 0.8), 0.5, 30.0)
	for d2 in [11.0, 25.0]:
		fill(-7.0, d2, 3.2, Color(0.3, 1.0, 0.6), 0.5, 7.0)
		fill(5.5, d2, 3.2, Color(0.3, 1.0, 0.6), 0.5, 7.0)
	terminal(-6.0, 38.6, 0)
	guard(-15.5, 8.0, 0, [[-15.5, 8, 3, 90], [-15.5, 32, 4, 90]], "css", 0, 3.0)  # catwalk
	guard(0.0, 33.0, 180)                                                         # overseer
	guard(11.0, 6.0, 0, [[11, 6, 3, 270], [11, 33, 3, 270]])                      # east lane
	guard(-1.5, 14.0, 0, [[-1.5, 14, 2, 90], [-1.5, 28, 2, 270]], "css", 1)        # centre lane
	guard(-10.5, 18.0, 90, [], "css", 2)
	for p in [[-6, 36], [6, 36], [-12, 36], [12, 30], [0, 30]]: spawn(p[0], p[1])
