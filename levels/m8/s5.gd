extends Sector
## M8 · Sector 6 · THE BOARDROOM — Hale's last stand. Three recall nodes must be answered (every
## chapter is fair game) to break the board's lock while Hale and his team hold the room.
## Read: a tall dark-wood room, night-blue window panels down both sides; the boardroom table on
## a dais across the north end; the three recall nodes at the corners and centre back.

func dims() -> Vector3: return Vector3(36, 10, 44)

func build() -> void:
	city_view(180.0)
	floor_rect(-18, 0, 18, 44, "", 0.0, Mats.flat(Color(0.18, 0.12, 0.08), 0.4))
	concrete_shell(9.5, 5.5, true, Mats.flat(Color(0.22, 0.14, 0.09), 0.5))
	for s in [-1.0, 1.0]:
		for k in 7:
			box(Vector3(0.1, 6.0, 4.6), s * 17.8, 3.0 + k * 5.5 + 2.75, 4.0, Mats.glow(Color(0.12, 0.16, 0.24), 0.5), false)
	# dais + table
	box(Vector3(24.0, 0.6, 10.0), 0, 37.0, 0.3, Mats.flat(Color(0.1, 0.07, 0.05), 0.4))
	for s2 in [-1.0, 1.0]: ramp(s2 * 13.0, 30.0, 0.0, 0.6, 2.0, 3.0)
	box(Vector3(14.0, 0.1, 3.0), 0, 36.0, 1.38, Mats.flat(Color(0.05, 0.04, 0.03), 0.2))
	box(Vector3(13.0, 0.78, 2.2), 0, 36.0, 0.99, Mats.flat(Color(0.08, 0.06, 0.04), 0.4))
	for k2 in 6:
		piece("ph:modern_arm_chair_01", -6.0 + k2 * 2.4, 34.2, 180, 0.6)
		piece("ph:modern_arm_chair_01", -6.0 + k2 * 2.4, 37.8, 0, 0.6)
	cover_pt(0, 33.6); cover_pt(-8.0, 36.0); cover_pt(8.0, 36.0)
	label("CASTELLAN GROUP", 0, 43.4, 6.5, 180, 200, Color(0.95, 0.85, 0.6))
	anchor("nodes", [P(-12.5, 39, 0.6), P(12.5, 39, 0.6), P(0, 39.5, 0.6)])
	anchor("boss", P(0, 34, 0.6))
	note("Recall nodes: corners + centre back", 0, 41)
	# cover on the approach
	for p in [[-8.0, 10.0], [8.0, 12.0], [-4.0, 20.0], [6.0, 22.0], [-11.0, 26.0], [11.0, 27.0]]:
		box(Vector3(2.4, 1.1, 0.8), p[0], p[1], 0.55, Mats.flat(Color(0.12, 0.09, 0.06), 0.4))
		cover_pt(p[0], p[1] - 1.0); cover_pt(p[0], p[1] + 1.0)
	for d in [8.0, 18.0, 28.0, 37.0]: lamp(0.0, d, 9.3, 7.0, 55, Color(1.0, 0.85, 0.65), "")
	fill(0, 37, 4.0, Color(1.0, 0.8, 0.6), 0.6, 16.0)
	fill(0, 18, 6.0, Color(0.5, 0.5, 0.6), 0.25, 30.0)
	for p2 in [[-14, 40], [14, 40], [-15, 28], [15, 28], [0, 30]]: spawn(p2[0], p2[1])
