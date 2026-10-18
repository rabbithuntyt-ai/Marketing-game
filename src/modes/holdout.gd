extends ModeBase
## Survive waves until extraction arrives (rooftop LZ).

var hold := 75.0
var t := 0.0
var started := false
var wave_t := 2.0
var mid_said := false

func setup() -> void:
	hold = float(r.data.get("hold", 75))
	var n := maxi(2, int(r.data.get("e", 4)) + int(Game.diff()["cnt"]))
	m.spawn_room_enemies(r, n)

func uses_terminal() -> bool: return false
func requires_clear() -> bool: return false

func enter() -> void:
	started = true
	m.main.hud.timer_show(true)
	for e in r.enemies: e.alert(false)

func music() -> String: return "combat" if started and not r.done else ""

func objective() -> String:
	if r.done: return "Board the helicopter"
	return "Hold the landing zone"

func tick(dt: float) -> void:
	if not started or r.done: return
	t += dt
	m.main.hud.timer_set(hold - t)
	if not mid_said and t > hold * 0.45:
		mid_said = true; Audio.say_lines(r.data.get("mid", []))
	wave_t -= dt
	if wave_t <= 0.0 and r.alive_enemies().size() < 7:
		wave_t = randf_range(7.0, 10.0)
		for i in 2 + randi() % 2 + int(Game.diff()["cnt"]):
			var s := -1.0 if randf() < 0.5 else 1.0
			var e := m.spawn_enemy(r, Vector3(s * (r.W * 0.5 - 2.0), 0, r.z1 + randf_range(2, 8)), "", false, true)
			e.alert_delay = 0.0
	if t >= hold:
		r.done = true
		m.main.hud.timer_show(false)
		for e in r.alive_enemies(): e.passive = true
		say_post()
		m.main.mission_complete_after_dialogue()
