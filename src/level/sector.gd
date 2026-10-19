class_name Sector
extends RefCounted
## Base class for a hand-built sector (levels/<mission>/s<ri>.gd). Nothing here is random: every wall,
## prop, light, guard route and pickup is placed by the layout script.
##
## Coordinates: x is left/right (world x), d is the distance into the sector from its entry door
## (world z = z0 - d), y is height. Yaw is in degrees, 0 = facing deeper into the sector.
## The kit grid is 4 m. Entry door is the cell x∈[-2,2] at d=0, exit door the same cell at d=D.

var b: Builder
var r: Room
var geo: Node3D
var accent: Color
var notes: Array = []          # blueprint annotations [text, Vector3]
var placed_wall := false
var _shadow_left := 0

## Override: Vector3(W, H, D)
func dims() -> Vector3: return Vector3(24, 5, 32)
## Override: build everything.
func build() -> void: pass
## Override: true for open-air sectors
func outdoor() -> bool: return false

func setup(builder: Builder, room: Room, g: Node3D) -> void:
	b = builder; r = room; geo = g; accent = b.accent
	_shadow_left = [0, 2, 4, 6][clampi(b.quality, 0, 3)]

# ---------------------------------------------------------------- coordinates
func P(x: float, d: float, y := 0.0) -> Vector3: return Vector3(x, y, r.z0 - d)
func yaw_basis(deg: float) -> Basis: return Basis(Vector3.UP, deg_to_rad(-deg) + PI)   # yaw 0 faces -z (deeper)
func XF(x: float, d: float, yaw := 0.0, y := 0.0, s := 1.0) -> Transform3D:
	return Transform3D(yaw_basis(yaw).scaled(Vector3.ONE * s), P(x, d, y))

# ---------------------------------------------------------------- placement
func piece(id: String, x: float, d: float, yaw := 0.0, y := 0.0, col := "box", s := 1.0) -> Node3D:
	return Kit.spawn(id, geo, XF(x, d, yaw, y, s), col)

## Prop that also offers cover points on its four sides (for AI and the ally).
func cover(id: String, x: float, d: float, yaw := 0.0, y := 0.0) -> Node3D:
	var n := piece(id, x, d, yaw, y)
	if n == null: return n
	var bb: AABB = n.transform * Kit.bounds(id) if not id.begins_with("tps:") else n.transform * Props._aabb(n)
	var c := bb.get_center()
	for o in [Vector3(bb.size.x * 0.5 + 0.7, 0, 0), Vector3(-bb.size.x * 0.5 - 0.7, 0, 0), Vector3(0, 0, bb.size.z * 0.5 + 0.7), Vector3(0, 0, -bb.size.z * 0.5 - 0.7)]:
		r.cover_points.append(Vector3(c.x + o.x, y, c.z + o.z))
	return n

func box(size: Vector3, x: float, d: float, y: float, m: Material, col := true, yaw := 0.0) -> MeshInstance3D:
	var mi := b.box(geo, size, P(x, d, y), m, col)
	mi.basis = yaw_basis(yaw)
	return mi

## Solid floor slab (collision) with kit floor tiles on a 4 m grid (or a material).
func floor_rect(x0: float, d0: float, x1: float, d1: float, tile := "q:Platform_Simple", y := 0.0, m: Material = null) -> void:
	var w := absf(x1 - x0); var dd := absf(d1 - d0)
	var cx := (x0 + x1) * 0.5; var cd := (d0 + d1) * 0.5
	var slab := b.box(geo, Vector3(w, 0.4, dd), P(cx, cd, y - 0.2), m if m else Mats.flat(Color(0.12, 0.12, 0.13), 0.8), true, false)
	if m != null or tile == "": return
	slab.visible = false
	var nx := int(round(w / 4.0)); var nd := int(round(dd / 4.0))
	for i in nx:
		for j in nd:
			Kit.spawn(tile, geo, XF(minf(x0, x1) + 2.0 + i * 4.0, minf(d0, d1) + 2.0 + j * 4.0, 0, y + 0.005), "none", false)

func ceiling(x0: float, d0: float, x1: float, d1: float, h := 5.0) -> void:
	var c := b.box(geo, Vector3(absf(x1 - x0), 0.3, absf(d1 - d0)), P((x0 + x1) * 0.5, (d0 + d1) * 0.5, h + 0.15), b.mat("metal", 3.0, Color(0.55, 0.56, 0.6)), false, false)
	c.add_to_group("ceiling")

## A run of kit walls along an axis-aligned line, inner face exactly on the line.
## cells: one character per 4 m cell:  W wall · D doorway (top band only) · O open · G window wall
##        B broken wall · S short wall (1 m) · H half wall (2 m)
## inside: any point on the room side of the line (x, d).
func wall(x0: float, d0: float, x1: float, d1: float, inside: Vector2, cells := "", style := "WallBand", top := "TopSimple", y := 0.0) -> void:
	var a := Vector2(x0, d0); var e := Vector2(x1, d1)
	var dir := (e - a).normalized(); var n := Vector2(-dir.y, dir.x)
	if (inside - a).dot(n) < 0: n = -n
	var count := int(round((e - a).length() / 4.0))
	if cells == "": cells = "W".repeat(count)
	for i in count:
		var c := a + dir * (i * 4.0 + 2.0) + n * 2.0
		var t := XF(c.x, c.y, 0.0, y)
		# piece local +x -> inward normal in world (x, -d)
		var nw := Vector3(n.x, 0, -n.y)
		t.basis = Basis(nw, Vector3.UP, nw.cross(Vector3.UP).normalized())
		var ch := cells[i] if i < cells.length() else "W"
		var wid := ""
		match ch:
			"W": wid = "q:%s_Straight" % style
			"B": wid = "q:%s_Straight_Broken" % style if style in ["WallBand", "WallAstra"] else "q:%s_Straight" % style
			"G": wid = "q:WallWindow_Straight"
			"S": wid = "q:ShortWall_Simple1_Straight"
			"H": wid = "q:ShortWall_Metal2_Straight"
		if wid != "": Kit.spawn(wid, geo, t, "box")
		if ch in ["W", "B", "G", "D"] and top != "": Kit.spawn("q:%s_Straight" % top, geo, t, "none")
		if ch == "G":
			# glass pane so the window blocks bullets and movement but not sight
			var gp := b.box(geo, Vector3(0.06, 2.2, 4.0), t.origin + t.basis.x * -2.0 + Vector3(0, 1.6, 0), Mats.glass(), true, false)
			gp.basis = t.basis
			gp.get_child(0).collision_layer = 1
	_mark_wall(a, e, n)

