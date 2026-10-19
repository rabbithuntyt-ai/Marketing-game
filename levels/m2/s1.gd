extends Sector
## M2 · Sector 2 · OBJECTIVES WING — planners' offices where Castellan sets its business objectives.
## Read: a central block of three glass meeting rooms (fronts face west) splits the floor into a
## west corridor (open, desks) and an east corridor (narrow, filing). A guard walks a ring around
## the block. A camera watches the entry corridor; the breaker at the north-east kills the lights.

func dims() -> Vector3: return Vector3(28, 5, 36)

func build() -> void:
	strategy_wall(-13.3, 30.0, 90, 2.6)
	floor_rect(-14, 0, 14, 36, "", 0.0, Mats.flat(Color(0.22, 0.24, 0.26), 0.85))
	concrete_shell(5.0, 6.0)
	# central meeting rooms
	for k in 3:
		var d0 := 7.0 + k * 8.0
		glass_room(-2.0, d0, 6.0, d0 + 7.0, "w", 0.5)
		piece("ph:dining_table", 2.0, d0 + 3.5, 90)
		for s in [-1.0, 1.0]:
			piece("ph:dining_chair_02", 2.0 + s * 1.2, d0 + 3.5 - 0.9, 0, 0.0, "none")
			piece("ph:dining_chair_02", 2.0 + s * 1.2, d0 + 3.5 + 0.9, 180, 0.0, "none")
		piece("ph:projector_screen", 5.6, d0 + 3.5, 270, 0.0, "none")
		label(["OBJECTIVES", "MISSION", "GOALS"][k], -2.0, d0 + 3.5, 2.6, 270, 44, Color(0.8, 0.9, 1.0))
		partition(6.0, d0, 6.0, d0 + 7.0, 5.0, b.mat("techc", 2.0), 0.3)
	# west desks
	for d in [6.0, 12.0, 18.0, 24.0, 30.0]:
		desk(-10.0, d, 90, "monitor" if int(d) % 12 != 0 else "laptop")
		desk(-6.5, d, 270, "monitor")
	# east filing corridor
	for d2 in [4.0, 10.0, 16.0, 22.0, 28.0]: shelf(12.8, d2, 270, int(d2))
	piece("ph:WetFloorSign_01", 9.0, 14.0, 20)
	intel(0, 2.0, 18.5, 90, 0.78)
	intel(1, -10.0, 30.0, 90, 0.78)
	power_box(13.4, 33.0, 270)
	camera(0.0, 0.6, 4.4, 0, 30, 8.0, 16.0)
	ceiling_lights(-14, 0, 14, 36, 5.0, 2, 4, 6.0, Color(0.95, 0.96, 1.0))
	fill(0, 18, 4.0, Color(0.6, 0.62, 0.7), 0.35, 24.0)
	terminal(-12.5, 34.5, 90)
	guard(-4.0, 5.0, 0, [[-4, 5, 2, 0], [-4, 31, 2, 90], [9, 31, 2, 180], [9, 5, 2, 270]])
	guard(-8.0, 20.0, 90)
	guard(10.5, 24.0, 180, [[10.5, 24, 3, 270], [10.5, 8, 3, 270]])
	guard(0.0, 33.0, 180, [], "heavy", 1)
	guard(-11.0, 12.0, 60, [], "css", 2)
	for p in [[-6, 34], [6, 34], [0, 34], [11, 34], [-11, 2]]: spawn(p[0], p[1])
