class_name Mission
extends Node3D
## Runs one mission: builds sectors, spawns actors, tracks the current room, objectives, analysis terminals,
## intel, checkpoints, music state and completion. Special room kinds are delegated to mode scripts.

signal objective_changed(text: String)

var main: Node
var mi := 0
var M: Dictionary
var rooms: Array = []
var cur_room: Room
var player: Player
var ally: Ally
var env: LevelEnv
var loud := false
var start_room := 0
var finished := false
var _obj := ""
var _slow_t := 0.0
var _music_state := ""
var _combat_hold := 0.0
var marked_t := 0.0
var _near: Dictionary = {}
var cut_active := false

const MODES := {
	"range": preload("res://src/modes/range.gd"), "hvt": preload("res://src/modes/hvt.gd"), "plant": preload("res://src/modes/plant.gd"),
	"defend": preload("res://src/modes/defend.gd"), "stealth": preload("res://src/modes/stealth.gd"), "tail": preload("res://src/modes/tail.gd"),
	"sniper": preload("res://src/modes/sniper.gd"), "evidence": preload("res://src/modes/evidence.gd"), "escape": preload("res://src/modes/escape.gd"),
	"holdout": preload("res://src/modes/holdout.gd"), "rescue": preload("res://src/modes/rescue.gd"), "ambush": preload("res://src/modes/ambush.gd"),
	"boss": preload("res://src/modes/boss.gd"), "combat": preload("res://src/modes/combat.gd"),
}

func build(main_node: Node, mission_index: int, from_room := 0) -> void:
	main = main_node; mi = mission_index; M = Game.missions[mi]; start_room = from_room
	Game.mission_index = mi
	Audio.voice_mission = M["id"]
	Fx.setup(self)
	env = LevelEnv.new(); add_child(env); env.setup(M)
	var b := Builder.new(self, M)
	rooms = b.build_all()
	for r in rooms:
		_bake_nav(r)
	player = Player.new(); player.mission = self; add_child(player)
	if M["rooms"].any(func(rd): return rd.get("ally", false)):
		ally = Ally.new(); add_child(ally); ally.init_ally(self)
	for r in rooms:
		var kind: String = r.kind
		var script: GDScript = MODES.get(kind, MODES["combat"])
		var mode: Node = script.new(); mode.name = "Mode"; r.add_child(mode); r.mode = mode
		mode.m = self; mode.r = r
		mode.setup()
	# skip earlier rooms when resuming from a checkpoint
	for i in from_room:
		var r: Room = rooms[i]
		r.entered = true; r.cleared = true; r.done = true; r.open_exit(true)
		for e in r.enemies: e.queue_free()
		r.enemies.clear()
		for it in r.intel: it.queue_free()
		r.intel.clear()
		if r.mode.has_method("skip"): r.mode.skip()
	var s: Room = rooms[from_room]
	player.global_position = Vector3(0, 0.1, s.z0 - 2.0 if from_room == 0 else s.z0 + 1.5)
	player.yaw = 0.0
	if ally: ally.global_position = player.global_position + Vector3(1.6, 0, 1.8)
	cur_room = s
	_update_visibility()
	Audio.music(M["music"].get("explore", "deeper"), 3.0)
	_ambience()

func _bake_nav(r: Room) -> void:
	var nm := NavigationMesh.new()
	nm.agent_radius = 0.5; nm.agent_height = 2.0; nm.agent_max_climb = 0.25; nm.cell_size = 0.25; nm.cell_height = 0.25
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	r.nav.navigation_mesh = nm
	r.nav.bake_navigation_mesh(false)

func spawn_enemy(r: Room, pos: Vector3, variant := "", stealth := false, alert := false) -> Enemy:
	if variant == "":
		variant = "css"
		var roll := randf()
		if mi >= 1 and roll < 0.14: variant = "marksman"
		elif mi >= 2 and roll < 0.28: variant = "heavy"
	var e := Enemy.new(); add_child(e)
	e.global_position = pos
	e.rotation.y = randf_range(-0.6, 0.6)
	e.init_enemy(self, r, variant, stealth)
	r.enemies.append(e)
	if alert: e.alert(false)
	return e

func spawn_room_enemies(r: Room, n: int, stealth := false) -> void:
	var pts := r.spawn_points.duplicate(); pts.shuffle()
	for i in n:
		var p: Vector3 = pts[i % pts.size()]
		spawn_enemy(r, p, "", stealth)

func all_enemies() -> Array:
	var out: Array = []
	if cur_room: out.append_array(cur_room.alive_enemies())
	var nx := next_room()
	if nx and nx.entered: out.append_array(nx.alive_enemies())
	return out

func next_room() -> Room:
	if cur_room == null: return null
	return rooms[cur_room.ri + 1] if cur_room.ri + 1 < rooms.size() else null

