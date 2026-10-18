extends ModeBase
## Tail the courier through the Commons. Keep 6-26 m back, break line of sight when he checks behind him,
## and predict his next move: the lab routes every visitor through the buyer decision process.

var courier: Humanoid
var path: Array = []
var wi := 0
var state := "wait"
var check_t := 6.0
var checking := 0.0
var seen := 0.0
var lost_t := 0.0
var predicted := false
var resetting := false

func setup() -> void:
	var hw := r.W * 0.5
	path = [Vector3(0, 0, r.z0 - 4), Vector3(-hw * 0.4, 0, r.z0 - r.D * 0.3), Vector3(hw * 0.35, 0, r.z0 - r.D * 0.55), Vector3(-hw * 0.2, 0, r.z1 + 7), Vector3(0, 0, r.z1 + 3.5), Vector3(0, 0, r.z1 - 3.0), Vector3(0, 0, r.cz1 + 1.0)]
	# a few passive security staff for atmosphere
	for i in maxi(0, int(r.data.get("e", 2))):
		var e := m.spawn_enemy(r, Vector3(randf_range(-hw + 3, hw - 3), 0, randf_range(r.z1 + 6, r.z0 - 8)), "css", false)
		e.passive = true
	courier = m.get_meta("courier") if m.has_meta("courier") else null
	if courier == null:
		courier = Humanoid.new(); m.add_child(courier); courier.team = "neutral"; courier.setup("civilian", r)
		if courier.muzzle: courier.muzzle.get_parent().visible = false
		m.set_meta("courier", courier)
		courier.global_position = path[0] + Vector3(0, 0, 3.0)
		courier.move_speed = 1.6

func uses_terminal() -> bool: return true
func requires_clear() -> bool: return false
func terminal_ready() -> bool: return predicted
func terminal_locked_text() -> String: return "Uplink locked  ·  stay on the courier"

func enter() -> void:
	state = "walk"; wi = 0
	courier.global_position = path[0]; courier.visible = true
	courier.room = r
	m.main.hud.tail_show(true)

func music() -> String: return "tail"

func objective() -> String:
	if r.done: return "Follow the courier"
	if state == "stop": return "Predict his next move"
	if not predicted: return "Tail the courier  ·  stay back, stay unseen"
	return default_objective()

func tick(dt: float) -> void:
	if not r.entered or resetting or r.done: return
	var p := m.player
	var dist := (courier.global_position - p.global_position).length()
	match state:
		"walk":
			_walk(dt)
			check_t -= dt
			if check_t <= 0.0 and checking <= 0.0:
				checking = 2.2; check_t = randf_range(6.0, 10.0)
		"stop":
			courier.velocity = Vector3.ZERO; courier.forced_anim = "Idle_TalkingPhone"
		"exit":
			_walk(dt)
	if checking > 0.0:
		checking -= dt
		courier.face(p.global_position, dt, 6.0)
		courier.forced_anim = "Idle_LookAround"
		if _visible_to_courier(p, dist):
			seen += dt * (0.55 if p.crouch else 1.4) * (1.5 if dist < 9.0 else 1.0)
	else:
		seen = maxf(0.0, seen - dt * 0.3)
		if state == "walk" or state == "exit": courier.forced_anim = ""
	courier.locomotion(dt)
	# distance discipline
	if dist < 6.0 and state != "stop":
		seen += dt * 0.6
		m.main.hud.tail_status("TOO CLOSE", seen)
	elif dist > 26.0:
		lost_t += dt
		m.main.hud.tail_status("LOSING HIM", lost_t / 5.0)
	else:
		lost_t = maxf(0.0, lost_t - dt)
		m.main.hud.tail_status("IN RANGE" if checking <= 0.0 else "HE'S CHECKING BEHIND HIM", seen)
	if seen >= 1.0: _fail("g_tail_seen")
	elif lost_t >= 5.0: _fail("g_tail_lost")

func _visible_to_courier(p: Player, dist: float) -> bool:
	if dist > 18.0: return false
	var eye := courier.global_position + Vector3(0, 1.6, 0)
	var q := PhysicsRayQueryParameters3D.create(eye, p.global_position + Vector3(0, 1.0 if p.crouch else 1.5, 0), Humanoid.LAYER_WORLD)
	return courier.get_world_3d().direct_space_state.intersect_ray(q).is_empty()

func _walk(dt: float) -> void:
	if wi >= path.size():
		courier.visible = false; return
	var wp: Vector3 = path[wi]
	if (wp - courier.global_position).length() < 0.8:
		wi += 1
		if wi == 4 and not predicted and state == "walk":
			state = "stop"; _predict(); return
		if wi == 5:
			r.open_exit()
		return
	var d := wp - courier.global_position; d.y = 0
	courier.velocity = d.normalized() * courier.move_speed
	courier.face(courier.global_position + courier.velocity, dt, 5.0)
	courier.move_and_slide()

func _predict() -> void:
	var P: Array = r.data.get("predict", [])
	if P.is_empty(): _after_predict(); return
	var pr: Dictionary = P[0]
	var opts: Array = pr["a"].duplicate(); var correct: String = opts[0]; opts.shuffle()
	Audio.say("MARR", pr["q"], "", "", true)
	m.main.hud.intercept_show(pr["q"], opts, 20.0, func(c: int):
		if c >= 0 and opts[c] == correct:
			Game.add_xp(60, "PREDICTION"); Audio.say("MARR", pr["say"], pr.get("vo", ""), "", true)
		else:
			Audio.say_generic("g_intercept_bad", true); m.main.hud.toast("✖  " + correct.to_upper(), "Need → search → evaluation → purchase → postpurchase", Color(1, 0.4, 0.3))
			Game.stats["missed"].append("predict:%s|%s" % [pr["q"], correct])
		_after_predict())

func _after_predict() -> void:
	predicted = true
	state = "exit"
	say_post()

func on_calls_done() -> void:
	complete()

func complete() -> void:
	super.complete()
	m.main.hud.tail_show(false)

func _fail(gid: String) -> void:
	resetting = true
	Audio.say_generic(gid, true)
	m.main.fade_reset(func():
		courier.global_position = path[0]; wi = 0; state = "walk"; seen = 0.0; lost_t = 0.0; checking = 0.0
		m.player.global_position = Vector3(0, 0.1, r.z0 + 1.5); m.player.yaw = 0.0
		resetting = false)
