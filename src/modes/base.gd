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
