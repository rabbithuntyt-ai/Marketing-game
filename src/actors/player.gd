class_name Player
extends CharacterBody3D
## First-person player: movement, look, rifle viewmodel (rendered in its own layer), hitscan, grenades,
## silent takedowns, health with regeneration, footsteps and interaction.

signal fired
signal hurt(amount: float, from: Vector3)
signal died
signal hit_marker(kill: bool, head: bool)

var cam: Camera3D
var head: Node3D
var vm_root: Node3D          # viewmodel root (layer 2)
var rifle: Node3D
var muzzle: Node3D
var flash: Sprite3D
var flash_light: OmniLight3D
var mission: Node            # Mission
var hp := 100.0
var dead := false
var last_hit := -99.0
var t := 0.0
var yaw := 0.0
var pitch := 0.0
var ammo := 30
var mag := 30
var reload_t := 0.0
var fire_cd := 0.0
var heat := 0.0
var ads := 0.0
var sprint := false
var crouch := false
var crouch_k := 0.0
var bob := 0.0
var kick := 0.0
var sway := Vector2.ZERO
var mouse_d := Vector2.ZERO
var step_d := 0.0
var nades := 3
var equip := 0.0
var suppressed := false
var sniper := false
var locked := false           # movement locked (sniper perch, cutscenes)
var input_enabled := true
var perch_bounds := Rect2()
var surface := "concrete"
var aim_assist_target = null

const SPEED := 4.7
const SPRINT := 7.2
const CROUCH := 2.3
const ADS_SPEED := 3.0
const JUMP := 4.6
const G := 16.0

func _ready() -> void:
	collision_layer = Humanoid.LAYER_PLAYER; collision_mask = Humanoid.LAYER_WORLD | Humanoid.LAYER_NPC
	var cs := CollisionShape3D.new(); var cap := CapsuleShape3D.new(); cap.radius = 0.36; cap.height = 1.8; cs.shape = cap; cs.position.y = 0.9; cs.name = "Shape"; add_child(cs)
	head = Node3D.new(); head.position.y = 1.62; add_child(head)
	cam = Camera3D.new(); cam.near = 0.04; cam.far = 400.0; cam.fov = Game.settings["fov"]; cam.cull_mask = 0xFFFFF; head.add_child(cam); cam.current = true
	_build_viewmodel()
	var lis := AudioListener3D.new(); cam.add_child(lis); lis.make_current()

func _build_viewmodel() -> void:
	vm_root = Node3D.new(); vm_root.name = "VM"; cam.add_child(vm_root)
	var rs: PackedScene = load("res://assets/models/rifle.gltf")
	rifle = rs.instantiate(); vm_root.add_child(rifle)
	rifle.scale = Vector3.ONE * 1.0; rifle.rotation = Vector3(0, PI, 0)
	for mi in rifle.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D; m.layers = 2; m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for s in m.mesh.get_surface_count():
			var b := m.get_active_material(s)
			if b is BaseMaterial3D:
				var d: BaseMaterial3D = b.duplicate(); d.albedo_color = Color(0.5, 0.5, 0.53); d.roughness = 0.55; d.metallic = 0.35; m.set_surface_override_material(s, d)
	# gloved hands and sleeves so the rifle isn't floating
	var sleeve := Mats.flat(Color(0.2, 0.22, 0.17), 0.85); var glove := Mats.flat(Color(0.05, 0.05, 0.055), 0.7)
	for spec in [[Vector3(0.02, -0.07, 0.12), Vector3(0.25, 0.0, 0.55)], [Vector3(-0.07, -0.05, -0.2), Vector3(-0.2, 0.0, 0.3)]]:
		var hand := MeshInstance3D.new(); var hb := BoxMesh.new(); hb.size = Vector3(0.07, 0.085, 0.11); hand.mesh = hb; hand.material_override = glove; hand.layers = 2
		hand.position = spec[0]; rifle.add_child(hand)
		var arm := MeshInstance3D.new(); var cm := CapsuleMesh.new(); cm.radius = 0.045; cm.height = 0.42; arm.mesh = cm; arm.material_override = sleeve; arm.layers = 2
		arm.position = spec[0] + Vector3(0, -0.06, 0.2) if spec[0].z > 0 else spec[0] + Vector3(0.02, -0.08, 0.2)
		arm.rotation = Vector3(deg_to_rad(80), spec[1].y, spec[1].x); rifle.add_child(arm)
	muzzle = Node3D.new(); rifle.add_child(muzzle); muzzle.position = Vector3(0, 0.05, 0.62)
	flash = Fx.make_flash_sprite(0.28); flash.layers = 2; muzzle.add_child(flash); flash.visible = false
	_viewmodel_materials(vm_root)
	flash_light = OmniLight3D.new(); flash_light.light_color = Color(1.0, 0.72, 0.4); flash_light.omni_range = 6.0; flash_light.light_energy = 0.0; cam.add_child(flash_light); flash_light.position = Vector3(0.2, -0.1, -0.8)