var _walls: Array = []
func _mark_wall(a: Vector2, e: Vector2, n: Vector2) -> void: _walls.append([a, e, n])

## Plain thick partition (any length), for places the 4 m grid doesn't fit.
func partition(x0: float, d0: float, x1: float, d1: float, h := 3.0, m: Material = null, t := 0.3) -> MeshInstance3D:
	var a := Vector2(x0, d0); var e := Vector2(x1, d1)
	var mid := (a + e) * 0.5; var L := (e - a).length()
	var ang := rad_to_deg(atan2(e.x - a.x, e.y - a.y))
	return box(Vector3(t, h, L), mid.x, mid.y, h * 0.5, m if m else b.mat("tech", 2.0), true, ang)

func column(id: String, x: float, d: float, yaw := 0.0, h := 5.0) -> Node3D:
	var n := piece(id, x, d, yaw, 0.0, "box")
	return n

## Raised walkway slab with kit grating and rails on the listed open sides ("n","s","e","w" = -d,+d,+x,-x).
func catwalk(x0: float, d0: float, x1: float, d1: float, y: float, rails := "", tile := "q:Platform_Metal2") -> void:
	var w := absf(x1 - x0); var dd := absf(d1 - d0)
	box(Vector3(w, 0.18, dd), (x0 + x1) * 0.5, (d0 + d1) * 0.5, y - 0.09, b.mat("grate", 2.0), true)
	var nx := maxi(1, int(round(w / 4.0))); var nd := maxi(1, int(round(dd / 4.0)))
	if fmod(w, 4.0) < 0.01 and fmod(dd, 4.0) < 0.01:
		for i in nx:
			for j in nd: Kit.spawn(tile, geo, XF(minf(x0, x1) + 2.0 + i * 4.0, minf(d0, d1) + 2.0 + j * 4.0, 0, y + 0.01), "none")
	for side in rails:
		var pts: Array
		match side:
			"n": pts = [Vector2(x0, minf(d0, d1)), Vector2(x1, minf(d0, d1))]
			"s": pts = [Vector2(x0, maxf(d0, d1)), Vector2(x1, maxf(d0, d1))]
			"w": pts = [Vector2(minf(x0, x1), d0), Vector2(minf(x0, x1), d1)]
			"e": pts = [Vector2(maxf(x0, x1), d0), Vector2(maxf(x0, x1), d1)]
		rail(pts[0].x, pts[0].y, pts[1].x, pts[1].y, y)
	# support legs every ~4 m along the long axis
	var legs_x := [minf(x0, x1) + 0.3, maxf(x0, x1) - 0.3]
	for k in maxi(2, nd + 1):
		var dk := minf(d0, d1) + 0.3 + (dd - 0.6) * k / maxf(1, maxi(2, nd + 1) - 1)
		for lx in legs_x: box(Vector3(0.16, y, 0.16), lx, dk, y * 0.5, b.mat("steel", 1.0), true)

## Guard rail (visual + low collider so nobody walks off).
func rail(x0: float, d0: float, x1: float, d1: float, y: float) -> void:
	var a := Vector2(x0, d0); var e := Vector2(x1, d1)
	var L := (e - a).length(); var mid := (a + e) * 0.5
	var ang := rad_to_deg(atan2(e.x - a.x, e.y - a.y))
	var m := b.mat("steel", 1.0)
	box(Vector3(0.05, 0.05, L), mid.x, mid.y, y + 1.0, m, false, ang)
	box(Vector3(0.04, 0.04, L), mid.x, mid.y, y + 0.55, m, false, ang)
	var posts := int(L / 1.5) + 1
	for k in posts + 1:
		var p := a + (e - a) * (k / float(posts))
		box(Vector3(0.05, 1.0, 0.05), p.x, p.y, y + 0.5, m, false)
	var c := box(Vector3(0.1, 1.1, L), mid.x, mid.y, y + 0.55, m, true, ang); c.visible = false

## Stairs from (x, d) climbing toward yaw over 4 m (rise 2) or 6 m tall (rise 3). Smooth ramp collider.
func stairs(x: float, d: float, yaw: float, tall := false, wide := false) -> void:
	var id := "q:Platform_Stairs_4WideTall" if tall else ("q:Platform_Stairs_4Wide" if wide else "q:Platform_Stairs_4")
	var run := 6.08 if tall else 4.08; var rise := 3.0 if tall else 2.0; var w := 4.0 if (tall or wide) else 2.0
	var xf := XF(x, d, yaw)
	var n := Kit.spawn(id, geo, xf, "none")
	# ramp: piece local +z runs up the stairs
	var L := sqrt(run * run + rise * rise)
	var body := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(w, 0.2, L)
	cs.shape = sh; body.add_child(cs); n.add_child(body)
	cs.position = Vector3(0, rise * 0.5 - 0.1, run * 0.5)
	cs.rotation.x = -atan2(rise, run)

# ---------------------------------------------------------------- light
func lamp(x: float, d: float, y: float, energy := 4.5, angle := 55.0, col := Color(), fixture := "q:Prop_Light_Wide") -> SpotLight3D:
	var c: Color = col if col != Color() else b.th["light"]
	if fixture != "": Kit.spawn(fixture, geo, XF(x + 0.66, d, 90, y), "none", false)
	var shadow := _shadow_left > 0
	if shadow: _shadow_left -= 1
	var s := b.spot(r, P(x, d, y - 0.2), c, energy, y + 5.0, angle, shadow)
	r.lights.append(s)
	if shadow: r.shadow_lights.append(s)
	return s

func glow_strip(x: float, d: float, y: float, length: float, yaw := 0.0, col := Color(), energy := 3.0) -> void:
	box(Vector3(0.06, 0.06, length), x, d, y, Mats.glow(col if col != Color() else accent, energy), false, yaw)

