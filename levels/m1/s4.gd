extends Sector
## M1 · Sector 5 · EXECUTIVE MEZZANINE — the visiting directors' lounge above the warehouse floor.
## Read: a marble reception at floor level; a raised glass-fronted mezzanine across the back third
## where five directors stand at the rail. You climb the west stairs, observe them, and pick out the
## one whose words match the concept Marr asked about.

func dims() -> Vector3: return Vector3(28, 9, 36)

func build() -> void:
	strategy_wall(13.3, 10.0, 270, 3.0)
	floor_rect(-14, 0, 14, 36, "", 0.0, b.mat("MARBLE"))
	ceiling(-14, 0, 14, 36, 9.0)
	wall(-14, 0, 14, 0, Vector2(0, 5), "WWWDWWW", "WallAstra", "TopAstra")
	wall(-14, 36, 14, 36, Vector2(0, 30), "WWWDWWW", "WallAstra", "TopAstra")
	wall(-14, 0, -14, 36, Vector2(0, 18), "", "WallAstra", "TopAstra")
	wall(14, 0, 14, 36, Vector2(0, 18), "", "WallAstra", "TopAstra")
	for s in [0.0, 36.0]: wall(-14, s, 14, s, Vector2(0, 18), "", "WallAstra", "", 5.0)
	wall(-14, 0, -14, 36, Vector2(0, 18), "GGGGGGGGG", "WallAstra", "", 5.0)
	wall(14, 0, 14, 36, Vector2(0, 18), "GGGGGGGGG", "WallAstra", "", 5.0)
	# mezzanine
	catwalk(-14, 25, 14, 35, 3.0, "", "q:Platform_Simple2")
	box(Vector3(28.0, 1.1, 0.05), 0, 25.0, 3.6, Mats.glass(), true)
	box(Vector3(28.0, 0.08, 0.12), 0, 25.0, 4.18, b.mat("gunmetal", 1.0), false)
	stairs(-12.0, 18.9, 0.0, true)
	anchor("directors", [P(-6, 29.5, 3.02), P(-3, 28.4, 3.02), P(0, 29.5, 3.02), P(3, 28.4, 3.02), P(6, 29.5, 3.02)])
	piece("ph:sofa_03", -8.0, 33.5, 180, 3.0)
	piece("ph:modern_coffee_table_01", -8.0, 31.6, 0, 3.0)
	piece("ph:mid_century_lounge_chair", 9.0, 33.0, 200, 3.0)
	piece("ph:modern_wooden_cabinet", 12.5, 34.5, 270, 3.0)
	label("CASTELLAN GROUP · DIRECTORS", 0, 35.8, 6.6, 180, 72, Color(0.95, 0.85, 0.6))
	# reception
	box(Vector3(5.0, 1.1, 1.0), 1.5, 9.0, 0.55, Mats.flat(Color(0.92, 0.9, 0.86), 0.3))
	box(Vector3(5.2, 0.06, 1.2), 1.5, 9.0, 1.12, b.mat("gunmetal", 1.0), false)
	cover_pt(1.5, 7.8)
	piece("ph:sofa_02", -8.0, 8.0, 90)
	piece("ph:sofa_02", -8.0, 13.0, 90)
	piece("ph:CoffeeTable_01", -6.0, 10.5, 0)
	for p in [[-11.5, 3.0], [11.5, 3.0], [-11.5, 22.0], [11.5, 22.0]]: planter(p[0], p[1], 1.6, 1.6)
	for p in [[8.0, 14.0], [8.0, 19.0]]: piece("ph:modern_arm_chair_01", p[0], p[1], 270)
	intel(0, 1.5, 9.0, 180, 1.15)
	terminal(10.0, 3.0, 180)
	for d in [6.0, 14.0, 20.0]: lamp(0.0, d, 8.8, 5.5, 60, Color(1.0, 0.86, 0.66), "")
	for x2 in [-7.0, 0.0, 7.0]: lamp(x2, 30.0, 8.8, 5.0, 50, Color(1.0, 0.88, 0.7), "")
	fill(0, 16, 5.0, Color(1.0, 0.85, 0.7), 0.35, 24.0)
	for p in [[-2, 4], [4, 4], [-10, 18], [10, 18], [0, 16]]: spawn(p[0], p[1])
