class_name Builder
extends RefCounted
## Procedural level builder: turns a mission's room list into lit, dressed, navigable sectors.

const WT := 0.6
const CORR := 10.0
const GAP := 4.0
const GH := 3.4

const THEMES := {
	"compound": {"wall": "techc", "upper": "rivet", "floor": "antislip", "ceil": "metal", "pillar": "pillar", "trim": "floor", "light": Color(1.0, 0.86, 0.66), "accent": Color(1.0, 0.64, 0.22),
		"cover": ["prop_cargobox1_a", "prop_cargobox2", "prop_barrier", "prop_cargobox5a", "prop_barrelcart", "prop_cargobox4", "prop_cargobox3"], "out_wall": "gunmetal"},
	"bunker": {"wall": "tech", "upper": "rivet", "floor": "floor", "ceil": "metal", "pillar": "steel", "trim": "antislip", "light": Color(0.82, 0.9, 1.0), "accent": Color(0.38, 0.72, 1.0),
		"cover": ["prop_cargobox3", "prop_cargobox2", "prop_barrier", "prop_gastriple", "prop_cargobox1_a", "prop_smallbox2"], "out_wall": "steel"},
	"port": {"wall": "gunmetal", "upper": "rivet", "floor": "antislip", "ceil": "steel", "pillar": "pillar", "trim": "grate", "light": Color(0.85, 0.95, 1.0), "accent": Color(0.3, 0.9, 0.78),
		"cover": ["prop_container2", "prop_container3", "prop_container4bare1", "prop_cargobox5a", "prop_barrelcart", "prop_cargolift", "prop_cargobox2"], "out_wall": "gunmetal"},
	"data": {"wall": "tech", "upper": "metal", "floor": "scifloor", "ceil": "metal", "pillar": "steel", "trim": "antislip", "light": Color(0.78, 0.82, 1.0), "accent": Color(0.62, 0.5, 1.0),
		"cover": ["prop_cargobox4", "prop_smallbox2", "prop_cargobox2", "prop_barrier", "prop_smallbox4"], "out_wall": "steel"},
	"mall": {"wall": "techc", "upper": "metal", "floor": "floor", "ceil": "metal", "pillar": "pillar", "trim": "scifloor", "light": Color(1.0, 0.94, 0.86), "accent": Color(1.0, 0.45, 0.72),
		"cover": ["prop_cargobox1_a", "prop_barrier", "prop_cargobox3", "prop_transitbarrierdirection", "prop_smallbox2"], "out_wall": "techc"},
	"array": {"wall": "steel", "upper": "rivet", "floor": "scifloor", "ceil": "steel", "pillar": "pillar", "trim": "grate", "light": Color(1.0, 0.9, 0.78), "accent": Color(1.0, 0.6, 0.22),
		"cover": ["prop_cargobox5a", "prop_reactorcylinder", "prop_barrier", "prop_cargobox2", "prop_gastriple"], "out_wall": "steel"},
	"vault": {"wall": "gunmetal", "upper": "tech", "floor": "MARBLE", "ceil": "metal", "pillar": "steel", "trim": "antislip", "light": Color(1.0, 0.93, 0.8), "accent": Color(0.95, 0.76, 0.3),
		"cover": ["prop_cargobox3", "prop_cargobox1_a", "prop_barrier", "prop_smallbox2", "prop_cargobox4"], "out_wall": "gunmetal"},
	"board": {"wall": "tech", "upper": "techc", "floor": "MARBLE", "ceil": "metal", "pillar": "pillar", "trim": "scifloor", "light": Color(0.95, 0.95, 1.0), "accent": Color(0.92, 0.9, 0.86),
		"cover": ["prop_cargobox1_a", "prop_barrier", "prop_cargobox3", "prop_smallbox2", "prop_cargobox2"], "out_wall": "tech"},
}

const SLOGANS := [["CASTELLAN", "Every customer, understood."], ["CASTELLAN", "We know what you need."], ["CASTELLAN Rx", "Your health. Our data."],
	["CASTELLANFRESH", "Feeding Canada since 1971."], ["CASTELLAN INSIGHT", "Data is the new shelf."], ["CASTELLAN", "Value, delivered."],
	["CASTELLAN ASSURE", "Coming soon. Never run out."], ["HEARTH&CO", "Home, for less."]]

var level: Node3D
var M: Dictionary
var th: Dictionary
var accent: Color
var rng := RandomNumberGenerator.new()
var quality := 1

func _init(lvl: Node3D, mission: Dictionary) -> void:
	level = lvl; M = mission; th = THEMES.get(mission["theme"], THEMES["compound"])
	accent = Color(mission["color"])
	quality = int(Game.settings["quality"])
	Props.init()

# ---------------------------------------------------------------- primitives
func mat(name: String, scale := 3.0, tint := Color.WHITE) -> Material:
	if name == "MARBLE": return Mats.city("T_MarbleFloor_BaseColor", "T_MarbleFloor_Normal", "T_MarbleFloor_ORM", 3.0, tint)
	if name == "CONCRETE": return Mats.city("T_Concrete_BaseColor", "T_Concrete_Normal", "T_Concrete_ORM", 4.0, tint)
	if name == "ASPHALT": return Mats.city("T_Concrete_Asphalt_BaseColor", "T_Concrete_Normal", "T_Concrete_ORM", 5.0, tint)
	return Mats.pbr(name, scale, tint)

