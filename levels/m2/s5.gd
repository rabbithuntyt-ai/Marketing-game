extends Sector
## M2 · Sector 6 · VALUE CHAIN HALL — a long gallery where Castellan maps its value chain.
## Read: two lines of columns split the hall into three lanes. Five stations down the centre
## (INBOUND · OPERATIONS · OUTBOUND · MARKETING · SERVICE), each a display plinth with a screen,
## give cover in the middle lane. The routing consoles at the far end answer Marr's calls about
## the value chain and the value delivery network.

func dims() -> Vector3: return Vector3(28, 8, 56)

func build() -> void:
	strategy_wall(-13.3, 6.0, 90, 3.0)
	floor_rect(-14, 0, 14, 56, "q:Platform_Simple2")
	concrete_shell(8.0, 8.0, true, b.mat("CONCRETE", 4.0, Color(0.8, 0.8, 0.82)))
	for d in [6.0, 14.0, 22.0, 30.0, 38.0, 46.0]:
		for x in [-6.0, 6.0]: pillar(x, d, "q:Column_Astra")
	var names := ["INBOUND", "OPERATIONS", "OUTBOUND", "MARKETING", "SERVICE"]
	for k in 5:
		var d2 := 10.0 + k * 8.0
		box(Vector3(2.6, 1.0, 1.4), 0, d2, 0.5, b.mat("gunmetal", 1.0))
		box(Vector3(2.4, 1.3, 0.06), 0, d2 - 0.3, 1.75, Mats.flat(Color(0.02, 0.03, 0.04), 0.3), false)
		label("%d · %s" % [k + 1, names[k]], 0, d2 - 0.34, 1.9, 180, 52, Color(0.65, 0.88, 1.0))
		box(Vector3(2.4, 0.04, 0.04), 0, d2 - 0.34, 1.25, Mats.glow(accent, 3.0), false)
		cover_pt(0, d2 - 1.4); cover_pt(0, d2 + 1.4)
		if k < 4: paint(0, d2 + 0.8, 0, d2 + 7.2, accent, 0.3)
		lamp(0, d2, 7.8, 5.0, 50, Color(0.8, 0.9, 1.0), "")
	for p in [[-11.0, 12.0, 0], [11.0, 20.0, 1], [-10.5, 30.0, 2], [11.0, 40.0, 0], [-11.0, 44.0, 1]]: crates(p[0], p[1], 10.0, p[2])
	desk(-11.0, 24.0, 90, "monitor"); desk(11.0, 32.0, 270, "monitor")
	intel(0, -11.0, 24.0, 90, 0.78)
	intel(1, 11.0, 32.0, 270, 0.78)
	call_panels([0, 55.4, 180], [[-5.4, 50.5, 180], [-1.8, 50.5, 180], [1.8, 50.5, 180], [5.4, 50.5, 180]])
	for d3 in [8.0, 24.0, 40.0]:
		lamp(-10.0, d3, 7.8, 4.0, 60, Color(1.0, 0.86, 0.66), "")
		lamp(10.0, d3, 7.8, 4.0, 60, Color(1.0, 0.86, 0.66), "")
	fill(0, 28, 5.0, Color(0.5, 0.55, 0.7), 0.35, 34.0)
	guard(-10.0, 6.0, 0, [[-10, 6, 2, 90], [-10, 46, 3, 90]])
	guard(10.0, 46.0, 180, [[10, 46, 2, 270], [10, 6, 3, 270]])
	guard(0.0, 23.0, 180)
	guard(0.0, 47.0, 180, [], "heavy", 0)
	guard(-3.0, 36.0, 160, [], "css", 1)
	guard(4.0, 14.0, 200, [], "marksman", 2)
	for p in [[-6, 53], [6, 53], [-11, 52], [11, 52], [0, 44]]: spawn(p[0], p[1])