## First-person weapon rendering: own FOV and compressed depth so the rifle never clips into walls.
func _viewmodel_materials(root: Node) -> void:
	for n in root.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if g is MeshInstance3D:
			var m := g as MeshInstance3D
			for s in m.mesh.get_surface_count():
				var b := m.get_active_material(s)
				if b is BaseMaterial3D:
					var d: BaseMaterial3D = b.duplicate()
					d.use_z_clip_scale = true; d.z_clip_scale = 0.3; d.use_fov_override = true; d.fov_override = 62.0
					m.set_surface_override_material(s, d)
			if m.material_override is BaseMaterial3D:
				var d2: BaseMaterial3D = m.material_override.duplicate()
				d2.use_z_clip_scale = true; d2.z_clip_scale = 0.3; d2.use_fov_override = true; d2.fov_override = 62.0
				m.material_override = d2
		elif g is SpriteBase3D or g.material_override is BaseMaterial3D:
			if g.material_override is BaseMaterial3D:
				var d3: BaseMaterial3D = g.material_override.duplicate()
				d3.use_z_clip_scale = true; d3.z_clip_scale = 0.3; d3.use_fov_override = true; d3.fov_override = 62.0
				g.material_override = d3

func set_room_settings(r: Room) -> void:
	suppressed = r.kind == "stealth" or r.data.get("suppressed", false)
	surface = "metal" if r.data.get("set", "") in ["servers", "analytics", "cooling", "crane", "array"] or Game.mission()["theme"] in ["data", "array"] else ("gravel" if r.outdoor else "concrete")

func hip_pos() -> Vector3: return Vector3(0.2, -0.22, -0.42) if not sniper else Vector3(0.18, -0.2, -0.36)
func ads_pos() -> Vector3: return Vector3(0.0, -0.152, -0.3)

func _unhandled_input(e: InputEvent) -> void:
	if not input_enabled or dead: return
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var s: float = 0.0022 * float(Game.settings["sens"]) * (0.45 if ads > 0.5 else 1.0) * (0.35 if sniper and ads > 0.5 else 1.0)
		var inv := -1.0 if Game.settings["invert_y"] else 1.0
		yaw -= e.relative.x * s; pitch = clampf(pitch - e.relative.y * s * inv, -1.45, 1.45)
		mouse_d += e.relative

