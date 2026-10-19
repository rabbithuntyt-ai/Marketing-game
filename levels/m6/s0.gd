extends Sector
## M6 · Sector 1 · PERIMETER WALL — Northgate Campus, Rocky View County. Night, snow, −18°C.
## Read: a tall concrete wall closes the west side; a guard tower on it (deck at 5 m) carries a
## searchlight and a marksman. The yard is open snow with parked snowcats (tarped vehicles) as the
## only big cover, plus barriers and generator sheds on the east. The intel is up in the tower.

func dims() -> Vector3: return Vector3(36, 10, 48)
func outdoor() -> bool: return true

func build() -> void:
	strategy_wall(17.0, 40.0, 270, 2.6)
	floor_rect(-18, 0, 18, 48, "", 0.0, Mats.flat(Color(0.82, 0.85, 0.9), 0.95))
	for k in 6: paint(-10.0 + k * 4.0, 2.0, -10.0 + k * 4.0, 46.0, Color(0.7, 0.73, 0.8), 0.6)   # tyre ruts
	# west wall + tower
	box(Vector3(1.2, 6.0, 48.0), -17.6, 24.0, 3.0, b.mat("CONCRETE", 3.0))
	box(Vector3(5.0, 5.0, 5.0), -14.5, 26.0, 2.5, b.mat("CONCRETE", 3.0))
	catwalk(-17.5, 23.0, -11.5, 29.0, 5.0, "ns")
	box(Vector3(6.2, 0.2, 6.2), -14.5, 26.0, 8.0, b.mat("metal", 2.0), false)
	for p in [[-17.3, 23.2], [-11.7, 23.2], [-17.3, 28.8], [-11.7, 28.8]]: box(Vector3(0.15, 3.0, 0.15), p[0], p[1], 6.5, b.mat("steel", 1.0), false)
	ramp(-9.5, 36.0, 180.0, 5.0, 9.0, 2.0, b.mat("grate", 2.0))
	box(Vector3(2.0, 0.2, 3.0), -10.5, 27.5, 4.9, b.mat("grate", 2.0))
	piece("ph:metal_office_desk", -15.5, 27.5, 90, 5.0)
	intel(0, -15.4, 27.5, 90, 5.85)
	camera(-13.0, 23.4, 8.5, 180, 40, 10.0, 34.0, true)
	label("NORTHGATE · TOWER 2", -11.4, 26.0, 3.5, 90, 56, Color(1.0, 0.85, 0.4))
	note("Tower: searchlight, marksman, intel", -14, 30)
	# snowcats
	for p in [[-4.0, 10.0, 15.0], [6.0, 18.0, -10.0], [-5.0, 30.0, 175.0], [7.0, 38.0, 5.0]]:
		cover("ph:covered_car", p[0], p[1], p[2])
		box(Vector3(2.4, 0.4, 4.6), p[0], p[1], 0.2, Mats.flat(Color(0.15, 0.15, 0.15), 0.9), false, p[2])
	for p2 in [[0.0, 22.0], [-2.0, 40.0], [12.0, 8.0]]: cover("ph:concrete_road_barrier", p2[0], p2[1], 90)
	# east sheds
	for d in [14.0, 30.0]:
		box(Vector3(4.0, 3.0, 6.0), 15.8, d, 1.5, b.mat("metal", 2.0, Color(0.62, 0.64, 0.67)))
		cover("ph:portable_generator", 13.0, d + 1.0, 270)
		box(Vector3(0.3, 0.3, 0.3), 13.7, d - 3.0, 2.8, Mats.glow(Color(1.0, 0.7, 0.3), 3.0), false)
		cover_pt(12.8, d - 2.0)
	for p3 in [[3.0, 44.0], [-12.0, 44.0]]:
		piece("ph:street_lamp_01", p3[0], p3[1], 180)
		lamp(p3[0], p3[1] - 0.3, 7.0, 8.0, 70, Color(1.0, 0.85, 0.6), "")
	dark(-10, 0, 10, 16)
	fill(0, 24, 9.0, Color(0.55, 0.65, 0.85), 0.35, 40.0)
	terminal(10.0, 46.0, 180)
	guard(-14.5, 26.0, 90, [], "marksman", 0, 5.15)
	guard(-8.0, 6.0, 0, [[-8, 6, 3, 90], [-8, 40, 3, 90]])
	guard(10.0, 40.0, 180, [[10, 40, 3, 270], [10, 10, 3, 270]])
	guard(1.0, 30.0, 180, [], "css", 1)
	guard(13.0, 22.0, 270, [], "heavy", 2)
	for p in [[-6, 46], [6, 46], [0, 45], [14, 44], [-12, 40]]: spawn(p[0], p[1])
