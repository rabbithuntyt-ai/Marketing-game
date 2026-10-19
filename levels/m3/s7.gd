extends Sector
## M3 · Sector 8 · PIER 9 — Kessler makes his stand at the end of the pier with the ship behind him.
## Read: the pier deck runs along the west two-thirds; black water on the east with the hull of
## the Meridian ship moored alongside. Bollards line the edge, the red legs of a ship-to-shore
## crane straddle the middle, and container islands give cover on the approach. Kessler holds the
## far end by the gangway.

func dims() -> Vector3: return Vector3(36, 12, 52)
func outdoor() -> bool: return true

func build() -> void:
	floor_rect(-18, 0, 12, 52, "", 0.0, b.mat("CONCRETE", 4.0, Color(0.7, 0.7, 0.72)))
	water(12, 0, 18, 52)
	box(Vector3(0.4, 0.3, 52.0), 11.8, 26.0, 0.15, b._hazard(), false)
	# ship hull
	box(Vector3(6.0, 9.0, 50.0), 17.0, 26.0, 2.5, Mats.flat(Color(0.1, 0.13, 0.17), 0.6, 0.4))
	box(Vector3(0.05, 0.6, 50.0), 13.98, 26.0, -0.6, Mats.flat(Color(0.5, 0.12, 0.08), 0.7), false)   # boot-top stripe at the waterline
	box(Vector3(5.6, 0.05, 49.6), 17.0, 26.0, 7.02, Mats.flat(Color(0.3, 0.32, 0.3), 0.8), false)
	rail(14.2, 1.2, 14.2, 50.8, 7.0)
	for k in 6: piece("tps:prop_container%d" % (2 + k % 2), 17.0, 6.0 + k * 6.6, 0.0, 7.05, "none")
	piece("tps:prop_container3", 17.0, 6.0, 2.0, 10.16, "none")
	piece("tps:prop_container2", 17.0, 19.2, -1.5, 10.16, "none")
	box(Vector3(5.6, 7.0, 5.0), 17.0, 47.5, 10.5, Mats.flat(Color(0.85, 0.85, 0.82), 0.5))
	box(Vector3(0.05, 1.0, 4.4), 14.18, 47.5, 12.8, Mats.glow(Color(1.0, 0.85, 0.6), 1.2), false)
	box(Vector3(0.2, 3.0, 0.2), 17.0, 48.0, 15.5, b.mat("steel", 1.0), false)
	box(Vector3(0.3, 0.3, 0.3), 17.0, 48.0, 17.1, Mats.glow(Color(1.0, 0.15, 0.1), 6.0), false)
	label("MERIDIAN STAR · NASSAU", 13.95, 20.0, 5.0, 270, 200, Color(0.9, 0.9, 0.9))
	for d in [8.0, 18.0, 30.0, 42.0]:
		b.cyl(geo, 0.3, 0.7, P(11.0, d, 0.35), Mats.flat(Color(0.15, 0.15, 0.15), 0.5, 0.6), Vector3.ZERO, true)
		cover_pt(10.0, d)
	# gangway
	ramp(11.0, 46.0, 90.0, 2.0, 4.0, 1.8, b.mat("grate", 2.0))
	# crane legs
	var red := Mats.flat(Color(0.75, 0.15, 0.1), 0.5, 0.4)
	for x in [-8.0, 9.0]:
		for d2 in [22.0, 30.0]: box(Vector3(1.2, 12.0, 1.2), x, d2, 6.0, red)
		box(Vector3(1.4, 1.0, 9.0), x, 26.0, 0.5, red)
	box(Vector3(18.4, 1.4, 1.4), 0.5, 22.0, 11.3, red, false)
	box(Vector3(18.4, 1.4, 1.4), 0.5, 30.0, 11.3, red, false)
	# container islands
	containers(-13.0, 8.0, 90.0, 2, 0)
	containers(2.0, 14.0, 0.0, 1, 1)
	containers(-12.0, 34.0, 0.0, 2, 1)
	containers(4.0, 38.0, 90.0, 1, 0)
	for p in [[-4.0, 9.0, 0], [-3.0, 30.0, 1], [6.0, 26.0, 2], [-8.0, 44.0, 0]]: crates(p[0], p[1], 15.0, p[2])
	anchor("boss", P(-2.0, 44.0))
	note("Kessler: holds the gangway end", -2, 44)
	for p in [[-16.0, 18.0], [-16.0, 42.0]]:
		piece("ph:street_lamp_01", p[0], p[1], 90)
		lamp(p[0] + 1.5, p[1], 7.0, 9.0, 70, Color(1.0, 0.85, 0.6), "")
	lamp(0.5, 26.0, 11.0, 10.0, 80, Color(0.95, 0.97, 1.0), "")
	fill(0, 26, 10.0, Color(0.45, 0.55, 0.7), 0.3, 46.0)
	terminal(-12.0, 50.0, 180)
	for p in [[-6, 50], [6, 48], [0, 50], [-15, 48], [-14, 26]]: spawn(p[0], p[1])
