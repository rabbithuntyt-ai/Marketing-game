class_name BriefVis
extends Control
## Briefing visuals: tactical maps, subject dossiers (live 3D portrait) and documents, drawn procedurally.

var vis := ""
var t := 0.0
var accent := Color(1, 0.7, 0.3)
var trans := 1.0
var svc: SubViewportContainer
var sv: SubViewport
var actor: Humanoid
var pcam: Camera3D
var head_mesh: Node3D
var cur_variant := ""

const CITIES := {
	"hamilton": ["HAMILTON, ON", 43.26, -79.87], "kingsway": ["KINGSWAY BUNKER · OTTAWA", 45.35, -75.75], "ottawa": ["OTTAWA, ON", 45.42, -75.69],
	"halifax": ["HALIFAX, NS", 44.65, -63.57], "port": ["SOUTH END CONTAINER TERMINAL · HALIFAX", 44.63, -63.56], "storm": ["ATLANTIC STORM CELL", 44.2, -62.4],
	"datacentre": ["CASTELLAN INSIGHT DATA CENTRE · MIRABEL", 45.67, -74.04], "calgary": ["CALGARY, AB", 51.05, -114.07], "northgate": ["NORTHGATE CAMPUS · ROCKY VIEW COUNTY, AB", 51.25, -114.0],
	"toronto": ["TORONTO, ON", 43.65, -79.38], "lobby": ["CASTELLAN TOWER · LOBBY", 43.648, -79.38], "tower": ["CASTELLAN TOWER · TORONTO", 43.648, -79.381],
	"tower_top": ["CASTELLAN TOWER · FLOOR 60", 43.648, -79.381], "mirabel": ["MIRABEL ARRAY, QC", 45.68, -74.03],
}
const DOSSIER := {
	"voss": ["director:voss", "ADRIAN VOSS", "Chief Executive Officer, Castellan Group", ["Architect of Project Meridian", "Former brand strategist", "No criminal record"], "PRIMARY"],
	"kessler": ["kessler", "GRANT KESSLER", "Director, Castellan Security Services", ["Ex-JTF2, dishonourably discharged", "Commands CSS field teams", "Armed and dangerous"], "HIGH"],
	"hale": ["hale", "MAJ. ELIAS HALE", "Commander, LEDGER Task Force", ["22 years service, 3 tours", "Recruited Wren and Ruiz", "Clearance: Top Secret"], "—"],
	"ruiz": ["ally", "CPL. DANI RUIZ", "LEDGER · Breacher", ["Demolitions specialist", "Talks too much", "Never misses a door"], "—"],
	"wren": ["wren", "SGT. WREN", "LEDGER · Operator (you)", ["Marksman, close-quarters", "Former analyst, Competition Bureau", "Reads the room before the map"], "—"],
	"ostrowski": ["director:director_2", "PAUL OSTROWSKI", "Director, Castellan Distribution", ["Ran Meridian logistics", "Wrote the internal handbook", "Cooperative under pressure"], "LOW"],
	"courier": ["courier", "THE COURIER", "Castellan Security contractor", ["Carries Phase II plans on foot", "Counter-surveillance trained", "Do not engage"], "MEDIUM"],
	"squad": ["css", "CASTELLAN SECURITY SERVICES", "Private security division · 'CSS'", ["Military surplus kit", "Marksmen and heavy units", "Coordinated by radio"], "HIGH"],
}
const DOCS := {
	"access": "BUILDING ACCESS LOG", "assure": "CASTELLAN ASSURE · LAUNCH DECK", "bcg": "PORTFOLIO REVIEW · GROWTH-SHARE", "blackbox": "THE BUYER'S BLACK BOX",
	"canary": "CANARY TRAP · METHOD", "environment": "MERIDIAN · ENVIRONMENT SCAN", "hale": "PERSONNEL FILE · HALE, E.", "logs": "CSS MESSAGE LOGS",
	"meridian": "PROJECT MERIDIAN · PHASE I", "meridian2": "PROJECT MERIDIAN · PHASE II", "portfolio": "CASTELLAN BUSINESS PORTFOLIO", "recall": "LEDGER RECALL PROTOCOL",
	"schedule": "LAUNCH SCHEDULE · T-48H", "terminals": "BOARDROOM TERMINAL NETWORK", "vault": "BRAND VAULT · ACCESS", "vote": "BOARD RESOLUTION 31-04",
}