func fill(x: float, d: float, y: float, col: Color, energy := 0.6, rad := 8.0) -> OmniLight3D:
	return b.omni(r, P(x, d, y), col, energy, rad)

# ---------------------------------------------------------------- gameplay
## Pickup for intel document k (desk or crate top). Height of the surface in `top`.
func intel(k: int, x: float, d: float, yaw := 0.0, top := 0.9, desk := "") -> void:
	var docs: Array = r.data.get("intel", [])
	if k >= docs.size(): return
	if desk != "": piece(desk, x, d, yaw)
	var n := Node3D.new(); n.name = "Intel%d" % k; r.add_child(n); n.position = P(x, d)
	n.basis = yaw_basis(yaw)
	b.box(n, Vector3(0.36, 0.03, 0.26), Vector3(0, top + 0.02, 0), Mats.flat(Color(0.75, 0.62, 0.35), 0.8), false)
	var tab := b.box(n, Vector3(0.3, 0.02, 0.22), Vector3(0.3, top + 0.02, 0.05), Mats.glow(Color(1.0, 0.82, 0.4), 1.3), false)
	tab.rotation.y = 0.3
	var gl := b.omni(n, Vector3(0, top + 0.4, 0), Color(1.0, 0.8, 0.45), 0.9, 2.6)
	n.set_meta("doc", docs[k]); n.set_meta("k", k); n.set_meta("glow", gl); n.set_meta("tab", tab)
	r.intel.append(n)

## LEDGER uplink: a field case on a crate, screen facing yaw. Interaction point 1 m in front.
func terminal(x: float, d: float, yaw := 180.0) -> void:
	var bs := yaw_basis(yaw)
	var base := b.box(geo, Vector3(1.0, 0.8, 0.7), P(x, d, 0.4), Mats.pbr("gunmetal", 1.0)); base.basis = bs
	var lid := b.box(geo, Vector3(0.9, 0.6, 0.05), P(x, d, 1.1) + bs * Vector3(0, 0, 0.3), Mats.pbr("gunmetal", 1.0), false); lid.basis = bs * Basis(Vector3.RIGHT, -0.25)
	var scr := b.box(geo, Vector3(0.78, 0.48, 0.02), P(x, d, 1.1) + bs * Vector3(0, 0, 0.27), Mats.glow(Color(0.25, 0.95, 0.5), 1.4), false, false); scr.basis = bs * Basis(Vector3.RIGHT, -0.25)
	var l := b.label(r, "LEDGER UPLINK", P(x, d, 1.12) + bs * Vector3(0, 0, 0.255), 0, 26, Color(0.05, 0.1, 0.06), "IBMPlexMono-Medium", 0, HORIZONTAL_ALIGNMENT_CENTER, false)
	l.basis = bs * Basis(Vector3.RIGHT, -0.25)
	var t := Node3D.new(); t.name = "Terminal"; r.add_child(t); t.position = P(x, d) + bs * Vector3(0, 0, 1.0)
	t.set_meta("screen", scr)
	r.terminal = t
	b.omni(r, P(x, d, 1.4) + bs * Vector3(0, 0, 0.6), Color(0.3, 1.0, 0.5), 0.5, 3.0)

## Guard post. route: Array of [x, d, wait_s, look_yaw or null]; empty = stands at post facing yaw.
## tier: 0 always · 1 Regular and Veteran · 2 Veteran only. y: floor height (catwalks, decks).
func guard(x: float, d: float, yaw: float, route: Array = [], variant := "css", tier := 0, y := 0.0) -> void:
	var pts: Array = []; var waits: Array = []; var looks: Array = []
	for w in route:
		pts.append(P(w[0], w[1], y)); waits.append(float(w[2]) if w.size() > 2 else 2.0)
		looks.append(w[3] if w.size() > 3 else null)
	r.guards.append({"pos": P(x, d, y + 0.05), "yaw": yaw, "patrol": pts, "waits": waits, "looks": looks, "variant": variant, "tier": tier})

## Combat spawn point (where alerted defenders appear) and optional cover hint.
func spawn(x: float, d: float) -> void: r.spawn_points.append(P(x, d))
func cover_pt(x: float, d: float) -> void: r.cover_points.append(P(x, d))

## Dark area: guards see you only up close here, and awareness builds slowly.
func dark(x0: float, d0: float, x1: float, d1: float) -> void:
	var a := P(x0, d0); var e := P(x1, d1)
	r.dark_zones.append(Rect2(minf(a.x, e.x), minf(a.z, e.z), absf(e.x - a.x), absf(e.z - a.z)))

## Security camera or searchlight sweeping yaw ± sweep degrees.
func camera(x: float, d: float, y: float, yaw: float, sweep := 40.0, period := 8.0, rng := 16.0, searchlight := false) -> void:
	var c := SecurityCam.new(); r.add_child(c)
	c.setup(r, P(x, d, y), yaw, sweep, period, rng, searchlight, self)
	r.cams.append(c)

func note(text: String, x: float, d: float) -> void: notes.append([text, P(x, d)])

func label(text: String, x: float, d: float, y: float, yaw: float, size := 64, col := Color.WHITE, font := "Rajdhani-Bold") -> Label3D:
	var l := b.label(r, text, P(x, d, y), 0, size, col, font, 0, HORIZONTAL_ALIGNMENT_CENTER)
	l.basis = yaw_basis(yaw)
	return l

## In-world answer consoles. screen: [x, d, yaw] of the wall screen; spots: up to 4 [x, d, yaw].
func call_panels(screen: Array, spots: Array) -> void:
	var cp := CallPanels.new(); cp.name = "CallPanels"; r.add_child(cp)
	cp.setup(r, self, screen, spots)
	r.panels = cp
	var t := Node3D.new(); t.name = "Terminal"; r.add_child(t); t.position = P(screen[0], screen[1]) + yaw_basis(screen[2]) * Vector3(0, 0, 2.5)
	r.terminal = t

