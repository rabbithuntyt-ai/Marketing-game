extends Sector
## M8 · Sector 3 · RESEARCH FLOOR — the board's own intelligence unit. Server rows on the west,
## reading tables in the middle, sound-proofed call booths on the east; the analysts' terminal at
## the north end.

func dims() -> Vector3: return Vector3(36, 6, 40)

func build() -> void:
	city_view(160.0)
	strategy_wall(17.3, 34.0, 270, 2.8)
	floor_rect(-18, 0, 18, 40, "q:Platform_DarkPlates")
	ceiling(-18, 0, 18, 40, 5.5)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallAstra", "TopCables")
	wall(-18, 40, 18, 40, Vector2(0, 30), "WWWWDWWWW", "WallAstra", "TopCables")
	wall(-18, 0, -18, 40, Vector2(0, 20), "", "WallAstra", "TopCables")
	wall(18, 0, 18, 40, Vector2(0, 20), "GGGGGGGGGG", "WallAstra", "TopWindow")
	for x in [-15.0, -11.5, -8.0]: server_row(x, 18.0, 0, 16)
	for d in [8.0, 16.0, 24.0, 32.0]:
		box(Vector3(4.0, 0.08, 1.6), 0.0, d, 0.76, Mats.flat(Color(0.35, 0.24, 0.15), 0.5))
		box(Vector3(3.6, 0.72, 1.2), 0.0, d, 0.36, Mats.flat(Color(0.3, 0.2, 0.12), 0.6))
		piece("ph:desk_lamp_arm_01", -1.2, d, 160, 0.8, "none")
		piece("ph:office_notepads", 0.8, d, 30, 0.8, "none")
		cover_pt(0, d - 1.3); cover_pt(0, d + 1.3)
	for k in 4:
		var d0 := 4.0 + k * 8.0
		box(Vector3(3.0, 2.6, 0.15), 15.5, d0, 1.3, Mats.flat(Color(0.2, 0.22, 0.26), 0.6))
		box(Vector3(0.06, 2.4, 3.0), 14.0, d0 + 2.5, 1.2, Mats.glass(), true)
		piece("ph:metal_stool_01", 16.0, d0 + 2.0, 270)
		piece("ph:classic_laptop", 16.6, d0 + 2.0, 270, 0.0, "none")
	desk(-4.0, 37.0, 180, "monitor"); desk(4.0, 37.0, 180, "monitor")
	ceiling_lights(-6, 0, 18, 40, 5.5, 2, 4, 5.5, Color(0.9, 0.93, 1.0))
	for d2 in [6.0, 18.0, 30.0]: lamp(-11.5, d2, 5.3, 4.0, 55, Color(0.6, 0.8, 1.0), "")
	terminal(0.0, 38.4, 180)
	guard(-9.8, 6.0, 0, [[-9.8, 6, 2, 0], [-9.8, 30, 2, 180]])
	guard(-13.3, 30.0, 180, [[-13.3, 30, 2, 180], [-13.3, 6, 2, 0]])
	guard(4.0, 20.0, 180, [[4, 20, 2, 270], [4, 34, 2, 180]])
	guard(12.0, 36.0, 200, [], "heavy", 0)
	guard(-3.0, 35.0, 180, [], "css", 1)
	guard(8.0, 10.0, 0, [], "css", 2)
	for p in [[-6, 38], [6, 38], [-16, 36], [12, 38], [0, 30]]: spawn(p[0], p[1])
