extends ModeBase
## The loading-bay betrayal: survive the ambush; Ruiz is taken; run.

var hold := 60.0
var t := 0.0
var started := false
var wave_t := 1.0
var taken := false

func setup() -> void:
	hold = float(r.data.get("hold", 60))
	var n := maxi(4, int(r.data.get("e", 6)) + int(Game.diff()["cnt"]))
	m.spawn_room_enemies(r, n)
	for e in r.enemies: e.passive = true

func uses_terminal() -> bool: return false
func requires_clear() -> bool: return false
func music() -> String: return "ambush" if started else "tension"

func enter() -> void:
	m.player.input_enabled = false
	get_tree().create_timer(15.0).timeout.connect(_go)

func _go() -> void:
	m.player.input_enabled = true
	started = true
	for e in r.enemies: e.passive = false; e.alert(false)
	m.main.hud.timer_show(true)
	Fx.explosion(Vector3(0, 0.5, r.z1 + 4), true)

func objective() -> String:
	if not started: return "..."
	if r.done: return "Get out. North stairwell."
	return "Survive"

func tick(dt: float) -> void:
	if not started or r.done: return
	t += dt
	m.main.hud.timer_set(hold - t)
	wave_t -= dt
	if wave_t <= 0.0 and r.alive_enemies().size() < 8:
		wave_t = randf_range(5.0, 8.0)
		for i in 2 + randi() % 2:
			var e := m.spawn_enemy(r, Vector3(randf_range(-r.W * 0.4, r.W * 0.4), 0, r.z1 + 2.0), "", false, true)
			e.alert_delay = 0.0
	if not taken and t > hold * 0.7 and m.ally and m.ally.visible:
		taken = true
		Fx.explosion(m.ally.global_position + Vector3(1.5, 0.3, 0), false)
		m.ally.visible = false; m.ally.process_mode = Node.PROCESS_MODE_DISABLED
		for rr in m.rooms: rr.data["ally"] = false
	if t >= hold:
		r.done = true
		m.main.hud.timer_show(false)
		for e in r.alive_enemies(): e.passive = true
		say_post()
		m.main.mission_complete_after_dialogue()
