extends Sector
## M1 · Sector 8 · ROOFTOP — hold the roof until the LEDGER helicopter lands.
## Read: a parapet ring; the helipad in the middle; rooftop aircon units and chillers form cover
## islands. Castellan reinforcements come up three stair heads (west, east, north-east), so the
## defensive spot is the helipad edge with the aircon blocks at your back.

func dims() -> Vector3: return Vector3(36, 6, 40)
func outdoor() -> bool: return true

func build() -> void:
	strategy_wall(-17.0, 10.0, 90, 2.6)
	floor_rect(-18, 0, 18, 40, "", 0.0, b.mat("CONCRETE"))
	for s in [-1.0, 1.0]:
		box(Vector3(0.5, 1.1, 40.0), s * 18.0, 20.0, 0.55, b.mat("CONCRETE", 1.0))
	box(Vector3(16.0, 1.1, 0.5), -10.0, 40.0, 0.55, b.mat("CONCRETE", 1.0))
	box(Vector3(16.0, 1.1, 0.5), 10.0, 40.0, 0.55, b.mat("CONCRETE", 1.0))
	box(Vector3(14.0, 1.1, 0.5), -11.0, 0.0, 0.55, b.mat("CONCRETE", 1.0))
	box(Vector3(14.0, 1.1, 0.5), 11.0, 0.0, 0.55, b.mat("CONCRETE", 1.0))
	# helipad
	var pad := b.cyl(geo, 7.0, 0.2, P(0, 20, 0.1), Mats.flat(Color(0.2, 0.22, 0.24), 0.8), Vector3.ZERO, true)
	pad.name = "Helipad"
	var ring := b.cyl(geo, 6.6, 0.04, P(0, 20, 0.22), Mats.glow(Color(0.3, 1.0, 0.5), 1.5))
	b.cyl(geo, 6.3, 0.05, P(0, 20, 0.23), Mats.flat(Color(0.2, 0.22, 0.24), 0.8))
	ring.name = "PadRing"
	var h := label("H", 0, 20, 0.26, 0, 900, Color(0.95, 0.95, 0.95))
	h.rotation.x = -PI * 0.5
	# cover islands
	for p in [[-9.0, 10.0, 0.0], [9.0, 10.0, 0.0], [-10.0, 30.0, 180.0], [10.0, 31.0, 180.0]]:
		cover("ph:exterior_aircon_unit", p[0], p[1], p[2])
		piece("ph:exterior_aircon_unit", p[0] + 1.4, p[1], p[2])
	chiller(-13.0, 20.0, 0, 6.0)
	chiller(13.0, 20.0, 0, 6.0)
	for p in [[-4.0, 34.0], [4.0, 6.0]]: pillar(p[0], p[1])
	for p in [[0.0, 36.5, 0], [0.0, 3.5, 1], [-15.0, 4.0, 0], [15.0, 36.0, 1]]: crates(p[0], p[1], 0.0, p[2])
	pipes(-17.5, 14, -17.5, 28, 0.4, 2)
	pipes(17.5, 14, 17.5, 28, 0.4, 2)
	# stair heads
	for st in [[-15.0, 26.0], [15.0, 26.0], [8.0, 37.0]]:
		box(Vector3(3.6, 3.0, 3.6), st[0], st[1], 1.5, b.mat("techc", 2.0))
		box(Vector3(0.1, 0.3, 0.3), st[0], st[1] - 1.85, 2.6, Mats.glow(Color(1.0, 0.2, 0.1), 4.0), false)
		spawn(st[0], st[1] - 2.8)
	note("Stair heads: reinforcements come up here", 15, 30)
	for p in [[-16.0, 2.0], [16.0, 38.0]]:
		piece("tps:prop_floodlight", p[0], p[1], 45.0 if p[0] < 0 else 225.0)
	lamp(-8.0, 6.0, 5.5, 8.0, 80, Color(0.95, 0.97, 1.0), "")
	lamp(8.0, 34.0, 5.5, 8.0, 80, Color(0.95, 0.97, 1.0), "")
	fill(0, 20, 5.0, Color(0.5, 0.58, 0.75), 0.4, 30.0)
	terminal(0.0, 11.0, 180)
	for p in [[-6, 38], [6, 38], [-16, 36], [16, 4]]: spawn(p[0], p[1])