func _physics_process(dt: float) -> void:
	t += dt
	if dead: return
	var inp := Vector2.ZERO
	if input_enabled:
		inp = Input.get_vector("move_left", "move_right", "move_back", "move_fwd")
	var want_crouch := input_enabled and Input.is_action_pressed("crouch")
	crouch = want_crouch
	crouch_k = move_toward(crouch_k, 1.0 if crouch else 0.0, dt * 5.0)
	sprint = input_enabled and Input.is_action_pressed("sprint") and inp.y > 0.2 and not crouch and ads < 0.3 and reload_t <= 0.0 and not Input.is_action_pressed("fire")
	var speed := SPRINT if sprint else (ADS_SPEED if ads > 0.5 else (CROUCH if crouch else SPEED))
	if locked: inp = Vector2.ZERO
	var basis_y := Basis(Vector3.UP, yaw)
	var wish := basis_y * Vector3(inp.x, 0, -inp.y)
	if wish.length() > 1.0: wish = wish.normalized()
	var accel := 11.0 if is_on_floor() else 2.5
	velocity.x = lerpf(velocity.x, wish.x * speed, 1.0 - exp(-accel * dt))
	velocity.z = lerpf(velocity.z, wish.z * speed, 1.0 - exp(-accel * dt))
	if is_on_floor():
		if input_enabled and Input.is_action_just_pressed("jump") and not crouch and not locked:
			velocity.y = JUMP; Audio.play2d("kenney_jump_a", -14.0, 0.05)
		else: velocity.y = -0.5
	else:
		velocity.y -= G * dt
	var was_air := not is_on_floor()
	move_and_slide()
	if was_air and is_on_floor() and velocity.y < -3.0: Audio.play2d("kenney_land", -10.0, 0.05)
	if locked and perch_bounds.size != Vector2.ZERO:
		global_position.x = clampf(global_position.x, perch_bounds.position.x, perch_bounds.end.x)
		global_position.z = clampf(global_position.z, perch_bounds.position.y, perch_bounds.end.y)
	# shape for crouch
	var shape := get_node("Shape") as CollisionShape3D
	(shape.shape as CapsuleShape3D).height = lerpf(1.8, 1.15, crouch_k); shape.position.y = (shape.shape as CapsuleShape3D).height * 0.5
	# footsteps
	var hs := Vector2(velocity.x, velocity.z).length()
	bob += dt * hs * 1.75
	step_d += hs * dt
	var stride := 2.3 if sprint else 1.75
	if step_d > stride and is_on_floor():
		step_d = 0.0
		var n: int = {"metal": 5, "gravel": 6, "concrete": 8}[surface]
		Audio.play2d("step_%s_%d" % [surface, 1 + randi() % n], (-15.0 if crouch else (-6.0 if sprint else -10.0)), 0.06)
	_weapon(dt)
	_camera(dt, hs)

func _camera(dt: float, hs: float) -> void:
	var shake := Fx.cam_shake * 0.05
	var bob_a := minf(1.0, hs / SPEED) * (1.0 - ads * 0.8)
	head.position = Vector3(0, lerpf(1.62, 1.05, crouch_k) + sin(bob) * 0.035 * bob_a, 0)
	head.rotation = Vector3(pitch + kick * 0.3 + randf_range(-shake, shake), yaw + randf_range(-shake, shake), sin(bob * 0.5) * 0.004 * bob_a)
	var base_fov: float = Game.settings["fov"]
	var tgt_fov := lerpf(base_fov, (14.0 if sniper else 52.0), ads) + (5.0 if sprint else 0.0)
	cam.fov = lerpf(cam.fov, tgt_fov, 1.0 - exp(-12.0 * dt))

