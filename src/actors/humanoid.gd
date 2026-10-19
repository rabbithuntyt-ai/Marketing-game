class_name Humanoid
extends CharacterBody3D
## Shared humanoid: soldier model with retargeted animation (soldier rifle set + Quaternius UAL1/UAL2),
## per-bone hitboxes, health, weapon muzzle, navigation and simple locomotion.

signal died(h: Humanoid)
signal damaged(h: Humanoid, amount: float)

const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_NPC := 4
const LAYER_HITBOX := 8

static var _model_scene: PackedScene
static var _lib1: AnimationLibrary
static var _lib2: AnimationLibrary
static var _rifle: PackedScene
static var _model_scale := 1.0

var variant := "css"
var hp := 100.0
var max_hp := 100.0
var armor := 0.0            # damage reduction on non-head hits (heavies)
var dead := false
var team := "css"
var model: Node3D
var skel: Skeleton3D
var anim: AnimationPlayer
var muzzle: Node3D
var flash: Node3D
var flash_t := 0.0
var agent: NavigationAgent3D
var room: Room
var move_speed := 2.6
var face_target = null      # Vector3 or null
var _cur_anim := ""
var _flinch_t := 0.0
var _mats: Array = []
var _hit_flash := 0.0
var gravity := 18.0
var forced_anim := ""       # cutscene override
var laser: MeshInstance3D
var rifle_node: Node3D
var weapon_hidden := false
var lh_ik: SkeletonIK3D     # pins the left hand to the handguard during rifle animations

static func load_shared() -> void:
	if _model_scene: return
	_model_scene = load("res://assets/models/soldier.gltf")
	_lib1 = load("res://assets/anim/UAL1.glb"); _lib2 = load("res://assets/anim/UAL2.glb")
	_rifle = load("res://assets/models/rifle.gltf")
	var probe: Node3D = _model_scene.instantiate()
	var aabb := AABB(); var first := true
	for mi in probe.find_children("*", "MeshInstance3D", true, false):
		var a: AABB = (mi as MeshInstance3D).get_aabb()
		aabb = a if first else aabb.merge(a); first = false
	_model_scale = 1.82 / maxf(0.5, aabb.size.y) if aabb.size.y > 0.5 and aabb.size.y < 5.0 else 1.0
	probe.free()
	for lib in [_lib1, _lib2]:
		for n in lib.get_animation_list():
			var a: Animation = lib.get_animation(n)
			if n.ends_with("Loop") or n in ["Jog_Fwd", "Jog_Bwd", "Jog_Left", "Jog_Right", "Idle", "Idle_Talking", "Crouch_Idle", "Crouch_Fwd", "Walk", "Walk_Fwd", "Walk_Carry", "Sprint", "Sitting_Idle", "Pistol_Idle", "Idle_LookAround", "Idle_FoldArms", "Idle_TalkingPhone", "GroundSit_Idle", "LiftAir_Idle", "Fixing_Kneeling", "Crouch_Bwd", "Crouch_Left", "Crouch_Right", "Walk_Bwd", "Walk_L", "Walk_R", "Idle_Tired", "Sitting_Talking", "Sitting_Nodding", "Counter_Idle", "Driving"]:
				a.loop_mode = Animation.LOOP_LINEAR

