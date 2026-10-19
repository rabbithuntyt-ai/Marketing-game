extends Sector
## M3 · Sector 7 · SERVER ROOM — the terminal's network room, where Castellan watches the market.
## Read: concrete shell, low. Server rows in the middle (four, short aisles). A UPS room behind a
## wall in the south-west; the NOC at the north wall with the routing consoles: Marr's environment
## calls (micro vs macro forces) are answered there. Breaker in the UPS room drops the lights.

func dims() -> Vector3: return Vector3(32, 6, 40)

func build() -> void:
	strategy_wall(15.3, 6.0, 270, 2.6)
	floor_rect(-16, 0, 16, 40, "q:Platform_DarkPlates")
	concrete_shell(5.5, 8.0, true, b.mat("tech", 3.0))
	for x in [-8.0, -3.0, 3.0, 8.0]:
		server_row(x, 14.0, 0, 9)
		server_row(x, 26.0, 0, 9)
	pipes(-16, 20, 16, 20, 4.8, 3)
	# UPS room SW
	partition(-16, 8, -10, 8, 5.5)
	partition(-10, 0.4, -10, 3.0, 5.5)
	partition(-10, 5.0, -10, 8.0, 5.5)
	for k in 3: box(Vector3(1.0, 1.8, 0.8), -14.5 + k * 1.4, 7.2, 0.9, b.mat("gunmetal", 1.0))
	label("UPS · BATTERY", -13.0, 8.0, 2.6, 180, 40, Color(1.0, 0.8, 0.3))
	power_box(-15.6, 3.0, 90)
	# NOC
	call_panels([0, 39.4, 180], [[-6.0, 34.5, 180], [-2.0, 34.5, 180], [2.0, 34.5, 180], [6.0, 34.5, 180]])
	for x2 in [-12.0, 12.0]: desk(x2, 36.5, 180, "monitor")
	intel(0, -12.0, 36.6, 180, 0.79)
	intel(1, 12.0, 6.0, 270, 0.79, "ph:metal_office_desk")
	for p in [[12.0, 32.0, 0], [-12.0, 30.0, 2]]: crates(p[0], p[1], 0.0, p[2])
	for d in [6.0, 20.0, 34.0]: lamp(0.0, d, 5.3, 4.5, 58, Color(0.65, 0.82, 1.0), "")
	fill(0, 20, 4.0, Color(0.45, 0.55, 0.85), 0.4, 26.0)
	guard(-5.5, 8.0, 0, [[-5.5, 8, 2, 0], [-5.5, 32, 2, 180]])
	guard(5.5, 32.0, 180, [[5.5, 32, 2, 180], [5.5, 8, 2, 0]])
	guard(-12.0, 4.0, 90)
	guard(0.0, 20.0, 90, [[0, 20, 2, 90], [-12, 20, 2, 270]], "css", 0)
	guard(12.0, 20.0, 270, [], "heavy", 1)
	guard(0.0, 37.0, 180, [], "css", 2)
	for p in [[-8, 38], [8, 38], [-14, 30], [14, 30], [0, 31]]: spawn(p[0], p[1])