func box(parent: Node3D, size: Vector3, pos: Vector3, m: Material, col := true, shadow := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = size; mi.mesh = bm; mi.material_override = m
	mi.position = pos; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	if col:
		var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = size; cs.shape = sh; b.add_child(cs); mi.add_child(b)
	return mi

func cyl(parent: Node3D, r: float, h: float, pos: Vector3, m: Material, rot := Vector3.ZERO, col := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = r; cm.bottom_radius = r; cm.height = h; cm.radial_segments = 14; mi.mesh = cm
	mi.material_override = m; mi.position = pos; mi.rotation = rot; parent.add_child(mi)
	if col:
		var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := CylinderShape3D.new(); sh.radius = r; sh.height = h; cs.shape = sh; b.add_child(cs); mi.add_child(b)
	return mi

func label(parent: Node3D, text: String, pos: Vector3, rot_y: float, size := 64, col := Color.WHITE, font := "Rajdhani-Bold", width := 0.0, align := HORIZONTAL_ALIGNMENT_LEFT, shaded := false) -> Label3D:
	var l := Label3D.new(); l.text = text; l.position = pos; l.rotation.y = rot_y; l.font_size = size; l.modulate = col
	l.font = load("res://assets/fonts/%s.ttf" % font); l.pixel_size = 0.004; l.outline_size = 0; l.horizontal_alignment = align
	l.double_sided = false; l.shaded = shaded
	if width > 0: l.width = width; l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not shaded: l.modulate = Color(col.r * 1.6, col.g * 1.6, col.b * 1.6, col.a)
	parent.add_child(l)
	return l

func spot(parent: Node3D, pos: Vector3, color: Color, energy: float, rng_m: float, angle: float, shadow: bool, dir := Vector3.DOWN) -> SpotLight3D:
	var s := SpotLight3D.new(); s.light_color = color; s.light_energy = energy; s.spot_range = rng_m; s.spot_angle = angle; s.spot_angle_attenuation = 0.8
	s.shadow_enabled = shadow; s.shadow_blur = 1.5; s.light_volumetric_fog_energy = 1.4; s.distance_fade_enabled = true; s.distance_fade_begin = 40.0; s.distance_fade_length = 12.0
	parent.add_child(s); s.position = pos
	var tgt := pos + dir
	if abs(dir.normalized().dot(Vector3.UP)) > 0.99: s.look_at_from_position(pos, tgt, Vector3.FORWARD)
	else: s.look_at_from_position(pos, tgt, Vector3.UP)
	return s

func omni(parent: Node3D, pos: Vector3, color: Color, energy: float, r: float, shadow := false) -> OmniLight3D:
	var o := OmniLight3D.new(); o.light_color = color; o.light_energy = energy; o.omni_range = r; o.shadow_enabled = shadow; o.position = pos
	o.distance_fade_enabled = true; o.distance_fade_begin = 35.0; o.distance_fade_length = 10.0; parent.add_child(o); return o

# ---------------------------------------------------------------- dimensions per kind
func dims(kind: String, outdoor: bool) -> Vector3:
	match kind:
		"boss", "holdout", "defend", "ambush": return Vector3(28, 8, 34)
		"range": return Vector3(20, 6, 32)
		"hvt": return Vector3(24, 9, 34)
		"plant": return Vector3(24, 7, 30)
		"tail": return Vector3(26, 9, 44)
		"stealth": return Vector3(26, 7, 34)
		"evidence": return Vector3(24, 6.5, 30)
		"sniper": return Vector3(44, 8, 78)
		"escape": return Vector3(14, 6, 56)
		"rescue": return Vector3(22, 5.5, 30)
	return Vector3(22, 7 if outdoor else 6.5, 28)

# ---------------------------------------------------------------- build
func build_all() -> Array:
	var rooms: Array = []
	var z := 0.0
	rng.seed = hash(M["id"])
	for ri in M["rooms"].size():
		var r := build_room(ri, M["rooms"][ri], z)
		rooms.append(r)
		z = r.cz1 - WT
	# end cap with extraction sign
	var last: Room = rooms[rooms.size() - 1]
	box(last, Vector3(4.4, 4, WT), Vector3(0, 2, last.cz1 - WT * 0.5), mat(th["wall"]))
	label(last, "EXTRACTION", Vector3(0, 3.0, last.cz1 + 0.02), 0, 80, Color(0.5, 1.0, 0.65), "Rajdhani-Bold", 0, HORIZONTAL_ALIGNMENT_CENTER)
	return rooms

func build_room(ri: int, data: Dictionary, z0: float) -> Room:
	var r := Room.new(); r.name = "Room%d" % ri
	r.ri = ri; r.data = data; r.kind = data.get("kind", "combat"); r.outdoor = data.get("outdoor", false)
	var d := dims(r.kind, r.outdoor)
	r.W = d.x; r.H = d.y; r.D = d.z; r.z0 = z0; r.z1 = z0 - r.D
	level.add_child(r)
	var nav := NavigationRegion3D.new(); nav.name = "Nav"; r.add_child(nav); r.nav = nav
	var geo := Node3D.new(); geo.name = "Geo"; nav.add_child(geo)
	var hw := r.W * 0.5; var cz := (r.z0 + r.z1) * 0.5
	var mW := mat(th["wall"]); var mU := mat(th["upper"]); var mF := mat(th["floor"]); var mC := mat(th["ceil"]); var mP := mat(th["pillar"], 2.0)
	var floor_name: String = th["floor"]
	if r.outdoor:
		mF = mat("ASPHALT") if r.kind != "sniper" else mat("CONCRETE")
	# floor
	box(geo, Vector3(r.W + WT * 2, 0.4, r.D + WT * 2), Vector3(0, -0.2, cz), mF)
	# ceiling
	if not r.outdoor:
		box(geo, Vector3(r.W + WT * 2, 0.3, r.D + WT * 2), Vector3(0, r.H + 0.15, cz), mC, false, false)
	# side walls
	var LB := 2.8
	var side_m := mat(th.get("out_wall", "gunmetal")) if r.outdoor else mW
	var wh := 4.2 if r.outdoor else r.H
	for s in [-1, 1]:
		var x: float = s * (hw + WT * 0.5)
		box(geo, Vector3(WT, LB, r.D + WT * 2), Vector3(x, LB * 0.5, cz), side_m)
		if not M["theme"] in ["vault", "board"] or r.outdoor:
			box(geo, Vector3(WT, wh - LB, r.D + WT * 2), Vector3(x, LB + (wh - LB) * 0.5, cz), mU if not r.outdoor else side_m)
		else:
			_window_wall(geo, r, s)
	# end walls with door gaps
	var seg := (r.W - GAP) * 0.5
	for e in [[r.z0 + WT * 0.5, true], [r.z1 - WT * 0.5, false]]:
		var zc: float = e[0]
		if e[1] and ri == 0:
			box(geo, Vector3(r.W, wh, WT), Vector3(0, wh * 0.5, zc), side_m); continue
		box(geo, Vector3(seg, wh, WT), Vector3(-GAP * 0.5 - seg * 0.5, wh * 0.5, zc), side_m)
		box(geo, Vector3(seg, wh, WT), Vector3(GAP * 0.5 + seg * 0.5, wh * 0.5, zc), side_m)
		box(geo, Vector3(GAP, wh - GH, WT), Vector3(0, GH + (wh - GH) * 0.5, zc), mU if not r.outdoor else side_m)
		for sx in [-1, 1]: box(geo, Vector3(0.35, GH, 0.8), Vector3(sx * (GAP * 0.5 + 0.17), GH * 0.5, zc), mP)
		box(geo, Vector3(GAP + 0.7, 0.35, 0.8), Vector3(0, GH + 0.17, zc), mP)
		box(geo, Vector3(GAP + 0.6, 0.06, 0.08), Vector3(0, GH + 0.4, zc + (0.42 if not e[1] else -0.42)), Mats.glow(accent, 3.0), false, false)
	# exit door
	var door := box(r, Vector3(GAP, GH, 0.3), Vector3(0, GH * 0.5, r.z1 - WT * 0.5), Mats.pbr("cont3", 2.0), false)
	r.door = door; r.door_closed_y = GH * 0.5
	var db := StaticBody3D.new(); var dcs := CollisionShape3D.new(); var dsh := BoxShape3D.new(); dsh.size = Vector3(GAP, GH, 0.3); dcs.shape = dsh; db.add_child(dcs); door.add_child(db); r.door_body = db
	var stripe := box(door, Vector3(GAP - 0.4, 0.08, 0.32), Vector3(0, 0.6, 0), Mats.glow(Color(1.0, 0.25, 0.15), 2.5), false, false)
	stripe.name = "Stripe"
	# corridor to the next room
	r.cz0 = r.z1 - WT; r.cz1 = r.cz0 - CORR
	var ccz := (r.cz0 + r.cz1) * 0.5
	box(geo, Vector3(4.6, 0.4, CORR), Vector3(0, -0.2, ccz), mat("grate", 2.0))
	box(geo, Vector3(4.6, 0.3, CORR), Vector3(0, 3.95, ccz), mC, false, false)
	for sx in [-1, 1]:
		box(geo, Vector3(0.4, 3.8, CORR), Vector3(sx * 2.4, 1.9, ccz), mW)
		for k in 3:
			var zz := r.cz0 - 1.6 - k * 3.4
			box(geo, Vector3(0.05, 0.05, 1.6), Vector3(sx * 2.17, 0.35, zz), Mats.glow(accent, 2.5), false, false)
	for k in 3:
		var zz2 := r.cz0 - 1.6 - k * 3.4
		box(geo, Vector3(1.2, 0.05, 0.4), Vector3(0, 3.78, zz2), Mats.glow(Color(0.92, 0.95, 1.0), 3.0), false, false)
	omni(r, Vector3(0, 3.2, ccz), th["light"], 0.9, 9.0)
	cyl(geo, 0.1, CORR, Vector3(-1.9, 3.4, ccz), mat("steel", 1.0), Vector3(PI * 0.5, 0, 0))
	# room dressing
	if r.outdoor: _outdoor(r, geo)
	else: _interior(r, geo)
	_wall_display(r, geo)
	_sector_sign(r)
	if r.kind == "range": _range_layout(r, geo)
	elif r.kind == "sniper": _sniper_layout(r, geo)
	else:
		_set_piece(r, geo)
		_cover(r, geo)
	if not r.kind in ["range", "sniper", "escape"]: _terminal(r, geo)
	_blk = _blockers(r, geo)
	_intel(r)
	_spawn_points(r)
	return r

func _window_wall(geo: Node3D, r: Room, s: int) -> void:
	# floor-to-ceiling glass with mullions; city beyond
	var hw := r.W * 0.5; var x := s * (hw + WT * 0.5); var cz := (r.z0 + r.z1) * 0.5
	var top := 2.8
	var gl := MeshInstance3D.new(); var pm := BoxMesh.new(); pm.size = Vector3(0.06, r.H - top, r.D); gl.mesh = pm; gl.material_override = Mats.glass()
	gl.position = Vector3(x, top + (r.H - top) * 0.5, cz); geo.add_child(gl)
	var body := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = pm.size; cs.shape = sh; body.add_child(cs); gl.add_child(body)
	var n := int(r.D / 3.0)
	for i in n + 1:
		box(geo, Vector3(0.18, r.H - top, 0.14), Vector3(x, top + (r.H - top) * 0.5, r.z0 - i * (r.D / n)), Mats.pbr("gunmetal", 1.0), false)
	_skyline(r, s)

func _skyline(r: Room, s: int) -> void:
	var names := ["Building_Large_2", "Building_Medium_2_001", "Building_Small_1"]
	var base := r.H - 60.0 if M["theme"] in ["vault", "board"] else -2.0
	for i in 5:
		var z := r.z0 - rng.randf_range(-10, r.D + 10)
		var x := s * rng.randf_range(r.W * 0.5 + 30, r.W * 0.5 + 90)
		Props.city(names[i % 3], r, Vector3(x, base + rng.randf_range(-8, 4), z), rng.randf_range(0, TAU), rng.randf_range(2.2, 3.4))

func _interior(r: Room, geo: Node3D) -> void:
	var hw := r.W * 0.5
	var mP := mat(th["pillar"], 2.0)
	var steps := int((r.D - 2.0) / 4.5)
	var gc: Color = accent
	for i in steps + 1:
		var z := r.z0 - 1.0 - i * ((r.D - 2.0) / steps)
		for s in [-1, 1]:
			var x: float = s * (hw - 0.22)
			box(geo, Vector3(0.44, r.H, 0.8), Vector3(x, r.H * 0.5, z), mP)
			box(geo, Vector3(0.05, r.H - 1.4, 0.09), Vector3(x - s * 0.24, r.H * 0.5 + 0.2, z), Mats.glow(gc, 2.2), false, false)
		box(geo, Vector3(r.W, 0.45, 0.32), Vector3(0, r.H - 0.23, z), mP, false)
	# light panels + spotlights
	var cols := [-r.W * 0.25, r.W * 0.25] if r.W < 26 else [-r.W * 0.3, 0.0, r.W * 0.3]
	var shadow_budget: int = [0, 2, 4, 6][clampi(quality, 0, 3)]
	var panels: Array = []
	for i in steps:
		var z := r.z0 - 1.0 - (i + 0.5) * ((r.D - 2.0) / steps)
		for x in cols: panels.append(Vector3(x, r.H - 0.06, z))
	var mid := (r.z0 + r.z1) * 0.5
	panels.sort_custom(func(a, b): return absf(a.z - mid) < absf(b.z - mid))
	for k in panels.size():
		var p: Vector3 = panels[k]
		box(geo, Vector3(1.8, 0.06, 0.55), p, Mats.glow(Color(0.95, 0.97, 1.0), 4.0), false, false)
		box(geo, Vector3(2.0, 0.08, 0.75), p + Vector3(0, 0.05, 0), mat(th["ceil"], 1.0), false, false)
		var sh: bool = k < shadow_budget
		var sp := spot(r, p - Vector3(0, 0.12, 0), th["light"], 5.5, r.H * 2.6, 68.0, sh)
		r.lights.append(sp)
		if sh: r.shadow_lights.append(sp)
	# pipes and cable tray
	var cz := (r.z0 + r.z1) * 0.5
	for pp in [[-hw + 0.55, r.H - 0.65, 0.13], [-hw + 0.9, r.H - 0.55, 0.09], [hw - 0.55, r.H - 0.65, 0.13], [hw - 0.85, r.H - 0.85, 0.07]]:
		cyl(geo, pp[2], r.D, Vector3(pp[0], pp[1], cz), mat("steel", 1.0), Vector3(PI * 0.5, 0, 0))
	box(geo, Vector3(0.7, 0.06, r.D), Vector3(-r.W * 0.2, r.H - 0.95, cz), mat("grate", 1.5), false, false)
	# posters / brand signage between pilasters
	var slots: Array = []
	for i in steps:
		var z := r.z0 - 1.0 - (i + 0.5) * ((r.D - 2.0) / steps)
		slots.append([-1, z]); slots.append([1, z])
	slots.shuffle()
	var used := 0
	for sl in slots:
		if used >= 3: break
		var z: float = sl[1]
		if absf(z - cz) < 5.5: continue
		_poster(r, geo, sl[0], z); used += 1
	# vents + console
	if slots.size() > 4:
		var sl2 = slots[4]
		box(geo, Vector3(0.9, 1.1, 1.4), Vector3(sl2[0] * (hw - 0.45), 0.55, sl2[1] + 1.4), mat("gunmetal", 1.0))
		var scr := box(geo, Vector3(0.04, 0.6, 1.0), Vector3(sl2[0] * (hw - 0.92), 1.2, sl2[1] + 1.4), Mats.glow(accent.lerp(Color.WHITE, 0.3), 1.6), false, false)
		scr.name = "Console"
	# floor hazard stripes at the exit and arrows
	box(geo, Vector3(GAP + 1.0, 0.02, 0.5), Vector3(0, 0.01, r.z1 + 0.6), _hazard(), false, false)
	# reflection probe for glossy floors
	if quality >= 1:
		var probe := ReflectionProbe.new(); probe.size = Vector3(r.W, r.H, r.D); probe.position = Vector3(0, r.H * 0.5, cz); probe.box_projection = true
		probe.update_mode = ReflectionProbe.UPDATE_ONCE; probe.intensity = 0.8; probe.interior = true; probe.ambient_mode = ReflectionProbe.AMBIENT_DISABLED
		r.add_child(probe)

static var _haz: Material = null
func _hazard() -> Material:
	if _haz: return _haz
	var img := Image.create(256, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 256:
			var band := int((x + y) / 24.0) % 2 == 0
			img.set_pixel(x, y, Color(0.92, 0.7, 0.1) if band else Color(0.08, 0.08, 0.08))
	var m := StandardMaterial3D.new(); m.albedo_texture = ImageTexture.create_from_image(img); m.roughness = 0.8
	_haz = m; return m

func _poster(r: Room, geo: Node3D, s: int, z: float) -> void:
	var hw := r.W * 0.5; var x := s * (hw - 0.02)
	var p: Array = SLOGANS[rng.randi() % SLOGANS.size()]
	var pnl := box(geo, Vector3(0.05, 1.9, 1.3), Vector3(x, 2.1, z), Mats.flat(Color(0.07, 0.08, 0.09), 0.5, 0.2), false, false)
	var rot := -s * PI * 0.5
	var off := Vector3(-s * 0.035, 0, 0)
	box(geo, Vector3(0.06, 0.08, 1.3), Vector3(x, 3.0, z) + off * 0.5, Mats.glow(accent, 2.0), false, false)
	label(r, p[0], Vector3(x, 2.7, z) + off, rot, 54, Color(0.95, 0.95, 0.95), "Rajdhani-Bold", 300, HORIZONTAL_ALIGNMENT_CENTER)
	label(r, p[1], Vector3(x, 2.35, z) + off, rot, 30, Color(0.75, 0.78, 0.8), "Barlow-Medium", 300, HORIZONTAL_ALIGNMENT_CENTER)
	if rng.randf() < 0.35:
		label(r, "VALUE FOR VALUE", Vector3(x, 1.6, z) + off * 1.4, rot + rng.randf_range(-0.1, 0.1), 46, Color(0.9, 0.2, 0.18), "BarlowCondensed-Bold", 0, HORIZONTAL_ALIGNMENT_CENTER)

func _wall_display(r: Room, geo: Node3D) -> void:
	var lines: Array = r.data.get("wall", [])
	if lines.is_empty(): return
	var hw := r.W * 0.5; var cz := (r.z0 + r.z1) * 0.5
	var x := -hw + 0.08; var z := cz + 2.0
	if r.outdoor: x = -hw + 0.4
	var pw := 6.4; var ph := 3.4; var y := 3.2 if not r.outdoor else 2.6
	box(geo, Vector3(0.1, ph + 0.2, pw + 0.2), Vector3(x, y, z), Mats.pbr("gunmetal", 1.0), false)
	box(geo, Vector3(0.04, ph, pw), Vector3(x + 0.06, y, z), Mats.flat(Color(0.02, 0.025, 0.03), 0.25, 0.0), false, false)
	box(geo, Vector3(0.05, 0.07, pw), Vector3(x + 0.08, y + ph * 0.5 - 0.1, z), Mats.glow(accent, 3.0), false, false)
	var rot := PI * 0.5; var lx := x + 0.1
	label(r, "CASTELLAN · STRATEGY WALL", Vector3(lx, y + ph * 0.5 - 0.35, z + pw * 0.5 - 0.25), rot, 30, accent, "IBMPlexMono-Medium")
	label(r, String(lines[0]), Vector3(lx, y + ph * 0.5 - 0.85, z + pw * 0.5 - 0.25), rot, 96, Color(0.96, 0.96, 0.96), "Rajdhani-Bold", 1500)
	for i in range(1, lines.size()):
		label(r, String(lines[i]), Vector3(lx, y + ph * 0.5 - 1.2 - i * 0.42, z + pw * 0.5 - 0.25), rot, 50, Color(0.8, 0.84, 0.86), "Barlow-Medium", 1500)
	omni(r, Vector3(x + 1.2, y, z), accent.lerp(Color.WHITE, 0.5), 0.6, 5.0)

func _sector_sign(r: Room) -> void:
	var t := "SECTOR %d · %s" % [r.ri + 1, String(r.data["n"]).to_upper()]
	label(r, t, Vector3(0, GH + 0.95, r.z1 + 0.02), 0, 56, accent, "Rajdhani-Bold", 0, HORIZONTAL_ALIGNMENT_CENTER)

func _terminal(r: Room, geo: Node3D) -> void:
	var hw := r.W * 0.5
	var tx := hw - 1.6; var tz := r.z1 + 2.6
	box(geo, Vector3(0.9, 1.3, 1.4), Vector3(tx, 0.65, tz), Mats.pbr("gunmetal", 1.0))
	var scr := box(geo, Vector3(0.05, 0.75, 1.1), Vector3(tx - 0.48, 1.15, tz), Mats.glow(Color(0.25, 0.95, 0.5), 1.4), false, false)
	label(r, "LEDGER\nUPLINK", Vector3(tx - 0.52, 1.18, tz), -PI * 0.5, 44, Color(0.05, 0.1, 0.06), "IBMPlexMono-Medium", 0, HORIZONTAL_ALIGNMENT_CENTER, false)
	var t := Node3D.new(); t.name = "Terminal"; r.add_child(t); t.position = Vector3(tx - 1.0, 0, tz)
	t.set_meta("screen", scr)
	r.terminal = t
	omni(r, Vector3(tx - 1.0, 1.4, tz), Color(0.3, 1.0, 0.5), 0.5, 3.0)

## Footprints (XZ) of everything already standing in the room, so pickups and spawns land in open floor.
var _blk: Array = []
func _blockers(r: Room, geo: Node3D) -> Array:
	var out: Array = []
	for n in geo.find_children("*", "MeshInstance3D", true, false) + r.find_children("Terminal*", "Node3D", false, false):
		var a: AABB
		if n is MeshInstance3D: a = (n as MeshInstance3D).global_transform * (n as MeshInstance3D).get_aabb()
		else: a = AABB((n as Node3D).global_position - Vector3(0.6, 0, 0.8), Vector3(1.6, 1.4, 1.6))
		if a.size.x > r.W * 0.7 or a.size.z > r.D * 0.7: continue      # floor, walls, ceiling, rails
		if a.end.y < 0.2 or a.position.y > 2.4: continue                # decals, puddles, lights, pipes
		out.append(Rect2(a.position.x, a.position.z, a.size.x, a.size.z))
	return out

func _free(p: Vector3, half: Vector2) -> bool:
	var me := Rect2(p.x - half.x, p.z - half.y, half.x * 2.0, half.y * 2.0)
	for b in _blk:
		if (b as Rect2).intersects(me): return false
	return true

func _intel(r: Room) -> void:
	var docs: Array = r.data.get("intel", [])
	var hw := r.W * 0.5
	for k in docs.size():
		var p := Vector3.ZERO
		for t in 120:
			p = Vector3(rng.randf_range(-hw + 2.5, hw - 2.5), 0, rng.randf_range(r.z1 + 4, r.z0 - 5))
			if absf(p.x) > 2.0 and _free(p, Vector2(1.4, 1.1)): break
		var n := Node3D.new(); n.name = "Intel%d" % k; r.add_child(n); n.position = p
		var desk := box(n, Vector3(1.4, 0.9, 0.8), Vector3(0, 0.45, 0), Mats.pbr("gunmetal", 1.0))
		var folder := box(n, Vector3(0.36, 0.03, 0.26), Vector3(0, 0.92, 0), Mats.flat(Color(0.75, 0.62, 0.35), 0.8), false)
		var tab := box(n, Vector3(0.3, 0.02, 0.22), Vector3(0.38, 0.92, 0.05), Mats.glow(Color(1.0, 0.82, 0.4), 1.3), false)
		tab.rotation.y = 0.3
		var gl := omni(n, Vector3(0, 1.3, 0), Color(1.0, 0.8, 0.45), 0.9, 2.6)
		n.set_meta("doc", docs[k]); n.set_meta("k", k); n.set_meta("glow", gl); n.set_meta("tab", tab)
		r.intel.append(n)
		_blk.append(Rect2(p.x - 0.8, p.z - 0.5, 1.6, 1.0))

func _spawn_points(r: Room) -> void:
	var hw := r.W * 0.5
	var tries := 0
	while r.spawn_points.size() < 24 and tries < 400:
		tries += 1
		var p := Vector3(rng.randf_range(-hw + 2, hw - 2), 0, rng.randf_range(r.z1 + 2.5, r.z1 + r.D * 0.6))
		if _free(p, Vector2(0.55, 0.55)): r.spawn_points.append(p)
	if r.spawn_points.is_empty(): r.spawn_points.append(Vector3(0, 0, r.z1 + 3.0))

# ---------------------------------------------------------------- cover props
func _cover(r: Room, geo: Node3D) -> void:
	if r.kind in ["tail", "escape", "evidence"]:
		_few_cover(r, geo, 4); return
	var hw := r.W * 0.5
	var n := 9 + rng.randi() % 4
	if r.kind in ["boss", "defend", "holdout", "ambush"]: n = 13
	if r.kind == "stealth": n = 14
	var placed: Array = []
	var tries := 0
	var cover_list: Array = th["cover"]
	while placed.size() < n and tries < 220:
		tries += 1
		var name: String = cover_list[rng.randi() % cover_list.size()]
		if name.begins_with("prop_container") and not r.outdoor and rng.randf() < 0.7: name = "prop_cargobox2"
		var rot := rng.randi() % 2
		var sz := Props.size(name, rot)
		var x := rng.randf_range(-hw + 1.4 + sz.x * 0.5, hw - 1.4 - sz.x * 0.5)
		var z := rng.randf_range(r.z1 + 4.0 + sz.z * 0.5, r.z0 - 5.0 - sz.z * 0.5)
		if absf(x) < 2.6 + sz.x * 0.5 and (z > r.z0 - 7.0 or z < r.z1 + 6.0): continue
		if x > hw - 4.0 and z < r.z1 + 5.5: continue   # terminal corner
		var bad := false
		for p in placed:
			if absf(x - p.x) < (p.w + sz.x) * 0.5 + 1.6 and absf(z - p.z) < (p.d + sz.z) * 0.5 + 1.6: bad = true; break
		if bad: continue
		for it in r.intel:
			if Vector2(x - it.position.x, z - it.position.z).length() < 2.5: bad = true
		if bad: continue
		var node := Props.spawn(name, geo, Vector3(x, 0, z), rot)
		if node == null: continue
		placed.append({"x": x, "z": z, "w": sz.x, "d": sz.z})
		for s in [-1, 1]:
			r.cover_points.append(Vector3(x, 0, z + s * (sz.z * 0.5 + 0.7)))
			r.cover_points.append(Vector3(x + s * (sz.x * 0.5 + 0.7), 0, z))
		if name == "prop_cargobox1_a" and Props.has("prop_cargobox1_alid"): Props.spawn("prop_cargobox1_alid", geo, Vector3(x, 0, z), rot, false)
		if name == "prop_cargobox3" and Props.has("prop_cargobox3lid"): Props.spawn("prop_cargobox3lid", geo, Vector3(x, 0, z), rot, false)
	# explosive barrels
	var nb := 1 + rng.randi() % 2
	for k in nb:
		var p := Vector3(rng.randf_range(-hw + 2, hw - 2), 0, rng.randf_range(r.z1 + 6, r.z0 - 8))
		if absf(p.x) < 2.5: continue
		var b := Props.spawn("prop_barrel2", geo, p, 0, true, Mats.prop("cargo", {"metal": 0.5, "tint": Color(1.0, 0.35, 0.28)}))
		if b: b.set_meta("barrel", true); b.add_to_group("barrels"); b.set_meta("hp", 2)
	# corner dressing
	for c in [["prop_floodlight", Vector3(-hw + 1.3, 0, r.z0 - 2.4), 1], ["prop_gastriple", Vector3(hw - 1.0, 0, r.z0 - 2.0), 0], ["prop_pellet", Vector3(-hw + 1.8, 0, r.z1 + 3.0), 0]]:
		Props.spawn(c[0], geo, c[2 - 1], c[2], true)

func _few_cover(r: Room, geo: Node3D, n: int) -> void:
	var hw := r.W * 0.5
	for i in n:
		var name: String = ["prop_smallbox2", "prop_cargobox4", "prop_barrier"][i % 3]
		var p := Vector3((-1 if i % 2 == 0 else 1) * rng.randf_range(hw * 0.35, hw - 2.0), 0, r.z0 - 6 - i * (r.D - 12) / maxf(1, n - 1))
		Props.spawn(name, geo, p, rng.randi() % 2)
		r.cover_points.append(p + Vector3(0, 0, 1.2))

# ---------------------------------------------------------------- outdoor
func _outdoor(r: Room, geo: Node3D) -> void:
	var hw := r.W * 0.5; var cz := (r.z0 + r.z1) * 0.5
	# floodlight poles
	var n := int(r.D / 12.0) + 1
	for i in n:
		var z := r.z0 - 4.0 - i * ((r.D - 8.0) / maxf(1, n - 1))
		for s in [-1, 1]:
			var x: float = s * (hw - 1.0)
			cyl(geo, 0.12, 9.0, Vector3(x, 4.5, z), mat("steel", 1.0), Vector3.ZERO, true)
			box(geo, Vector3(0.9, 0.3, 0.5), Vector3(x - s * 0.4, 9.0, z), mat("gunmetal", 1.0), false)
			box(geo, Vector3(0.7, 0.05, 0.35), Vector3(x - s * 0.4, 8.84, z), Mats.glow(Color(1.0, 0.92, 0.75), 6.0), false, false)
			var sp := spot(r, Vector3(x - s * 0.4, 8.7, z), th["light"].lerp(Color(1.0, 0.85, 0.6), 0.4), 11.0, 30.0, 62.0, i == n / 2 and quality >= 1, Vector3(-s * 0.55, -1, 0))
			r.lights.append(sp)
	# perimeter: container stacks / fence beyond walls
	for s in [-1, 1]:
		for k in int(r.D / 6.5):
			var z := r.z0 - 3.0 - k * 6.5
			if rng.randf() < 0.65 and Props.has("prop_container2"):
				Props.spawn(["prop_container2", "prop_container3"][rng.randi() % 2], geo, Vector3(s * (hw + 3.2), 0, z), 1, false)
				if rng.randf() < 0.5: Props.spawn("prop_container3", geo, Vector3(s * (hw + 3.2), 3.11, z), 1, false)
	_skyline(r, -1); _skyline(r, 1)
	# puddles: glossy dark planes
	for k in 6:
		var pz := rng.randf_range(r.z1 + 3, r.z0 - 3); var px := rng.randf_range(-hw + 2, hw - 2)
		var pm := MeshInstance3D.new(); var pl := PlaneMesh.new(); pl.size = Vector2(rng.randf_range(1.5, 4), rng.randf_range(1, 3)); pm.mesh = pl
		pm.material_override = _puddle_mat(); pm.position = Vector3(px, 0.012, pz); pm.rotation.y = rng.randf() * TAU; geo.add_child(pm)
		pm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static var _puddle: StandardMaterial3D
## Soft-edged wet patch: darkens the ground and picks up specular highlights from the floodlights.
func _puddle_mat() -> StandardMaterial3D:
	if _puddle: return _puddle
	var g := Gradient.new(); g.set_color(0, Color(1, 1, 1, 0.75)); g.add_point(0.55, Color(1, 1, 1, 0.55)); g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0.0))
	var gt := GradientTexture2D.new(); gt.gradient = g; gt.fill = GradientTexture2D.FILL_RADIAL; gt.fill_from = Vector2(0.5, 0.5); gt.fill_to = Vector2(1.0, 0.5); gt.width = 128; gt.height = 128
	_puddle = StandardMaterial3D.new()
	_puddle.albedo_texture = gt; _puddle.albedo_color = Color(0.03, 0.035, 0.04, 1.0)
	_puddle.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_puddle.roughness = 0.03; _puddle.metallic = 0.85; _puddle.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	return _puddle

# ---------------------------------------------------------------- set pieces
func _set_piece(r: Room, geo: Node3D) -> void:
	var hw := r.W * 0.5; var cz := (r.z0 + r.z1) * 0.5
	var sp: String = r.data.get("set", "")
	match sp:
		"conveyors", "docks":
			for k in 2:
				var x: float = (-1 if k == 0 else 1) * hw * 0.55
				box(geo, Vector3(1.4, 0.9, r.D * 0.5), Vector3(x, 0.45, cz), mat("steel", 1.0))
				box(geo, Vector3(1.2, 0.04, r.D * 0.5), Vector3(x, 0.92, cz), Mats.flat(Color(0.06, 0.06, 0.06), 0.9), false, false)
				for i in 5: Props.spawn("prop_smallbox4", geo, Vector3(x, 0.94, cz - r.D * 0.2 + i * r.D * 0.1), 1, false)
		"servers", "analytics", "archive", "cooling":
			_server_rows(r, geo, 3)
		"glass_office":
			_mezzanine(r, geo)
		"vault_servers":
			pass  # built by plant mode
		"lab", "psych", "decision", "studio":
			for k in 3:
				var tz := r.z0 - 8 - k * 6
				box(geo, Vector3(4.0, 0.95, 1.4), Vector3(-hw * 0.45, 0.475, tz), Mats.pbr("metal", 1.0))
				box(geo, Vector3(4.0, 0.95, 1.4), Vector3(hw * 0.45, 0.475, tz), Mats.pbr("metal", 1.0))
				box(geo, Vector3(0.9, 0.55, 0.05), Vector3(-hw * 0.45, 1.25, tz), Mats.glow(accent.lerp(Color.WHITE, 0.4), 1.2), false, false)
		"offices", "office", "callcentre", "positioning", "b2b", "segfloor":
			for row in 3:
				for col in 3:
					var p := Vector3(-hw * 0.5 + col * hw * 0.5, 0, r.z0 - 8 - row * 5.5)
					if absf(p.x) < 2.0: continue
					box(geo, Vector3(2.2, 0.75, 1.0), p + Vector3(0, 0.375, 0), Mats.pbr("gunmetal", 1.0))
					box(geo, Vector3(0.7, 0.45, 0.04), p + Vector3(0, 1.0, -0.3), Mats.glow(Color(0.6, 0.75, 1.0), 1.0), false, false)
					r.cover_points.append(p + Vector3(0, 0, 1.0))
		"hall", "lobby", "skylobby", "showroom":
			for k in 4:
				var z := r.z0 - 6 - k * (r.D - 12) / 3.0
				for s in [-1, 1]: cyl(geo, 0.45, r.H, Vector3(s * hw * 0.42, r.H * 0.5, z), mat(th["pillar"], 2.0), Vector3.ZERO, true)
			if sp in ["lobby", "showroom"]:
				label(r, "CASTELLAN", Vector3(0, r.H - 1.6, r.z0 - 0.4), PI, 260, Color(0.96, 0.92, 0.82), "Rajdhani-Bold", 0, HORIZONTAL_ALIGNMENT_CENTER)
		"boardroom":
			box(geo, Vector3(3.0, 0.8, 14), Vector3(0, 0.4, cz + 2), Mats.pbr("gunmetal", 1.0))
			for i in 7:
				for s in [-1, 1]: box(geo, Vector3(0.6, 1.1, 0.6), Vector3(s * 2.1, 0.55, cz + 2 - 6 + i * 2), Mats.flat(Color(0.08, 0.08, 0.09), 0.6), true)
		"vault":
			for k in 4:
				var x: float = (-1 if k % 2 == 0 else 1) * (hw - 2.4); var z := r.z0 - 6 - (k / 2) * 10
				box(geo, Vector3(1.2, 1.0, 1.2), Vector3(x, 0.5, z), Mats.pbr("gunmetal", 1.0))
				var gm := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(1.1, 1.1, 1.1); gm.mesh = bm; gm.material_override = Mats.glass(); gm.position = Vector3(x, 1.55, z); geo.add_child(gm)
				label(r, ["CASTELLAN ASSURE", "HEARTH&CO", "CASTELLANFRESH", "SHELFWISE"][k], Vector3(x, 1.55, z + 0.6), 0, 38, accent, "Rajdhani-Bold", 0, HORIZONTAL_ALIGNMENT_CENTER)
			_ring(r, cz)
		"array", "crane", "segment":
			_ring(r, cz)
		"atrium", "gallery", "evallab":
			_storefronts(r, geo)
		"cells":
			for s in [-1, 1]:
				for k in 4:
					var z := r.z0 - 5 - k * 6
					for b in 6: cyl(geo, 0.03, 3.0, Vector3(s * (hw - 3.0), 1.5, z - 2 + b * 0.8), mat("steel", 1.0), Vector3.ZERO, true)
					box(geo, Vector3(3.0, 0.1, 5.0), Vector3(s * (hw - 1.5), 3.0, z), mat("metal", 1.0), false)
		"collapse":
			for k in 6:
				var p := Vector3(rng.randf_range(-3, 3), 0, r.z0 - 6 - k * 8)
				box(geo, Vector3(2.4, 0.6, 1.2), p + Vector3(0, 0.3, 0), mat("CONCRETE"), true).rotation = Vector3(0, rng.randf_range(-0.5, 0.5), rng.randf_range(-0.2, 0.2))
		"loadingbay", "loading", "b2b_exit":
			for k in 2:
				Props.spawn("prop_cargolift", geo, Vector3((-1 if k == 0 else 1) * hw * 0.5, 0, cz - 4 + k * 6), 0)

func _ring(r: Room, cz: float) -> void:
	var t := MeshInstance3D.new(); var tm := TorusMesh.new(); tm.inner_radius = 2.8; tm.outer_radius = 3.1; tm.rings = 48; t.mesh = tm
	t.material_override = Mats.glow(accent, 2.5); t.position = Vector3(0, r.H - 1.6, cz); r.add_child(t); t.name = "Ring"

func _server_rows(r: Room, geo: Node3D, rows: int) -> void:
	var hw := r.W * 0.5
	var led := _led_tex()
	var sm := StandardMaterial3D.new(); sm.albedo_texture = led; sm.emission_enabled = true; sm.emission_texture = led; sm.emission_energy_multiplier = 1.6; sm.roughness = 0.35; sm.metallic = 0.6
	for i in rows:
		var z := r.z0 - 7 - i * 6.5
		if z < r.z1 + 6: break
		for s in [-1, 1]:
			var x: float = s * (hw - 1.6)
			var rack := box(geo, Vector3(1.0, 2.4, 2.6), Vector3(x, 1.2, z), sm)
			r.cover_points.append(Vector3(x - s * 1.0, 0, z))
			var x2: float = s * (hw * 0.38)
			box(geo, Vector3(1.0, 2.4, 2.6), Vector3(x2, 1.2, z - 2.5), sm)
			r.cover_points.append(Vector3(x2, 0, z - 4.2))

static var _led: Texture2D = null
func _led_tex() -> Texture2D:
	if _led: return _led
	var img := Image.create(128, 256, false, Image.FORMAT_RGB8)
	img.fill(Color(0.05, 0.06, 0.07))
	var rr := RandomNumberGenerator.new(); rr.seed = 7
	for y in range(8, 248, 14):
		for x in range(6, 122): img.set_pixel(x, y, Color(0.11, 0.13, 0.15))
		for k in 6:
			var c := Color(0.2, 1.0, 0.45) if rr.randf() < 0.6 else (Color(1.0, 0.6, 0.2) if rr.randf() < 0.5 else Color(0.15, 0.25, 0.2))
			for dx in 4:
				for dy in 3: img.set_pixel(12 + k * 8 + dx, y + 4 + dy, c)
	_led = ImageTexture.create_from_image(img)
	return _led

func _storefronts(r: Room, geo: Node3D) -> void:
	var hw := r.W * 0.5
	var shops := ["NORTHLINE OPTICAL", "ARDEN & FIELD", "KITE MOBILE", "MERCER HOME", "SOLACE BEAUTY", "PINE & POST", "HALVARD SPORT", "CASTELLANFRESH"]
	var n := int(r.D / 10.0)
	for s in [-1, 1]:
		for k in n:
			var z := r.z0 - 5 - k * 10
			var x: float = s * (hw - 0.4)
			var gm := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.08, 3.0, 7.0); gm.mesh = bm; gm.material_override = Mats.glass(); gm.position = Vector3(x, 1.5, z); geo.add_child(gm)
			var c: Color = [Color(1.0, 0.45, 0.72), Color(0.4, 0.85, 1.0), Color(1.0, 0.85, 0.45), Color(0.55, 1.0, 0.6)][(k + (1 if s > 0 else 0)) % 4]
			box(geo, Vector3(0.12, 0.8, 7.2), Vector3(x, 3.6, z), Mats.flat(Color(0.04, 0.04, 0.05), 0.5), false)
			label(r, shops[(k * 2 + (1 if s > 0 else 0)) % shops.size()], Vector3(x - s * 0.08, 3.6, z), -s * PI * 0.5, 72, c, "Rajdhani-Bold", 0, HORIZONTAL_ALIGNMENT_CENTER)
			omni(r, Vector3(x - s * 1.5, 2.2, z), c.lerp(Color.WHITE, 0.6), 0.7, 5.0)
	# planters and benches down the middle
	for k in int(r.D / 9.0):
		var z := r.z0 - 8 - k * 9
		if Props.has("prop_smallbox2"):
			box(geo, Vector3(2.0, 0.6, 2.0), Vector3(rng.randf_range(-3, 3), 0.3, z), mat("CONCRETE"))
			r.cover_points.append(Vector3(0, 0, z + 1.6))