## Breaker panel: cut the sector's lights. Emergency red lighting, the whole room becomes shadow.
func power_box(x: float, d: float, yaw: float) -> void:
	piece("ph:power_box_01", x, d, yaw, 1.1, "none")
	var pos := P(x, d) + yaw_basis(yaw) * Vector3(0, 0, -0.9)
	var entry := {"pos": pos, "radius": 1.6, "prompt": "Cut the power  ·  lights out, harder to spot you"}
	entry["cb"] = func():
		r.extra.erase(entry)
		Audio.play3d("door_open", pos, -2.0, 0.0, 12.0)
		for l in r.lights:
			if is_instance_valid(l): (l as Light3D).light_energy *= 0.08; (l as Light3D).light_color = Color(1.0, 0.3, 0.25)
		r.dark_zones.append(Rect2(-r.W * 0.5 - 2.0, r.z1 - 1.0, r.W + 4.0, r.D + 2.0))
		Game.add_xp(25, "POWER CUT")
	r.extra.append(entry)
	note("Breaker: cut the lights", x, d)

## Hand-placed anchor for a sector mode (directors, racks, console, boss, nodes, blast, cell, path,
## perch, escort ...). Values are world positions (or [pos, rot] pairs for racks).
func anchor(name: String, value) -> void: r.set_meta("a_" + name, value)

## The sector's STRATEGY WALL (chapter key ideas) — centre of the panel at (x, d, y), facing yaw.
func strategy_wall(x: float, d: float, yaw: float, y := 3.0) -> void:
	placed_wall = true
	b.strategy_wall(r, geo, P(x, d, y), PI - deg_to_rad(yaw))
	note("Strategy wall", x, d)

# ================================================================ set pieces
# Deterministic composite props. Each takes a position and yaw; nothing inside is random.

var _rack_m: Material
func _rack_mat() -> Material:
	if _rack_m: return _rack_m
	var led := b._led_tex()
	var sm := StandardMaterial3D.new(); sm.albedo_texture = led; sm.emission_enabled = true; sm.emission_texture = led
	sm.emission_energy_multiplier = 1.6; sm.roughness = 0.35; sm.metallic = 0.6
	_rack_m = sm; return sm

## Server racks in a row along the yaw axis (n cabinets, 0.8 m wide each), optional cold-aisle glow.
func server_row(x: float, d: float, yaw: float, n: int, glow := true) -> void:
	var bs := yaw_basis(yaw)
	var L := n * 0.8
	var c := P(x, d)
	var body := b.box(geo, Vector3(1.1, 2.3, L), c + Vector3(0, 1.15, 0), b.mat("gunmetal", 1.0)); body.basis = bs
	var face := b.box(geo, Vector3(0.02, 2.0, L - 0.1), c + bs * Vector3(0.56, 1.1, 0), _rack_mat(), false, false); face.basis = bs
	var face2 := b.box(geo, Vector3(0.02, 2.0, L - 0.1), c + bs * Vector3(-0.56, 1.1, 0), _rack_mat(), false, false); face2.basis = bs
	b.box(geo, Vector3(1.2, 0.08, L + 0.1), c + Vector3(0, 2.34, 0), b.mat("steel", 1.0), false).basis = bs
	if glow: b.box(geo, Vector3(0.04, 0.04, L), c + bs * Vector3(0.6, 2.25, 0), Mats.glow(accent, 2.0), false, false).basis = bs
	for s in [-1.0, 1.0]:
		var e := c + bs * Vector3(0, 0, s * (L * 0.5 + 0.7))
		r.cover_points.append(Vector3(e.x, 0, e.z))
	r.cover_points.append(c + bs * Vector3(1.3, 0, 0)); r.cover_points.append(c + bs * Vector3(-1.3, 0, 0))

## Office desk with monitor/laptop and chair. kind: "monitor", "laptop", "bare"
func desk(x: float, d: float, yaw: float, kind := "monitor", chair := true) -> void:
	piece("ph:metal_office_desk", x, d, yaw)
	var bs := yaw_basis(yaw)
	var top := P(x, d, 0.78)
	match kind:
		"monitor":
			var m := b.box(geo, Vector3(0.62, 0.38, 0.03), top + bs * Vector3(0, 0.3, -0.25), Mats.glow(Color(0.35, 0.55, 0.9), 0.9), false, false); m.basis = bs
			b.box(geo, Vector3(0.66, 0.42, 0.02), top + bs * Vector3(0, 0.3, -0.27), b.mat("gunmetal", 1.0), false, false).basis = bs
			b.box(geo, Vector3(0.05, 0.25, 0.05), top + bs * Vector3(0, 0.12, -0.3), b.mat("gunmetal", 1.0), false, false).basis = bs
		"laptop":
			Kit.spawn("ph:classic_laptop", geo, Transform3D(bs, top + bs * Vector3(0.2, 0, -0.05)), "none")
	if chair: Kit.spawn("ph:dining_chair_02", geo, Transform3D(bs * Basis(Vector3.UP, PI), P(x, d) + bs * Vector3(0.1, 0, 0.75)), "none")
	r.cover_points.append(P(x, d) + bs * Vector3(0, 0, 1.0))

## Storage shelving unit 2.4 m with crates and boxes on it.
func shelf(x: float, d: float, yaw: float, fill_kind := 0) -> void:
	piece("ph:steel_frame_shelves_03", x, d, yaw)
	var bs := yaw_basis(yaw)
	var items := [["ph:cardboard_box_01", -0.7, 0.05], ["ph:plastic_crate_02", 0.1, 0.05], ["ph:cardboard_box_01", 0.8, 0.83], ["ph:plastic_crate_01", -0.5, 0.83], ["ph:cardboard_box_01", 0.3, 1.58], ["ph:wooden_crate_02", -0.6, 1.58]]
	for i in items.size():
		if (i + fill_kind) % 3 == 2: continue
		var it: Array = items[i]
		Kit.spawn(it[0], geo, Transform3D(bs, P(x, d, it[2]) + bs * Vector3(it[1], 0, 0)), "none")

