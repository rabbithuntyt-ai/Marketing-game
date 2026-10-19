extends Sector
## M2 · Sector 5 · GROWTH LAB — the product/market expansion lab, built around a steel core.
## Read: a tall steel cylinder in the middle with glowing rings; a ring catwalk at 3 m wraps it,
## reached by stairs at the south-west and north-east corners. Four lab bays in the corners hold
## the four growth strategies (penetration, market development, product development,
## diversification). The catwalk is the high ground; the bays are cover.

func dims() -> Vector3: return Vector3(32, 9, 36)

func build() -> void:
	strategy_wall(15.3, 18.0, 270, 3.4)
	floor_rect(-16, 0, 16, 36, "q:Platform_Squares")
	concrete_shell(9.0, 6.0, true, b.mat("CONCRETE", 4.0, Color(0.75, 0.78, 0.82)))
	# core
	b.cyl(geo, 2.8, 9.0, P(0, 18, 4.5), b.mat("steel", 2.0), Vector3.ZERO, true)
	for y in [1.5, 4.5, 7.5]: b.cyl(geo, 2.86, 0.12, P(0, 18, y), Mats.glow(accent, 3.0))
	cover_pt(0, 14.2); cover_pt(0, 21.8); cover_pt(-3.8, 18); cover_pt(3.8, 18)
	# ring catwalk (four slabs around the core)
	catwalk(-7, 11, 7, 14, 3.0, "n")
	catwalk(-7, 22, 7, 25, 3.0, "s")
	catwalk(-7, 14, -4, 22, 3.0, "w")
	catwalk(4, 14, 7, 22, 3.0, "e")
	stairs(-12.0, 5.0, 0.0, true)
	box(Vector3(4.0, 0.2, 2.0), -12.0, 12.1, 2.9, b.mat("grate", 2.0))
	box(Vector3(5.0, 0.2, 2.0), -9.5, 12.5, 2.9, b.mat("grate", 2.0))
	stairs(12.0, 31.0, 180.0, true)
	box(Vector3(4.0, 0.2, 2.0), 12.0, 23.9, 2.9, b.mat("grate", 2.0))
	box(Vector3(5.0, 0.2, 2.0), 9.5, 23.5, 2.9, b.mat("grate", 2.0))
	# corner lab bays
	var bays := [[-11.0, 25.0, "PENETRATION"], [11.0, 10.0, "MARKET DEV."], [-11.0, 31.5, "PRODUCT DEV."], [11.0, 4.5, "DIVERSIFICATION"]]
	for bb in bays:
		var x: float = bb[0]; var d: float = bb[1]
		box(Vector3(4.0, 0.92, 1.0), x, d, 0.46, Mats.flat(Color(0.86, 0.88, 0.9), 0.35))
		box(Vector3(4.1, 0.05, 1.1), x, d, 0.94, b.mat("gunmetal", 1.0), false)
		piece("q:Prop_Computer", x - 1.2, d, 180, 0.95, "none")
		piece("ph:circuit_board", x + 0.8, d, 30, 0.95, "none")
		label(String(bb[2]), x, d - 0.55, 1.4, 180, 32, Color(0.75, 0.9, 1.0))
		cover_pt(x, d - 1.2); cover_pt(x, d + 1.2)
	for p in [[-14.0, 18.0], [14.0, 18.0]]: piece("tps:prop_reactorcylinder", p[0], p[1], 0)
	for p in [[-6.0, 32.0, 0], [6.0, 4.0, 1], [-4.0, 6.0, 2]]: crates(p[0], p[1], 10.0, p[2])
	piece("ph:industrial_storage_cart", 6.0, 32.0, 90)
	intel(0, 11.0, 10.0, 180, 0.96)
	lamp(0, 18, 8.8, 7.0, 75, Color(0.8, 0.9, 1.0), "")
	for p in [[-11.0, 6.0], [11.0, 30.0], [-11.0, 28.0], [11.0, 7.0]]: lamp(p[0], p[1], 8.8, 5.0, 55, Color(0.9, 0.95, 1.0), "")
	fill(0, 18, 5.0, Color(0.45, 0.6, 0.9), 0.5, 24.0)
	terminal(-8.0, 34.5, 180)
	guard(-5.5, 12.5, 90, [[-5.5, 12.5, 2, 0], [5.5, 12.5, 2, 90], [5.5, 23.5, 2, 180], [-5.5, 23.5, 2, 270]], "css", 0, 3.0)
	guard(-8.0, 20.0, 90)
	guard(9.0, 15.0, 270, [[9, 15, 3, 270], [9, 28, 3, 180]])
	guard(0.0, 30.0, 180, [], "heavy", 1)
	guard(-12.0, 9.0, 45, [], "css", 2)
	for p in [[-6, 34], [6, 34], [0, 33], [-14, 22], [14, 26]]: spawn(p[0], p[1])