func _weapon(dt: float) -> void:
	fire_cd -= dt; heat = maxf(0.0, heat - dt * 5.0); equip = minf(1.0, equip + dt * 1.8)
	if flash.visible and fire_cd < (0.07 if not sniper else 0.95) - 0.045: flash.visible = false
	flash_light.light_energy = maxf(0.0, flash_light.light_energy - dt * 60.0)
	var want_ads := input_enabled and Input.is_action_pressed("aim") and not sprint and reload_t <= 0.0
	ads = lerpf(ads, 1.0 if want_ads else 0.0, 1.0 - exp(-(10.0 if not sniper else 7.0) * dt))
	if reload_t > 0.0:
		reload_t -= dt
		if reload_t <= 0.0: ammo = mag
	if input_enabled and Input.is_action_just_pressed("reload"): start_reload()
	if input_enabled and Input.is_action_pressed("fire") and fire_cd <= 0.0 and reload_t <= 0.0 and equip > 0.6 and not sprint:
		if ammo > 0: fire()
		else: start_reload()
	if input_enabled and Input.is_action_just_pressed("grenade"): throw_grenade()
	if input_enabled and Input.is_action_just_pressed("melee"): takedown()
	# viewmodel pose
	kick = lerpf(kick, 0.0, 1.0 - exp(-9.0 * dt))
	sway = sway.lerp(Vector2(clampf(-mouse_d.x * 0.0012, -0.05, 0.05), clampf(-mouse_d.y * 0.0012, -0.04, 0.04)), 1.0 - exp(-10.0 * dt)); mouse_d = Vector2.ZERO
	var hs := Vector2(velocity.x, velocity.z).length(); var bob_a := minf(1.0, hs / SPEED) * (1.0 - ads * 0.85)
	var target := hip_pos().lerp(ads_pos(), ads)
	var rl := sin(clampf(1.0 - reload_t / 1.6, 0.0, 1.0) * PI) if reload_t > 0.0 else 0.0
	var eq := 1.0 - equip
	var ak := 1.0 - ads * 0.85
	vm_root.position = target + Vector3(cos(bob * 0.5) * 0.012 * bob_a + sway.x * 0.4 * ak, -absf(sin(bob * 0.5)) * 0.011 * bob_a - rl * 0.16 - eq * 0.4 + (-0.04 if sprint else 0.0) + sway.y * 0.3 * ak, kick * 0.35)
	vm_root.rotation = Vector3(sway.y * ak + (-0.22 if sprint else 0.0) + eq * 0.6 + kick * 0.8 - rl * 0.5, sway.x * ak + (0.5 if sprint else 0.0), (0.15 if sprint else 0.0) + sway.x * 0.6 * ak + rl * 0.4)
	vm_root.visible = not (sniper and ads > 0.85)

func start_reload() -> void:
	if reload_t > 0.0 or ammo == mag: return
	reload_t = 1.6 if not sniper else 2.2
	Audio.play2d("reload", -4.0)

func spread() -> float:
	var s := lerpf(0.026, 0.0025, ads) + (0.012 if Vector2(velocity.x, velocity.z).length() > 1.0 else 0.0) * (1.0 - ads * 0.6) + heat * 0.002 * (1.0 - ads * 0.5)
	if crouch: s *= 0.75
	if sniper: s = lerpf(0.03, 0.0, ads)
	return s

