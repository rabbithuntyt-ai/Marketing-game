extends ModeBase
## Holding block: clear the guards, open cell four, Ruiz rejoins.

var freed := false
var prisoner: Humanoid
var cell := Vector3.ZERO

func setup() -> void:
	var n := maxi(3, int(r.data.get("e", 5)) + int(Game.diff()["cnt"]))
	populate(n, true)
	cell = anchor("cell", Vector3(r.W * 0.5 - 1.5, 0, r.z0 - 5 - 3 * 6))
	prisoner = Humanoid.new(); m.add_child(prisoner); prisoner.team = "neutral"; prisoner.setup("ally", r)
	prisoner.global_position = cell; prisoner.rotation.y = PI * 0.5
	prisoner.forced_anim = "GroundSit_Idle"; prisoner.set_physics_process(false)
	if prisoner.muzzle: prisoner.muzzle.get_parent().visible = false
	for a in prisoner.find_children("*", "Area3D", true, false): (a as Area3D).collision_layer = 0

func enter() -> void:
	if r.alive_enemies().size() > 0: m.breach()

func objective() -> String:
	if r.done: return "Advance with Ruiz"
	if r.alive_enemies().size() > 0: return "Eliminate hostiles  (%d)" % r.alive_enemies().size()
	if not freed: return "Free Ruiz  ·  cell four"
	return default_objective()

func interactables() -> Array:
	if freed or r.alive_enemies().size() > 0: return []
	return [{"pos": cell + Vector3(-2.2, 0, 0), "radius": 2.6, "prompt": "Open cell four", "cb": _free}]

func tick(dt: float) -> void:
	if is_instance_valid(prisoner) and prisoner.visible: prisoner.locomotion(dt)
	if freed and not r.done and r.alive_enemies().is_empty() and (not has_calls() or r.calls_done) and intel_left() == 0: complete()

func requires_clear() -> bool: return true

func _free() -> void:
	freed = true
	Audio.play3d("door_open", cell, 0.0)
	prisoner.queue_free()
	var a := m.ally
	for rr in m.rooms:
		if rr.ri >= r.ri: rr.data["ally"] = true
	a.visible = true; a.process_mode = Node.PROCESS_MODE_INHERIT
	a.global_position = cell + Vector3(-1.5, 0, 0)
	say_post()
	Game.add_xp(200, "RUIZ RESCUED")

func terminal_ready() -> bool: return freed
func terminal_locked_text() -> String: return "Uplink locked  ·  get Ruiz first"