func _ready() -> void:
	clip_contents = true
	svc = SubViewportContainer.new(); svc.stretch = true; add_child(svc); svc.visible = false
	sv = SubViewport.new(); sv.own_world_3d = true; sv.transparent_bg = true; sv.msaa_3d = Viewport.MSAA_4X; svc.add_child(sv)
	var env := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR; e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.25, 0.27, 0.3); e.ambient_light_energy = 0.4
	e.tonemap_mode = Environment.TONE_MAPPER_AGX; env.environment = e; sv.add_child(env)
	var key := SpotLight3D.new(); key.position = Vector3(1.6, 2.6, 1.8); key.light_energy = 6.0; key.spot_range = 8; key.spot_angle = 35; key.shadow_enabled = true; sv.add_child(key)
	key.look_at_from_position(key.position, Vector3(0, 1.4, 0))
	var rim := SpotLight3D.new(); rim.position = Vector3(-1.4, 2.4, -1.6); rim.light_color = Color(1.0, 0.55, 0.3); rim.light_energy = 9.0; rim.spot_range = 8; rim.spot_angle = 40; sv.add_child(rim)
	rim.look_at_from_position(rim.position, Vector3(0, 1.4, 0)); rim.name = "Rim"
	pcam = Camera3D.new(); pcam.fov = 30; sv.add_child(pcam); pcam.current = true

func set_vis(v: String, acc: Color) -> void:
	if v == vis: return
	vis = v; accent = acc; trans = 0.0
	var kind := v.split(":")[0]
	svc.visible = kind == "dossier"
	if kind == "dossier":
		var d: Array = DOSSIER.get(v.split(":")[1], DOSSIER["squad"])
		_portrait(d[0])
		(sv.get_node("Rim") as SpotLight3D).light_color = accent
	Audio.play2d("kenney_weapon_change", -16.0, 0.2, "UI")

func _portrait(variant: String) -> void:
	if variant == cur_variant: return
	cur_variant = variant
	if actor and is_instance_valid(actor): actor.queue_free()
	actor = Humanoid.new(); actor.team = "neutral"; sv.add_child(actor); actor.setup(variant)
	actor.set_physics_process(false)
	if actor.variant in ["director", "civilian", "courier"]: actor.hide_weapon()
	actor.play("Idle" if actor.variant in ["director", "civilian", "courier"] else "soldier_idle")
	actor.rotation.y = 0.0

func _process(dt: float) -> void:
	t += dt; trans = minf(1.0, trans + dt * 2.2)
	if svc.visible:
		svc.position = Vector2(30, 30); svc.size = Vector2(size.x * 0.42, size.y - 60)
		var a := sin(t * 0.25) * 0.35 + 0.25
		pcam.position = Vector3(sin(a) * 2.3, 1.55, cos(a) * 2.3)
		pcam.look_at(Vector3(0, 1.42, 0))
	queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0.03, 0.04, 0.045))
	var kind := vis.split(":")[0]
	var arg := vis.split(":")[1] if vis.contains(":") else ""
	match kind:
		"map": _draw_map(arg)
		"dossier": _draw_dossier(arg)
		"doc": _draw_doc(arg)
	# scanlines + frame
	for y in range(0, int(size.y), 4): draw_line(Vector2(0, y), Vector2(size.x, y), Color(0, 0, 0, 0.12), 1.0)
	draw_rect(r, Color(1, 1, 1, 0.14), false, 1.0)
	for c in [Vector2(0, 0), Vector2(size.x, 0), Vector2(0, size.y), size]:
		var sx := 1.0 if c.x == 0 else -1.0; var sy := 1.0 if c.y == 0 else -1.0
		draw_line(c, c + Vector2(26 * sx, 0), accent, 2.0); draw_line(c, c + Vector2(0, 26 * sy), accent, 2.0)
	if trans < 1.0:
		draw_rect(r, Color(0, 0, 0, 1.0 - trans))
		var gy := size.y * fmod(trans * 3.0, 1.0)
		draw_rect(Rect2(0, gy, size.x, 3), Color(accent.r, accent.g, accent.b, 0.6 * (1.0 - trans)))