## Glass-walled room on the floor plan (x0,d0)-(x1,d1); door gap on side "n"/"s"/"e"/"w" at offset.
func glass_room(x0: float, d0: float, x1: float, d1: float, door_side := "s", door_at := 0.5, h := 3.0) -> void:
	var frame := b.mat("gunmetal", 1.0)
	var sides := {"n": [Vector2(x0, d0), Vector2(x1, d0)], "s": [Vector2(x0, d1), Vector2(x1, d1)], "w": [Vector2(x0, d0), Vector2(x0, d1)], "e": [Vector2(x1, d0), Vector2(x1, d1)]}
	for k in sides.keys():
		var a: Vector2 = sides[k][0]; var e: Vector2 = sides[k][1]
		var segs: Array = [[a, e]]
		if k == door_side:
			var mid := a.lerp(e, door_at); var dir := (e - a).normalized()
			segs = [[a, mid - dir * 0.6], [mid + dir * 0.6, e]]
			box(Vector3(0.12, 0.6, 1.3), mid.x, mid.y, h - 0.3, frame, false, rad_to_deg(atan2(dir.x, dir.y)))
		for sg in segs:
			var p0: Vector2 = sg[0]; var p1: Vector2 = sg[1]
			var L := (p1 - p0).length()
			if L < 0.2: continue
			var mid2 := (p0 + p1) * 0.5; var ang := rad_to_deg(atan2(p1.x - p0.x, p1.y - p0.y))
			box(Vector3(0.05, h - 0.2, L), mid2.x, mid2.y, (h - 0.2) * 0.5 + 0.1, Mats.glass(), true, ang)
			box(Vector3(0.1, 0.1, L), mid2.x, mid2.y, h - 0.05, frame, false, ang)
			box(Vector3(0.1, 0.1, L), mid2.x, mid2.y, 0.05, frame, false, ang)
			for k2 in int(L / 1.5) + 1:
				var pp := p0.lerp(p1, k2 / maxf(1.0, float(int(L / 1.5))))
				box(Vector3(0.08, h, 0.08), pp.x, pp.y, h * 0.5, frame, false)

## Overhead pipe bundle between two floor-plan points at height y.
func pipes(x0: float, d0: float, x1: float, d1: float, y: float, n := 3) -> void:
	var a := Vector2(x0, d0); var e := Vector2(x1, d1); var L := (e - a).length()
	var dir := (e - a) / L; var nn := Vector2(-dir.y, dir.x)
	var cols := [b.mat("steel", 1.0), b.mat("gunmetal", 1.0), Mats.flat(Color(0.25, 0.32, 0.4), 0.5, 0.6)]
	for i in n:
		var o := nn * (i - (n - 1) * 0.5) * 0.38
		var mid := (a + e) * 0.5 + o
		var mi := b.cyl(geo, 0.14, L, P(mid.x, mid.y, y), cols[i % 3])
		mi.basis = yaw_basis(rad_to_deg(atan2(dir.x, dir.y))) * Basis(Vector3.RIGHT, PI * 0.5)
	for k in int(L / 4.0) + 1:
		var p := a + dir * minf(L, k * 4.0)
		box(Vector3(0.06, 0.06, n * 0.4 + 0.2), p.x, p.y, y + 0.2, b.mat("steel", 1.0), false, rad_to_deg(atan2(nn.x, nn.y)))

## Floor marking strip (paint) between two points.
func paint(x0: float, d0: float, x1: float, d1: float, col := Color(0.9, 0.75, 0.2), w := 0.12) -> void:
	var a := Vector2(x0, d0); var e := Vector2(x1, d1)
	var mid := (a + e) * 0.5
	box(Vector3(w, 0.01, (e - a).length()), mid.x, mid.y, 0.012, Mats.flat(col, 0.8), false, rad_to_deg(atan2(e.x - a.x, e.y - a.y)))

## Crate stack (cover): kind 0 military crates, 1 cardboard on pallet, 2 TPS cargo boxes.
func crates(x: float, d: float, yaw: float, kind := 0) -> void:
	match kind:
		0:
			cover("ph:wooden_military_crate", x, d, yaw)
			piece("ph:wooden_military_crate", x, d, yaw + 4, 0.5, "box")
		1:
			cover("ph:old_military_crate", x, d, yaw)
			piece("ph:cardboard_box_01", x - 0.4, d, yaw + 10, 0.3, "none")
			piece("ph:cardboard_box_01", x + 0.4, d + 0.1, yaw - 8, 0.3, "none")
		2:
			cover("tps:prop_cargobox2", x, d, yaw)

## Tall cover column of the kit (blocks sight lines in stealth spaces).
func pillar(x: float, d: float, kind := "q:Column_Pipes") -> void:
	piece(kind, x, d, 0, 0, "box")
	r.cover_points.append(P(x + 1.0, d)); r.cover_points.append(P(x - 1.0, d))

## Industrial chiller unit (cover, blocks sight): body, top fans, side pipes. Long axis along yaw.
func chiller(x: float, d: float, yaw: float, L := 6.0) -> void:
	var bs := yaw_basis(yaw); var c := P(x, d)
	b.box(geo, Vector3(2.8, 2.5, L), c + Vector3(0, 1.25, 0), b.mat("gunmetal", 1.5)).basis = bs
	b.box(geo, Vector3(2.9, 0.15, L + 0.1), c + Vector3(0, 2.55, 0), b.mat("steel", 1.0), false).basis = bs
	for k in int(L / 2.0):
		Kit.spawn("q:Prop_Fan_Small", geo, Transform3D(bs, c + bs * Vector3(0, 2.62, -L * 0.5 + 1.0 + k * 2.0)), "none")
	for s in [-1.0, 1.0]:
		var pm := b.cyl(geo, 0.16, L, c + bs * Vector3(s * 1.55, 0.6, 0), b.mat("steel", 1.0)); pm.basis = bs * Basis(Vector3.RIGHT, PI * 0.5)
		Kit.spawn("q:Prop_Vent_Wide", geo, Transform3D(bs * Basis(Vector3.FORWARD, s * PI * 0.5), c + bs * Vector3(s * 1.41, 1.5, L * 0.25)), "none")
	b.box(geo, Vector3(0.05, 0.3, 0.5), c + bs * Vector3(1.42, 1.9, -L * 0.3), Mats.glow(Color(0.3, 1.0, 0.5), 2.0), false, false).basis = bs
	for s2 in [-1.0, 1.0]:
		r.cover_points.append(c + bs * Vector3(s2 * 2.1, 0, -L * 0.3)); r.cover_points.append(c + bs * Vector3(s2 * 2.1, 0, L * 0.3))
		r.cover_points.append(c + bs * Vector3(0, 0, s2 * (L * 0.5 + 0.8)))

