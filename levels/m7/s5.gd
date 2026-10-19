extends Sector
## M7 · Sector 6 · SERVICE CENTRE — Castellan's customer service floor ("the moments of truth").
## Read: hexagonal agent pods in a honeycomb across the floor; a raised escalations deck along the
## west wall (1 m, ramps at both ends) for supervisors; the live queue board on the north wall with
## the routing consoles in front of it for Marr's service calls.

func dims() -> Vector3: return Vector3(36, 6, 40)

func build() -> void:
	city_view(150.0)
	strategy_wall(17.3, 6.0, 270, 2.8)
	floor_rect(-18, 0, 18, 40, "", 0.0, Mats.flat(Color(0.14, 0.17, 0.2), 0.8))
	ceiling(-18, 0, 18, 40, 5.5)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallAstra", "TopSimple")
	wall(-18, 40, 18, 40, Vector2(0, 30), "WWWWDWWWW", "WallAstra", "TopSimple")
	wall(-18, 0, -18, 40, Vector2(0, 20), "", "WallAstra", "TopSimple")
	wall(18, 0, 18, 40, Vector2(0, 20), "GGGGGGGGGG", "WallAstra", "TopWindow")
	# hex pods (6 desks around a centre column)
	for c in [[-3.0, 9.0], [7.0, 9.0], [2.0, 17.5], [12.0, 17.5], [-3.0, 26.0], [7.0, 26.0]]:
		box(Vector3(0.5, 1.4, 0.5), c[0], c[1], 0.7, Mats.flat(Color(0.3, 0.55, 0.8), 0.6))
		box(Vector3(0.52, 0.1, 0.52), c[0], c[1], 1.45, Mats.glow(Color(0.4, 0.8, 1.0), 3.0), false)
		for k in 6:
			var a := TAU * k / 6.0
			desk(c[0] + sin(a) * 1.8, c[1] + cos(a) * 1.8, rad_to_deg(a) + 180.0, "monitor", false)
		cover_pt(c[0] + 3.0, c[1]); cover_pt(c[0] - 3.0, c[1])
	# escalations deck west
	box(Vector3(6.0, 1.0, 26.0), -15.0, 18.0, 0.5, b.mat("metal", 2.0, Color(0.45, 0.47, 0.5)))
	box(Vector3(0.1, 1.0, 26.0), -12.0, 18.0, 1.5, Mats.glass(), true)
	ramp(-15.0, 1.0, 0.0, 1.0, 4.0, 2.4)
	ramp(-15.0, 35.0, 180.0, 1.0, 4.0, 2.4)
	for d in [10.0, 18.0, 26.0]: piece("ph:metal_office_desk", -15.5, d, 90, 1.0)
	label("ESCALATIONS", -12.05, 18.0, 2.8, 270, 52, Color(1.0, 0.5, 0.35))
	intel(0, -15.4, 18.0, 90, 1.79)
	# queue board + consoles
	call_panels([0, 39.4, 180], [[-6.0, 34.5, 180], [-2.0, 34.5, 180], [2.0, 34.5, 180], [6.0, 34.5, 180]])
	for k2 in 4:
		box(Vector3(2.2, 0.5, 0.04), 10.0 + (k2 % 2) * 2.5, 39.8, 2.4 + int(k2 / 2) * 0.7, Mats.glow([Color(0.4, 1.0, 0.6), Color(1.0, 0.8, 0.3), Color(1.0, 0.4, 0.3), Color(0.4, 0.8, 1.0)][k2], 2.0), false)
	label("QUEUE · 214 WAITING · AVG 18:40", 11.2, 39.75, 4.2, 180, 40, Color(1.0, 0.6, 0.4), "IBMPlexMono-Medium")
	ceiling_lights(-10, 0, 18, 40, 5.5, 3, 4, 5.5, Color(0.92, 0.95, 1.0))
	guard(-15.0, 6.0, 0, [[-15, 6, 2, 90], [-15, 30, 2, 90]], "css", 0, 1.0)
	guard(2.0, 4.0, 0, [[2, 4, 2, 0], [2, 31, 2, 180]])
	guard(14.0, 26.0, 270)
	guard(-15.5, 22.0, 80, [], "marksman", 1, 1.0)
	guard(10.0, 32.0, 200, [], "heavy", 1)
	guard(-6.0, 18.0, 90, [], "css", 2)
	for p in [[-8, 38], [8, 37], [14, 36], [-14, 38], [0, 31]]: spawn(p[0], p[1])