func fire() -> void:
	ammo -= 1; fire_cd = 0.088 if not sniper else 1.0
	Game.stats["shots"] += 1
	var outdoor: bool = mission.cur_room != null and mission.cur_room.outdoor
	if sniper: Audio.play2d("sniper", 2.0, 0.03)
	elif suppressed: Audio.play2d("pistol", -16.0, 0.08)
	else: Audio.play2d(("rifle_out_%d" if outdoor else "rifle_in_%d") % (1 + randi() % 3), -1.0, 0.04)
	if randf() < 0.5: get_tree().create_timer(0.35).timeout.connect(func(): Audio.play2d("brass" if randf() < 0.5 else "brass2", -20.0, 0.1))
	var sp := spread(); heat = minf(heat + 1.0, 8.0)
	var dir := -cam.global_basis.z
	dir += cam.global_basis.x * randf_range(-sp, sp) + cam.global_basis.y * randf_range(-sp, sp)
	dir = dir.normalized()
	# gentle aim assist toward the nearest enemy head when aiming down sights
	if Game.settings["aim_assist"] and ads > 0.7 and not sniper and mission:
		var best = null; var bd := 0.035
		for e in mission.all_enemies():
			if e.dead: continue
			var hp_: Vector3 = e.global_position + Vector3(0, 1.45, 0)
			var to := (hp_ - cam.global_position).normalized()
			var a := to.angle_to(dir)
			if a < bd: bd = a; best = to
		if best != null: dir = dir.slerp(best, 0.5)
	var from := cam.global_position
	var to := from + dir * 160.0
	var q := PhysicsRayQueryParameters3D.create(from, to, Humanoid.LAYER_WORLD | Humanoid.LAYER_HITBOX, [get_rid()])
	q.collide_with_areas = true; q.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var end := to
	if hit:
		end = hit["position"]
		var col = hit["collider"]
		if col is Area3D and col.has_meta("actor"):
			var a: Humanoid = col.get_meta("actor")
			if a.team == "neutral":
				if mission.cur_room.mode.has_method("director_shot"): mission.cur_room.mode.director_shot(a)
			elif a.team != "ally":
				var part: String = col.get_meta("part")
				var dmg := 34.0 if not sniper else 260.0
				var was_dead := a.dead
				a.take_damage(dmg, part, from, self)
				Game.stats["hits"] += 1
				Fx.blood(end, -dir)
				hit_marker.emit(a.dead and not was_dead, part == "head")
				if a.dead and not was_dead: mission.on_kill(a, part == "head")
				elif suppressed and mission: mission.noise(a.global_position, 6.0)
		elif col and col.has_meta("target"):
			Fx.emit("dust", end, hit["normal"])
			if mission.cur_room and mission.cur_room.mode.has_method("target_hit"): mission.cur_room.mode.target_hit(col, end)
		elif col and col.has_meta("director"):
			if mission.cur_room.mode.has_method("director_shot"): mission.cur_room.mode.director_shot(col)
		else:
			Fx.impact(end, hit["normal"], true)
			if col and col.get_parent() and col.get_parent().has_meta("barrel"): mission.hit_barrel(col.get_parent())
	Fx.tracer(muzzle.global_position, end, Color(1.0, 0.85, 0.55), 0.04)
	flash.visible = true; flash.rotation.z = randf() * TAU; flash_light.light_energy = 3.5 if not suppressed else 0.6
	kick = minf(kick + (0.05 if not sniper else 0.25), 0.18 if not sniper else 0.35)
	pitch += lerpf(0.0085, 0.0045, ads) if not sniper else 0.03
	yaw += randf_range(-0.0035, 0.0035)
	if not suppressed and mission: mission.noise(global_position, 40.0)
	fired.emit()

func throw_grenade() -> void:
	if nades <= 0 or reload_t > 0.0 or sniper: return
	nades -= 1
	Audio.play2d("kenney_weapon_change", -8.0)
	var g := Grenade.new(); mission.add_child(g)
	g.global_position = cam.global_position - cam.global_basis.z * 0.6
	g.linear_velocity = -cam.global_basis.z * 15.0 + Vector3(0, 4.0, 0) + Vector3(velocity.x, 0, velocity.z) * 0.5
	g.mission = mission

func takedown() -> void:
	if mission == null: return
	for e in mission.all_enemies():
		if e.dead: continue
		var d: Vector3 = e.global_position - global_position; d.y = 0
		if d.length() > 2.0: continue
		var fwd := -global_transform.basis.z; fwd = (-cam.global_basis.z); fwd.y = 0
		if fwd.normalized().dot(d.normalized()) < 0.6: continue
		var efwd: Vector3 = -e.global_transform.basis.z; efwd.y = 0
		var behind: bool = efwd.normalized().dot(d.normalized()) > 0.2
		if (e.has_method("is_alerted") and not e.is_alerted()) or behind:
			Audio.play3d("hurt_%d" % (1 + randi() % 4), e.global_position, -6.0)
			e.take_damage(9999, "body", global_position, self)
			mission.on_kill(e, false, true)
			kick = 0.2
			return

func take_hit(amount: float, from: Vector3) -> void:
	if dead: return
	hp -= amount; last_hit = t
	Fx.cam_shake = maxf(Fx.cam_shake, 0.25)
	if randf() < 0.35: Audio.play2d("hurt_%d" % (1 + randi() % 4), -9.0, 0.05)
	hurt.emit(amount, from)
	if hp <= 0.0:
		dead = true; died.emit()

func _process(dt: float) -> void:
	if not dead and t - last_hit > 4.0 and hp < 100.0:
		hp = minf(100.0, hp + 28.0 * dt * Game.diff()["regen"])