# ---------------------------------------------------------------- frame
func _process(dt: float) -> void:
	if finished or player == null: return
	if cut_active:
		env.update(dt, get_viewport().get_camera_3d().global_position, cur_room.outdoor, cur_room.data.get("weather", ""))
		return
	Game.stats["time"] = Game.stats.get("time", 0.0) + dt
	# breach slow motion uses real time
	if _slow_t > 0.0:
		_slow_t -= dt / maxf(0.05, Engine.time_scale)
		Engine.time_scale = 0.35 if _slow_t > 0.25 else lerpf(1.0, 0.35, _slow_t / 0.25)
		if _slow_t <= 0.0: Engine.time_scale = 1.0
	var pz := player.global_position.z
	for r in rooms:
		if r.contains(player.global_position) and r != cur_room:
			cur_room = r; _update_visibility(); _ambience(); player.set_room_settings(r)
			if r.kind != "range": main.hud.drill_show(false)
	if not cur_room.entered and pz < cur_room.z0 - 1.0:
		_enter(cur_room)
	cur_room.mode.tick(dt)
	env.update(dt, player.cam.global_position, cur_room.outdoor, cur_room.data.get("weather", ""))
	_interactions()
	_music_logic(dt)
	var o: String = cur_room.mode.objective()
	if o != _obj:
		_obj = o; objective_changed.emit(o)
	# mission end
	var last: Room = rooms[rooms.size() - 1]
	if last.done and pz < last.cz1 + 3.0 and not finished:
		finished = true; main.mission_complete()
	if player.dead and not finished:
		finished = true; main.player_died()

func _update_visibility() -> void:
	for r in rooms:
		var near: bool = absi(r.ri - cur_room.ri) <= 1
		r.visible = near
		for l in r.shadow_lights: (l as Light3D).shadow_enabled = r == cur_room
	if ally:
		var on: bool = cur_room.data.get("ally", false)
		ally.visible = on
		ally.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
		if on and (ally.global_position - player.global_position).length() > 15.0:
			ally.global_position = player.global_position + Vector3(1.4, 0, 2.0)

func _ambience() -> void:
	var th: String = M["theme"]
	var w: String = cur_room.data.get("weather", "")
	var any_rain: bool = M["rooms"].any(func(rd): return rd.get("weather", "") in ["rain", "storm"])
	if cur_room.outdoor:
		match w:
			"rain": Audio.ambience("rain_heavy", -6.0, "night", -20.0)
			"storm": Audio.ambience("storm", -3.0, "rain_heavy", -10.0)
			"snow": Audio.ambience("snowstorm", -8.0)
			_: Audio.ambience("night", -10.0)
		Audio.set_reverb(0.04, 0.9)
	else:
		Audio.ambience("underground" if th in ["bunker", "data"] else "indoors", -14.0, "rain_inside" if any_rain else "", -16.0)
		Audio.set_reverb(0.16 if cur_room.H > 7 else 0.11, 0.6)

func _enter(r: Room) -> void:
	r.entered = true
	Game.stats["room"] = r.ri
	Game.save["checkpoint"] = {"m": mi, "r": r.ri}
	Game.persist()
	main.hud.sector_card(r.ri + 1, rooms.size(), r.data["n"], M["color"])
	Audio.say_lines(r.data.get("r", []))
	player.set_room_settings(r)
	if ally and r.data.get("ally", false):
		ally.stealth = r.kind == "stealth"
	r.mode.enter()
	_tips_for(r)
	if marked_t > 0.0:
		for e in r.enemies: main.hud.mark_enemy(e, 25.0)
		marked_t = 0.0

func _tips_for(r: Room) -> void:
	var seen: Dictionary = Game.save.get("tips", {})
	var want: Array = []
	if mi == 0 and r.ri == 0: want = ["move", "fire", "intel"]
	match r.kind:
		"range": want.append("range")
		"stealth": want.append("stealth")
		"hvt": want.append("hvt")
		"tail": want.append("tail")
		"sniper": want.append("sniper")
		"defend": want.append("defend")
	if mi == 0 and r.ri == 1: want.append_array(["grenade", "takedown"])
	const T := {
		"move": [["W A S D", "Move"], ["Shift", "Sprint"], ["Ctrl", "Crouch"]],
		"fire": [["LMB", "Fire"], ["RMB", "Aim down sights"], ["R", "Reload"]],
		"intel": [["E", "Read glowing intel. It's what the uplink questions are about."]],
		"grenade": [["G", "Throw grenade"]], "takedown": [["F", "Silent takedown from behind"]],
		"range": [["LMB", "Shoot the targets Marr calls, in order when she says so"]],
		"stealth": [["Ctrl", "Stay crouched and out of sight. The meter above your sights is their suspicion."], ["F", "Takedowns are silent"]],
		"hvt": [["RMB", "Aim at a director to listen in"], ["E", "Mark the one whose philosophy matches Marr's profile"]],
		"tail": [["Shift", "Keep your distance. Too close and he'll make you; too far and you lose him."]],
		"sniper": [["RMB", "Scope in. Five rounds per magazine; make them count."]],
		"defend": [["1 2 3", "Classify intercepted radio chatter while you hold the position"]],
	}
	var out: Array = []
	for k in want:
		if seen.has(k): continue
		seen[k] = true
		out.append_array(T[k])
	Game.save["tips"] = seen
	if not out.is_empty(): main.hud.tips(out)

