extends Sector
## M4 · Sector 7 · ANALYTICS FLOOR — the CRM / big-data floor and the mole's last workspace.
## Read: server rows on both flanks (aisles = flanking routes), a sunken analysis pit in the middle
## where the evidence board goes up, and two glass analyst offices at the far end, one per side,
## each with a document. Clear the floor, then pin the evidence to the board to unmask the mole.

func dims() -> Vector3: return Vector3(36, 7, 40)

func build() -> void:
	strategy_wall(17.3, 6.0, 270, 3.0)
	floor_rect(-18, 0, 18, 40, "q:Platform_DarkPlates")
	ceiling(-18, 0, 18, 40, 7.0)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallAstra", "TopCables")
	wall(-18, 40, 18, 40, Vector2(0, 35), "WWWWDWWWW", "WallAstra", "TopCables")
	wall(-18, 0, -18, 40, Vector2(0, 20), "", "WallAstra", "TopCables")
	wall(18, 0, 18, 40, Vector2(0, 20), "", "WallAstra", "TopCables")
	for s in [0.0, 40.0]: wall(-18, s, 18, s, Vector2(0, 20), "", "WallAstra", "", 5.0)
	wall(-18, 0, -18, 40, Vector2(0, 20), "", "WallAstra", "", 5.0)
	wall(18, 0, 18, 40, Vector2(0, 20), "", "WallAstra", "", 5.0)
	# server flanks
	for x in [-15.0, -11.5, 11.5, 15.0]: server_row(x, 15.0, 0, 16)
	pipes(-13.2, 6, -13.2, 24, 6.0, 3)
	pipes(13.2, 6, 13.2, 24, 6.0, 3)
	note("Analysis pit: low walls, gap in the middle", 0, 18)
	# analysis pit: sunken by framing (rails + low walls) with desks around a centre
	for s in [-1.0, 1.0]:
		box(Vector3(0.3, 0.9, 10.0), s * 6.0, 24.0, 0.45, b.mat("gunmetal", 1.0))
		box(Vector3(4.0, 0.9, 0.3), s * 4.0, 19.0, 0.45, b.mat("gunmetal", 1.0))
	for p in [[-4.0, 21.0, 0.0], [-1.3, 21.0, 0.0], [1.3, 21.0, 0.0], [4.0, 21.0, 0.0]]: desk(p[0], p[1], p[2], "monitor")
	glow_strip(0, 19.0, 0.05, 12.0, 90.0, accent, 3.0)
	r.set_meta("board_pos", P(0, 27))
	r.set_meta("board_rot", PI)
	note("Evidence board goes up here", 0, 27)
	ceiling_lights(-8, 18, 8, 30, 7.0, 2, 2, 7.5, Color(0.9, 0.93, 1.0))
	# far offices
	glass_room(-17.6, 32.0, -8.0, 39.6, "e", 0.4)
	glass_room(8.0, 32.0, 17.6, 39.6, "w", 0.4)
	desk(-13.0, 37.5, 180, "monitor")
	desk(13.0, 37.5, 180, "laptop")
	piece("ph:drawer_cabinet", -17.0, 33.0, 90)
	piece("ph:modern_wooden_cabinet", 17.0, 35.0, 270)
	piece("ph:mid_century_lounge_chair", 10.0, 34.0, 120)
	intel(0, -13.0, 37.6, 180, 0.79)
	intel(1, 13.0, 37.6, 180, 0.79)
	label("A. NADEAU · ANALYTICS LEAD", -12.8, 32.0, 2.6, 180, 36, Color(0.9, 0.9, 1.0))
	label("CRM · CUSTOMER 360", 12.8, 32.0, 2.6, 180, 36, Color(0.9, 0.9, 1.0))
	fill(-13.0, 36.0, 2.6, Color(1.0, 0.85, 0.65), 0.8, 7.0)
	fill(13.0, 36.0, 2.6, Color(1.0, 0.85, 0.65), 0.8, 7.0)
	for p in [[-5.0, 8.0, 0], [5.0, 8.0, 1], [-5.0, 33.0, 1], [5.0, 33.0, 0]]: crates(p[0], p[1], 10.0, p[2])
	for d in [10.0, 22.0]:
		lamp(-13.2, d, 6.8, 4.0, 55, Color(0.6, 0.8, 1.0), "")
		lamp(13.2, d, 6.8, 4.0, 55, Color(0.6, 0.8, 1.0), "")
	fill(0, 12, 5.0, Color(0.5, 0.6, 0.85), 0.4, 26.0)
	terminal(0.0, 38.5, 180)
	guard(-13.2, 6.0, 0, [[-13.2, 6, 2, 90], [-13.2, 26, 3, 90]])
	guard(13.2, 26.0, 180, [[13.2, 26, 3, 270], [13.2, 6, 2, 270]])
	guard(0.0, 23.0, 180)
	guard(-13.0, 35.0, 90, [], "css", 1)
	guard(13.0, 35.0, 270, [], "heavy", 1)
	guard(0.0, 10.0, 0, [], "css", 2)
	for p in [[-6, 36], [6, 36], [0, 34], [-9, 28], [9, 28], [0, 31]]: spawn(p[0], p[1])
