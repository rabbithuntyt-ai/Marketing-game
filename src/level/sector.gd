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
func wall(x0: float, d0: float, x1: float, d1: float, inside: Vector2, cells := "", style := "WallBand", top := "TopSimple") -> void:
	var a := Vector2(x0, d0); var e := Vector2(x1, d1)
	var dir := (e - a).normalized(); var n := Vector2(-dir.y, dir.x)
	if (inside - a).dot(n) < 0: n = -n
	var count := int(round((e - a).length() / 4.0))
	if cells == "": cells = "W".repeat(count)
	for i in count:
		var c := a + dir * (i * 4.0 + 2.0) + n * 2.0
		var t := XF(c.x, c.y, 0.0)
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
func guard(x: float, d: float, yaw: float, route: Array = [], variant := "css", veteran_only := false) -> void:
	var pts: Array = []; var waits: Array = []; var looks: Array = []
	for w in route:
		pts.append(P(w[0], w[1])); waits.append(float(w[2]) if w.size() > 2 else 2.0)
		looks.append(w[3] if w.size() > 3 else null)
	r.guards.append({"pos": P(x, d), "yaw": yaw, "patrol": pts, "waits": waits, "looks": looks, "variant": variant, "veteran": veteran_only})

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
