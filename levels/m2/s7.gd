extends Sector
## M2 · Sector 8 · EXIT LIFT — the bunker is coming down. Run the collapsed access corridor to the
## freight lift before the timer runs out.
## Read: a long corridor choked with fallen beams, slabs and burning debris that forces a slalom
## (left-right-left), sparks and red emergency light. The lift cage waits at the far end.

func dims() -> Vector3: return Vector3(16, 7, 60)

func build() -> void:
	floor_rect(-8, 0, 8, 60, "", 0.0, b.mat("CONCRETE"))
	concrete_shell(7.0, 6.0, true, b.mat("CONCRETE", 4.0, Color(0.6, 0.58, 0.55)))
	var blocks := [[-3.0, 8.0, 10.0], [3.5, 15.0, -8.0], [-3.0, 22.0, 6.0], [3.0, 29.0, -12.0], [-3.5, 36.0, 14.0], [3.0, 43.0, -6.0], [-3.0, 50.0, 4.0]]
	for bl in blocks:
		box(Vector3(9.0, 2.2, 1.6), bl[0], bl[1], 1.1, b.mat("CONCRETE", 2.0, Color(0.55, 0.53, 0.5)), true, bl[2])
		piece("tps:prop_steelbeam", bl[0], bl[1], 90.0 + bl[2], 2.2, "none")
		var side: float = -signf(bl[0])
		fill(bl[0] * 0.3, bl[1], 1.0, Color(1.0, 0.45, 0.15), 1.2, 5.0)
		piece("ph:cardboard_box_01", side * 5.5, bl[1] + 2.0, bl[2] * 3.0)
	for d in [5.0, 18.0, 31.0, 44.0, 55.0]:
		box(Vector3(0.3, 0.3, 0.3), 7.5, d, 5.5, Mats.glow(Color(1.0, 0.1, 0.05), 5.0), false)
		fill(6.0, d, 5.0, Color(1.0, 0.15, 0.1), 1.0, 9.0)
	for p in [[6.0, 11.0], [-6.0, 26.0], [6.0, 39.0]]: piece("tps:prop_gastank1", p[0], p[1], 30)
	# lift cage
	box(Vector3(8.0, 0.2, 5.0), 0, 57.0, 0.1, b.mat("grate", 2.0))
	for s in [-1.0, 1.0]:
		box(Vector3(0.1, 6.0, 5.0), s * 4.0, 57.0, 3.0, b.mat("steel", 1.0), false)
		for k in 6: box(Vector3(0.12, 6.0, 0.12), s * 4.0, 54.6 + k * 0.95, 3.0, b.mat("steel", 1.0), false)
	box(Vector3(8.0, 0.2, 5.0), 0, 57.0, 6.2, b.mat("steel", 1.0), false)
	label("FREIGHT LIFT · SURFACE", 0, 54.4, 5.2, 180, 56, Color(1.0, 0.85, 0.4))
	lamp(0, 57.0, 6.0, 6.0, 70, Color(1.0, 0.9, 0.7), "")
	fill(0, 30, 4.0, Color(0.6, 0.3, 0.2), 0.4, 30.0)
	for p in [[-5, 58], [5, 58], [0, 46]]: spawn(p[0], p[1])
