class_name ModeBase
extends Node
## Base behaviour for a sector. Subclasses override hooks.

var m: Mission
var r: Room
var said_post := false

func setup() -> void: pass
func enter() -> void: pass
func tick(_dt: float) -> void: pass
func skip() -> void: pass
func music() -> String: return ""
func interactables() -> Array: return []
func uses_terminal() -> bool: return true
func terminal_ready() -> bool: return true
func requires_clear() -> bool: return true
func terminal_locked_text() -> String: return ""
func on_kill(_e) -> void: pass
func on_detected() -> void: pass
func is_loud() -> bool: return true

## Spawn hand-placed guards (authored sectors). unaware=true: they patrol until they spot you.
func spawn_guards(unaware: bool) -> void:
	var diff := int(Game.settings["difficulty"])
	for g in r.guards:
		if int(g.get("tier", 0)) > diff: continue
		var e: Enemy = m.spawn_enemy(r, g["pos"], g["variant"], unaware)
		e.rotation.y = -deg_to_rad(float(g["yaw"]))
		if not unaware: continue
		e.stealth_room = true
		if (g["patrol"] as Array).is_empty():
			e.post_yaw = g["yaw"]; e.state = "idle"
		else:
			e.patrol = g["patrol"]; e.patrol_waits = g["waits"]; e.patrol_looks = g["looks"]; e.state = "patrol"

## Authored anchor (set by a hand-built sector with Sector.anchor) or the procedural default.
func anchor(name: String, default):
	return r.get_meta("a_" + name, default)

## Where reinforcements enter: an authored spawn point (one of the farther ones from the player) or default.
func entry_point(default: Vector3) -> Vector3:
	if not r.authored or r.spawn_points.is_empty(): return default
	var pp := m.player.global_position
	var pts: Array = r.spawn_points.duplicate()
	pts.sort_custom(func(a, b): return (a - pp).length() > (b - pp).length())
	return pts[randi() % maxi(1, pts.size() / 2 + 1)] + Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6))

## Standard enemy population: hand-placed guards when the sector has them, else spawn points.
func populate(n: int, unaware := false) -> void:
	if r.authored and not r.guards.is_empty(): spawn_guards(unaware)
	else: m.spawn_room_enemies(r, n)

func has_calls() -> bool:
	return not r.data.get("calls", []).is_empty() or int(r.data.get("recall", 0)) > 0

func on_calls_done() -> void:
	complete()

func say_post() -> void:
	if said_post: return
	said_post = true
	Audio.say_lines(r.data.get("post", []))

func complete() -> void:
	if r.done: return
	r.done = true
	r.open_exit()
	m.main.hud.toast("SECTOR SECURE", "Exit unlocked", Color(0.5, 1.0, 0.65))
	Game.add_xp(50, "SECTOR")

func intel_left() -> int:
	return r.intel.filter(func(i): return is_instance_valid(i)).size()

func default_objective() -> String:
	if r.done: return "Advance to the next sector" if r.ri < m.rooms.size() - 1 else "Reach extraction"
	var alive := r.alive_enemies().size()
	if alive > 0 and requires_clear(): return "Eliminate hostiles  (%d)" % alive
	var left := intel_left()
	if left > 0: return "Recover intel  (%d left)" % left
	if has_calls() and not r.calls_done: return "Access the LEDGER uplink"
	return "Advance to the next sector"
