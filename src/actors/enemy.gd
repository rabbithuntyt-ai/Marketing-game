class_name Enemy
extends Humanoid
## Castellan Security Services operative. Stealth awareness, cover-seeking combat, burst fire, barks.

var mission: Node
var state := "idle"            # idle, patrol, suspicious, alert
var awareness := 0.0           # 0..1 stealth detection
var alert_delay := 0.6
var patrol: Array = []         # Vector3 waypoints
var patrol_i := 0
var patrol_wait := 0.0
var patrol_waits: Array = []   # authored seconds per waypoint
var patrol_looks: Array = []   # authored facing (deg, sector yaw convention) while waiting, or null
var post_yaw = null            # stationary guards return to this facing
var think_t := 0.0
var move_t := 0.0
var shoot_cd := 1.5
var burst := 0
var burst_t := 0.0
var aim_t := 0.0
var target: Node3D
var voice := "CSS1"
var bark_cd := 0.0
var can_see := false
var last_seen := Vector3.ZERO
var stealth_room := false
var grenade_cd := 8.0
var is_boss := false
var hold_pos = null            # Vector3: holdout defenders stay near
var passive := false           # ignores the player until released (HVT guards, tail-room staff)
var focus_ally := false        # always targets Ruiz (sniper escort)

func is_alerted() -> bool: return state == "alert"

func init_enemy(m: Node, r: Room, v: String, stealth := false) -> void:
	mission = m; team = "css"; stealth_room = stealth
	setup(v, r)
	voice = ["CSS1", "CSS2", "CSS3", "CSS4"][randi() % 4]
	alert_delay = randf_range(0.3, 1.0)
	shoot_cd = randf_range(0.8, 2.0)
	is_boss = v in ["kessler", "hale"]
	if stealth: state = "patrol" if not patrol.is_empty() else "idle"

func _physics_process(dt: float) -> void:
	if dead:
		super._physics_process(dt); return
	if forced_anim != "":
		locomotion(dt); return
	bark_cd -= dt; think_t -= dt
	var player: Player = mission.player
	if player == null or player.dead:
		velocity = Vector3.ZERO; locomotion(dt); return
	var eye := global_position + Vector3(0, 1.6 * scale.y, 0)
	if think_t <= 0.0:
		think_t = 0.25
		can_see = _sees(player, eye)
		if can_see: last_seen = player.global_position
	match state:
		"idle", "patrol", "suspicious": _unaware(dt, player, eye)
		"alert": _combat(dt, player, eye)
	locomotion(dt)

func _sees(p: Player, eye: Vector3) -> bool:
	var tgt := p.global_position + Vector3(0, 1.0 if p.crouch else 1.5, 0)
	var d := tgt - eye
	var dist := d.length()
	var rng_m := 60.0 if state == "alert" else (13.0 if p.crouch else 20.0)
	if mission.cur_room and mission.cur_room.outdoor and state != "alert": rng_m *= 0.85
	if state != "alert" and room and room.in_dark(p.global_position): rng_m = minf(rng_m, 4.5 if p.crouch else 8.0)
	if dist > rng_m: return false
	if state != "alert":
		var fwd := -global_transform.basis.z
		var flat := Vector3(d.x, 0, d.z).normalized()
		if fwd.dot(flat) < cos(deg_to_rad(58.0)): return false
	var q := PhysicsRayQueryParameters3D.create(eye, tgt, Humanoid.LAYER_WORLD)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

