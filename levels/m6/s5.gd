extends Sector
## M6 · Sector 6 · POSITIONING WING — the brand positioning team works on a giant map painted on
## the floor: PRICE runs left to right, VALUE runs front to back, and brand pillars stand where each
## competitor sits. West: glass offices. The pillars are cover; the map is a lesson you walk on.

func dims() -> Vector3: return Vector3(36, 6, 40)

func build() -> void:
	strategy_wall(17.3, 34.0, 270, 2.8)
	floor_rect(-18, 0, 18, 40, "", 0.0, Mats.flat(Color(0.88, 0.88, 0.86), 0.4))
	ceiling(-18, 0, 18, 40, 5.5)
	wall(-18, 0, 18, 0, Vector2(0, 5), "WWWWDWWWW", "WallAstra", "TopPlastic")
	wall(-18, 40, 18, 40, Vector2(0, 30), "WWWWDWWWW", "WallAstra", "TopPlastic")
	wall(-18, 0, -18, 40, Vector2(0, 20), "", "WallAstra", "TopPlastic")
	wall(18, 0, 18, 40, Vector2(0, 20), "GGGGGGGGGG", "WallAstra", "TopPlastic")
	# perceptual map axes
	paint(-6.0, 20.0, 16.0, 20.0, Color(0.15, 0.15, 0.18), 0.25)
	paint(5.0, 4.0, 5.0, 36.0, Color(0.15, 0.15, 0.18), 0.25)
	label("PRICE  →", 14.0, 20.6, 0.03, 0, 120, Color(0.15, 0.15, 0.18)).rotation.x = -PI * 0.5
	label("VALUE  ↑", 5.6, 35.0, 0.03, 0, 120, Color(0.15, 0.15, 0.18)).rotation.x = -PI * 0.5
	var brands := [["CASTELLAN ASSURE", 12.0, 31.0, Color(1.0, 0.35, 0.3)], ["HALDANE", -1.0, 27.0, Color(0.3, 0.75, 1.0)], ["NORTHSTAR", 9.0, 12.0, Color(1.0, 0.75, 0.3)], ["BUDGETLINE", -2.0, 8.0, Color(0.6, 0.6, 0.65)], ["VERIDIAN", 13.5, 22.5, Color(0.4, 1.0, 0.55)]]
	for br in brands:
		b.cyl(geo, 0.6, 3.2, P(br[1], br[2], 1.6), Mats.flat(Color(0.12, 0.12, 0.14), 0.4), Vector3.ZERO, true)
		b.cyl(geo, 0.62, 0.15, P(br[1], br[2], 2.6), Mats.glow(br[3], 3.0))
		label(String(br[0]), br[1], br[2] - 0.62, 2.2, 180, 30, br[3])
		cover_pt(br[1], br[2] - 1.3); cover_pt(br[1], br[2] + 1.3)
	# west offices
	for k in 4:
		var d0 := 2.0 + k * 9.0
		glass_room(-17.6, d0, -9.0, d0 + 8.0, "e", 0.5)
		desk(-14.0, d0 + 4.0, 90, "monitor" if k % 2 == 0 else "laptop")
		piece("ph:drawer_cabinet", -17.2, d0 + 7.0, 90)
	label("BRAND POSITIONING", -9.0, 21.0, 2.6, 270, 40, Color(0.2, 0.2, 0.25))
	intel(0, -14.0, 24.0, 90, 0.79)
	for p in [[-4.0, 34.0], [0.0, 14.5]]: desk(p[0], p[1], 180, "monitor")
	ceiling_lights(-18, 0, 18, 40, 5.5, 3, 4, 5.5, Color(0.95, 0.97, 1.0))
	terminal(-6.0, 38.5, 180)
	guard(5.0, 6.0, 0, [[5, 6, 2, 90], [5, 34, 2, 270]])
	guard(-6.0, 20.0, 90, [[-6, 20, 2, 90], [15, 20, 2, 270]])
	guard(-13.0, 33.0, 90)
	guard(12.0, 34.0, 200, [], "heavy", 1)
	guard(-4.0, 30.0, 150, [], "css", 2)
	for p in [[-6, 38], [6, 38], [14, 38], [-6, 2], [14, 4]]: spawn(p[0], p[1])
