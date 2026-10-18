extends Node
## Visual effects: muzzle flashes, tracers, impacts, bullet holes, blood mist, explosions, debris, smoke.
## Particle systems are pooled and pre-warmed to avoid shader-compile hitches mid-fight.

var root: Node3D               # set by the mission
var cam_shake := 0.0
var _tex := {}
var _pools := {}
var _decals: Array = []
var _tracers: Array = []
var _tr_i := 0

func T(name: String) -> Texture2D:
	if not _tex.has(name): _tex[name] = load("res://assets/fx/%s.png" % name)
	return _tex[name]

static func make_flash_sprite(size := 0.4) -> Sprite3D:
	var s := Sprite3D.new(); s.texture = load("res://assets/fx/muzzle.png"); s.pixel_size = size / 128.0
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED; s.shaded = false; s.double_sided = true
	s.modulate = Color(1.4, 1.15, 0.8); s.render_priority = 10
	var m := StandardMaterial3D.new(); m.albedo_texture = s.texture; m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED; m.albedo_color = Color(1.4, 1.1, 0.7)
	s.material_override = m
	return s

func setup(r: Node3D) -> void:
	root = r
	_pools.clear(); _decals.clear(); _tracers.clear()
	for i in 24:
		var t := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.012, 0.012, 1.0); t.mesh = bm
		var m := StandardMaterial3D.new(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; m.albedo_color = Color(1.0, 0.85, 0.55, 0.8); m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD; m.emission_enabled = true; m.emission = Color(1.0, 0.75, 0.4); m.emission_energy_multiplier = 3.0
		t.material_override = m; t.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; t.visible = false; t.top_level = true
		root.add_child(t); _tracers.append({"n": t, "t": 0.0, "max": 0.05})
	# warm every particle type once, far below the level
	for kind in ["sparks", "dust", "blood", "fire", "smoke", "debris", "ring"]: _take(kind).global_position = Vector3(0, -500, 0)

func _process(dt: float) -> void:
	cam_shake = maxf(0.0, cam_shake - dt * 1.6)
	for tr in _tracers:
		if tr["t"] > 0.0 and is_instance_valid(tr["n"]):
			tr["t"] -= dt
			(tr["n"].material_override as StandardMaterial3D).albedo_color.a = clampf(tr["t"] / tr["max"], 0.0, 1.0) * 0.8
			if tr["t"] <= 0.0: tr["n"].visible = false

# ---------------------------------------------------------------- particle templates
func _mat(tex: Texture2D, add := false, col := Color.WHITE, lit := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_texture = tex; m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if add: m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL if lit else BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES; m.vertex_color_use_as_albedo = true; m.albedo_color = col
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func _make(kind: String) -> GPUParticles3D:
	var p := GPUParticles3D.new(); p.one_shot = true; p.emitting = false; p.explosiveness = 0.95; p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-8, -8, -8), Vector3(16, 16, 16)); p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := ParticleProcessMaterial.new()
	var q := QuadMesh.new()
	var grad := Gradient.new()
	match kind:
		"sparks":
			p.amount = 14; p.lifetime = 0.45
			pm.direction = Vector3(0, 0, 1); pm.spread = 55.0; pm.initial_velocity_min = 3.0; pm.initial_velocity_max = 9.0; pm.gravity = Vector3(0, -12, 0)
			pm.scale_min = 0.5; pm.scale_max = 1.0
			q.size = Vector2(0.03, 0.03); var m := _mat(T("particle"), true, Color(1.6, 1.0, 0.45)); q.material = m
			grad.set_color(0, Color(1, 0.9, 0.6, 1)); grad.set_color(1, Color(1, 0.4, 0.1, 0))
		"dust":
			p.amount = 6; p.lifetime = 1.1
			pm.direction = Vector3(0, 0, 1); pm.spread = 30.0; pm.initial_velocity_min = 0.5; pm.initial_velocity_max = 1.6; pm.gravity = Vector3(0, 0.2, 0); pm.damping_min = 2.0; pm.damping_max = 3.0
			pm.scale_min = 0.6; pm.scale_max = 1.3; pm.angle_min = 0; pm.angle_max = 360
			var sc := Curve.new(); sc.add_point(Vector2(0, 0.3)); sc.add_point(Vector2(1, 1.4)); var ct := CurveTexture.new(); ct.curve = sc; pm.scale_curve = ct
			q.size = Vector2(0.45, 0.45); q.material = _mat(T("smoke"), false, Color(0.62, 0.6, 0.56, 0.5), true)
			grad.set_color(0, Color(1, 1, 1, 0.55)); grad.set_color(1, Color(1, 1, 1, 0))
		"blood":
			p.amount = 10; p.lifetime = 0.5
			pm.direction = Vector3(0, 0, 1); pm.spread = 35.0; pm.initial_velocity_min = 1.0; pm.initial_velocity_max = 3.5; pm.gravity = Vector3(0, -6, 0); pm.scale_min = 0.5; pm.scale_max = 1.2
			q.size = Vector2(0.18, 0.18); q.material = _mat(T("smoke"), false, Color(0.35, 0.02, 0.02, 0.8), true)
			grad.set_color(0, Color(1, 1, 1, 0.8)); grad.set_color(1, Color(1, 1, 1, 0))
		"fire":
			p.amount = 22; p.lifetime = 0.9; p.explosiveness = 0.85
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE; pm.emission_sphere_radius = 0.6
			pm.direction = Vector3.UP; pm.spread = 180.0; pm.initial_velocity_min = 2.0; pm.initial_velocity_max = 6.0; pm.gravity = Vector3(0, 2.5, 0); pm.damping_min = 3.0; pm.damping_max = 5.0
			pm.scale_min = 0.8; pm.scale_max = 1.8; pm.angle_min = 0; pm.angle_max = 360
			var sc2 := Curve.new(); sc2.add_point(Vector2(0, 0.6)); sc2.add_point(Vector2(1, 1.6)); var ct2 := CurveTexture.new(); ct2.curve = sc2; pm.scale_curve = ct2
			q.size = Vector2(1.6, 1.6); q.material = _mat(T("explosion"), true, Color(2.2, 1.5, 1.0))
			grad.set_color(0, Color(1, 1, 1, 1)); grad.add_point(0.4, Color(1, 0.6, 0.3, 0.8)); grad.set_color(grad.get_point_count() - 1, Color(0.3, 0.1, 0.05, 0))
		"smoke":
			p.amount = 16; p.lifetime = 4.0; p.explosiveness = 0.7
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE; pm.emission_sphere_radius = 0.8
			pm.direction = Vector3.UP; pm.spread = 40.0; pm.initial_velocity_min = 0.8; pm.initial_velocity_max = 2.2; pm.gravity = Vector3(0, 0.6, 0); pm.damping_min = 0.6; pm.damping_max = 1.2
			pm.scale_min = 1.0; pm.scale_max = 2.0; pm.angle_min = 0; pm.angle_max = 360
			var sc3 := Curve.new(); sc3.add_point(Vector2(0, 0.5)); sc3.add_point(Vector2(1, 2.8)); var ct3 := CurveTexture.new(); ct3.curve = sc3; pm.scale_curve = ct3
			q.size = Vector2(1.8, 1.8); q.material = _mat(T("smoke"), false, Color(0.16, 0.15, 0.14, 0.75), true)
			grad.set_color(0, Color(1, 1, 1, 0.7)); grad.set_color(1, Color(1, 1, 1, 0))
		"debris":
			p.amount = 18; p.lifetime = 1.6
			pm.direction = Vector3.UP; pm.spread = 70.0; pm.initial_velocity_min = 4.0; pm.initial_velocity_max = 11.0; pm.gravity = Vector3(0, -14, 0)
			pm.scale_min = 0.4; pm.scale_max = 1.2; pm.angular_velocity_min = -400; pm.angular_velocity_max = 400
			var bm := BoxMesh.new(); bm.size = Vector3(0.08, 0.05, 0.1); bm.material = Mats.flat(Color(0.18, 0.18, 0.2), 0.8, 0.3)
			p.draw_pass_1 = bm; p.process_material = pm; p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			root.add_child(p); return p
		"ring":
			p.amount = 1; p.lifetime = 0.45; p.explosiveness = 1.0
			pm.gravity = Vector3.ZERO; pm.initial_velocity_min = 0; pm.initial_velocity_max = 0
			var sc4 := Curve.new(); sc4.add_point(Vector2(0, 0.2)); sc4.add_point(Vector2(1, 6.0)); var ct4 := CurveTexture.new(); ct4.curve = sc4; pm.scale_curve = ct4
			q.size = Vector2(1.5, 1.5); var rm := _mat(T("blast"), true, Color(1.4, 1.2, 1.0, 0.6)); q.material = rm
			grad.set_color(0, Color(1, 1, 1, 0.7)); grad.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture1D.new(); gt.gradient = grad; pm.color_ramp = gt
	p.process_material = pm; p.draw_pass_1 = q
	root.add_child(p)
	return p