func _unaware(dt: float, p: Player, eye: Vector3) -> void:
	if passive:
		velocity.x = 0; velocity.z = 0; move_and_slide(); return
	if not stealth_room:
		# combat rooms: become alert shortly after the player enters
		if room and room.entered:
			alert_delay -= dt
			if alert_delay <= 0.0: alert(true)
		velocity.x = 0; velocity.z = 0; move_and_slide(); return
	# stealth: patrol and build awareness when the player is visible
	if can_see:
		var dist := (p.global_position - global_position).length()
		var rate := (1.4 if dist < 6.0 else (0.8 if dist < 12.0 else 0.45)) * (0.55 if p.crouch else 1.0) * (1.6 if Vector2(p.velocity.x, p.velocity.z).length() > 4.0 else 1.0)
		if room and room.in_dark(p.global_position): rate *= 0.45
		awareness = minf(1.0, awareness + rate * dt)
		if state != "suspicious" and awareness > 0.35:
			state = "suspicious"; if bark_cd <= 0: bark("heard")
		if awareness >= 1.0: alert(true); return
	else:
		awareness = maxf(0.0, awareness - dt * 0.18)
		if state == "suspicious" and awareness < 0.05: state = "patrol" if not patrol.is_empty() else "idle"
	if state == "suspicious":
		velocity.x = 0; velocity.z = 0; face(last_seen, dt, 3.0); move_and_slide(); return
	if not patrol.is_empty():
		if patrol_wait > 0.0:
			patrol_wait -= dt; velocity.x = 0; velocity.z = 0
			var lk = patrol_looks[patrol_i - 1 if patrol_i > 0 else patrol.size() - 1] if patrol_looks.size() == patrol.size() else null
			if lk != null: face_yaw(-deg_to_rad(float(lk)), dt, 2.5)
			move_and_slide()
			return
		var wp: Vector3 = patrol[patrol_i]
		if (wp - global_position).length() < 0.9:
			patrol_wait = float(patrol_waits[patrol_i]) if patrol_waits.size() == patrol.size() else randf_range(1.5, 3.5)
			patrol_i = (patrol_i + 1) % patrol.size()
			if randf() < 0.15 and bark_cd <= 0: bark("allclear")
		else:
			nav_to(wp); nav_step(dt, 1.3); face(global_position + Vector3(velocity.x, 0, velocity.z), dt, 4.0)
	else:
		velocity.x = 0; velocity.z = 0
		if post_yaw != null: face_yaw(-deg_to_rad(float(post_yaw)), dt, 2.0)
		move_and_slide()

func face_yaw(ry: float, dt: float, spd: float) -> void:
	rotation.y = lerp_angle(rotation.y, ry, 1.0 - exp(-spd * dt))

func alert(propagate := false) -> void:
	if state == "alert" or dead: return
	state = "alert"; awareness = 1.0
	shoot_cd = randf_range(0.5, 1.3); move_t = 0.0
	if bark_cd <= 0.0 and randf() < 0.7: bark("contact" if randf() < 0.6 else "there")
	if propagate and mission: mission.on_enemy_alert(self)

func _pick_target(p: Player) -> Node3D:
	var ally = mission.ally
	if focus_ally and ally and is_instance_valid(ally): return ally
	if ally and is_instance_valid(ally) and not ally.dead and ally.visible and randf() < 0.22:
		return ally
	return p

func _combat(dt: float, p: Player, eye: Vector3) -> void:
	if target == null or not is_instance_valid(target) or (target is Humanoid and target.dead) or randf() < dt * 0.15:
		target = _pick_target(p)
	var tpos: Vector3 = target.global_position
	var to_t := tpos - global_position; to_t.y = 0
	var dist := to_t.length()
	move_t -= dt
	if move_t <= 0.0:
		move_t = randf_range(2.5, 5.0) if variant != "heavy" else randf_range(1.5, 3.0)
		nav_to(_choose_position(tpos, dist))
	var spd := move_speed * (0.0 if burst > 0 and variant != "heavy" else 1.0)
	nav_step(dt, spd)
	face(tpos, dt, 7.0)
	# laser for marksmen
	if laser:
		var a := muzzle_pos(); var b := (p.global_position + Vector3(0, 1.3, 0)) if can_see else a - global_transform.basis.z * 30.0
		laser.visible = can_see and aim_t > 0.0
		laser.global_position = (a + b) * 0.5; laser.look_at(b, Vector3.UP); laser.rotate_object_local(Vector3.RIGHT, PI * 0.5); laser.scale = Vector3(1, (b - a).length(), 1)
	# firing
	shoot_cd -= dt
	var los := can_see if target == p else _los_to(target, eye)
	if variant == "marksman":
		if los and dist > 6.0: aim_t += dt
		else: aim_t = maxf(0.0, aim_t - dt)
		if aim_t > 1.7:
			aim_t = 0.0; _fire_at(target, dist, 42.0, 0.85)
		return
	if burst > 0:
		burst_t -= dt
		if burst_t <= 0.0:
			burst -= 1; burst_t = 0.11 if variant != "heavy" else 0.08
			if los: _fire_at(target, dist, Game.diff()["dmg"] * (1.4 if is_boss else 1.0), 1.0)
	elif shoot_cd <= 0.0:
		if los and dist < 55.0:
			burst = 3 + randi() % 3 if variant != "heavy" else 8 + randi() % 5
			if is_boss: burst = 6
			burst_t = 0.0; shoot_cd = randf_range(1.1, 2.4) * (0.7 if is_boss else 1.0)
			if randf() < 0.08 and bark_cd <= 0: bark("suppress")
		else: shoot_cd = 0.3
	# grenades
	grenade_cd -= dt
	if grenade_cd <= 0.0 and los and dist > 7.0 and dist < 20.0 and variant in ["heavy", "css"] and randf() < 0.35:
		grenade_cd = randf_range(12.0, 22.0); _throw_grenade(tpos)
	elif grenade_cd <= 0.0: grenade_cd = randf_range(4.0, 8.0)

