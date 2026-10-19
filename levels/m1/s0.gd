extends Sector
## M1 · Sector 1 · PERIMETER FENCE — Castellan Fulfillment Centre 7, Hamilton. Night, rain.
## Read: you come through the south fence into the trailer yard. Parked trailers angle in from both
## sides and make a funnel toward the guard hut in the middle; the gate out is in the north fence.
## Two guards walk the west trailers as a pair, one walks the east side, a hut guard watches the
## centre. Floodlights at the north gate light the last 8 m: that's where they'll see you.

func dims() -> Vector3: return Vector3(36, 6, 44)
func outdoor() -> bool: return true

func build() -> void:
	strategy_wall(-17.3, 22.0, 90, 2.6)
	floor_rect(-18, 0, 18, 44, "", 0.0, b.mat("ASPHALT"))
	for k in 6:
		piece("ph:modular_chainlink_fence", -18.4, 4.0 + k * 8.0, 90, 0, "box")
		piece("ph:modular_chainlink_fence", 18.4, 4.0 + k * 8.0, 90, 0, "box")
	for x in [-14.0, -6.2, 6.2, 14.0]:
		piece("ph:modular_chainlink_fence", x, -0.4, 0, 0, "box")
		piece("ph:modular_chainlink_fence", x, 44.2, 0, 0, "box")
	for x in [-2.2, 2.2]: box(Vector3(0.3, 3.2, 0.3), x, 43.8, 1.6, b.mat("steel", 1.0))
	label("CASTELLAN · GATE 3", 0, 43.8, 3.4, 180, 56, Color(1.0, 0.85, 0.4))
	# trailers in the yard
	for t in [[-11.0, 10.0, 15.0], [-11.0, 20.0, 15.0], [11.0, 13.0, -15.0], [11.0, 25.0, -15.0], [-10.0, 32.0, 10.0]]:
		_trailer(t[0], t[1], t[2])
	for x in [-4.0, 4.0]: cover("ph:concrete_road_barrier", x, 6.0, 0)
	cover("ph:concrete_road_barrier_02", 6.0, 36.5, 20)
	for k in 5: paint(4.0, 30.0 + k * 3.0, 9.0, 30.0 + k * 3.0, Color(0.9, 0.9, 0.85))
	_hut(0.0, 22.0)
	# lighting: two yard lamps, two floodlights at the gate
	for p in [[6.0, 30.0], [-6.0, 14.0]]:
		piece("ph:street_lamp_01", p[0], p[1], 0)
		lamp(p[0], p[1] + 0.3, 3.8, 8.0, 70.0, Color(1.0, 0.85, 0.6), "")
	for x in [-15.5, 15.5]:
		piece("tps:prop_floodlight", x, 38.0, 180 + (30 if x < 0 else -30))
		lamp(x * 0.8, 38.5, 5.5, 10.0, 80.0, Color(0.95, 0.97, 1.0), "")
	cover("ph:portable_generator", 15.5, 34.0, 270)
	crates(-15.0, 39.0, 10, 0)
	crates(14.5, 5.0, 80, 1)
	piece("ph:metal_trash_can", -16.8, 3.0, 0)
	dark(-18, 0, -6, 30); dark(6, 0, 18, 20)
	note("Trailer shadow: west and south-east", -12, 4)
	note("Gate floodlit: last 8 m", 0, 40)
	intel(0, 2.1, 22.0, 90, 0.86)
	terminal(13.0, 42.0, 180)
	guard(-6.0, 12.0, 0, [[-6, 12, 2, 270], [-6, 30, 3, 90]])
	guard(-7.5, 12.5, 0, [[-7.5, 12.5, 2, 270], [-7.5, 30.5, 3, 90]])
	guard(7.5, 36.0, 180, [[7.5, 36, 3, 90], [7.5, 10, 3, 270]])
	guard(1.5, 23.5, 180, [], "css", 1)
	guard(-2.0, 41.0, 180, [], "css", 2)
	for p in [[-6, 40], [6, 40], [0, 42], [-12, 42], [12, 40]]: spawn(p[0], p[1])
	fill(0, 22, 9.0, Color(0.5, 0.58, 0.75), 0.25, 40.0)

func _trailer(x: float, d: float, yaw: float) -> void:
	var bs := yaw_basis(yaw); var c := P(x, d)
	b.box(geo, Vector3(2.6, 2.9, 10.0), c + Vector3(0, 2.45, 0), Mats.pbr("cont3", 2.0)).basis = bs
	b.box(geo, Vector3(2.4, 0.3, 9.6), c + Vector3(0, 0.85, 0), b.mat("gunmetal", 1.0), false).basis = bs
	for s in [-1.0, 1.0]:
		for z in [3.2, 4.4]:
			var w := b.cyl(geo, 0.5, 0.35, c + bs * Vector3(s * 1.1, 0.5, z), Mats.flat(Color(0.05, 0.05, 0.05), 0.9))
			w.basis = bs * Basis(Vector3.FORWARD, PI * 0.5)
		var l := b.label(r, "CASTELLAN · VALUE, DELIVERED.", c + bs * Vector3(s * 1.32, 2.6, 0), 0, 64, Color(0.95, 0.95, 0.95), "Rajdhani-Bold", 0, HORIZONTAL_ALIGNMENT_CENTER)
		l.basis = bs * Basis(Vector3.UP, s * PI * 0.5)
	b.box(geo, Vector3(0.1, 1.2, 0.1), c + bs * Vector3(0, 0.6, -4.5), b.mat("steel", 1.0), false).basis = bs
	for s2 in [-1.0, 1.0]:
		r.cover_points.append(c + bs * Vector3(s2 * 2.0, 0, -2.5)); r.cover_points.append(c + bs * Vector3(s2 * 2.0, 0, 2.5))

func _hut(x: float, d: float) -> void:
	var m := b.mat("tech", 2.0)
	box(Vector3(3.6, 2.6, 3.6), x, d, 1.3, m)
	box(Vector3(3.9, 0.15, 3.9), x, d, 2.68, b.mat("metal", 2.0))
	box(Vector3(0.05, 1.0, 2.4), x + 1.82, d, 1.5, Mats.glass(), false)
	box(Vector3(2.4, 1.0, 0.05), x, d + 1.82, 1.5, Mats.glass(), false)
	box(Vector3(0.5, 0.86, 1.2), x + 2.1, d, 0.43, b.mat("gunmetal", 1.0))
	label("SECURITY", x, d - 1.82, 2.2, 180, 56, Color(1.0, 0.85, 0.4))
	fill(x, d, 2.4, Color(1.0, 0.9, 0.7), 0.7, 5.0)
	cover_pt(x - 2.6, d); cover_pt(x, d - 2.6)
