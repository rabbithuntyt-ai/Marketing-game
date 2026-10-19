extends Sector
## M5 · Sector 2 · SEARCH GALLERY — an electronics department laid out for "information search":
## display tables in a grid, TV bays on the west wall, a compare bar on the east.
## The courier walks up the west aisle, crosses at the TV bays and stops at the compare bar.
## Read: tables are waist-high (you can see over them, so can he) — hide behind the TV bays and the
## tall review stands.

func dims() -> Vector3: return Vector3(32, 7, 40)

func build() -> void:
	strategy_wall(15.3, 6.0, 270, 3.0)
	floor_rect(-16, 0, 16, 40, "", 0.0, Mats.flat(Color(0.86, 0.86, 0.88), 0.4))
	ceiling(-16, 0, 16, 40, 7.0)
	wall(-16, 0, 16, 0, Vector2(0, 5), "WWWWDWWW", "WallAstra", "TopPlastic")
	wall(-16, 40, 16, 40, Vector2(0, 30), "WWWWDWWW", "WallAstra", "TopPlastic")
	wall(-16, 0, -16, 40, Vector2(0, 20), "", "WallAstra", "TopPlastic")
	wall(16, 0, 16, 40, Vector2(0, 20), "", "WallAstra", "TopPlastic")
	for s in [0.0, 40.0]: wall(-16, s, 16, s, Vector2(0, 20), "SSSSSSSS", "WallAstra", "", 5.0)
	# display tables grid
	for x in [-2.5, 3.0, 8.5]:
		for d in [8.0, 14.0, 20.0, 32.0]:
			box(Vector3(3.0, 0.9, 1.6), x, d, 0.45, Mats.flat(Color(0.95, 0.95, 0.95), 0.3))
			for k in 3: piece("ph:classic_laptop", x - 1.0 + k * 1.0, d, 180, 0.9, "none")
			cover_pt(x, d - 1.3); cover_pt(x, d + 1.3)
	# tall review stands (break sight lines)
	for p in [[0.2, 11.0], [5.7, 17.0], [0.2, 23.5], [5.7, 29.0], [11.5, 22.0]]:
		box(Vector3(0.4, 2.4, 1.6), p[0], p[1], 1.2, Mats.flat(Color(0.12, 0.13, 0.15), 0.5))
		box(Vector3(0.05, 1.6, 1.4), p[0] - 0.22, p[1], 1.4, Mats.glow(Color(0.4, 0.7, 1.0), 0.9), false)
		cover_pt(p[0] + 0.8, p[1]); cover_pt(p[0] - 0.8, p[1])
	# TV bays west
	for d2 in [6.0, 14.0, 22.0, 30.0]:
		partition(-16, d2 - 3.0, -11, d2 - 3.0, 2.8)
		for k2 in 3: piece("ph:Television_01", -15.4, d2 - 1.6 + k2 * 1.3, 90, 1.0, "none")
		box(Vector3(0.6, 1.0, 4.0), -15.4, d2, 0.5, b.mat("gunmetal", 1.0))
	label("COMPARE · REVIEW · DECIDE", 13.5, 36.4, 3.0, 270, 44, Color(0.4, 0.75, 1.0))
	box(Vector3(1.2, 1.05, 8.0), 13.5, 32.0, 0.52, Mats.flat(Color(0.12, 0.14, 0.18), 0.4))
	for k3 in 4: piece("ph:metal_stool_01", 12.2, 29.0 + k3 * 2.0, 90)
	intel(0, 13.5, 33.0, 270, 1.07)
	anchor("path", [P(-8, 4), P(-8, 26.5), P(0, 26.5), P(0, 36.5)])
	note("Courier route", -8, 15)
	ceiling_lights(-16, 0, 16, 40, 7.0, 3, 4, 6.0, Color(0.95, 0.97, 1.0))
	terminal(-12.0, 38.0, 180)
	guard(13.5, 26.0, 270)
	guard(-11.0, 36.0, 180, [[-11, 36, 3, 180], [-11, 4, 3, 0]])
	guard(3.0, 38.0, 180, [], "css", 1)
	guard(14.0, 6.0, 300, [], "css", 2)
	for p in [[-6, 38], [6, 38], [0, 38], [12, 38], [-12, 2]]: spawn(p[0], p[1])