func _mezzanine(r: Room, geo: Node3D) -> void:
	# raised glass conference room at the far end; directors stand inside
	var hw := r.W * 0.5
	var z := r.z1 + 5.0
	box(geo, Vector3(r.W - 2, 0.4, 8.0), Vector3(0, 3.6, z), mat("metal", 2.0))
	for x in [-hw + 3, 0.0, hw - 3]: cyl(geo, 0.3, 3.4, Vector3(x, 1.7, z + 3.6), mat("steel", 1.0), Vector3.ZERO, true)
	var gm := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(r.W - 2, 3.0, 0.08); gm.mesh = bm; gm.material_override = Mats.glass(); gm.position = Vector3(0, 5.3, z + 4.0); geo.add_child(gm)
	box(geo, Vector3(5.0, 0.8, 1.6), Vector3(0, 4.2, z - 0.5), Mats.pbr("gunmetal", 1.0))
	omni(r, Vector3(0, 6.2, z), Color(1.0, 0.95, 0.85), 1.4, 9.0)
	r.set_meta("mezz_z", z)

func _range_layout(r: Room, geo: Node3D) -> void:
	var hw := r.W * 0.5
	if Props.has("prop_transitbarrierdirection"):
		Props.spawn("prop_transitbarrierdirection", geo, Vector3(-3.2, 0, r.z0 - 7), 0)
		Props.spawn("prop_transitbarrierdirection", geo, Vector3(3.2, 0, r.z0 - 7), 0)
	box(geo, Vector3(r.W, 0.02, 0.35), Vector3(0, 0.01, r.z0 - 7.7), _hazard(), false, false)
	for i in range(-2, 3):
		box(geo, Vector3(0.08, 0.01, r.D - 10), Vector3(i * 3.6, 0.012, (r.z0 - 8 + r.z1) * 0.5), Mats.flat(Color(0.55, 0.57, 0.48), 0.9), false, false)
	var board := Node3D.new(); board.name = "Board"; r.add_child(board); board.position = Vector3(0, 4.4, r.z1 + 0.08)
	box(board, Vector3(8.4, 2.2, 0.1), Vector3.ZERO, Mats.flat(Color(0.03, 0.035, 0.04), 0.4), false, false)
	r.set_meta("board", board)