## Low crawl duct (crouch only): a tunnel along an axis, 1.25 m clear height, sealed sides.
func duct(x0: float, d0: float, x1: float, d1: float, w := 1.6) -> void:
	var a := Vector2(x0, d0); var e := Vector2(x1, d1); var mid := (a + e) * 0.5; var L := (e - a).length()
	var ang := rad_to_deg(atan2(e.x - a.x, e.y - a.y))
	var m := b.mat("steel", 2.0)
	box(Vector3(w + 0.2, 0.12, L), mid.x, mid.y, 1.31, m, true, ang)
	var dir := (e - a) / L; var nn := Vector2(-dir.y, dir.x)
	for s in [-1.0, 1.0]:
		var o: Vector2 = mid + nn * s * (w * 0.5 + 0.05)
		box(Vector3(0.1, 1.3, L), o.x, o.y, 0.65, m, true, ang)
	for k in int(L / 2.0) + 1:
		var p := a + dir * minf(L, k * 2.0)
		box(Vector3(w + 0.3, 0.08, 0.12), p.x, p.y, 1.4, b.mat("gunmetal", 1.0), false, ang)
	dark(minf(x0, x1) - w * 0.5, minf(d0, d1), maxf(x0, x1) + w * 0.5, maxf(d0, d1))

## Ceiling light grid: emissive panels on the ceiling with a spot under each (shadows on a few).
func ceiling_lights(x0: float, d0: float, x1: float, d1: float, h: float, nx: int, nd: int, energy := 7.0, col := Color(), panel := Vector2(1.6, 0.5)) -> void:
	var c: Color = col if col != Color() else b.th["light"]
	for i in nx:
		for j in nd:
			var x := x0 + (x1 - x0) * (i + 0.5) / nx
			var d := d0 + (d1 - d0) * (j + 0.5) / nd
			box(Vector3(panel.x, 0.06, panel.y), x, d, h - 0.04, Mats.glow(c.lerp(Color.WHITE, 0.5), 4.0), false)
			lamp(x, d, h - 0.1, energy, 68.0, c, "")

## Training range furniture: firing line, lane paint, results board on the far wall, target slots.
func range_kit(line_d: float, board_y := 4.4, slots: Array = []) -> void:
	for x in [-3.2, 3.2]: Kit.spawn("tps:prop_transitbarrierdirection", geo, XF(x, line_d, 0), "box")
	box(Vector3(r.W - 1.0, 0.02, 0.35), 0, line_d + 0.7, 0.01, b._hazard(), false)
	var board := Node3D.new(); board.name = "Board"; r.add_child(board); board.position = P(0, r.D - 0.25, board_y)
	b.box(board, Vector3(8.4, 2.2, 0.1), Vector3.ZERO, Mats.flat(Color(0.03, 0.035, 0.04), 0.4), false, false)
	r.set_meta("board", board)
	var w: Array = []
	for s in slots: w.append(P(s[0], s[1]))
	if not w.is_empty(): r.set_meta("target_slots", w)

## Conveyor belt between two points (axis-aligned), belt top at h, with parcels on it.
func conveyor(x0: float, d0: float, x1: float, d1: float, h := 0.95, parcels := 4) -> void:
	var a := Vector2(x0, d0); var e := Vector2(x1, d1); var L := (e - a).length(); var mid := (a + e) * 0.5
	var ang := rad_to_deg(atan2(e.x - a.x, e.y - a.y))
	box(Vector3(1.3, 0.25, L), mid.x, mid.y, h - 0.12, b.mat("steel", 1.0), true, ang)
	box(Vector3(1.1, 0.03, L), mid.x, mid.y, h + 0.02, Mats.flat(Color(0.05, 0.05, 0.05), 0.9), false, ang)
	for s in [-1.0, 1.0]:
		var dir := (e - a) / L; var nn: Vector2 = Vector2(-dir.y, dir.x) * s * 0.68
		box(Vector3(0.06, 0.18, L), mid.x + nn.x, mid.y + nn.y, h + 0.06, Mats.flat(Color(0.9, 0.7, 0.15), 0.6), false, ang)
	for k in int(L / 2.5) + 1:
		var p := a.lerp(e, k / maxf(1.0, float(int(L / 2.5))))
		box(Vector3(1.2, h - 0.25, 0.12), p.x, p.y, (h - 0.25) * 0.5, b.mat("gunmetal", 1.0), false, ang)
	for i in parcels:
		var q := a.lerp(e, (i + 0.5) / parcels)
		piece("ph:cardboard_box_01", q.x, q.y, ang + i * 23.0, h + 0.03, "none")
	var dir2 := (e - a) / L
	r.cover_points.append(P(mid.x + dir2.y * 1.2, mid.y - dir2.x * 1.2)); r.cover_points.append(P(mid.x - dir2.y * 1.2, mid.y + dir2.x * 1.2))

## Pallet rack bay: tall racking with pallets of boxes (blocks sight), long axis along yaw.
func pallet_rack(x: float, d: float, yaw: float, bays := 3, levels := 3) -> void:
	var bs := yaw_basis(yaw); var L := bays * 2.8; var c := P(x, d)
	var orange := Mats.flat(Color(0.95, 0.45, 0.1), 0.6, 0.3); var blue := Mats.flat(Color(0.12, 0.25, 0.6), 0.6, 0.3)
	for k in bays + 1:
		var o := bs * Vector3(0, 0, -L * 0.5 + k * 2.8)
		for s in [-0.55, 0.55]: b.box(geo, Vector3(0.08, levels * 1.6 + 0.4, 0.08), c + o + bs * Vector3(s, (levels * 1.6 + 0.4) * 0.5, 0), blue, false).basis = bs
	for lv in levels:
		var y := 0.15 + lv * 1.6
		b.box(geo, Vector3(1.2, 0.1, L), c + Vector3(0, y + 1.45, 0), orange, false).basis = bs
		for k2 in bays:
			var o2 := bs * Vector3(0, y, -L * 0.5 + 1.4 + k2 * 2.8)
			if (k2 + lv) % 4 != 3:
				b.box(geo, Vector3(1.0, 1.1 - 0.2 * ((k2 + lv) % 2), 1.9), c + o2 + Vector3(0, 0.62, 0), Mats.prop("cargo", {"metal": 0.2}) if (k2 + lv) % 3 == 0 else Mats.flat(Color(0.62, 0.48, 0.32), 0.9), false).basis = bs
	var col := b.box(geo, Vector3(1.2, levels * 1.6, L), c + Vector3(0, levels * 0.8, 0), Mats.flat(Color.BLACK), true); col.basis = bs; col.visible = false
	for s2 in [-1.0, 1.0]:
		r.cover_points.append(c + bs * Vector3(0, 0, s2 * (L * 0.5 + 0.8)))