func setup(v: String, r: Room = null) -> void:
	load_shared()
	variant = v; room = r
	collision_layer = LAYER_NPC; collision_mask = LAYER_WORLD
	var cs := CollisionShape3D.new(); var cap := CapsuleShape3D.new(); cap.radius = 0.38; cap.height = 1.8; cs.shape = cap; cs.position.y = 0.9; add_child(cs)
	model = _model_scene.instantiate(); add_child(model)
	model.scale = Vector3.ONE * _model_scale
	model.rotation.y = PI
	skel = model.find_children("*", "Skeleton3D", true, false)[0]
	anim = model.find_children("*", "AnimationPlayer", true, false)[0]
	anim.add_animation_library("u1", _lib1); anim.add_animation_library("u2", _lib2)
	anim.playback_default_blend_time = 0.2
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for s in m.mesh.get_surface_count():
			var base := m.get_active_material(s)
			if base == null: continue
			var dup: BaseMaterial3D = base.duplicate()
			dup.albedo_color = _tint_for(v, dup.albedo_color, s)
			dup.emission_enabled = true; dup.emission = Color.BLACK
			m.set_surface_override_material(s, dup); _mats.append(dup)
	_attach_rifle()
	_hitboxes()
	agent = NavigationAgent3D.new(); agent.path_desired_distance = 0.6; agent.target_desired_distance = 0.8; agent.radius = 0.45; agent.avoidance_enabled = false
	add_child(agent)
	match v:
		"heavy": max_hp = 260; armor = 0.55; move_speed = 1.9; scale = Vector3.ONE * 1.08
		"marksman": max_hp = 90; move_speed = 2.2; _make_laser()
		"kessler": max_hp = 2600; armor = 0.65; move_speed = 1.7; scale = Vector3.ONE * 1.18
		"hale": max_hp = 1600; armor = 0.4; move_speed = 2.6; scale = Vector3.ONE * 1.02
		"ally": max_hp = 999999; move_speed = 3.6
		_: max_hp = 100
	max_hp *= Game.diff()["hp"] if team == "css" else 1.0
	hp = max_hp
	if v in ["director", "civilian"]: hide_weapon()
	_align_rifle()
	_left_hand_ik()
	play("soldier_idle")

func _tint_for(v: String, base: Color, surf: int) -> Color:
	match v:
		"css", "marksman": return base * Color(0.42, 0.44, 0.48)        # charcoal CSS uniform
		"heavy": return base * Color(0.25, 0.25, 0.27)
		"kessler": return base * Color(0.18, 0.17, 0.17) + Color(0.08, 0.0, 0.0)
		"hale": return base * Color(0.3, 0.34, 0.42)
		"ally": return base * Color(0.62, 0.66, 0.5)                    # LEDGER olive
		"wren": return base * Color(0.38, 0.42, 0.4)                    # Wren: darker field grey
		"director", "civilian": return base * Color(0.2, 0.2, 0.22)
	return base

func _attach_rifle() -> void:
	var ba := BoneAttachment3D.new(); ba.bone_name = "RightHand"; skel.add_child(ba)
	if _rifle:
		var rf: Node3D = _rifle.instantiate(); ba.add_child(rf)
		rf.scale = Vector3.ONE * (1.0 / _model_scale)
		rf.name = "Rifle"
		rifle_node = rf
		for mi in rf.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			for s in (mi as MeshInstance3D).mesh.get_surface_count():
				var mat := (mi as MeshInstance3D).get_active_material(s)
				if mat is BaseMaterial3D:
					var d: BaseMaterial3D = mat.duplicate(); d.albedo_color = Color(0.32, 0.32, 0.34); (mi as MeshInstance3D).set_surface_override_material(s, d)
		muzzle = Node3D.new(); rf.add_child(muzzle); muzzle.position = Vector3(0, 0.075, 0.47)
	else:
		muzzle = Node3D.new(); ba.add_child(muzzle)
	flash = Fx.make_flash_sprite(0.45); muzzle.add_child(flash); flash.visible = false
	var fl := OmniLight3D.new(); fl.light_color = Color(1.0, 0.7, 0.35); fl.omni_range = 5.0; fl.light_energy = 0.0; fl.name = "FlashLight"; muzzle.add_child(fl)

