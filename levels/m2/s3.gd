extends Sector
## M2 · Sector 4 · PORTFOLIO VAULT — the business-portfolio servers, one rack per SBU.
## Read: a blast-door frame at the entry; the racks stand on an arc around a raised dais so every
## rack face points at the centre. Plant charges on the cash cows only (BCG matrix): the right
## call starves the stars of nothing. Pillars give cover between the arc and the entry.

func dims() -> Vector3: return Vector3(28, 7, 32)

func build() -> void:
	strategy_wall(-13.3, 6.0, 90, 3.0)
	floor_rect(-14, 0, 14, 32, "q:Platform_DarkPlates")
	concrete_shell(7.0, 8.0, true, b.mat("CONCRETE", 4.0, Color(0.7, 0.72, 0.78)))
	for s in [-1.0, 1.0]:
		box(Vector3(1.2, 4.6, 1.6), s * 2.6, 1.5, 2.3, b.mat("gunmetal", 1.5))
		box(Vector3(0.3, 4.6, 0.3), s * 2.0, 1.5, 2.3, b._hazard(), false)
	box(Vector3(6.4, 1.2, 1.6), 0, 1.5, 5.2, b.mat("gunmetal", 1.5))
	label("VAULT 2 · PORTFOLIO", 0, 2.3, 4.2, 0, 56, Color(1.0, 0.8, 0.3))
	# dais
	b.cyl(geo, 4.0, 0.3, P(0, 18, 0.15), Mats.flat(Color(0.15, 0.16, 0.18), 0.4), Vector3.ZERO, true)
	b.cyl(geo, 3.8, 0.04, P(0, 18, 0.32), Mats.glow(accent, 1.6))
	label("BCG · GROWTH-SHARE", 0, 18, 0.35, 0, 120, Color(0.7, 0.85, 1.0)).rotation.x = -PI * 0.5
	var rk: Array = []
	for k in 5:
		var a := deg_to_rad(-60.0 + k * 30.0)
		rk.append([P(sin(a) * 9.0, 18.0 + cos(a) * 9.0), -a])
	anchor("racks", rk)
	note("SBU racks on the arc, faces to the dais", 0, 27)
	for p in [[-7.0, 9.0], [7.0, 9.0], [-11.0, 17.0], [11.0, 17.0]]: pillar(p[0], p[1], "q:Column_Large_Straight")
	for p in [[-4.0, 7.0, 0], [4.0, 7.0, 1]]: crates(p[0], p[1], 0.0, p[2])
	intel(0, -11.5, 28.0, 90, 0.79, "ph:metal_office_desk")
	for k2 in 5:
		var a2 := deg_to_rad(-60.0 + k2 * 30.0)
		lamp(sin(a2) * 9.0, 18.0 + cos(a2) * 9.0 - 1.5, 6.8, 4.0, 45, Color(0.7, 0.85, 1.0), "")
	lamp(0, 18, 6.8, 6.0, 60, Color(0.8, 0.9, 1.0), "")
	fill(0, 14, 4.0, Color(0.45, 0.55, 0.8), 0.4, 22.0)
	terminal(9.0, 30.0, 180)
	for p in [[-6, 30], [6, 30], [0, 30], [-12, 24], [12, 24]]: spawn(p[0], p[1])