func _f(n := "IBMPlexMono-Medium") -> Font: return UIKit.font(n)

func _project(lat: float, lon: float, c_lat: float, c_lon: float, scale: float) -> Vector2:
	return size * 0.5 + Vector2((lon - c_lon) * cos(deg_to_rad(c_lat)), -(lat - c_lat)) * scale

func _draw_map(place: String) -> void:
	var grid := Color(accent.r, accent.g, accent.b, 0.08)
	var c := size * 0.5
	if place == "canada":
		var sc := size.x / 70.0
		for lat in range(40, 62, 2): var p1 := _project(lat, -125, 49, -95, sc); draw_line(Vector2(0, p1.y), Vector2(size.x, p1.y), grid, 1.0)
		for lon in range(-130, -55, 5): var p2 := _project(49, lon, 49, -95, sc); draw_line(Vector2(p2.x, 0), Vector2(p2.x, size.y), grid, 1.0)
		var route := ["hamilton", "ottawa", "halifax", "mirabel", "toronto", "calgary"]
		var pts: Array = []
		for k in route:
			var cd: Array = CITIES[k]; pts.append(_project(cd[1], cd[2], 49, -95, sc))
		var shown := int(clampf(t * 1.6, 0, pts.size()))
		for i in range(1, shown):
			_dash(pts[i - 1], pts[i], Color(accent.r, accent.g, accent.b, 0.5))
		for i in shown:
			var p: Vector2 = pts[i]
			draw_circle(p, 5.0, accent); draw_arc(p, 9.0 + fmod(t * 8.0 + i * 3.0, 14.0), 0, TAU, 32, Color(accent.r, accent.g, accent.b, 0.5), 1.0)
			draw_string(_f(), p + Vector2(12, -8), String(CITIES[route[i]][0]).split(",")[0].split(" ·")[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.8))
		draw_string(_f("Rajdhani-Bold"), Vector2(34, 60), "CASTELLAN GROUP · NATIONAL FOOTPRINT", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 1, 1, 0.9))
		draw_string(_f(), Vector2(34, 86), "Grocery · Pharmacy · Distribution · Data", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.5))
		return
	var cd2: Array = CITIES.get(place, ["UNKNOWN", 45.0, -75.0])
	# pseudo terrain contours seeded by place name
	var seed := place.hash()
	for k in 9:
		var rr := 60.0 + k * 46.0
		var off := Vector2(sin(seed + k) * 80.0, cos(seed * 0.7 + k) * 50.0)
		var pts2 := PackedVector2Array()
		for i in 49:
			var a := i * TAU / 48.0
			var wob := 1.0 + 0.18 * sin(a * 3.0 + seed + k) + 0.08 * sin(a * 7.0 + k * 1.7)
			pts2.append(c + off + Vector2(cos(a), sin(a)) * rr * wob)
		draw_polyline(pts2, Color(accent.r, accent.g, accent.b, 0.07 + 0.02 * (k % 3)), 1.0)
	for x in range(0, int(size.x), 60): draw_line(Vector2(x, 0), Vector2(x, size.y), grid, 1.0)
	for y in range(0, int(size.y), 60): draw_line(Vector2(0, y), Vector2(size.x, y), grid, 1.0)
	# street-ish blocks
	var rng := RandomNumberGenerator.new(); rng.seed = seed
	for i in 40:
		var p := Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		if p.distance_to(c) < 60: continue
		var s := Vector2(rng.randf_range(18, 70), rng.randf_range(12, 50))
		draw_rect(Rect2(p, s), Color(1, 1, 1, 0.035))
		draw_rect(Rect2(p, s), Color(1, 1, 1, 0.07), false, 1.0)
	# sweep
	var sw := t * 1.4
	for k in 24:
		var a2 := sw - k * 0.03
		draw_line(c, c + Vector2(cos(a2), sin(a2)) * size.length(), Color(accent.r, accent.g, accent.b, 0.08 * (1.0 - k / 24.0)), 2.0)
	# target
	var pulse := fmod(t, 1.6) / 1.6
	draw_arc(c, 18 + pulse * 70, 0, TAU, 48, Color(accent.r, accent.g, accent.b, 0.8 * (1.0 - pulse)), 2.0)
	draw_arc(c, 14, 0, TAU, 32, accent, 2.0)
	draw_line(c + Vector2(-34, 0), c + Vector2(-20, 0), accent, 2.0); draw_line(c + Vector2(20, 0), c + Vector2(34, 0), accent, 2.0)
	draw_line(c + Vector2(0, -34), c + Vector2(0, -20), accent, 2.0); draw_line(c + Vector2(0, 20), c + Vector2(0, 34), accent, 2.0)
	draw_string(_f("Rajdhani-Bold"), Vector2(34, 60), String(cd2[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1, 1, 1, 0.92))
	draw_string(_f(), Vector2(34, 88), "%.4f° N   %.4f° W" % [absf(cd2[1]), absf(cd2[2])], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.55))
	draw_string(_f(), Vector2(size.x - 260, size.y - 30), "SAT PASS %02d:%02d:%02d UTC" % [int(t / 3600) % 24, int(t / 60) % 60, int(t) % 60], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.4))