## Seat the rifle in the right hand exactly as the soldier model's original game (Dive, Mugen87) does:
## a fixed offset from the Mixamo RightHand bone. That offset, evaluated at the model's rest pose, is
## RIFLE_REST (in the model's own scene space). Re-expressed against the retargeted bone's rest frame it
## stays correct in every animation, whatever axes the retargeter gave the bone.
const RIFLE_REST := Transform3D(Vector3(0, -1, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(-0.881576, 1.429206, 0.010983))
func _align_rifle() -> void:
	if rifle_node == null or skel == null: return
	var rh := skel.find_bone("RightHand")
	if rh < 0: return
	var to_root := Transform3D.IDENTITY            # skeleton space -> model scene space
	var n: Node = skel
	while n != null and n != model:
		if n is Node3D: to_root = (n as Node3D).transform * to_root
		n = n.get_parent()
	var rest := skel.get_bone_global_rest(rh)

	rifle_node.transform = rest.affine_inverse() * (to_root.affine_inverse() * RIFLE_REST)

## Left-hand IK: the Mixamo rifle clips carry the left hand near the handguard but not on it (idle
## drops it ~10 cm low). A two-bone FABRIK chain pulls the wrist onto a grip point fixed to the rifle.
const LH_GRIP := Vector3(0.05, -0.03, 0.18)      # wrist position in rifle space (handguard, underside)
func _left_hand_ik() -> void:
	if rifle_node == null or weapon_hidden: return
	if skel.find_bone("LeftUpperArm") < 0 or skel.find_bone("LeftHand") < 0: return
	var tgt := Node3D.new(); tgt.name = "LHGrip"; rifle_node.add_child(tgt); tgt.position = LH_GRIP
	lh_ik = SkeletonIK3D.new(); lh_ik.name = "LeftHandIK"
	lh_ik.root_bone = "LeftUpperArm"; lh_ik.tip_bone = "LeftHand"
	lh_ik.override_tip_basis = false
	lh_ik.max_iterations = 6; lh_ik.min_distance = 0.005
	skel.add_child(lh_ik)
	lh_ik.target_node = lh_ik.get_path_to(tgt)
	lh_ik.start()

func _set_ik(on: bool) -> void:
	if lh_ik == null: return
	lh_ik.active = on
	lh_ik.influence = 1.0 if on else 0.0

func _hitboxes() -> void:
	for spec in [["Head", "head", SphereShape3D, 0.15, Vector3(0, 0.08, 0)], ["Chest", "body", CapsuleShape3D, 0.26, Vector3(0, 0.0, 0)], ["Hips", "legs", CapsuleShape3D, 0.22, Vector3(0, -0.35, 0)]]:
		var ba := BoneAttachment3D.new(); ba.bone_name = spec[0]; skel.add_child(ba)
		var ar := Area3D.new(); ar.collision_layer = LAYER_HITBOX; ar.collision_mask = 0; ar.monitoring = false; ar.monitorable = true
		var cs := CollisionShape3D.new(); var sh = spec[2].new()
		if sh is SphereShape3D: sh.radius = spec[3] / _model_scale
		else: sh.radius = spec[3] / _model_scale; sh.height = (0.75 if spec[1] == "body" else 0.95) / _model_scale
		cs.shape = sh; cs.position = spec[4] / _model_scale; ar.add_child(cs); ba.add_child(ar)
		ar.set_meta("actor", self); ar.set_meta("part", spec[1])

func _make_laser() -> void:
	laser = MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.006; cm.bottom_radius = 0.006; cm.height = 1.0; laser.mesh = cm
	var m := StandardMaterial3D.new(); m.albedo_color = Color(1, 0.1, 0.05, 0.55); m.emission_enabled = true; m.emission = Color(1, 0.1, 0.05); m.emission_energy_multiplier = 3.0
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; laser.material_override = m
	laser.top_level = true; laser.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(laser)

## Animation helpers. Names may be soldier_* (default library) or UAL names with "u1/" / "u2/" prefix.
func play(n: String, blend := 0.2, speed := 1.0) -> void:
	if n == _cur_anim and anim.is_playing(): anim.speed_scale = speed; return
	var key := n
	if not anim.has_animation(key):
		key = "u1/" + n if anim.has_animation("u1/" + n) else ("u2/" + n if anim.has_animation("u2/" + n) else "")
	if key == "": return
	anim.play(key, blend); anim.speed_scale = speed; _cur_anim = n
	# the rifle only belongs in the rifle clips; anything else (talking, jogging, sitting) puts it away
	var armed := n.begins_with("soldier_") and not weapon_hidden
	if rifle_node: (rifle_node.get_parent() as Node3D).visible = armed
	_set_ik(armed and not n.begins_with("soldier_death"))

func play_once(n: String, blend := 0.12) -> void:
	_cur_anim = ""; play(n, blend)

func locomotion(dt: float) -> void:
	if dead or forced_anim != "":
		if forced_anim != "": play(forced_anim)
		return
	if _flinch_t > 0.0: _flinch_t -= dt; return
	var v := velocity; v.y = 0
	var sp := v.length()
	if sp < 0.3:
		play("soldier_idle"); return
	var local := global_transform.basis.inverse() * v
	var fwd := -local.z; var side := local.x
	var n := "soldier_forward"
	if absf(side) > absf(fwd): n = "soldier_right" if side > 0 else "soldier_left"
	elif fwd < 0: n = "soldier_backward"
	play(n, 0.2, clampf(sp / 2.4, 0.7, 1.35))

func face(target: Vector3, dt: float, rate := 8.0) -> void:
	var d := target - global_position; d.y = 0
	if d.length() < 0.05: return
	var want := atan2(-d.x, -d.z)
	rotation.y = lerp_angle(rotation.y, want, 1.0 - exp(-rate * dt))

func nav_to(p: Vector3) -> void:
	agent.target_position = p

func nav_step(dt: float, speed: float) -> void:
	var desired := Vector3.ZERO
	if not agent.is_navigation_finished():
		var nxt := agent.get_next_path_position()
		var d := nxt - global_position; d.y = 0
		if d.length() > 0.05: desired = d.normalized() * speed
	velocity.x = lerpf(velocity.x, desired.x, 1.0 - exp(-8.0 * dt))
	velocity.z = lerpf(velocity.z, desired.z, 1.0 - exp(-8.0 * dt))
	if not is_on_floor(): velocity.y -= gravity * dt
	else: velocity.y = -0.5
	move_and_slide()

func hide_weapon() -> void:
	weapon_hidden = true
	_set_ik(false)
	if muzzle and muzzle.get_parent(): (muzzle.get_parent() as Node3D).visible = false
	if laser: laser.visible = false

func is_boss_actor() -> bool: return variant in ["kessler", "hale"]

func muzzle_pos() -> Vector3:
	return muzzle.global_position if muzzle else global_position + Vector3(0, 1.4, 0)

func show_flash() -> void:
	flash.visible = true; flash.rotation.z = randf() * TAU; flash_t = 0.05
	var fl := muzzle.get_node_or_null("FlashLight") as OmniLight3D
	if fl: fl.light_energy = 3.0

func _process(dt: float) -> void:
	if flash_t > 0.0:
		flash_t -= dt
		if flash_t <= 0.0:
			flash.visible = false
			var fl := muzzle.get_node_or_null("FlashLight") as OmniLight3D
			if fl: fl.light_energy = 0.0
	if _hit_flash > 0.0:
		_hit_flash -= dt
		var v := maxf(0.0, _hit_flash * 2.5)
		for m in _mats: m.emission = Color(v, v * 0.15, 0.0)

func take_damage(amount: float, part: String, from: Vector3, attacker = null) -> void:
	if dead: return
	var dmg := amount
	if part != "head": dmg *= (1.0 - armor)
	if part == "head": dmg *= 2.6 if armor < 0.5 else 1.6
	if part == "legs": dmg *= 0.75
	hp -= dmg; _hit_flash = 0.25
	damaged.emit(self, dmg)
	if hp <= 0.0:
		die(part == "head", from)
	elif dmg > 18.0 and randf() < 0.5 and armor < 0.5:
		play_once(["Hit_Chest", "Hit_Shoulder_L", "Hit_Shoulder_R", "Hit_Stomach"][randi() % 4], 0.08); _flinch_t = 0.35

func die(head := false, from := Vector3.ZERO) -> void:
	if dead: return
	dead = true; hp = 0
	velocity = Vector3.ZERO
	collision_layer = 0
	for a in find_children("*", "Area3D", true, false): (a as Area3D).monitorable = false; (a as Area3D).collision_layer = 0
	if laser: laser.visible = false
	play_once(["soldier_death1", "soldier_death2", "Death01", "Death02"][randi() % 4], 0.1)
	anim.speed_scale = 1.0
	died.emit(self)

func _physics_process(dt: float) -> void:
	if dead:
		if not is_on_floor():
			velocity.y -= gravity * dt; move_and_slide()
		return