## Plain ramp (concrete/steel) from (x, d) running toward yaw, rising `rise` over `run`.
func ramp(x: float, d: float, yaw: float, rise: float, run: float, w := 2.4, m: Material = null) -> void:
	var L := sqrt(run * run + rise * rise)
	var bs := yaw_basis(yaw)
	var c := P(x, d) + bs * Vector3(0, rise * 0.5 - 0.1, run * 0.5)
	var mi := b.box(geo, Vector3(w, 0.2, L), c, m if m else b.mat("antislip", 1.0))
	mi.basis = bs * Basis(Vector3.RIGHT, -atan2(rise, run))

## Box truck backed toward +x (cargo box east of the cab).
func truck(x: float, d: float) -> void:
	var c := P(x, d)
	b.box(geo, Vector3(7.0, 2.8, 2.5), c + Vector3(-0.5, 1.9, 0), Mats.pbr("cont2", 2.0))
	b.box(geo, Vector3(2.4, 2.4, 2.4), c + Vector3(-4.6, 1.5, 0), Mats.flat(Color(0.75, 0.75, 0.78), 0.4, 0.4))
	b.box(geo, Vector3(0.05, 0.9, 2.2), c + Vector3(-5.81, 2.1, 0), Mats.glass(), false)
	for s in [-1.0, 1.0]:
		for xx in [-3.0, 1.5, 2.6]:
			var w := b.cyl(geo, 0.48, 0.35, c + Vector3(xx - 1.0, 0.48, s * 1.1), Mats.flat(Color(0.05, 0.05, 0.05), 0.9))
			w.rotation = Vector3(PI * 0.5, 0, 0)
	r.cover_points.append(c + Vector3(-1.0, 0, 2.0)); r.cover_points.append(c + Vector3(-1.0, 0, -2.0))

## Shipping containers stacked `levels` high (6.25 x 3.1 x 3.1 m each), long axis along yaw.
func containers(x: float, d: float, yaw: float, levels := 1, kind := 0) -> void:
	for lv in levels:
		var id := "tps:prop_container2" if (kind + lv) % 2 == 0 else "tps:prop_container3"
		Kit.spawn(id, geo, XF(x, d, yaw + (2.0 if lv % 2 == 1 else 0.0), lv * 3.11), "box")
	var bs := yaw_basis(yaw); var c := P(x, d)
	for s in [-1.0, 1.0]:
		r.cover_points.append(c + bs * Vector3(s * 2.3, 0, 1.8)); r.cover_points.append(c + bs * Vector3(s * 2.3, 0, -1.8))
		r.cover_points.append(c + bs * Vector3(0, 0, s * 3.9))

## Dark water plane (harbour) with an invisible barrier along its edge.
func water(x0: float, d0: float, x1: float, d1: float, y := -1.2) -> void:
	var m := StandardMaterial3D.new(); m.albedo_color = Color(0.02, 0.04, 0.05); m.roughness = 0.05; m.metallic = 0.3
	box(Vector3(absf(x1 - x0), 0.1, absf(d1 - d0)), (x0 + x1) * 0.5, (d0 + d1) * 0.5, y, m, false)
	var blk := box(Vector3(absf(x1 - x0), 4.0, absf(d1 - d0)), (x0 + x1) * 0.5, (d0 + d1) * 0.5, 2.0, m, true); blk.visible = false

## Poured-concrete room shell (bunkers, car parks, service levels): thick walls with door gaps at
## x∈[-2,2] on the entry and exit walls, structural ribs every `rib` metres, optional ceiling.
func concrete_shell(H := 5.0, rib := 6.0, ceil := true, m: Material = null) -> void:
	var cm := m if m else b.mat("CONCRETE", 4.0)
	var hw := r.W * 0.5
	for dd in [0.0, r.D]:
		box(Vector3(hw - 2.0, H, 0.8), -(hw + 2.0) * 0.5, dd, H * 0.5, cm)
		box(Vector3(hw - 2.0, H, 0.8), (hw + 2.0) * 0.5, dd, H * 0.5, cm)
		box(Vector3(4.0, H - 4.0, 0.8), 0, dd, 4.0 + (H - 4.0) * 0.5, cm)
	for s in [-1.0, 1.0]:
		box(Vector3(0.8, H, r.D + 0.8), s * (hw + 0.4), r.D * 0.5, H * 0.5, cm)
		var k := 0
		while k * rib <= r.D:
			box(Vector3(0.5, H, 0.6), s * (hw - 0.25), k * rib, H * 0.5, cm)
			k += 1
	if ceil:
		ceiling(-hw, 0, hw, r.D, H)
		var k2 := 0
		while k2 * rib <= r.D:
			box(Vector3(r.W, 0.5, 0.6), 0, k2 * rib, H - 0.25, cm, false)
			k2 += 1

