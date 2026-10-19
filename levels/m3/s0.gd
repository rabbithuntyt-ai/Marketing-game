extends Sector
## M3 · Sector 1 · GATEHOUSE — truck gate into the container terminal. Storm, horizontal rain.
## Read: walls of stacked containers on both sides make a canyon. A queue of trailers waits in the
## east lane (cover all the way up); the west lane is open tarmac. The gatehouse booth in the middle
## controls the booms; the intel is on its counter. A marksman stands on the west container wall.

func dims() -> Vector3: return Vector3(36, 8, 44)
func outdoor() -> bool: return true

func build() -> void:
	strategy_wall(-14.3, 40.0, 90, 2.6)
	floor_rect(-18, 0, 18, 44, "", 0.0, b.mat("ASPHALT"))
	for d in [4.0, 11.0, 18.0, 32.0]:
		containers(-16.0, d, 0.0, 2, int(d) % 3)
		containers(16.0, d + 2.0, 0.0, 2, int(d + 1) % 3)
	containers(-16.0, 39.0, 0.0, 1, 1)
	containers(16.0, 40.0, 0.0, 1, 0)
	for k in 3: paint(0, 2.0 + k * 13.0, 0, 10.0 + k * 13.0, Color(0.95, 0.95, 0.9), 0.15)
	# gatehouse booth + booms
	box(Vector3(3.0, 2.6, 4.0), -3.0, 26.0, 1.3, b.mat("techc", 2.0))
	box(Vector3(3.3, 0.15, 4.3), -3.0, 26.0, 2.68, b.mat("metal", 2.0))
	box(Vector3(0.05, 1.1, 3.0), -1.48, 26.0, 1.55, Mats.glass(), false)
	box(Vector3(0.6, 0.9, 2.6), -1.1, 26.0, 0.45, b.mat("gunmetal", 1.0))
	label("GATE 4 · INBOUND", -3.0, 23.98, 2.3, 180, 48, Color(1.0, 0.85, 0.4))
	cover_pt(-3.0, 23.2); cover_pt(-3.0, 28.8)
	for s in [-1.0, 1.0]:
		box(Vector3(0.4, 1.2, 0.4), s * 7.0 - 1.5 * s, 25.0, 0.6, b.mat("steel", 1.0))
		box(Vector3(5.5, 0.12, 0.12), s * 7.0 + 1.3 * s, 25.0, 1.1, Mats.flat(Color(0.9, 0.2, 0.15), 0.6), false)
	# trailer queue, east lane
	for d2 in [8.0, 18.0, 33.0]: _trailer_x(9.0, d2)
	for p in [[-8.0, 14.0], [-6.0, 36.0], [4.0, 30.0]]: cover("ph:concrete_road_barrier", p[0], p[1], 0)
	piece("tps:prop_tripodlight", -10.5, 26.0, 60)
	for p in [[-12.0, 8.0], [12.0, 26.0], [-12.0, 34.0]]:
		piece("ph:street_lamp_01", p[0], p[1], 0 if p[0] < 0 else 180)
		lamp(p[0] * 0.85, p[1], 7.0, 9.0, 70, Color(1.0, 0.85, 0.6), "")
	fill(-3.0, 26.0, 2.4, Color(1.0, 0.9, 0.7), 0.8, 5.0)
	fill(0, 22, 9.0, Color(0.45, 0.55, 0.7), 0.3, 40.0)
	dark(-14, 0, -6, 20)
	intel(0, -1.1, 26.0, 270, 0.92)
	terminal(-5.0, 42.0, 180)
	guard(-3.0, 23.0, 180)
	guard(-9.0, 4.0, 0, [[-9, 4, 2, 90], [-9, 38, 3, 90]])
	guard(5.5, 36.0, 180, [[5.5, 36, 2, 90], [5.5, 4, 3, 90]])
	guard(-16.0, 18.0, 90, [], "marksman", 1, 6.22)
	guard(3.0, 40.0, 180, [], "heavy", 2)
	for p in [[-6, 42], [6, 42], [0, 41], [-10, 42], [12, 42]]: spawn(p[0], p[1])

func _trailer_x(x: float, d: float) -> void:
	box(Vector3(2.6, 2.9, 9.0), x, d, 2.45, Mats.pbr("cont2", 2.0))
	box(Vector3(2.5, 2.4, 2.4), x, d - 6.0, 1.5, Mats.flat(Color(0.7, 0.72, 0.75), 0.4, 0.4))
	box(Vector3(2.2, 0.9, 0.05), x, d - 7.21, 2.1, Mats.glass(), false)
	for s in [-1.0, 1.0]:
		for z in [-6.0, 2.5, 3.8]:
				var w := b.cyl(geo, 0.48, 0.35, P(x + s * 1.1, d + z, 0.48), Mats.flat(Color(0.05, 0.05, 0.05), 0.9)); w.rotation = Vector3(0, 0, PI * 0.5)
	for s2 in [-1.0, 1.0]: cover_pt(x + s2 * 2.0, d)
