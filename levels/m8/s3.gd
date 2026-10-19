extends Sector
## M8 · Sector 4 · TARGETING FLOOR — rows of operators facing a red wall of target towns.
## Read: the lower floor is operator rows (desks in lines facing north, low cover); an upper deck
## at +1.5 m across the back third with a glass balustrade and ramps at each side; the red target
## wall lists every town Meridian is buying. Defenders hold the deck.

func dims() -> Vector3: return Vector3(36, 7, 40)

func build() -> void:
	city_view(165.0)
	strategy_wall(-17.3, 6.0, 90, 3.0)
	floor_rect(-18, 0, 18, 40, "", 0.0, Mats.flat(Color(0.12, 0.12, 0.14), 0.8))
	ceiling(-18, 0, 18, 40, 7.0)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallAstra", "TopAstra")
	wall(-18, 40, 18, 40, Vector2(0, 30), "WWWWDWWWW", "WallAstra", "TopAstra")
	wall(-18, 0, -18, 40, Vector2(0, 20), "", "WallAstra", "TopAstra")
	wall(18, 0, 18, 40, Vector2(0, 20), "", "WallAstra", "TopAstra")
	for s in [0.0, 40.0]: wall(-18, s, 18, s, Vector2(0, 20), "", "WallAstra", "", 5.0)
	# operator rows
	for d in [8.0, 13.0, 18.0, 23.0]:
		for x in [-12.0, -8.0, -4.0, 4.0, 8.0, 12.0]: desk(x, d, 0, "monitor")
	# upper deck
	box(Vector3(36.0, 1.5, 12.0), 0, 34.0, 0.75, Mats.flat(Color(0.16, 0.16, 0.18), 0.5))
	box(Vector3(28.0, 1.1, 0.05), 0, 28.0, 2.05, Mats.glass(), true)
	for s2 in [-1.0, 1.0]: ramp(s2 * 16.0, 22.0, 0.0, 1.5, 6.0, 4.0)
	for x2 in [-8.0, 0.0, 8.0]:
		piece("ph:metal_office_desk", x2, 31.0, 0, 1.5)
		box(Vector3(0.6, 0.35, 0.03), x2, 31.3, 2.6, Mats.glow(Color(1.0, 0.4, 0.3), 1.4), false)
	# red target wall
	box(Vector3(26.0, 4.0, 0.1), 0, 39.8, 3.9, Mats.flat(Color(0.12, 0.02, 0.02), 0.4), false)
	var towns := ["SMITHS FALLS", "DRUMHELLER", "TRURO", "KAPUSKASING", "NELSON", "ANTIGONISH", "PORTAGE", "COBOURG", "RIMOUSKI", "YORKTON", "KENORA", "BRANDON"]
	for k in towns.size():
		label(towns[k], -9.0 + (k % 3) * 9.0, 39.7, 5.4 - int(k / 3) * 0.8, 180, 52, Color(1.0, 0.35, 0.3))
	glow_strip(0, 39.6, 1.8, 26.0, 90.0, Color(1.0, 0.2, 0.15), 3.0)
	label("MERIDIAN · TARGET MARKETS", 0, 39.7, 6.3, 180, 80, Color(1.0, 0.85, 0.8))
	ceiling_lights(-18, 0, 18, 26, 7.0, 3, 3, 5.5, Color(0.92, 0.95, 1.0))
	fill(0, 36, 4.0, Color(1.0, 0.3, 0.25), 0.7, 14.0)
	terminal(14.0, 38.0, 180)
	guard(0.0, 6.0, 0, [[0, 6, 2, 90], [0, 25, 2, 270]])
	guard(-16.0, 10.0, 0, [[-16, 10, 2, 90], [-16, 20, 2, 90]])
	guard(-6.0, 32.0, 180, [], "marksman", 0, 1.5)
	guard(6.0, 32.0, 180, [], "css", 0, 1.5)
	guard(14.0, 34.0, 200, [], "heavy", 1, 1.5)
	guard(10.0, 16.0, 270, [], "css", 2)
	for p in [[-6, 26], [6, 26], [-16, 26], [16, 4], [-16, 4]]: spawn(p[0], p[1])
