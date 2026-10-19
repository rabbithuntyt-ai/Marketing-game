extends Sector
## M3 · Sector 5 · CRANE CONTROL — defend the console while Marr pulls Meridian's shipping manifests.
## Read: a glass-walled control room with the storm outside. The console sits in the centre with
## banks of crane-operator desks around it; corner pods give fallback cover. Attackers come through
## both doors and the broken glass on the east side.

func dims() -> Vector3: return Vector3(28, 6, 32)

func build() -> void:
	strategy_wall(-13.3, 26.0, 90, 2.6)
	floor_rect(-14, 0, 14, 32, "q:Platform_Squares")
	ceiling(-14, 0, 14, 32, 5.0)
	wall(-14, 0, 14, 0, Vector2(0, 5), "WWWDWWW", "WallAstra", "TopWindow")
	wall(-14, 32, 14, 32, Vector2(0, 26), "WWWDWWW", "WallAstra", "TopWindow")
	wall(-14, 0, -14, 32, Vector2(0, 16), "GGGGGGGG", "WallAstra", "TopWindow")
	wall(14, 0, 14, 32, Vector2(0, 16), "GGGBBGGG", "WallAstra", "TopWindow")
	anchor("console", P(0, 16))
	note("Console: hold here", 0, 16)
	for a in [0.0, 90.0, 180.0, 270.0]:
		var ra := deg_to_rad(a)
		desk(sin(ra) * 4.0, 16.0 + cos(ra) * 4.0, a, "monitor", true)
	for p in [[-8.0, 10.0, 90.0], [-8.0, 22.0, 90.0], [8.0, 10.0, 270.0], [8.0, 22.0, 270.0]]:
		box(Vector3(1.0, 1.0, 4.0), p[0], p[1], 0.5, b.mat("gunmetal", 1.0), true)
		box(Vector3(1.0, 0.4, 3.6), p[0], p[1], 1.2, Mats.glow(Color(0.25, 0.6, 1.0), 1.0), false)
		cover_pt(p[0] + (1.2 if p[0] > 0 else -1.2), p[1])
	for p in [[-11.0, 4.0, 0], [11.0, 4.0, 1], [-11.0, 28.0, 1], [11.0, 28.0, 0]]: crates(p[0], p[1], 0.0, p[2])
	label("STS CRANE CONTROL · BERTH 9", 0, 31.8, 4.2, 180, 54, Color(0.6, 0.85, 1.0))
	intel(0, -11.0, 28.0, 0, 0.98)
	ceiling_lights(-12, 2, 12, 30, 5.0, 2, 3, 6.0, Color(0.9, 0.95, 1.0))
	fill(0, 16, 4.0, Color(0.45, 0.55, 0.75), 0.4, 22.0)
	for p in [[-6, 31], [6, 31], [0, 31], [-6, 1], [6, 1], [13, 15], [13, 18]]: spawn(p[0], p[1])