func _dash(a: Vector2, b: Vector2, col: Color) -> void:
	var n := int(a.distance_to(b) / 10.0)
	for i in range(0, n, 2):
		draw_line(a.lerp(b, float(i) / n), a.lerp(b, float(i + 1) / n), col, 1.5)

func _draw_dossier(who: String) -> void:
	var d: Array = DOSSIER.get(who, DOSSIER["squad"])
	var x := size.x * 0.46
	draw_rect(Rect2(30, 30, size.x * 0.42, size.y - 60), Color(0.06, 0.065, 0.07))
	draw_string(_f(), Vector2(x, 70), "SUBJECT FILE", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, accent)
	draw_string(_f("Rajdhani-Bold"), Vector2(x, 128), String(d[1]), HORIZONTAL_ALIGNMENT_LEFT, size.x - x - 30, 52, Color(1, 1, 1, 0.95))
	draw_string(_f("Barlow-Medium"), Vector2(x, 166), String(d[2]), HORIZONTAL_ALIGNMENT_LEFT, size.x - x - 30, 22, Color(1, 1, 1, 0.6))
	var y := 230.0
	for line in d[3]:
		var k := clampf(t * 2.0 - (y - 230.0) / 40.0, 0.0, 1.0)
		draw_rect(Rect2(x, y - 12, 6, 6), accent)
		draw_string(_f("Barlow-Medium"), Vector2(x + 20, y), String(line).substr(0, int(String(line).length() * k)), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.85))
		y += 44.0
	if String(d[4]) != "—":
		draw_string(_f(), Vector2(x, y + 30), "THREAT ASSESSMENT", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.45))
		draw_string(_f("Rajdhani-Bold"), Vector2(x, y + 70), String(d[4]), HORIZONTAL_ALIGNMENT_LEFT, -1, 38, UIKit.RED)
	# barcode
	var rng := RandomNumberGenerator.new(); rng.seed = who.hash()
	var bx := x
	for i in 50:
		var w := rng.randi_range(1, 4)
		if i % 2 == 0: draw_rect(Rect2(bx, size.y - 80, w, 36), Color(1, 1, 1, 0.5))
		bx += w + 1
	draw_string(_f(), Vector2(x, size.y - 30), "LDG-%06d" % (absi(who.hash()) % 1000000), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.4))

