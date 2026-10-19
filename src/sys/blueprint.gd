class_name Blueprint
extends Control
## Overhead plan of a sector for level design reviews: the real geometry rendered from above with the
## ceiling cut away, overlaid with the gameplay layer — guard posts and routes, sight ranges, cameras,
## shadows, intel, uplink, spawns, cover and designer notes.

var cam: Camera3D
var room: Room
var title := ""

const RED := Color(1.0, 0.28, 0.22)
const GOLD := Color(1.0, 0.8, 0.3)
const GREEN := Color(0.35, 1.0, 0.55)
const BLUE := Color(0.3, 0.55, 1.0)
const CYAN := Color(0.4, 0.95, 1.0)
const ORANGE := Color(1.0, 0.6, 0.15)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _s(p: Vector3) -> Vector2: return cam.unproject_position(p)

func _px_per_m() -> float: return (_s(Vector3(1, 0, 0)) - _s(Vector3(0, 0, 0))).length()

func _draw() -> void:
	if cam == null or room == null: return
	var font := load("res://assets/fonts/IBMPlexMono-Medium.ttf") as Font
	var ppm := _px_per_m()
	var hw := room.W * 0.5
	# 4 m grid with metre labels along the edge
	var gx := -hw
	while gx <= hw + 0.01:
		draw_line(_s(Vector3(gx, 0, room.z0)), _s(Vector3(gx, 0, room.z1)), Color(1, 1, 1, 0.07), 1.0)
		gx += 4.0
	var gd := 0.0
	while gd <= room.D + 0.01:
		var z := room.z0 - gd
		draw_line(_s(Vector3(-hw, 0, z)), _s(Vector3(hw, 0, z)), Color(1, 1, 1, 0.07), 1.0)
		draw_string(font, _s(Vector3(-hw, 0, z)) + Vector2(-34, 4), "%d" % int(gd), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.5))
		gd += 4.0
	# dark zones
	for z in room.dark_zones:
		var rr: Rect2 = z
		var a := _s(Vector3(rr.position.x, 0, rr.position.y)); var e := _s(Vector3(rr.end.x, 0, rr.end.y))
		var rect := Rect2(Vector2(minf(a.x, e.x), minf(a.y, e.y)), (e - a).abs())
		draw_rect(rect, Color(0.1, 0.2, 0.9, 0.22))
		draw_rect(rect, Color(0.3, 0.45, 1.0, 0.6), false, 1.5)
	# guards: posts, facing, crouched sight range, routes
	var gi := 0
	for g in room.guards:
		gi += 1
		var p: Vector3 = g["pos"]
		var yaw := deg_to_rad(float(g["yaw"]))
		var fwd := Vector3(sin(yaw), 0, -cos(yaw))
		_cone(p, fwd, 58.0, 13.0 * ppm, Color(1, 0.2, 0.15, 0.13))
		var pts: Array = g["patrol"]
		if not pts.is_empty():
			var prev: Vector3 = p
			for k in pts.size() + 1:
				var q: Vector3 = pts[k % pts.size()]
				_dashed(_s(prev), _s(q), RED, 2.0)
				prev = q
			for k in pts.size():
				var q2: Vector3 = pts[k]
				draw_circle(_s(q2), 4.0, RED)
				var w := float(g["waits"][k]) if k < g["waits"].size() else 0.0
				var lk = g["looks"][k] if k < g["looks"].size() else null
				if lk != null:
					var ly := deg_to_rad(float(lk))
					draw_line(_s(q2), _s(q2 + Vector3(sin(ly), 0, -cos(ly)) * 2.0), RED, 2.0)
				if w > 0.0: draw_string(font, _s(q2) + Vector2(6, -6), "%ds" % int(w), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, RED)
		var tier := int(g.get("tier", 0))
		draw_circle(_s(p), 7.0, [RED, Color(1.0, 0.55, 0.3), Color(0.8, 0.3, 1.0)][tier])
		draw_line(_s(p), _s(p + fwd * 1.6), Color.WHITE, 2.5)
		draw_string(font, _s(p) + Vector2(9, 14), "G%d%s" % [gi, ["", " (reg+)", " (vet)"][tier]], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	if room.guards.is_empty():
		for e in room.enemies:
			if is_instance_valid(e): draw_circle(_s(e.global_position), 6.0, RED)
	# cameras / searchlights
	for c in room.cams:
		var cp: Vector3 = c.global_position
		var col := Color(1, 0.95, 0.7, 0.16) if c.searchlight else Color(1, 0.55, 0.1, 0.16)
		for sgn in [-1.0, 0.0, 1.0]:
			var a := deg_to_rad(c.base_yaw + sgn * c.sweep)
			_cone(cp, Vector3(sin(a), 0, -cos(a)), c.half_angle, c.rng_m * ppm * 0.9, col)
		draw_circle(_s(cp), 6.0, ORANGE)
		draw_string(font, _s(cp) + Vector2(8, -8), "LIGHT" if c.searchlight else "CAM", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ORANGE)
	for cpt in room.cover_points: draw_circle(_s(cpt), 2.5, Color(CYAN, 0.7))
	for sp in room.spawn_points:
		var s2 := _s(sp)
		draw_line(s2 + Vector2(-5, -5), s2 + Vector2(5, 5), Color(1, 0.4, 0.4, 0.9), 2.0); draw_line(s2 + Vector2(-5, 5), s2 + Vector2(5, -5), Color(1, 0.4, 0.4, 0.9), 2.0)
	for it in room.intel:
		if not is_instance_valid(it): continue
		var s3 := _s(it.global_position)
		draw_rect(Rect2(s3 - Vector2(7, 7), Vector2(14, 14)), GOLD)
		draw_string(font, s3 + Vector2(10, 5), "INTEL %d" % (int(it.get_meta("k")) + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, GOLD)
	if room.terminal:
		var s4 := _s(room.terminal.global_position)
		draw_rect(Rect2(s4 - Vector2(8, 8), Vector2(16, 16)), GREEN)
		draw_string(font, s4 + Vector2(11, 5), "UPLINK", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, GREEN)
	_arrow(_s(Vector3(0, 0, room.z0 + 2.0)), _s(Vector3(0, 0, room.z0 - 1.0)), GREEN, "ENTRY")
	_arrow(_s(Vector3(0, 0, room.z1 + 1.0)), _s(Vector3(0, 0, room.z1 - 2.0)), Color(1, 1, 1), "EXIT")
	if room.sector:
		for n in room.sector.notes:
			var s5 := _s(n[1])
			draw_circle(s5, 3.0, Color.WHITE)
			draw_string(font, s5 + Vector2(6, 4), String(n[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.92))
	draw_rect(Rect2(0, 0, size.x, 34), Color(0, 0, 0, 0.7))
	draw_string(font, Vector2(14, 23), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	var lg := [[RED, "guard · route · crouched sight 13 m"], [ORANGE, "camera / searchlight sweep"], [BLUE, "shadow (seen only up close)"], [GOLD, "intel"], [GREEN, "uplink"], [CYAN, "cover"], [Color(1, 0.4, 0.4), "reinforcement spawn"]]
	var lx := 14.0
	var ly2 := size.y - 14.0
	draw_rect(Rect2(0, size.y - 32, size.x, 32), Color(0, 0, 0, 0.7))
	for l in lg:
		draw_circle(Vector2(lx + 5, ly2 - 4), 5.0, l[0])
		draw_string(font, Vector2(lx + 14, ly2), l[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.85))
		lx += 22.0 + font.get_string_size(l[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 14.0

func _cone(p: Vector3, fwd: Vector3, half_deg: float, rad_px: float, col: Color) -> void:
	var c := _s(p)
	var f2 := (_s(p + fwd) - c).normalized()
	var a0 := f2.angle()
	var pts := PackedVector2Array([c])
	for i in 17:
		var a := a0 + deg_to_rad(-half_deg + 2.0 * half_deg * i / 16.0)
		pts.append(c + Vector2(cos(a), sin(a)) * rad_px)
	draw_colored_polygon(pts, col)

func _dashed(a: Vector2, e: Vector2, col: Color, w: float) -> void:
	var L := (e - a).length(); var n := int(L / 10.0)
	for i in n:
		if i % 2 == 0: draw_line(a.lerp(e, i / float(n)), a.lerp(e, (i + 1) / float(n)), col, w)

func _arrow(a: Vector2, e: Vector2, col: Color, t: String) -> void:
	draw_line(a, e, col, 3.0)
	var d := (e - a).normalized(); var nn := Vector2(-d.y, d.x)
	draw_colored_polygon(PackedVector2Array([e + d * 8, e - d * 4 + nn * 7, e - d * 4 - nn * 7]), col)
	var font := load("res://assets/fonts/IBMPlexMono-Medium.ttf") as Font
	draw_string(font, a + nn * 12 + Vector2(0, 4), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
