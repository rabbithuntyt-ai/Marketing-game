extends Sector
## M2 · Sector 1 · SERVICE TUNNEL — the utility tunnel under Castellan's Ottawa campus.
## Read: poured concrete, low and long. Partitions make a dogleg: you enter on the east side, cross
## west through the pump-room door at 14 m, run north along the chillers, and cross back east at
## 30 m to reach the exit. A crawl duct on the east side (11.5 m) shortcuts the middle leg unseen.
## Two cameras cover the crossings.

func dims() -> Vector3: return Vector3(28, 6, 44)

func build() -> void:
	strategy_wall(13.3, 6.0, 270, 2.8)
	floor_rect(-14, 0, 14, 44, "", 0.0, b.mat("CONCRETE"))
	concrete_shell(6.0, 6.0)
	# dogleg partitions
	partition(-14, 14, -3, 14, 4.0, b.mat("CONCRETE", 3.0), 0.5)
	partition(1, 14, 10.6, 14, 4.0, b.mat("CONCRETE", 3.0), 0.5)
	partition(12.4, 14, 14, 14, 4.0, b.mat("CONCRETE", 3.0), 0.5)
	box(Vector3(1.8, 2.6, 0.5), 11.5, 14, 2.7, b.mat("CONCRETE", 3.0))
	partition(-14, 30, -1, 30, 4.0, b.mat("CONCRETE", 3.0), 0.5)
	partition(3, 30, 10.6, 30, 4.0, b.mat("CONCRETE", 3.0), 0.5)
	partition(12.4, 30, 14, 30, 4.0, b.mat("CONCRETE", 3.0), 0.5)
	box(Vector3(1.8, 2.6, 0.5), 11.5, 30, 2.7, b.mat("CONCRETE", 3.0))
	partition(-3, 14, -3, 20, 4.0, b.mat("CONCRETE", 3.0), 0.5)
	partition(3, 24, 3, 30, 4.0, b.mat("CONCRETE", 3.0), 0.5)
	label("PUMP ROOM P-2", -1, 14.3, 3.2, 0, 48, Color(1.0, 0.8, 0.3))
	# pump room (south-west)
	for p in [[-10.0, 6.0], [-6.0, 9.0]]:
		piece("tps:prop_reactorcylinder", p[0], p[1], 0)
		cover_pt(p[0] + 1.6, p[1])
	pipes(-14, 4, -2, 4, 4.2, 3)
	piece("ph:metal_tool_chest", -13.3, 11.0, 90)
	intel(0, -12.0, 2.0, 0, 0.8, "ph:metal_office_desk")
	# middle leg: chillers along the west, duct along the east
	for d in [18.0, 25.0]: chiller(-9.0, d, 0, 5.0)
	duct(11.5, 10.5, 11.5, 29.5, 1.6)
	note("Crawl duct: skips the middle leg", 11.5, 20)
	desk(0.0, 24.0, 90, "laptop")
	piece("ph:clipboard", 0.2, 24.3, 0, 0.78, "none")
	intel(1, 0.0, 24.0, 90, 0.78)
	label("SURVEY · CONCRETE CORE 7", 0, 21.6, 1.5, 0, 30, Color(0.9, 0.9, 0.85))
	# north leg
	for p in [[-8.0, 36.0, 0], [8.0, 38.0, 1], [-11.0, 41.0, 2]]: crates(p[0], p[1], 10.0, p[2])
	piece("ph:Barrel_01", 11.5, 33.5, 0)
	piece("ph:Barrel_01", 12.3, 34.4, 40)
	camera(0.0, 13.4, 5.0, 180, 25, 7.0, 14.0)
	camera(6.0, 33.4, 5.0, 180, 25, 8.0, 16.0)
	for d2 in [4.0, 10.0, 18.0, 26.0, 36.0, 42.0]:
		lamp(-6.0 if d2 < 14 else 0.0, d2, 5.4, 4.5, 60, Color(1.0, 0.8, 0.55), "q:Prop_Light_Small")
	fill(0, 22, 4.0, Color(0.55, 0.5, 0.45), 0.3, 26.0)
	dark(-14, 15, -4, 29)
	terminal(-1.8, 41.5, 90)
	guard(-8.0, 9.0, 90, [[-8, 9, 3, 90], [-12, 9, 2, 0]])
	guard(-5.0, 22.0, 0, [[-5, 17, 2, 90], [-5, 28, 3, 270]])
	guard(6.0, 36.0, 180, [[6, 36, 2, 270], [-8, 36, 3, 90]])
	guard(10.0, 6.0, 270, [], "css", 1)
	guard(0.0, 40.0, 180, [], "heavy", 2)
	for p in [[-6, 42], [6, 42], [0, 38], [10, 40], [-10, 34]]: spawn(p[0], p[1])
