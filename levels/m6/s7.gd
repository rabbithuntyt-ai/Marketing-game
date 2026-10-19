extends Sector
## M6 · Sector 8 · OVERWATCH — you're on the admin-block roof with the long rifle; Ruiz crosses the
## yard below to the truck. Castellan teams flank in from the warehouses on both sides.
## Read (from the perch at the south end, looking north): a 70 m yard with two warehouse rows on
## the flanks (enemies emerge from their doors), cover islands down the middle that Ruiz moves
## between, and the truck at the far end.

func dims() -> Vector3: return Vector3(44, 12, 80)
func outdoor() -> bool: return true

func build() -> void:
	floor_rect(-22, 0, 22, 80, "", 0.0, Mats.flat(Color(0.82, 0.85, 0.9), 0.95))
	# the roof you stand on (d 0-7, y 7) with a stairwell hut behind
	box(Vector3(44.0, 7.0, 7.0), 0, 3.5, 3.5, b.mat("CONCRETE", 3.0))
	box(Vector3(44.0, 1.0, 0.3), 0, 6.85, 7.5, b.mat("CONCRETE", 2.0))
	box(Vector3(4.0, 3.0, 2.2), 0, 1.1, 8.5, b.mat("tech", 2.0))
	for x in [-14.0, 14.0]: piece("ph:exterior_aircon_unit", x, 2.0, 0, 7.0)
	r.set_meta("perch_y", 7.0)
	anchor("perch", P(0, 4.0, 7.2))
	note("Perch: admin roof", 0, 4)
	# warehouses
	for s in [-1.0, 1.0]:
		for k in 3:
			var d0 := 16.0 + k * 20.0
			box(Vector3(4.0, 8.0, 16.0), s * 20.0, d0 + 8.0, 4.0, b.mat("metal", 3.0, Color(0.62, 0.64, 0.67)))
			box(Vector3(4.4, 0.4, 16.4), s * 20.0, d0 + 8.0, 8.2, Mats.flat(Color(0.9, 0.92, 0.95), 0.9), false)
			piece("ph:rollershutter_door", s * 17.9, d0 + 8.0, 90.0 if s > 0 else 270.0, 0, "none")
			box(Vector3(0.3, 0.3, 0.3), s * 17.8, d0 + 5.0, 4.4, Mats.glow(Color(1.0, 0.7, 0.3), 3.0), false)
			label("W%d" % (k + 1 + (0 if s < 0 else 3)), s * 17.85, d0 + 12.0, 5.5, 90.0 if s > 0 else 270.0, 140, Color(0.15, 0.15, 0.18))
	# cover islands along Ruiz's route
	for p in [[-8.0, 16.0, 0], [6.0, 27.0, 1], [-5.0, 42.0, 2], [7.0, 54.0, 0], [-2.0, 63.0, 1]]:
		crates(p[0], p[1] + 1.5, 10.0, p[2])
		cover("ph:concrete_road_barrier", p[0] + 2.0, p[1] + 2.5, 0)
	for p2 in [[2.0, 20.0, 10.0], [-10.0, 34.0, -15.0], [10.0, 46.0, 170.0]]: cover("ph:covered_car", p2[0], p2[1], p2[2])
	containers(-6.0, 50.0, 90.0, 1, 1)
	containers(3.0, 36.0, 0.0, 2, 0)
	truck(4.0, 72.0)
	r.set_meta("truck", P(4.0, 72.0))
	anchor("escort", [P(-8, 14), P(6, 27), P(-5, 42), P(7, 54), P(1.5, 70)])
	note("Ruiz's route to the truck", -5, 42)
	for p3 in [[-10.0, 24.0], [10.0, 40.0], [-10.0, 58.0], [10.0, 70.0]]:
		piece("ph:street_lamp_01", p3[0], p3[1], 90.0 if p3[0] < 0 else 270.0)
		lamp(p3[0] * 0.85, p3[1], 7.0, 9.0, 75, Color(1.0, 0.85, 0.6), "")
	fill(0, 40, 10.0, Color(0.55, 0.65, 0.85), 0.3, 60.0)
	terminal(-6.0, 78.0, 180)
