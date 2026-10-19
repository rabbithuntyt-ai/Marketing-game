extends Sector
## M3 · Sector 2 · CONTAINER STACKS — the yard. A maze of stacked containers under two gantry cranes.
## Read: container blocks on a grid make lanes north-south and east-west; some blocks are one high
## (you can see over), some two (you can't). Two gantry cranes straddle the yard at 14 m and 38 m,
## each with a walkway at 9 m and a marksman on it. Stairs at the west edge climb onto the stacks
## onto a one-high stack: an overlook across the yard.

func dims() -> Vector3: return Vector3(44, 12, 52)
func outdoor() -> bool: return true

func build() -> void:
	strategy_wall(21.3, 6.0, 270, 2.6)
	floor_rect(-22, 0, 22, 52, "", 0.0, b.mat("ASPHALT"))
	var grid := [[-15.0, 6.0, 2], [-7.0, 6.0, 1], [7.0, 6.0, 2], [15.0, 6.0, 1],
		[-15.0, 20.0, 1], [-7.0, 22.0, 2], [7.0, 20.0, 1], [15.0, 22.0, 2],
		[-15.0, 32.0, 2], [-7.0, 30.0, 1], [7.0, 32.0, 2], [15.0, 30.0, 1],
		[-15.0, 45.0, 1], [-7.0, 45.0, 2], [7.0, 45.0, 1], [15.0, 45.0, 2]]
	# blocks vary: pairs along d, cross-laid pairs (yaw 90), single boxes and an offset step
	var turned := [[7.0, 6.0], [-15.0, 20.0], [15.0, 30.0], [-7.0, 45.0]]
	var single := [[-7.0, 30.0], [15.0, 45.0]]
	for g in grid:
		var key := [g[0], g[1]]
		if key in turned:
			containers(g[0], g[1] - 1.6, 90.0, g[2], int(g[0] + g[1]) % 3)
			containers(g[0] + 0.8, g[1] + 1.6, 90.0 + 3.0, maxi(1, g[2] - 1), int(g[0] + g[1] + 1) % 3)
		elif key in single:
			containers(g[0], g[1], 8.0, g[2], int(g[0]) % 3)
			crates(g[0] + 3.0, g[1] - 2.0, 20.0, 1)
		else:
			containers(g[0] - 1.6, g[1], 0.0, g[2], int(g[0] + g[1]) % 3)
			containers(g[0] + 1.6, g[1] + (1.2 if int(g[0]) % 2 == 0 else -0.8), 0.0, g[2] if int(g[1]) % 4 != 0 else 1, int(g[0] + g[1] + 1) % 3)
	for gd in [14.0, 38.0]: _gantry(gd)
	stairs(-20.0, 30.0, 180.0, true)
	box(Vector3(4.2, 0.2, 2.4), -19.9, 23.0, 3.0, b.mat("grate", 2.0))
	note("Stairs onto the low stack: overlook", -20, 31)
	for p in [[0.0, 26.0, 0], [-11.0, 38.0, 1], [11.0, 13.0, 2], [0.0, 49.0, 1]]: crates(p[0], p[1], 10.0, p[2])
	piece("tps:prop_barrelcart", 3.0, 10.0, 30)
	piece("ph:hand_truck", -3.0, 38.0, 0)
	intel(0, 0.0, 26.0, 0, 1.0)
	for p in [[-11.0, 2.0], [11.0, 26.0], [-11.0, 50.0]]:
		piece("ph:street_lamp_01", p[0], p[1], 0)
		lamp(p[0], p[1] + 0.3, 7.0, 9.0, 70, Color(1.0, 0.85, 0.6), "")
	fill(0, 26, 11.0, Color(0.45, 0.55, 0.7), 0.3, 46.0)
	dark(-22, 34, -3, 52)
	terminal(-3.0, 50.5, 180)
	guard(0.0, 4.0, 0, [[0, 4, 2, 90], [0, 48, 3, 270]])
	guard(-11.0, 13.0, 90, [[-11, 13, 2, 90], [11, 13, 2, 270]])
	guard(11.0, 38.0, 270, [[11, 38, 2, 270], [-11, 38, 2, 90]])
	guard(-6.0, 14.0, 180, [], "marksman", 0, 9.15)
	guard(6.0, 38.0, 180, [], "marksman", 1, 9.15)
	guard(19.5, 30.0, 270, [], "heavy", 1)
	guard(-19.0, 44.0, 90, [], "css", 2)
	for p in [[-6, 50], [6, 50], [0, 47], [-19, 50], [19, 50]]: spawn(p[0], p[1])

func _gantry(d: float) -> void:
	var red := Mats.flat(Color(0.75, 0.15, 0.1), 0.5, 0.4)
	for x in [-20.5, 20.5]:
		for dd in [-2.0, 2.0]: box(Vector3(0.8, 11.0, 0.8), x, d + dd, 5.5, red)
		box(Vector3(1.2, 0.6, 5.0), x, d, 0.3, red)
	box(Vector3(42.0, 1.2, 1.2), 0, d - 2.0, 10.4, red, false)
	box(Vector3(42.0, 1.2, 1.2), 0, d + 2.0, 10.4, red, false)
	catwalk(-20, d - 0.9, 20, d + 0.9, 9.0, "ns")
	box(Vector3(3.0, 2.6, 3.0), 4.0, d, 11.2, Mats.flat(Color(0.85, 0.85, 0.8), 0.5), false)
	b.box(geo, Vector3(0.6, 0.9, 0.05), P(4.0, d - 1.52, 11.4), Mats.glass(), false)
	lamp(0, d, 10.0, 7.0, 70, Color(1.0, 0.95, 0.85), "")
	label("GC-%d" % (1 if d < 20 else 2), 20.5, d - 2.5, 8.0, 180, 120, Color(0.95, 0.95, 0.95))
