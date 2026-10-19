extends ModeBase
## Hold the room while Marr runs an uplink. Waves attack from the far end; intercepted lines pop up and
## must be classified with keys 1-3 while fighting. Right calls speed the uplink, wrong ones slow it.

var hold := 100.0
var progress := 0.0
var started := false
var wave_t := 3.0
var icpt_t := 8.0
var icpt_i := 0
var icpts: Array = []
var active := false
var console: Node3D
var finished_hold := false

func setup() -> void:
	hold = float(r.data.get("hold", 100))
	icpts = r.data.get("intercepts", []).duplicate()
	icpts.shuffle()
	var b := Builder.new(m, m.M)
	console = Node3D.new(); r.add_child(console); console.position = anchor("console", Vector3(0, 0, (r.z0 + r.z1) * 0.5 + 3.0))
	b.box(console, Vector3(2.2, 1.1, 1.2), Vector3(0, 0.55, 0), Mats.pbr("gunmetal", 1.0))
	b.box(console, Vector3(1.8, 0.9, 0.06), Vector3(0, 1.6, 0.0), Mats.glow(Color(0.3, 0.9, 1.0), 1.2), false, false)
	b.label(console, "LEDGER UPLINK", Vector3(0, 1.62, 0.05), 0, 40, Color(0.02, 0.06, 0.08), "IBMPlexMono-Medium", 0, HORIZONTAL_ALIGNMENT_CENTER, true)
	b.omni(console, Vector3(0, 2.2, 1.0), Color(0.4, 0.9, 1.0), 1.2, 5.0)
	for p in [Vector3(-3, 0, 2.5), Vector3(3, 0, 2.5), Vector3(0, 0, -2.4)]:
		Props.spawn("prop_barrier", console, p, 0 if absf(p.x) < 1 else 1)
		r.cover_points.append(console.global_position + p * 1.2)

func uses_terminal() -> bool: return false
func requires_clear() -> bool: return false

func enter() -> void:
	started = true
	m.main.hud.progress_show(true, "UPLINK")

func music() -> String: return "defend" if started and not finished_hold else ""

func objective() -> String:
	if r.done: return "Advance to the next sector"
	if not finished_hold: return "Defend the uplink  ·  %d%%" % int(progress / hold * 100.0)
	if r.alive_enemies().size() > 0: return "Clear the remaining hostiles  (%d)" % r.alive_enemies().size()
	return default_objective()

func tick(dt: float) -> void:
	if not started or r.done: return
	if not finished_hold:
		progress += dt
		m.main.hud.progress_set(progress / hold)
		wave_t -= dt
		var alive := r.alive_enemies().size()
		if wave_t <= 0.0 and alive < 7:
			wave_t = randf_range(6.0, 9.0)
			var n := 2 + randi() % 2 + int(Game.diff()["cnt"])
			for i in n:
				var p := entry_point(Vector3(randf_range(-r.W * 0.4, r.W * 0.4), 0, r.z1 + randf_range(1.5, 4.0)))
				var e := m.spawn_enemy(r, p, "", false, true)
				e.alert_delay = 0.0
			if randf() < 0.5: Audio.bark("RUIZ", "contact2")
		icpt_t -= dt
		if icpt_t <= 0.0 and not active and icpt_i < icpts.size():
			_next_intercept()
		if progress >= hold:
			finished_hold = true
			m.main.hud.progress_show(false, "")
			m.main.hud.intercept_hide()
			say_post()
			m.main.hud.toast("UPLINK COMPLETE", "", Color(0.4, 0.95, 1.0))
	elif r.alive_enemies().is_empty() and intel_left() == 0:
		complete()

func _next_intercept() -> void:
	var ic: Dictionary = icpts[icpt_i]; icpt_i += 1
	active = true
	var opts: Array = ic["a"].duplicate(); var correct: String = opts[0]; opts.shuffle()
	m.main.hud.intercept_show(ic["line"], opts, 12.0, func(choice: int): _answer(ic, opts, correct, choice))

func _answer(ic: Dictionary, opts: Array, correct: String, choice: int) -> void:
	active = false; icpt_t = randf_range(5.0, 8.0)
	Game.stats["intercepts"] += 1
	if choice >= 0 and opts[choice] == correct:
		Game.stats["intercepts_ok"] += 1
		progress = minf(hold, progress + 6.0)
		Game.add_xp(30, "INTERCEPT")
		Audio.say_generic("g_intercept_ok")
	else:
		progress = maxf(0.0, progress - 5.0)
		Audio.say_generic("g_intercept_bad")
		m.main.hud.toast("✖  " + correct.to_upper(), ic["line"], Color(1, 0.4, 0.3))
		Game.stats["missed"].append("icpt:%s|%s" % [ic["line"], correct])