func breach() -> void:
	_slow_t = 1.05
	Audio.play2d("whoosh" if Audio.sfx("whoosh") else "kenney_weapon_change", -6.0)

func _music_logic(dt: float) -> void:
	var mm: Dictionary = M["music"]
	var want: String = cur_room.mode.music()
	if want == "":
		var fighting := false
		for e in cur_room.alive_enemies():
			if e.is_alerted(): fighting = true; break
		if fighting: _combat_hold = 6.0
		else: _combat_hold -= dt
		want = mm.get("combat", "retribution") if _combat_hold > 0.0 else mm.get("explore", "deeper")
	elif mm.has(want): want = mm[want]
	if want != _music_state:
		_music_state = want; Audio.music(want, 2.5)

## Where the HUD marker should point: the current room's open task, else the exit.
func waypoint():
	if cur_room == null: return null
	var r := cur_room
	if r.mode.has_method("waypoint"):
		var w = r.mode.waypoint()
		if w != null: return w
	if r.alive_enemies().size() > 0 and r.mode.requires_clear() and r.kind != "stealth": return null
	for it in r.intel:
		if is_instance_valid(it): return it.global_position
	if r.terminal and r.mode.uses_terminal() and not r.calls_done and r.mode.terminal_ready(): return r.terminal.global_position
	for it2 in r.mode.interactables():
		return it2["pos"]
	var last := r.ri == rooms.size() - 1
	if r.kind == "escape": return Vector3(0, 0, r.cz1 + 1.0)
	if r.done and not last: return Vector3(0, 0, r.z1 - 1.0)
	return null

# ---------------------------------------------------------------- interaction
func _interactions() -> void:
	var best = null; var bd := 99.0
	var pp := player.global_position
	for it in cur_room.intel:
		if not is_instance_valid(it): continue
		var d := Vector2(it.global_position.x - pp.x, it.global_position.z - pp.z).length()
		if d < 1.9 and d < bd:
			bd = d; best = {"prompt": "Read intel  ·  %s" % it.get_meta("doc")["t"], "cb": _read_intel.bind(it)}
	if cur_room.terminal and cur_room.mode.uses_terminal():
		var d2 := Vector2(cur_room.terminal.global_position.x - pp.x, cur_room.terminal.global_position.z - pp.z).length()
		if d2 < 2.3 and d2 < bd:
			bd = d2; best = _terminal_prompt()
	for it2 in cur_room.mode.interactables():
		var p2: Vector3 = it2["pos"]
		var d3 := Vector2(p2.x - pp.x, p2.z - pp.z).length()
		if d3 < it2.get("radius", 2.0) and d3 < bd: bd = d3; best = it2
	_near = best if best != null else {}
	main.hud.set_prompt(_near.get("prompt", ""), _near.has("cb"))
	if _near.has("cb") and Input.is_action_just_pressed("interact") and player.input_enabled and not main.input_cooldown():
		(_near["cb"] as Callable).call()

func _terminal_prompt() -> Dictionary:
	var r := cur_room
	if r.calls_done: return {}
	var alive := r.alive_enemies().size()
	if alive > 0 and r.mode.requires_clear(): return {"prompt": "Uplink locked  ·  %d hostile%s in sector" % [alive, "s" if alive > 1 else ""]}
	var left := r.intel.filter(func(i): return is_instance_valid(i)).size()
	if left > 0: return {"prompt": "Uplink locked  ·  recover all intel first (%d left)" % left}
	if not r.mode.terminal_ready(): return {"prompt": r.mode.terminal_locked_text()}
	return {"prompt": "Access uplink  ·  Dr. Marr needs your read", "cb": _open_terminal}

func _read_intel(it: Node3D) -> void:
	var doc: Dictionary = it.get_meta("doc")
	var id := "%s-%d-%d" % [M["id"], cur_room.ri, it.get_meta("k")]
	if not Game.save["intel"].has(id):
		Game.add_xp(25, "INTEL"); Game.save["intel"][id] = 1; Game.persist()
	Game.stats["intel"] += 1
	cur_room.intel.erase(it)
	Audio.play2d("kenney_weapon_change", -10.0)
	it.queue_free()
	main.open_intel(doc, M, cur_room.ri)

