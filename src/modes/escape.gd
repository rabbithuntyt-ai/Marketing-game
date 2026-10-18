extends ModeBase
## Timed escape through a collapsing passage: alarms, red light, explosions behind you.

var timer := 75.0
var running := false
var boom_t := 2.0
var alarm_lights: Array = []

func setup() -> void:
	timer = float(r.data.get("timer", 75))
	r.open_exit(true)
	for l in r.lights: (l as Light3D).light_color = Color(1.0, 0.25, 0.15)
	var n := maxi(3, int(r.data.get("e", 4)) + int(Game.diff()["cnt"]))
	m.spawn_room_enemies(r, n)

func uses_terminal() -> bool: return false
func requires_clear() -> bool: return false
func music() -> String: return "escape"

func enter() -> void:
	running = true
	Audio.play2d("boom_big_1", 0.0)
	Fx.cam_shake = 1.0
	Audio.ambience("alarm", -10.0, "underground", -14.0)
	m.main.hud.timer_show(true)
	for e in r.enemies: e.alert(false)

func objective() -> String:
	if r.done: return "Get to the lift"
	return "Reach the lift before the bunker seals"

func tick(dt: float) -> void:
	if not running or r.done: return
	timer -= dt
	m.main.hud.timer_set(timer)
	for l in r.lights: (l as Light3D).light_energy = 4.0 + sin(Time.get_ticks_msec() * 0.008) * 2.5
	boom_t -= dt
	if boom_t <= 0.0:
		boom_t = randf_range(2.5, 5.0)
		var p := m.player.global_position + Vector3(randf_range(-4, 4), 0.5, randf_range(6, 14))
		Fx.explosion(p, true); Fx.cam_shake = 0.7
	if m.player.global_position.z < r.z1 + 1.5:
		r.done = true; running = false
		m.main.hud.timer_show(false)
		say_post()
	elif timer <= 0.0:
		running = false
		Audio.say_generic("g_escape_fail", true)
		m.main.restart_room()