func _draw_doc(id: String) -> void:
	var title: String = DOCS.get(id, id.to_upper())
	var pw := size.x * 0.56; var ph := size.y * 0.86
	var p := Vector2(size.x * 0.5 - pw * 0.5, size.y * 0.07)
	draw_set_transform(size * 0.5, -0.025 + sin(t * 0.3) * 0.004, Vector2.ONE)
	var o := p - size * 0.5
	draw_rect(Rect2(o + Vector2(10, 14), Vector2(pw, ph)), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(o, Vector2(pw, ph)), Color(0.9, 0.89, 0.85))
	draw_string(_f(), o + Vector2(36, 44), "CASTELLAN GROUP  ·  CONFIDENTIAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.55, 0.12, 0.1))
	draw_string(_f("Rajdhani-Bold"), o + Vector2(36, 92), title, HORIZONTAL_ALIGNMENT_LEFT, pw - 72, 32, Color(0.08, 0.08, 0.09))
	draw_line(o + Vector2(36, 108), o + Vector2(pw - 36, 108), Color(0, 0, 0, 0.3), 1.0)
	var rng := RandomNumberGenerator.new(); rng.seed = id.hash()
	if id == "bcg" or id == "portfolio":
		var gx := o + Vector2(80, 150); var gs := Vector2(pw - 160, ph - 260)
		draw_rect(Rect2(gx, gs), Color(0, 0, 0, 0.04)); draw_rect(Rect2(gx, gs), Color(0, 0, 0, 0.5), false, 1.5)
		draw_line(gx + Vector2(gs.x * 0.5, 0), gx + Vector2(gs.x * 0.5, gs.y), Color(0, 0, 0, 0.5), 1.0)
		draw_line(gx + Vector2(0, gs.y * 0.5), gx + Vector2(gs.x, gs.y * 0.5), Color(0, 0, 0, 0.5), 1.0)
		var lab := [["STARS", 0, 0], ["QUESTION MARKS", 1, 0], ["CASH COWS", 0, 1], ["DOGS", 1, 1]]
		for l in lab:
			draw_string(_f("Rajdhani-Bold"), gx + Vector2(gs.x * 0.5 * l[1] + 14, gs.y * 0.5 * l[2] + 30), l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.15, 0.15, 0.17))
		for i in 7:
			var bp := gx + Vector2(rng.randf_range(0.08, 0.92) * gs.x, rng.randf_range(0.12, 0.92) * gs.y)
			var rad := rng.randf_range(8, 24) * minf(1.0, t * 1.5)
			draw_circle(bp, rad, Color(0.55, 0.12, 0.1, 0.55))
		draw_string(_f(), gx + Vector2(0, gs.y + 26), "← RELATIVE MARKET SHARE        MARKET GROWTH RATE ↑", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.3, 0.3, 0.32))
	else:
		var y := 150.0
		var shown := t * 9.0
		var n := 0
		while y < ph - 60:
			var w := rng.randf_range(0.5, 1.0) * (pw - 72)
			if n < shown:
				if rng.randf() < 0.22: draw_rect(Rect2(o + Vector2(36, y - 12), Vector2(w * 0.6, 16)), Color(0.05, 0.05, 0.06))
				else: draw_rect(Rect2(o + Vector2(36, y - 8), Vector2(w, 7)), Color(0, 0, 0, 0.16))
			y += 28.0 if rng.randf() > 0.12 else 50.0
			n += 1
	# stamp
	var sa := clampf(t * 1.2 - 0.8, 0.0, 1.0)
	if sa > 0.0:
		draw_set_transform(size * 0.5 + Vector2(pw * 0.22, ph * 0.3), -0.35, Vector2.ONE * lerpf(1.6, 1.0, sa))
		draw_rect(Rect2(-130, -34, 260, 68), Color(0.7, 0.1, 0.08, 0.75 * sa), false, 4.0)
		draw_string(_f("Rajdhani-Bold"), Vector2(-112, 16), "EVIDENCE", HORIZONTAL_ALIGNMENT_LEFT, -1, 46, Color(0.7, 0.1, 0.08, 0.75 * sa))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