func _sniper_layout(r: Room, geo: Node3D) -> void:
	var hw := r.W * 0.5
	# perch: raised roof at the entry end
	box(geo, Vector3(r.W, 7.0, 6.0), Vector3(0, 3.5, r.z0 - 3.0), mat("CONCRETE"))
	box(geo, Vector3(r.W, 0.9, 0.3), Vector3(0, 7.45, r.z0 - 6.1), mat("CONCRETE"))
	r.set_meta("perch_y", 7.0)
	# yard buildings and cover along the route
	for k in 6:
		var z := r.z0 - 16 - k * 10
		var x: float = (-1 if k % 2 == 0 else 1) * rng.randf_range(8, 15)
		Props.spawn(["prop_container2", "prop_container3", "prop_cargolift"][k % 3], geo, Vector3(x, 0, z), rng.randi() % 2)
		r.cover_points.append(Vector3(x, 0, z + 3.5))
	# warehouses at the sides
	for s in [-1, 1]:
		for k in 3:
			box(geo, Vector3(10, 9, 16), Vector3(s * (hw - 5), 4.5, r.z0 - 20 - k * 20), mat("CONCRETE"))
	# truck at the far end
	box(geo, Vector3(2.6, 2.8, 7.0), Vector3(4, 1.4, r.z1 + 8), Mats.pbr("cont2", 2.0))
	r.set_meta("truck", Vector3(4, 0, r.z1 + 8))
