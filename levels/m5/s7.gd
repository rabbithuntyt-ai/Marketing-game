extends Sector
## M5 · Sector 8 · LOADING BAY — the courier's van is here. It's a setup: the truck blows as you
## arrive and Castellan's team comes through the roller doors.
## Read: concrete service bay; the north wall is a dock with three roller doors (enemy entries);
## the box truck sits in the middle (the blast point). Pillars, cages and pallets give cover; a
## raised loading platform on the east is the high ground.

func dims() -> Vector3: return Vector3(36, 8, 40)

func build() -> void:
	strategy_wall(-17.3, 8.0, 90, 3.0)
	floor_rect(-18, 0, 18, 40, "", 0.0, b.mat("CONCRETE"))
	concrete_shell(8.0, 8.0)
	box(Vector3(36.0, 1.2, 4.0), 0, 37.6, 0.6, b.mat("CONCRETE", 2.0))
	for x in [-10.0, 10.0, 0.0]:
		if x != 0.0: piece("ph:rollershutter_door", x, 39.3, 180, 1.2, "box")
		box(Vector3(0.3, 0.3, 0.3), x, 39.2, 5.6, Mats.glow(Color(1.0, 0.6, 0.1), 4.0), false)
	ramp(-4.0, 32.6, 0.0, 1.2, 3.0, 3.0)
	truck(2.0, 20.0)
	anchor("blast", P(0, 20, 0.5))
	note("Truck: blast point", 2, 17)
	for p in [[-9.0, 12.0], [9.0, 12.0], [-9.0, 28.0], [9.0, 28.0]]: pillar(p[0], p[1], "q:Column_Large_Straight")
	for p in [[-14.0, 18.0, 0], [-5.0, 30.0, 1], [6.0, 8.0, 2], [-4.0, 6.0, 0], [13.0, 22.0, 1]]: crates(p[0], p[1], 10.0, p[2])
	for d in [12.0, 24.0]:
		piece("ph:modular_chainlink_fence", -15.0, d, 90, 0, "box")
		shelf(-17.0, d, 90, int(d))
	box(Vector3(5.0, 1.2, 14.0), 15.5, 16.0, 0.6, b.mat("CONCRETE", 2.0))
	ramp(15.5, 7.0, 0.0, 1.2, 2.0, 3.0)
	for d2 in [6.0, 16.0, 26.0, 34.0]: lamp(0.0, d2, 7.8, 6.0, 62, Color(1.0, 0.85, 0.6), "q:Prop_Light_Wide")
	fill(0, 20, 5.0, Color(0.55, 0.55, 0.62), 0.4, 28.0)
	terminal(-12.0, 34.5, 180)
	for p in [[-10, 34], [10, 34], [-3, 34], [-15, 34], [15, 34], [15, 4]]: spawn(p[0], p[1])
