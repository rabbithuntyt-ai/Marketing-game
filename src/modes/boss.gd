extends ModeBase
## Boss sector: an armoured commander plus reinforcements. Optional recall nodes (final mission) must be
## answered under fire. Some bosses escape when badly hurt.

var boss: Enemy
var nodes: Array = []
var nodes_done := 0
var spawn_t := 18.0
var escaped := false
var started := false

func setup() -> void:
	var n := maxi(3, int(r.data.get("e", 5)) + int(Game.diff()["cnt"]))
	m.spawn_room_enemies(r, n)
	var who: String = String(r.data.get("boss", "KESSLER")).to_lower()
	boss = m.spawn_enemy(r, Vector3(0, 0, r.z1 + 7.0), "kessler" if who == "kessler" else "hale")
	boss.alert_delay = 1.6
	var k := int(r.data.get("recall_nodes", 0))
	var b := Builder.new(m, m.M)
	for i in k:
		var p := Vector3([-r.W * 0.35, r.W * 0.35, 0.0][i], 0, [(r.z0 + r.z1) * 0.5 + 4, (r.z0 + r.z1) * 0.5 + 4, r.z1 + 3.5][i])
		var node := Node3D.new(); r.add_child(node); node.position = p
		b.box(node, Vector3(1.0, 1.2, 1.0), Vector3(0, 0.6, 0), Mats.pbr("gunmetal", 1.0))
		b.box(node, Vector3(0.8, 0.5, 0.05), Vector3(0, 1.45, 0.4), Mats.glow(Color(1.0, 0.85, 0.5), 1.4), false, false)
		var l := b.omni(node, Vector3(0, 2.0, 0), Color(1.0, 0.8, 0.4), 1.2, 4.0)
		nodes.append({"node": node, "done": false, "light": l})

func uses_terminal() -> bool: return r.done and has_calls() and not r.calls_done

func enter() -> void:
	started = true
	m.main.hud.boss_show(String(r.data.get("boss", "KESSLER")), true)
	m.breach()

func music() -> String: return "boss" if started and not r.done else ""

func objective() -> String:
	if r.done and has_calls() and not r.calls_done: return "Send Marr your last read at the uplink"
	if r.done: return "Extract"
	var parts: Array = []
	if not nodes.is_empty() and nodes_done < nodes.size(): parts.append("Answer the board terminals  (%d/%d)" % [nodes_done, nodes.size()])
	if is_instance_valid(boss) and not boss.dead and not escaped: parts.append("Bring down %s" % String(r.data.get("boss", "")).capitalize())
	elif r.alive_enemies().size() > 0: parts.append("Clear the room  (%d)" % r.alive_enemies().size())
	return "  ·  ".join(parts) if not parts.is_empty() else default_objective()

func interactables() -> Array:
	var out: Array = []
	for nd in nodes:
		if nd["done"]: continue
		out.append({"pos": nd["node"].global_position + Vector3(0, 0, 1.0), "radius": 2.0, "prompt": "Board terminal  ·  recall check", "cb": _node.bind(nd)})
	return out

func _node(nd: Dictionary) -> void:
	var keys := Game.recall_items(1, [], 6)
	if keys.is_empty(): _node_done(nd); return
	m.main.open_terminal(r, ["R:" + keys[0]], func(ok: bool):
		if ok: _node_done(nd)
		else: m.on_wrong_answer())

func _node_done(nd: Dictionary) -> void:
	nd["done"] = true; nodes_done += 1
	(nd["light"] as OmniLight3D).light_color = Color(0.4, 1.0, 0.5)
	m.main.hud.toast("VOTE NODE %d CANCELLED" % nodes_done, "", Color(0.5, 1.0, 0.6))
	Game.add_xp(100, "RECALL")

func tick(dt: float) -> void:
	if not started or r.done: return
	if is_instance_valid(boss):
		m.main.hud.boss_set(boss.hp / boss.max_hp, boss.armor)
		if r.data.get("boss_escapes", false) and not escaped and boss.hp < boss.max_hp * 0.4:
			escaped = true
			Fx.emit("smoke", boss.global_position + Vector3(0, 1, 0))
			boss.visible = false; boss.dead = true; boss.collision_layer = 0
			m.main.hud.boss_show("", false)
	spawn_t -= dt
	if spawn_t <= 0.0 and is_instance_valid(boss) and not boss.dead and r.alive_enemies().size() < 4:
		spawn_t = 20.0
		for i in 2: m.spawn_enemy(r, Vector3(randf_range(-3, 3), 0, r.z1 + 2), "", false, true)
		m.main.hud.toast("REINFORCEMENTS", "", Color(1, 0.35, 0.3))
	var boss_done: bool = escaped or not is_instance_valid(boss) or boss.dead
	if boss_done and r.alive_enemies().is_empty() and nodes_done >= nodes.size():
		r.done = true
		m.main.hud.boss_show("", false)
		say_post()
		if not has_calls(): m.main.mission_complete_after_dialogue()

func on_calls_done() -> void:
	m.main.mission_complete_after_dialogue()

func on_kill(e) -> void:
	if e == boss:
		m.main.hud.boss_show("", false)
		Fx.cam_shake = 0.5
		for o in r.alive_enemies():
			if randf() < 0.5: o.take_damage(999, "body", o.global_position)
