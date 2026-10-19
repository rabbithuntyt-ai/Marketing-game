extends ModeBase
## High-value target: five directors in a glass room. Scope each, listen to how they talk about customers,
## and mark the one who holds the selling concept. Wrong marks bring the guards down on you.

var directors: Array = []
var heard := {}
var focused = null
var marked := false
var wrong := 0
var guards_released := false
var ray_t := 0.0

func setup() -> void:
	var H: Dictionary = r.data.get("hvt", {})
	var z: float = r.get_meta("mezz_z", r.z1 + 5.0)
	var ds: Array = H.get("directors", [])
	for k in ds.size():
		var d := Humanoid.new(); m.add_child(d); d.team = "neutral"
		d.setup("director", r)
		var dp: Array = anchor("directors", [])
		d.global_position = dp[k] if k < dp.size() else Vector3(-6.0 + k * 3.0, 3.8, z - 0.5 + (k % 2) * 1.2)
		d.rotation.y = PI + randf_range(-0.4, 0.4)
		d.forced_anim = ["Idle_Talking", "Idle_FoldArms", "Idle_Talking", "Idle_TalkingPhone", "Idle_LookAround"][k]
		d.set_physics_process(false)
		if d.muzzle: d.muzzle.get_parent().visible = false   # hide rifle on directors
		d.set_meta("idx", k)
		directors.append(d)
	var n := maxi(3, int(r.data.get("e", 4)) + int(Game.diff()["cnt"]))
	populate(n)
	for e in r.enemies: e.passive = true

func enter() -> void:
	Game.stats["hvt_start"] = Game.stats["time"]

func requires_clear() -> bool: return marked

func objective() -> String:
	if not marked: return "Scope the directors (aim)  ·  mark Ostrowski  [E]"
	return default_objective()

func music() -> String: return "tension" if not marked else ""

func tick(dt: float) -> void:
	for d in directors:
		if is_instance_valid(d) and not d.dead: d.locomotion(dt)
	if not r.entered or marked:
		_after(dt); return
	ray_t -= dt
	if ray_t <= 0.0:
		ray_t = 0.08
		focused = _aimed_director()
		if focused != null:
			var k: int = focused.get_meta("idx")
			var info: Dictionary = r.data["hvt"]["directors"][k]
			m.main.hud.focus_label(info["name"], "[E]  Mark as Ostrowski")
			if not heard.has(k) and m.player.ads > 0.6:
				heard[k] = true
				Audio.say(info["spk"], info["quote"], info.get("vo", ""), "", true)
		else:
			m.main.hud.focus_label("", "")
	if focused != null and Input.is_action_just_pressed("interact"):
		_mark(focused)

func _aimed_director():
	var cam := m.player.cam
	var from := cam.global_position; var to := from - cam.global_basis.z * 60.0
	var q := PhysicsRayQueryParameters3D.create(from, to, Humanoid.LAYER_WORLD | Humanoid.LAYER_HITBOX, [m.player.get_rid()])
	q.collide_with_areas = true
	var hit := m.player.get_world_3d().direct_space_state.intersect_ray(q)
	if hit and hit["collider"] is Area3D and hit["collider"].has_meta("actor"):
		var a = hit["collider"].get_meta("actor")
		if a in directors: return a
	# glass blocks the ray (world layer); try ignoring it with a cone test
	for d in directors:
		var dir: Vector3 = (d.global_position + Vector3(0, 1.5, 0) - from).normalized()
		if dir.angle_to(-cam.global_basis.z) < 0.035: return d
	return null

func _mark(d: Humanoid) -> void:
	var k: int = d.get_meta("idx")
	var target: int = int(r.data["hvt"]["target"])
	m.main.hud.focus_label("", "")
	if k == target:
		marked = true
		Audio.say_generic("g_hvt_ok", true)
		Game.add_xp(150, "TARGET IDENTIFIED")
		_release_guards(false)
		for o in directors:
			if o != d: _flee(o)
		d.forced_anim = "Idle_LookAround"
	else:
		wrong += 1
		Audio.say_generic("g_hvt_wrong", true)
		m.main.hud.toast("WRONG TARGET", "%s follows the %s" % [r.data["hvt"]["directors"][k]["name"], String(r.data["hvt"]["directors"][k]["concept"]).to_lower()], Color(1, 0.35, 0.3))
		Game.stats["missed"].append("hvt:%s|%s" % [r.data["hvt"]["directors"][k]["quote"], r.data["hvt"]["directors"][k]["concept"]])
		if not guards_released: _release_guards(true)

func _release_guards(extra: bool) -> void:
	guards_released = true
	for e in r.enemies:
		e.passive = false; e.alert(false)
	if extra:
		for i in 2: m.spawn_enemy(r, entry_point(Vector3(randf_range(-3, 3), 0, r.z1 + 2.0)), "css", false, true)
	m.breach()

func _flee(d: Humanoid) -> void:
	d.forced_anim = "Jog_Fwd"
	var tw := create_tween()
	tw.tween_property(d, "global_position", d.global_position + Vector3(randf_range(-2, 2), 0, -3.0), 1.4)
	tw.tween_callback(d.hide)

func director_shot(a: Humanoid) -> void:
	var k: int = a.get_meta("idx")
	if k == int(r.data["hvt"]["target"]):
		m.main.hud.toast("HOLD FIRE", "We need Ostrowski alive", Color(1, 0.4, 0.3))
		Audio.say("MARR", "Hold your fire! We need him alive.", "", "", true)
	if not guards_released: _release_guards(true)

func _after(_dt: float) -> void:
	if marked and not r.cleared and r.alive_enemies().is_empty():
		r.cleared = true; say_post()
		m.main.hud.toast("SECTOR CLEAR", "Ostrowski secured", Color(0.85, 0.9, 0.9))
	if r.cleared and not has_calls() and intel_left() == 0 and not r.done: complete()

func terminal_ready() -> bool: return marked and r.cleared
func terminal_locked_text() -> String: return "Uplink locked  ·  identify the target first"
