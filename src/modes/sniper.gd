extends ModeBase
## Rooftop overwatch: high-power rifle, Ruiz crosses the yard to the truck. Hostiles target him; keep him alive.

var started := false
var wave_t := 2.0
var spawned := 0
var max_spawn := 16
var failed := false

func setup() -> void:
	max_spawn = 14 + int(Game.diff()["cnt"]) * 3

func uses_terminal() -> bool: return false
func requires_clear() -> bool: return false
func music() -> String: return "sniper"

func enter() -> void:
	started = true
	var py: float = r.get_meta("perch_y", 7.0)
	var p := m.player
	p.global_position = Vector3(0, py + 0.2, r.z0 - 3.0)
	p.sniper = true; p.mag = 5; p.ammo = 5; p.locked = false
	p.perch_bounds = Rect2(Vector2(-r.W * 0.45, r.z0 - 5.6), Vector2(r.W * 0.9, 4.6))
	p.locked = true
	var a := m.ally
	a.visible = true; a.process_mode = Node.PROCESS_MODE_INHERIT
	a.scripted = true; a.escort_hp = 100.0
	a.global_position = Vector3(-6, 0, r.z0 - 8.0)
	var truck: Vector3 = r.get_meta("truck", Vector3(4, 0, r.z1 + 8))
	a.escort_path = [Vector3(-8, 0, r.z0 - 18), Vector3(6, 0, r.z0 - 30), Vector3(-5, 0, r.z0 - 44), Vector3(7, 0, r.z0 - 56), truck + Vector3(-2.5, 0, 2.0)]
	a.escort_i = 0
	m.main.hud.progress_show(true, "RUIZ")
	m.main.hud.toast("OVERWATCH", "Hold [RMB] to scope · protect Ruiz", Color(1.0, 0.75, 0.4))

func objective() -> String:
	if r.done: return "Extract"
	return "Cover Ruiz to the truck  ·  %d%%" % int(m.ally.escort_hp)

func tick(dt: float) -> void:
	if not started or r.done or failed: return
	var a := m.ally
	m.main.hud.progress_set(a.escort_hp / 100.0)
	wave_t -= dt
	if wave_t <= 0.0 and spawned < max_spawn and r.alive_enemies().size() < 6:
		wave_t = randf_range(3.0, 5.5)
		var ahead: Vector3 = a.escort_path[mini(a.escort_i + 1, a.escort_path.size() - 1)]
		for i in 1 + randi() % 2:
			var s := -1.0 if randf() < 0.5 else 1.0
			var pos := Vector3(s * randf_range(10, 18), 0, ahead.z + randf_range(-6, 6))
			var e := m.spawn_enemy(r, pos, "css", false, true)
			e.focus_ally = true; e.hold_pos = Vector3(s * randf_range(6, 12), 0, ahead.z + randf_range(-4, 4)); spawned += 1
	if a.escort_hp <= 0.0:
		failed = true
		Audio.say_generic("g_sniper_fail", true)
		m.main.restart_room()
		return
	var truck: Vector3 = r.get_meta("truck", Vector3(4, 0, r.z1 + 8))
	if a.escort_i >= a.escort_path.size() - 1 and (a.global_position - a.escort_path[-1]).length() < 1.6:
		r.done = true
		for e in r.alive_enemies(): e.passive = true
		a.visible = false
		m.player.sniper = false; m.player.locked = false; m.player.mag = 30; m.player.ammo = 30
		m.main.hud.progress_show(false, "")
		say_post()
		m.main.mission_complete_after_dialogue()
