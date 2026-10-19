class_name Ally
extends Humanoid
## Cpl. Ruiz: follows the player, takes positions near cover, engages hostiles, calls out.

var mission: Node
var follow_off := Vector3(1.8, 0, 2.8)
var think_t := 0.0
var shoot_cd := 0.8
var burst := 0
var burst_t := 0.0
var target: Humanoid
var bark_cd := 0.0
var scripted := false          # cutscene / sniper escort control
var escort_path: Array = []
var escort_i := 0
var escort_hp := 100.0
var stealth := false

func init_ally(m: Node) -> void:
	mission = m; team = "ally"
	setup("ally", null)
	collision_layer = 0   # don't block the player in corridors
	for a in find_children("*", "Area3D", true, false): (a as Area3D).collision_layer = 0

func _physics_process(dt: float) -> void:
	if dead or not visible:
		return
	if forced_anim != "":
		locomotion(dt); return
	bark_cd -= dt; think_t -= dt; shoot_cd -= dt
	var p: Player = mission.player
	if scripted:
		_escort(dt); locomotion(dt); return
	if think_t <= 0.0:
		think_t = 0.35
		target = _pick_enemy()
		var goal := _follow_goal(p)
		if (goal - global_position).length() > 1.2: nav_to(goal)
		# teleport if left far behind (e.g. door closed behind him)
		if (p.global_position - global_position).length() > 22.0:
			global_position = p.global_position + p.global_transform.basis * Vector3(1.5, 0, 2.0)
	var spd := move_speed * (1.4 if (p.global_position - global_position).length() > 9.0 else 1.0)
	if stealth: spd *= 0.6
	nav_step(dt, spd)
	if target:
		face(target.global_position, dt, 8.0)
		if burst > 0:
			burst_t -= dt
			if burst_t <= 0.0:
				burst -= 1; burst_t = 0.12; _fire(target)
		elif shoot_cd <= 0.0:
			burst = 3 + randi() % 3; shoot_cd = randf_range(0.9, 1.8)
			if bark_cd <= 0.0 and randf() < 0.25: bark(["contact", "contact2", "cover", "moving"][randi() % 4])
	else:
		var v := Vector3(velocity.x, 0, velocity.z)
		if v.length() > 0.4: face(global_position + v, dt, 6.0)
		else: face(p.global_position, dt, 2.0)
	locomotion(dt)

func _follow_goal(p: Player) -> Vector3:
	var r: Room = mission.cur_room
	var base := p.global_position + p.global_transform.basis * follow_off
	if r and target:
		# prefer a nearby cover point when fighting
		var best := base; var bd := 1e9
		for c in r.cover_points:
			var d: float = (c - p.global_position).length()
			if d < 9.0 and d < bd: bd = d; best = c
		return best
	return base

func _pick_enemy() -> Humanoid:
	if stealth and not mission.loud: return null
	var best: Humanoid = null; var bd := 40.0
	var eye := global_position + Vector3(0, 1.5, 0)
	for e in mission.all_enemies():
		if e.dead: continue
		if e is Enemy and not (e as Enemy).is_alerted() and not mission.loud: continue
		var d: float = (e.global_position - global_position).length()
		if d < bd:
			var q := PhysicsRayQueryParameters3D.create(eye, e.global_position + Vector3(0, 1.4, 0), Humanoid.LAYER_WORLD)
			if get_world_3d().direct_space_state.intersect_ray(q).is_empty(): bd = d; best = e
	return best

func _fire(t: Humanoid) -> void:
	var from := muzzle_pos(); show_flash()
	Audio.play3d("gun_enemy_%d" % (1 + randi() % 4), from, -3.0, 0.06, 9.0)
	var hit := randf() < 0.38
	var end := t.global_position + Vector3(0, 1.3, 0)
	if not hit: end += Vector3(randf_range(-1, 1), randf_range(-0.5, 0.6), randf_range(-1, 1))
	Fx.tracer(from, end, Color(1.0, 0.85, 0.55), 0.05)
	if hit:
		var was := t.dead
		t.take_damage(26.0 if not t.is_boss_actor() else 10.0, "body", from, self)
		if t.dead and not was:
			mission.on_kill(t, false, false, true)
			if bark_cd <= 0.0: bark(["gotone", "down"][randi() % 2])

func bark(id: String) -> void:
	bark_cd = randf_range(5.0, 9.0)
	Audio.bark("RUIZ", id)

func _escort(dt: float) -> void:
	if escort_path.is_empty(): velocity = Vector3.ZERO; move_and_slide(); return
	var wp: Vector3 = escort_path[escort_i]
	if (wp - global_position).length() < 1.0:
		if escort_i < escort_path.size() - 1: escort_i += 1
		else: velocity = Vector3.ZERO; move_and_slide(); return
	nav_to(wp); nav_step(dt, 2.2)
	face(global_position + Vector3(velocity.x, 0, velocity.z), dt, 5.0)

func take_damage(amount: float, part: String, from: Vector3, attacker = null) -> void:
	if scripted:
		escort_hp -= amount * 0.6
		_hit_flash = 0.25
		if bark_cd <= 0.0: bark_cd = 4.0; Audio.say_generic("g_sniper_hurt")
		return
	# Ruiz is never killed in normal play; he just flinches
	_hit_flash = 0.15
