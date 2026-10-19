class_name SecurityCam
extends Node3D
## Sweeping security camera or yard searchlight for stealth sectors. It watches a cone; keep the player
## inside it (with line of sight) for long enough and the sector goes loud. Cameras can be shot out
## (suppressed fire stays quiet). Shadows hide you from cameras but not from a searchlight's beam.

var room: Room
var base_yaw := 0.0
var sweep := 40.0
var period := 8.0
var rng_m := 16.0
var searchlight := false
var half_angle := 20.0
var t := 0.0
var seen := 0.0            # 0..1 meter
var dead := false
var head: Node3D
var beam: SpotLight3D
var led: MeshInstance3D
var led_m: StandardMaterial3D

func setup(r: Room, pos: Vector3, yaw: float, sw: float, per: float, rg: float, sl: bool, sec: Sector) -> void:
	room = r; base_yaw = yaw; sweep = sw; period = per; rng_m = rg; searchlight = sl
	half_angle = 13.0 if sl else 22.0
	global_position = pos
	head = Node3D.new(); add_child(head)
	if sl:
		Kit.spawn("ph:security_light", head, Transform3D(Basis(Vector3.UP, PI), Vector3(0, -0.25, 0)), "none")
	else:
		Kit.spawn("ph:security_camera_01", head, Transform3D(Basis(Vector3.UP, PI), Vector3(0, -0.15, 0)), "none")
	beam = SpotLight3D.new(); head.add_child(beam)
	beam.spot_angle = half_angle + 4.0; beam.spot_range = rng_m + 4.0
	beam.light_color = Color(1.0, 0.97, 0.9) if sl else Color(1.0, 0.25, 0.2)
	beam.light_energy = 9.0 if sl else 0.9
	beam.light_volumetric_fog_energy = 3.0 if sl else 1.5
	beam.shadow_enabled = sl and sec.b.quality >= 1
	beam.rotation.x = deg_to_rad(-18.0 if sl else -28.0)
	led = MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.035; sm.height = 0.07; led.mesh = sm
	led_m = StandardMaterial3D.new(); led_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; led_m.albedo_color = Color(1, 0.15, 0.1)
	led.material_override = led_m; head.add_child(led); led.position = Vector3(0, 0.02, -0.25)
	# shootable body
	var body := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(0.35, 0.35, 0.6)
	cs.shape = sh; body.add_child(cs); head.add_child(body); body.set_meta("cam", self)
	_aim(0.0)

func _aim(phase: float) -> void:
	var a := base_yaw + sin(phase) * sweep
	head.rotation.y = -deg_to_rad(a)

func shot() -> void:
	if dead: return
	dead = true; seen = 0.0
	beam.visible = false; led.visible = false
	Fx.impact(global_position, Vector3.DOWN, true)
	Audio.play3d("tps_hit", global_position, -4.0, 0.05, 8.0)
	head.rotation.x = 0.6

func _physics_process(dt: float) -> void:
	if dead or room == null or not room.entered or room.mode == null: return
	var m: Mission = room.mode.m
	if m == null or m.player == null: return
	var detected: bool = room.mode.get("detected") == true
	if detected:
		led_m.albedo_color = Color(1, 0.1, 0.05); return
	t += dt
	var p := m.player
	var tgt := p.global_position + Vector3(0, 1.0 if p.crouch else 1.4, 0)
	var eye := beam.global_position
	var to := tgt - eye
	var dist := to.length()
	var visible_now := false
	var reach := rng_m
	if not searchlight and room.in_dark(p.global_position): reach = minf(reach, 6.0)
	if dist < reach:
		var fwd := -beam.global_basis.z
		if rad_to_deg(fwd.angle_to(to.normalized())) < half_angle:
			var q := PhysicsRayQueryParameters3D.create(eye, tgt, Humanoid.LAYER_WORLD)
			var hit := get_world_3d().direct_space_state.intersect_ray(q)
			visible_now = hit.is_empty() or hit.get("collider") is StaticBody3D and (hit["collider"] as Node).has_meta("cam")
	if visible_now:
		seen = minf(1.0, seen + dt * (1.6 if searchlight else 1.1))
		led_m.albedo_color = Color(1, 0.75, 0.1)
		if seen >= 1.0:
			Audio.play3d("alarm", global_position, -2.0, 0.0, 20.0)
			room.mode.on_detected()
	else:
		seen = maxf(0.0, seen - dt * 0.5)
		led_m.albedo_color = Color(1, 0.15, 0.1) if fmod(t, 1.2) < 0.15 else Color(0.25, 0.03, 0.02)
		_aim(t / period * TAU)
