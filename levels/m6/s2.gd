extends Sector
## M6 · Sector 3 · HOLDING BLOCK — Ruiz is held in cell E4.
## Read: a central corridor with barred cells down both sides (four each). A glass guard station
## sits at the near end of the corridor; guards patrol the corridor and stand in the station.
## Cell E4 (east, fourth) is the objective; clear the block, then open it.

func dims() -> Vector3: return Vector3(32, 6, 40)

func build() -> void:
	strategy_wall(-15.3, 4.0, 90, 2.6)
	floor_rect(-16, 0, 16, 40, "", 0.0, b.mat("CONCRETE", 3.0, Color(0.7, 0.72, 0.75)))
	concrete_shell(6.0, 8.0, true, b.mat("CONCRETE", 4.0, Color(0.68, 0.7, 0.72)))
	for s in [-1.0, 1.0]:
		for k in 4:
			var d0 := 8.0 + k * 6.0
			var xb: float = s * 9.0
			partition(xb, d0, s * 16.0, d0, 3.2, b.mat("CONCRETE", 2.0), 0.4)
			# bars on the corridor side (E4 bars have no collider: cell door opens on interaction)
			var open: bool = s > 0 and k == 3
			for b2 in 11:
				box(Vector3(0.07, 3.0, 0.07), xb, d0 + 0.35 + b2 * 0.53, 1.5, b.mat("steel", 1.0), not open)
			box(Vector3(0.12, 0.12, 6.0), xb, d0 + 3.0, 2.95, b.mat("steel", 1.0), false)
			piece("ph:metal_stool_01", s * 14.5, d0 + 2.0, 0)
			box(Vector3(2.4, 0.5, 0.9), s * 14.8, d0 + 4.2, 0.25, b.mat("steel", 1.0))
			label("%s%d" % ["E" if s > 0 else "W", k + 1], xb + s * -0.05, d0 + 3.0, 3.3, 90.0 if s < 0 else 270.0, 64, Color(1.0, 0.85, 0.4))
			lamp(s * 12.5, d0 + 3.0, 5.8, 2.5, 60, Color(0.9, 0.95, 1.0), "")
		partition(s * 9.0, 32.0, s * 16.0, 32.0, 3.2, b.mat("CONCRETE", 2.0), 0.4)
	anchor("cell", P(12.0, 29.0))
	note("Cell E4: Ruiz", 12, 29)
	# guard station
	glass_room(-4.0, 3.0, 4.0, 8.0, "s", 0.5)
	desk(0.0, 6.5, 180, "monitor")
	piece("ph:Television_01", -3.0, 7.4, 180, 0.78, "none")
	intel(0, 0.0, 6.6, 180, 0.79)
	for p in [[-6.0, 36.0, 0], [6.0, 36.0, 1]]: crates(p[0], p[1], 0.0, p[2])
	for d in [12.0, 20.0, 28.0, 36.0]: lamp(0.0, d, 5.8, 5.0, 60, Color(0.85, 0.92, 1.0), "q:Prop_Light_Small")
	fill(0, 20, 4.0, Color(0.5, 0.58, 0.72), 0.35, 24.0)
	terminal(-6.0, 38.5, 180)
	guard(0.0, 10.0, 0, [[0, 10, 2, 0], [0, 34, 3, 180]])
	guard(-2.0, 5.0, 180)
	guard(6.0, 36.0, 180, [], "css", 0)
	guard(-6.0, 22.0, 90, [], "heavy", 1)
	guard(2.5, 4.5, 200, [], "css", 2)
	for p in [[-6, 38], [6, 38], [0, 38], [-12, 36], [12, 36]]: spawn(p[0], p[1])
