extends ModeBase
## Stealth sector: patrols with vision cones. Crouch, use cover, take guards from behind (F).
## Being seen raises the alarm: everyone converges and reinforcements arrive. The uplink works mid-patrol.

var detected := false

func setup() -> void:
	var n := maxi(3, int(r.data.get("e", 4)) + int(Game.diff()["cnt"]))
	var hw := r.W * 0.5
	for i in n:
		var a := Vector3(randf_range(-hw + 3, hw - 3), 0, randf_range(r.z1 + 4, r.z0 - 9))
		var e := m.spawn_enemy(r, a, "css", true)
		var pts: Array = [a]
		for k in 2 + randi() % 2:
			pts.append(Vector3(clampf(a.x + randf_range(-9, 9), -hw + 2, hw - 2), 0, clampf(a.z + randf_range(-9, 9), r.z1 + 3, r.z0 - 8)))
		e.patrol = pts; e.state = "patrol"; e.stealth_room = true

func enter() -> void:
	m.loud = false
	m.main.hud.toast("STAY QUIET", "Crouch [C] · takedown from behind [F]", Color(0.75, 0.7, 1.0))

func requires_clear() -> bool: return detected

func music() -> String: return "stealth" if not detected else ""

func on_detected() -> void:
	if detected: return
	detected = true; m.loud = true
	Audio.say_generic("g_detected", true)
	Audio.play2d("alarm", -6.0)
	for e in r.alive_enemies(): e.alert(false)
	for i in 2: m.spawn_enemy(r, Vector3(randf_range(-2, 2), 0, r.z1 + 2.0), "css", false, true)
	m.main.hud.toast("DETECTED", "Alarm raised", Color(1, 0.35, 0.3))

func tick(_dt: float) -> void:
	if not r.entered: return
	var max_aw := 0.0
	for e in r.alive_enemies():
		if e.state != "alert": max_aw = maxf(max_aw, e.awareness)
	m.main.hud.detection(max_aw if not detected else 0.0)
	if detected and not r.cleared and r.alive_enemies().is_empty():
		r.cleared = true; say_post()
	if not has_calls() and intel_left() == 0 and not r.done and (r.cleared or not detected) and m.player.global_position.z < r.z1 + 4.0:
		complete()

func on_calls_done() -> void:
	if not detected:
		Game.stats["undetected"] += 1
		Game.add_xp(150, "UNDETECTED")
	say_post()
	complete()

func objective() -> String:
	if r.done: return "Advance to the next sector"
	if detected and r.alive_enemies().size() > 0: return "Detected  ·  eliminate hostiles  (%d)" % r.alive_enemies().size()
	var left := intel_left()
	if left > 0: return "Stay hidden  ·  recover intel  (%d left)" % left
	if has_calls() and not r.calls_done: return "Stay hidden  ·  reach the uplink"
	return "Advance to the next sector"