func _los_to(n: Node3D, eye: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(eye, n.global_position + Vector3(0, 1.4, 0), Humanoid.LAYER_WORLD)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

func _choose_position(tpos: Vector3, dist: float) -> Vector3:
	if hold_pos != null: return hold_pos + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
	var lo := 7.0; var hi := 20.0
	if variant == "heavy": lo = 4.0; hi = 12.0
	if variant == "marksman": lo = 16.0; hi = 32.0
	if is_boss: lo = 8.0; hi = 18.0
	var best := global_position; var best_s := -1e9
	var cands: Array = room.cover_points.duplicate() if room else []
	for i in 6: cands.append(global_position + Vector3(randf_range(-7, 7), 0, randf_range(-7, 7)))
	for c in cands:
		var d: float = (c - tpos).length()
		if room and not room.contains(c): continue
		if room and absf(c.x) > room.W * 0.5 - 1.0: continue
		var s: float = -absf(d - (lo + hi) * 0.5) - (c - global_position).length() * 0.25 + randf_range(0, 3)
		if d < lo: s -= 20
		if s > best_s: best_s = s; best = c
	return best

func _fire_at(t: Node3D, dist: float, dmg: float, acc_mult: float) -> void:
	var from := muzzle_pos()
	show_flash()
	Audio.play3d("gun_enemy_%d" % (1 + randi() % 8) if variant != "marksman" else "gun_sniper_%d" % (3 + randi() % 2), from, 0.0, 0.07, 10.0)
	var acc: float = Game.diff()["acc"] * acc_mult * (1.0 - minf(dist / 60.0, 0.6))
	var aimp := t.global_position + Vector3(0, 1.35, 0)
	if t is Player:
		var pl := t as Player
		if Vector2(pl.velocity.x, pl.velocity.z).length() > 1.0: acc *= 0.75
		if pl.sprint: acc *= 0.7
		if pl.crouch: acc *= 0.85
		aimp = pl.cam.global_position + Vector3(0, -0.25, 0)
	var hit := randf() < acc
	var end := aimp
	if not hit: end += Vector3(randf_range(-1.4, 1.4), randf_range(-0.6, 0.9), randf_range(-1.4, 1.4))
	# world blocking
	var q := PhysicsRayQueryParameters3D.create(from, from + (end - from) * 1.6, Humanoid.LAYER_WORLD)
	var w := get_world_3d().direct_space_state.intersect_ray(q)
	if w and (w["position"] - from).length() < (aimp - from).length() - 0.5:
		hit = false; end = w["position"]
		if randf() < 0.4: Fx.impact(end, w["normal"], true)
	Fx.tracer(from, end, Color(1.0, 0.6, 0.3), 0.06)
	if hit:
		if t is Player: (t as Player).take_hit(dmg, from)
		elif t is Humanoid: (t as Humanoid).take_damage(dmg * 0.5, "body", from, self)
	elif t is Player and (end - (t as Player).cam.global_position).length() < 2.2 and randf() < 0.5:
		Audio.play3d("tps_hit", end, -12.0, 0.3, 2.0)

func _throw_grenade(tpos: Vector3) -> void:
	bark("grenade")
	var g := Grenade.new(); mission.add_child(g); g.from_enemy = true; g.mission = mission; g.fuse = 2.4
	var from := global_position + Vector3(0, 1.6, 0)
	g.global_position = from
	var d := tpos - from; var flat := Vector3(d.x, 0, d.z)
	var tt := clampf(flat.length() / 14.0, 0.6, 1.4)
	g.linear_velocity = flat / tt + Vector3(0, 0.5 * 16.0 * tt * 0.6, 0)
	mission.warn_grenade(g)

func bark(id: String) -> void:
	bark_cd = randf_range(3.0, 6.0)
	Audio.bark(voice, id, global_position + Vector3(0, 1.6, 0))

func take_damage(amount: float, part: String, from: Vector3, attacker = null) -> void:
	super.take_damage(amount, part, from, attacker)
	if not dead and state != "alert":
		alert(true)
	elif not dead and randf() < 0.12 and bark_cd <= 0: bark("taking")