## Shop unit: glass front (door gap) facing yaw, lit sign, display furniture inside. w along front,
## depth 4 m behind the front line. (x, d) is the centre of the front line.
func storefront(x: float, d: float, yaw: float, w: float, name: String, col: Color, kind := 0) -> void:
	var bs := yaw_basis(yaw); var c := P(x, d)
	for s in [-1.0, 1.0]:
		var seg := (w - 1.8) * 0.5
		var g := b.box(geo, Vector3(seg, 2.8, 0.06), c + bs * Vector3(s * (0.9 + seg * 0.5), 1.4, 0), Mats.glass(), true); g.basis = bs
	b.box(geo, Vector3(w, 0.9, 0.3), c + bs * Vector3(0, 3.25, 0), Mats.flat(Color(0.05, 0.05, 0.06), 0.4), false).basis = bs
	var l := b.label(r, name, c + bs * Vector3(0, 3.25, 0.17), 0, 72, col, "Rajdhani-Bold", 0, HORIZONTAL_ALIGNMENT_CENTER)
	l.basis = bs
	for s2 in [-1.0, 1.0]: b.box(geo, Vector3(0.2, 3.7, 4.0), c + bs * Vector3(s2 * w * 0.5, 1.85, -2.0), b.mat("techc", 2.0)).basis = bs
	b.box(geo, Vector3(w, 3.7, 0.2), c + bs * Vector3(0, 1.85, -4.0), b.mat("techc", 2.0)).basis = bs
	b.box(geo, Vector3(w, 0.1, 4.0), c + bs * Vector3(0, 3.75, -2.0), Mats.flat(Color(0.9, 0.9, 0.9), 0.5), false).basis = bs
	b.omni(r, c + bs * Vector3(0, 2.8, -2.0), col.lerp(Color.WHITE, 0.6), 0.9, 5.5)
	match kind:
		0:
			for s3 in [-1.0, 1.0]: Kit.spawn("ph:steel_frame_shelves_02", geo, Transform3D(bs, c + bs * Vector3(s3 * (w * 0.5 - 0.5), 0, -3.6)), "box")
			b.box(geo, Vector3(1.6, 0.9, 0.8), c + bs * Vector3(0, 0.45, -2.0), Mats.flat(Color(0.85, 0.82, 0.76), 0.5), true).basis = bs
		1:
			Kit.spawn("ph:sofa_02", geo, Transform3D(bs * Basis(Vector3.UP, PI), c + bs * Vector3(0, 0, -3.3)), "box")
			Kit.spawn("ph:side_table_01", geo, Transform3D(bs, c + bs * Vector3(1.5, 0, -3.3)), "none")
		2:
			for k in 3: Kit.spawn("ph:Television_01", geo, Transform3D(bs, c + bs * Vector3(-w * 0.3 + k * w * 0.3, 0.9, -3.6)), "none")
			b.box(geo, Vector3(w - 1.0, 0.9, 0.6), c + bs * Vector3(0, 0.45, -3.6), b.mat("gunmetal", 1.0), true).basis = bs

## Planter (concrete box with shrubs as dark mounds) — low cover.
func planter(x: float, d: float, w := 2.0, l := 2.0) -> void:
	box(Vector3(w, 0.7, l), x, d, 0.35, b.mat("CONCRETE", 1.0))
	var leaf := Mats.flat(Color(0.12, 0.22, 0.1), 0.9)
	for k in 3:
		b.cyl(geo, minf(w, l) * 0.3, 0.6, P(x - w * 0.25 + k * w * 0.25, d, 0.95), leaf)
	cover_pt(x, d - l * 0.5 - 0.7); cover_pt(x, d + l * 0.5 + 0.7)

## Security turnstile gate line across x0..x1 at d (passage gaps every 2 m), low cover.
func turnstiles(x0: float, x1: float, d: float) -> void:
	var n := int((x1 - x0) / 2.0)
	for k in n + 1:
		var x := x0 + k * 2.0
		box(Vector3(0.35, 1.0, 1.4), x, d, 0.5, b.mat("steel", 1.0))
		box(Vector3(0.36, 0.05, 1.2), x, d, 1.02, Mats.glow(Color(0.4, 1.0, 0.6), 2.0), false)

## Distant lit towers outside both long walls (night city). floor_height: how high this floor is.
func city_view(floor_height := 0.0) -> void:
	var tex := _window_tex()
	var m := StandardMaterial3D.new(); m.albedo_color = Color(0.05, 0.06, 0.08); m.roughness = 0.3; m.metallic = 0.6
	m.emission_enabled = true; m.emission_texture = tex; m.emission_energy_multiplier = 1.4
	m.uv1_triplanar = true; m.uv1_scale = Vector3(0.05, 0.05, 0.05)
	var cz := (r.z0 + r.z1) * 0.5
	# fixed layout: [side, distance from the wall, z offset, width, depth, height]
	var towers := [[-1, 70, -60, 30, 30, 160], [-1, 110, 10, 40, 26, 220], [-1, 85, 70, 26, 26, 120], [-1, 160, -20, 50, 40, 260], [-1, 140, 110, 30, 30, 180],
		[1, 75, -40, 28, 34, 150], [1, 120, 30, 36, 30, 240], [1, 90, 95, 30, 24, 130], [1, 170, -90, 44, 44, 280], [1, 150, 60, 34, 34, 200]]
	for t in towers:
		var x: float = t[0] * (r.W * 0.5 + float(t[1]))
		var h: float = t[5]
		var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(t[3], h, t[4]); mi.mesh = bm; mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		r.add_child(mi); mi.position = Vector3(x, h * 0.5 - 120.0 - floor_height, cz + float(t[2]))
		var top := MeshInstance3D.new(); var tm := BoxMesh.new(); tm.size = Vector3(1.5, 1.5, 1.5); top.mesh = tm; top.material_override = Mats.glow(Color(1.0, 0.15, 0.1), 6.0)
		r.add_child(top); top.position = mi.position + Vector3(0, h * 0.5 + 1.0, 0)

static var _wtex: Texture2D
func _window_tex() -> Texture2D:
	if _wtex: return _wtex
	var img := Image.create(256, 256, false, Image.FORMAT_RGB8); img.fill(Color(0, 0, 0))
	for y in range(4, 252, 8):
		for x in range(3, 252, 6):
			var hsh := ((x * 73856093) ^ (y * 19349663)) & 1023
			if hsh < 300:
				var c := Color(1.0, 0.85, 0.6) if hsh < 220 else Color(0.7, 0.85, 1.0)
				for dy in 4:
					for dx in 3: img.set_pixel(x + dx, y + dy, c * (0.5 + (hsh % 50) / 100.0))
	_wtex = ImageTexture.create_from_image(img)
	return _wtex
