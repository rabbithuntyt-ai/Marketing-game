extends Sector
## M4 · Sector 3 · ARCHIVE — the research division's paper archive, two floors below the servers.
## Read: tall shelving makes a grid of narrow aisles; sight lines are short and broken, so this is the
## sneakiest room in the mission. The centre aisle is the obvious line and the camera at the far wall
## covers it. Side aisles are dark. Cross aisles at 12 m and 24 m are where patrols meet you.
## Calls: the ROUTING CONSOLES in the far east bay — Marr's research-process questions are answered by
## walking to the console that carries your answer (wrong route = alarm).

func dims() -> Vector3: return Vector3(28, 6, 36)

func build() -> void:
	strategy_wall(13.3, 26.0, 270, 2.8)
	floor_rect(-14, 0, 14, 36, "q:Platform_Simple2")
	ceiling(-14, 0, 14, 36, 5.0)
	wall(-14, 0, 14, 0, Vector2(0, 5), "WWWDWWW", "WallAstra", "TopSimple")
	wall(-14, 36, 14, 36, Vector2(0, 30), "WWWDWWW", "WallAstra", "TopSimple")
	wall(-14, 0, -14, 36, Vector2(0, 18), "", "WallAstra", "TopSimple")
	wall(14, 0, 14, 36, Vector2(0, 18), "", "WallAstra", "TopSimple")
	for x in [-11.0, -7.5, -4.0, 4.0, 7.5, 11.0]:
		for d0 in [2.5, 14.0]:
			for k in 4:
				shelf(x, d0 + 1.2 + k * 2.4, 90, int(abs(x) + k))
			r.cover_points.append(P(x + 0.9, d0 + 4.8)); r.cover_points.append(P(x - 0.9, d0 + 4.8))
	for x in [-11.0, -7.5]:
		for k in 3: piece("ph:drawer_cabinet", x, 26.0 + k * 1.1, 90)
	glass_room(-13.6, 27.5, -5.5, 35.6, "e", 0.5)
	piece("ph:dining_table", -9.6, 31.5, 0)
	for p in [[-10.6, 30.4, 180], [-8.6, 30.4, 180], [-10.6, 32.6, 0], [-8.6, 32.6, 0]]: piece("ph:dining_chair_02", p[0], p[1], p[2], 0.0, "none")
	piece("ph:office_notepads", -9.6, 31.5, 10, 0.78, "none")
	piece("ph:desk_lamp_arm_01", -9.0, 31.2, 200, 0.78, "none")
	piece("ph:Shelf_01", -13.2, 33.5, 90)
	label("RESEARCH DIVISION · STUDY ARCHIVE", 0, 35.8, 3.6, 180, 64, Color(0.9, 0.85, 0.65))
	call_panels([8.5, 35.4, 180], [[5.0, 31.0, 180], [7.4, 31.0, 180], [9.8, 31.0, 180], [12.2, 31.0, 180]])
	note("Routing consoles: walk to your answer", 8.5, 29)
	piece("ph:industrial_storage_cart", 5.8, 13.0, 0)
	piece("ph:hand_truck", -5.8, 24.5, 30)
	piece("ph:WetFloorSign_01", 1.2, 18.5, 40)
	piece("ph:cardboard_box_01", -2.4, 26.0, 15)
	piece("ph:plastic_crate_02", 2.6, 9.0, 80)
	for d in [6.0, 12.5, 19.0, 24.5, 30.0]:
		piece("ph:hanging_industrial_lamp", 0.0, d, 0, 3.6, "none")
		lamp(0.0, d, 3.9, 5.0, 62.0, Color(1.0, 0.86, 0.62), "")
	for x2 in [-9.3, 9.3]:
		piece("ph:hanging_industrial_lamp", x2, 12.8, 0, 3.6, "none")
		lamp(x2, 12.8, 3.9, 3.5, 58.0, Color(1.0, 0.86, 0.62), "")
	fill(-9.6, 31.5, 2.6, Color(1.0, 0.9, 0.7), 0.8, 7.0)
	fill(8.5, 32.0, 2.6, Color(0.5, 0.8, 1.0), 0.7, 8.0)
	fill(0, 18, 4.0, Color(0.45, 0.5, 0.65), 0.25, 26.0)
	for x3 in [-9.25, -5.75, 5.75, 9.25]: dark(x3 - 1.2, 2.5, x3 + 1.2, 23.5)
	dark(-14, 2.5, -12, 25); dark(12, 2.5, 14, 25)
	camera(0.0, 35.4, 4.2, 180, 18, 7.0, 20.0)
	intel(0, 5.8, 13.0, 0, 0.9)
	guard(0.0, 30.0, 180, [[0, 30, 3, 180], [0, 8, 3, 0]])
	guard(-12.0, 12.6, 90, [[-12, 12.6, 3, 90], [12.5, 12.6, 3, 270]])
	guard(-8.0, 30.5, 90)
	guard(9.3, 24.0, 180, [[9.3, 24, 2, 270], [-9.3, 24, 2, 90]], "css", 1)
	guard(5.75, 6.0, 0, [], "css", 2)
	for p in [[-4, 33], [4, 33], [0, 33], [-12, 26], [12, 26]]: spawn(p[0], p[1])