func _take(kind: String) -> GPUParticles3D:
	if not _pools.has(kind): _pools[kind] = {"list": [], "i": 0}
	var pool: Dictionary = _pools[kind]
	var size := 6 if kind in ["smoke", "fire", "debris", "ring"] else 14
	if pool["list"].size() < size:
		var p := _make(kind); pool["list"].append(p); return p
	var p2: GPUParticles3D = pool["list"][pool["i"] % size]; pool["i"] += 1
	return p2

func emit(kind: String, pos: Vector3, normal := Vector3.UP, count_scale := 1.0) -> void:
	if root == null or not is_instance_valid(root): return
	var p := _take(kind)
	p.global_position = pos
	if normal.length() > 0.1:
		var up := Vector3.UP if absf(normal.normalized().dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
		p.global_basis = Basis.looking_at(-normal, up)
	p.amount_ratio = clampf(count_scale, 0.1, 1.0)
	p.restart(); p.emitting = true

# ---------------------------------------------------------------- high level
func tracer(a: Vector3, b: Vector3, col := Color(1.0, 0.85, 0.55), life := 0.05) -> void:
	if _tracers.is_empty() or root == null or not is_instance_valid(root): return
	var tr: Dictionary = _tracers[_tr_i % _tracers.size()]; _tr_i += 1
	var n: MeshInstance3D = tr["n"]; var d := b - a; var L := d.length()
	if L < 0.1: return
	n.global_position = a + d * 0.5
	var up := Vector3.UP if absf(d.normalized().dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	n.global_basis = Basis.looking_at(d, up).scaled(Vector3(1, 1, L))
	(n.material_override as StandardMaterial3D).albedo_color = Color(col.r, col.g, col.b, 0.8)
	n.visible = true; tr["t"] = life; tr["max"] = life

func impact(pos: Vector3, normal: Vector3, metal := true) -> void:
	emit("sparks", pos + normal * 0.02, normal, 1.0 if metal else 0.4)
	emit("dust", pos + normal * 0.05, normal)
	bullet_hole(pos, normal)
	if randf() < 0.5: Audio.play3d("tps_hit", pos, -10.0, 0.2, 3.0)

func blood(pos: Vector3, dir: Vector3) -> void:
	emit("blood", pos, dir)

static var _hole_tex: Texture2D = null
func bullet_hole(pos: Vector3, normal: Vector3) -> void:
	if root == null or not is_instance_valid(root): return
	if _hole_tex == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		for y in 64:
			for x in 64:
				var d := Vector2(x - 32, y - 32).length() / 32.0
				var a := clampf(1.0 - d, 0.0, 1.0)
				var core := 1.0 if d < 0.22 else 0.0
				img.set_pixel(x, y, Color(0.02, 0.02, 0.02, clampf(core + a * a * 0.55 * (0.6 + randf() * 0.4), 0, 1)))
		_hole_tex = ImageTexture.create_from_image(img)
	var d := Decal.new(); d.texture_albedo = _hole_tex; d.size = Vector3(0.12, 0.12, 0.12); d.cull_mask = 1
	root.add_child(d); d.global_position = pos
	var up := Vector3.UP if absf(normal.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	d.global_basis = Basis.looking_at(-normal, up) * Basis(Vector3.RIGHT, -PI * 0.5)
	_decals.append(d)
	if _decals.size() > 90: (_decals.pop_front() as Node).queue_free()

func explosion(pos: Vector3, big := false) -> void:
	if root == null or not is_instance_valid(root): return
	emit("fire", pos + Vector3(0, 0.4, 0)); emit("smoke", pos + Vector3(0, 0.6, 0)); emit("debris", pos + Vector3(0, 0.2, 0)); emit("ring", pos + Vector3(0, 0.3, 0))
	for i in 2: emit("sparks", pos + Vector3(0, 0.5, 0), Vector3.UP)
	var l := OmniLight3D.new(); l.light_color = Color(1.0, 0.6, 0.3); l.omni_range = 14.0; l.light_energy = 9.0; l.shadow_enabled = false
	root.add_child(l); l.global_position = pos + Vector3(0, 1.0, 0)
	var tw := root.create_tween(); tw.tween_property(l, "light_energy", 0.0, 0.6); tw.tween_callback(l.queue_free)
	Audio.play3d(["boom_1", "boom_2"][randi() % 2] if not big else ["boom_big_1", "boom_big_2"][randi() % 2], pos, 6.0, 0.08, 14.0)
	cam_shake = maxf(cam_shake, 0.9 if big else 0.6)
