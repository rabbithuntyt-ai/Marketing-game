class_name Autotest
extends RefCounted
## Command-line test driver:  -- --autotest=<spec>[,<spec>...]   (screenshots go to user://shots)
##   menu | page:<name> | brief:<mi> | load:<mi> | rooms:<mi> | cut:<cid> | debrief:<mi> | terminal:<mi> | intel:<mi> | play:<mi>

var main: Node
var out := ""
var tree: SceneTree

func run(m: Node) -> void:
	main = m; tree = m.get_tree()
	out = OS.get_user_data_dir() + "/shots"
	DirAccess.make_dir_recursive_absolute(out)
	main.fade_rect.color.a = 0.0
	for spec in Game.autotest.split(","):
		print("[autotest] ", spec)
		await _do(spec)
	print("[autotest] done")
	tree.quit()

func _wait(s: float) -> void:
	await tree.create_timer(s, true, false, true).timeout
	for i in 3: await tree.process_frame

func shot(name: String) -> void:
	await tree.process_frame
	await tree.process_frame
	var img := main.get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out, name])
	print("[autotest] shot ", name)

func _do(spec: String) -> void:
	var p := spec.split(":")
	var k := p[0]
	var arg := p[1] if p.size() > 1 else ""
	match k:
		"noop":
			await _wait(1.0); await shot("noop")
		"bg":
			var bg := MenuBG.new(); main.world.add_child(bg)
			for i in 10:
				await tree.process_frame
				print("[autotest] frame ", Engine.get_process_frames(), " t=", Time.get_ticks_msec())
			await shot("bg")
		"menu":
			print("[autotest] t=", Time.get_ticks_msec())
			main.show_menu()
			print("[autotest] menu built t=", Time.get_ticks_msec())
			await _wait(2.5)
			print("[autotest] waited t=", Time.get_ticks_msec())
			await shot("menu")
		"page":
			main.show_menu(arg); await _wait(1.5); await shot("page_" + arg)
		"brief":
			main.clear_world(); main.state = "briefing"
			var b := BriefingUI.new(); b.main = main; b.mi = int(arg); main.set_screen(b)
			await _wait(4.5); await shot("brief%s_a" % arg)
			for i in 3:
				b._advance(); await _wait(1.2); await shot("brief%s_%d" % [arg, i])
			Audio.clear_dialogue()
		"load":
			main.clear_world()
			var l := LoadingUI.new(); l.mi = int(arg); main.set_screen(l)
			await _wait(0.5); await shot("loading%s" % arg)
		"rooms":
			await _build(int(arg))
			var mis: Mission = main.mission
			for r in mis.rooms:
				_teleport(mis, r)
				await _wait(1.2)
				await shot("m%s_r%d_%s" % [arg, r.ri, r.kind])
		"cut":
			var mi := int(arg.substr(1, 1)) - 1
			var from := 0
			await _build(mi, from)
			var c := Cutscene.new(); main.world.add_child(c); main.state = "cutscene"; main.hud_layer.visible = false
			var done := [false]
			c.play(main, main.mission, arg, func(): done[0] = true)
			await _wait(2.0); await shot("cut_%s_0" % arg)
			for i in 6:
				if done[0]: break
				Audio.skip_line(); await _wait(1.6); await shot("cut_%s_%d" % [arg, i + 1])
		"debrief":
			Game.stats = Game.new_stats(); Game.stats["missed"] = [Game.q_key(int(arg), 1, 0)]; Game.stats["q_seen"] = {"a": 1, "b": 1}; Game.stats["q_first_ok"] = 1
			main._show_debrief(int(arg)); await _wait(2.5); await shot("debrief%s" % arg)
		"terminal":
			await _build(int(arg))
			var mis2: Mission = main.mission
			var r1: Room = mis2.rooms[1]
			_teleport(mis2, r1)
			await _wait(0.5)
			var q: Array = []
			for i in r1.data.get("calls", []).size(): q.append(Game.q_key(int(arg), 1, i))
			q.append("R:" + Game.q_key(0, 2, 0))
			main.open_terminal(r1, q, func(_ok): pass)
			await _wait(0.8); await shot("terminal_a")
			main.overlay._pick(0); await _wait(0.5); await shot("terminal_b")
			main.close_overlay()
			var rs: Dictionary = {}
			for R in Game.missions:
				for rr in R["rooms"]:
					if rr.has("evidence"): rs = rr["evidence"]
			main.open_evidence(rs, func(): pass)
			await _wait(0.8); await shot("evidence")
			main.close_overlay()
			main.pause_game(); await _wait(0.8); await shot("pause")
			main.resume_game()
		"intel":
			await _build(int(arg))
			var mis3: Mission = main.mission
			var d: Dictionary = mis3.M["rooms"][1]["intel"][0]
			main.open_intel(d, mis3.M, 1); await _wait(0.8); await shot("intel%s" % arg)
			main.close_overlay(); Audio.clear_dialogue()
		"sim":
			await _sim(int(arg))
		"vm":
			await _build(int(arg))
			var mv: Mission = main.mission
			_teleport(mv, mv.rooms[1])
			mv.player.input_enabled = true
			await _wait(1.0); await shot("vm_hip")
			Input.action_press("aim"); await _wait(1.0); await shot("vm_ads"); Input.action_release("aim")
			await _wait(0.5)
		"look":
			var parts2 := arg.split("/")
			await _build(int(parts2[0]))
			var ml: Mission = main.mission
			for rs in parts2.slice(1):
				var rr: Room = ml.rooms[int(rs)]
				_teleport(ml, rr)
				await _wait(1.5)
				await shot("look_m%s_r%s_%s" % [parts2[0], rs, rr.kind])
		"combat":
			await _build(int(arg))
			var mc: Mission = main.mission
			var rc: Room = mc.rooms[1]
			mc.player.global_position = Vector3(0, 0.1, rc.z0 - 3.0)
			mc.player.input_enabled = false
			await _wait(0.5)
			for e in rc.alive_enemies(): e.alert(false)
			for i in 8:
				mc.player.hp = 100.0
				if i == 3:
					mc.player.fire()
				await _wait(0.7)
				await shot("combat%s_%d" % [arg, i])
			print("[autotest] combat alive=", rc.alive_enemies().size(), " player hp=", mc.player.hp)
		"play":
			await _build(int(arg))
			await _wait(3.0); await shot("play%s_a" % arg)
			await _wait(3.0); await shot("play%s_b" % arg)