func _open_terminal() -> void:
	var r := cur_room
	if r.q_queue.is_empty():
		var keys: Array = []
		for k in r.data.get("calls", []).size(): keys.append(Game.q_key(mi, r.ri, k))
		var n_rec := int(r.data.get("recall", 0))
		if n_rec == 0 and (mi > 0 or r.ri >= 2) and not keys.is_empty(): n_rec = 1
		var rec := Game.recall_items(n_rec, keys, mi if not M.get("final", false) else 6)
		r.q_queue = keys + rec.map(func(k): return "R:" + k)
	if r.q_queue.is_empty():
		_terminal_done(true); return
	main.open_terminal(r, r.q_queue, _terminal_done)

## called by the terminal UI. ok_all: every question answered correctly the first time this visit
func _terminal_done(ok_all: bool) -> void:
	var r := cur_room
	if not r.q_queue.is_empty():
		on_wrong_answer(); return
	if r.q_queue.is_empty():
		r.calls_done = true
		Audio.say_generic("g_bonus" if ok_all else "g_right_%d" % (randi() % 4))
		if ok_all and r.ri + 1 < rooms.size(): marked_t = 1.0
		r.mode.on_calls_done()

## wrong answer consequence: reinforcements burst in
func on_wrong_answer() -> void:
	var r := cur_room
	if r.kind in ["evidence", "range"]: return
	Audio.play2d("alarm", -8.0)
	var n := 2 + (1 if int(Game.settings["difficulty"]) >= 2 else 0)
	for i in n:
		var p := Vector3(randf_range(-2, 2), 0, r.z1 - 1.5 - i * 1.2)
		var e := spawn_enemy(r, p, "css", false, true)
		e.alert_delay = 0.0
	main.hud.toast("ALARM", "Wrong call  ·  reinforcements inbound", Color(1.0, 0.3, 0.25))

# ---------------------------------------------------------------- events
func on_kill(a: Humanoid, head := false, takedown := false, by_ally := false) -> void:
	if a.team == "ally": return
	if not by_ally:
		Game.stats["kills"] += 1
		if head: Game.stats["heads"] += 1
		if takedown: Game.stats["takedowns"] += 1
		Game.add_xp(100 if a.is_boss_actor() else (20 if takedown else (15 if head else 10)), "TAKEDOWN" if takedown else ("HEADSHOT" if head else "KILL"))
	for e in cur_room.alive_enemies():
		if (e.global_position - a.global_position).length() < 14.0 and randf() < 0.3: e.bark("mandown"); break
	cur_room.mode.on_kill(a)

func on_enemy_alert(e: Enemy) -> void:
	if e.room == null: return
	if e.room.kind == "stealth":
		cur_room.mode.on_detected()
	else:
		for o in e.room.alive_enemies():
			if o != e and (o.global_position - e.global_position).length() < 26.0: o.alert(false)

func noise(pos: Vector3, radius: float) -> void:
	for e in cur_room.alive_enemies():
		if e.state != "alert" and (e.global_position - pos).length() < radius:
			if cur_room.kind == "stealth":
				e.awareness = minf(1.0, e.awareness + 0.6); e.last_seen = pos
				if e.awareness >= 1.0: e.alert(true)
			else:
				e.alert(true)

func blast(p: Vector3, radius: float, dmg: float, from_enemy: bool) -> void:
	for r in rooms:
		if not r.visible: continue
		for e in r.alive_enemies():
			var d: float = (e.global_position - p).length()
			if d < radius:
				var was: bool = e.dead
				e.take_damage(dmg * (1.0 - d / radius) / (1.0 - e.armor * 0.5), "body", p)
				if e.dead and not was: on_kill(e, false)
	var pd := (player.global_position - p).length()
	if pd < radius * 0.85: player.take_hit(dmg * 0.45 * (1.0 - pd / (radius * 0.85)), p)
	for b in get_tree().get_nodes_in_group("barrels"):
		if is_instance_valid(b) and (b.global_position - p).length() < 3.5 and b.get_meta("hp", 0) > 0:
			get_tree().create_timer(0.15).timeout.connect(hit_barrel.bind(b, 9))
	noise(p, 40.0)

func hit_barrel(b: Node3D, dmg := 1) -> void:
	if not is_instance_valid(b): return
	var hp: int = b.get_meta("hp", 0) - dmg
	b.set_meta("hp", hp)
	if hp <= 0 and b.is_inside_tree():
		var p := b.global_position + Vector3(0, 0.6, 0)
		b.remove_from_group("barrels"); b.queue_free()
		Fx.explosion(p, true)
		blast(p, 6.0, 300.0, false)

func warn_grenade(g: Node3D) -> void:
	main.hud.grenade_warning(g)
	if ally and ally.visible and randf() < 0.7: Audio.bark("RUIZ", "six")