func _build(mi: int, from := 0) -> void:
	main.clear_world()
	Game.stats = Game.new_stats()
	main.set_screen(null)
	main._build_mission(mi, from)
	main.state = "play"; main.hud_layer.visible = true
	main.mission.player.input_enabled = false
	await _wait(1.0)

func _teleport(mis: Mission, r: Room) -> void:
	mis.player.global_position = Vector3(0, 0.1, r.z0 - 3.0)
	mis.player.yaw = 0.0; mis.player.pitch = -0.05
	for e in r.enemies:
		if is_instance_valid(e): e.set_physics_process(false)


# ---------------------------------------------------------------- god-mode walkthrough
func _kill_all(mis: Mission, r: Room) -> void:
	for e in r.alive_enemies():
		if not e.dead:
			e.take_damage(999999, "head", mis.player.global_position)
			mis.on_kill(e, true)

func _resolve_overlay() -> void:
	for guard in 40:
		var o = main.overlay
		if o == null or not is_instance_valid(o): return
		if o is TerminalUI:
			if not o.answered:
				var idx: int = o.order.find(0)
				o._pick(idx)
			await tree.process_frame
			o._continue()
		elif o is EvidenceUI:
			if not o.answered: o._pick(o.order.find(0))
			await tree.process_frame
			o._continue()
		elif o is IntelView:
			o._close()
		else:
			main.close_overlay()
		await tree.process_frame

func _sim(mi: int) -> void:
	await _build(mi)
	var mis: Mission = main.mission
	mis.player.input_enabled = true
	var flog := []
	for r in mis.rooms:
		mis.player.hp = 100.0
		mis.player.global_position = Vector3(0, 0.1, r.z0 - 2.0); mis.player.yaw = 0.0
		await _wait(0.6)
		for step in 6:
			mis.player.hp = 100.0
			_kill_all(mis, r)
			await _wait(0.3)
			for it in r.intel.duplicate():
				if is_instance_valid(it):
					mis._read_intel(it); await _resolve_overlay()
			for it2 in r.mode.interactables():
				if it2.has("cb"):
					mis.player.global_position = Vector3(it2["pos"].x, 0.1, it2["pos"].z)
					(it2["cb"] as Callable).call()
					await _wait(0.3)
					await _resolve_overlay()
			if r.mode.uses_terminal() and r.terminal and not r.calls_done and r.mode.terminal_ready():
				_kill_all(mis, r)
				mis._open_terminal()
				await _resolve_overlay()
			await _wait(0.4)
			if r.done: break
		if not r.done:
			flog.append("%d:%s forced (calls_done=%s alive=%d intel=%d)" % [r.ri, r.kind, str(r.calls_done), r.alive_enemies().size(), r.intel.size()])
			r.mode.complete()
			if not r.done:
				r.done = true
				r.open_exit(true)
		await shot("sim%d_r%d_%s" % [mi, r.ri, r.kind])
	mis.player.global_position = Vector3(0, 0.1, mis.rooms[-1].cz1 + 2.5)
	await _wait(1.0)
	print("[autotest] sim ", mi, " forced: ", flog)
	print("[autotest] sim ", mi, " state=", main.state, " completing=", main._completing, " stats=", Game.stats)
