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
		"chars":
			# cast line-up on the menu backdrop: idle, walking, a close-up row
			var bg := MenuBG.new(); main.world.add_child(bg)
			await _wait(0.5)
			var ids := ["kessler", "hale", "ally", "director:director_0", "director:director_1", "director:director_2", "director:director_3", "director:director_4", "director:voss", "courier", "civilian:civilian_a", "civilian:civilian_b", "civilian:civilian_c"]
			var root := Node3D.new(); main.world.add_child(root)
			var cam := Camera3D.new(); root.add_child(cam); cam.fov = 38
			var hs: Array = []
			for i in ids.size():
				var h := Humanoid.new(); h.team = "neutral"; root.add_child(h); h.setup(ids[i])
				h.set_physics_process(false)
				if h.variant in ["director", "civilian", "courier"]: h.hide_weapon()
				h.position = Vector3(-9.75 + i * 1.5, 0, -40.0); h.rotation.y = PI
				hs.append(h)
			var key := DirectionalLight3D.new(); root.add_child(key); key.rotation_degrees = Vector3(-35, 25, 0); key.light_energy = 1.4
			cam.current = true
			for pose in ["Idle", "Walk", "Sitting_Idle", "Idle_Talking"]:
				for h in hs: (h as Humanoid).forced_anim = ""; (h as Humanoid).play(pose if (h as Humanoid).weapon_hidden or pose != "Idle" else "soldier_idle")
				cam.position = Vector3(0, 1.3, -26.5); cam.look_at(Vector3(0, 0.95, -40.0))
				await _wait(1.3); await shot("chars_%s" % pose)
			for g in 4:
				cam.position = Vector3(-8.25 + g * 4.5, 1.6, -36.2); cam.look_at(Vector3(-8.25 + g * 4.5, 1.45, -40.0))
				for h in hs: (h as Humanoid).play("Idle")
				await _wait(0.8); await shot("chars_face%d" % g)
			root.queue_free(); bg.queue_free()
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
			for i in 8:
				await tree.process_frame
				print("[autotest] f", i, " ts=", Engine.time_scale, " paused=", tree.paused, " dt=", main.get_process_delta_time(), " mod=", main.screen.left.modulate.a)
			await _wait(2.5)
			print("[autotest] waited t=", Time.get_ticks_msec(), " left mod=", main.screen.left.modulate, " fade=", main.fade_rect.color)
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
			var tl := OmniLight3D.new(); tl.omni_range = 3.0; tl.light_energy = 1.2; mv.player.cam.add_child(tl); tl.position = Vector3(0.6, 0.4, 0.2)
			await _wait(1.0); await shot("vm_hip")
			Input.action_press("aim"); await _wait(0.25); await shot("vm_ads_mid"); await _wait(0.75); await shot("vm_ads"); Input.action_release("aim")
			await _wait(0.8)
			mv.player.ammo = 3; mv.player.start_reload()
			for ph in [0.3, 0.5, 0.75, 0.86]:
				while mv.player.reload_t > 0.0 and 1.0 - mv.player.reload_t / mv.player.reload_len < ph: await tree.process_frame
				var img := main.get_viewport().get_texture().get_image(); img.save_png("%s/vm_reload_%d.png" % [out, int(ph * 100)])
			await _wait(1.5)
			Input.action_press("fire"); await _wait(0.12); await shot("vm_fire"); Input.action_release("fire")
			await _wait(0.6)
			mv.player.cam.cull_mask = 2; mv.player.cam.fov = 40; await _wait(0.3); await shot("vm_only")
		"wrong":
			await _build(int(arg))
			var mw: Mission = main.mission
			for ri in mw.rooms.size():
				var rw: Room = mw.rooms[ri]
				if rw.kind in ["range", "evidence", "tail", "escape", "sniper"]: continue
				_teleport(mw, rw)
				await _wait(0.8)
				var before := rw.enemies.size()
				mw.on_wrong_answer()
				await _wait(0.3)
				var bad := 0
				for e in rw.enemies.slice(before):
					var ep: Vector3 = e.global_position
					if absf(ep.x) > rw.W * 0.5 or ep.z > rw.z0 or ep.z < rw.z1: bad += 1
				print("[autotest] wrong m%s r%d spawned=%d outside=%d" % [arg, ri, rw.enemies.size() - before, bad])
		"bp":
			var pb := arg.split("/")
			await _build(int(pb[0]))
			await _blueprints(int(pb[0]), pb.slice(1))
		"look":
			var parts2 := arg.split("/")
			await _build(int(parts2[0]))
			var ml: Mission = main.mission
			for rs in parts2.slice(1):
				var rr: Room = ml.rooms[int(rs)]
				_teleport(ml, rr)
				await _wait(1.5)
				await shot("look_m%s_r%s_%s" % [parts2[0], rs, rr.kind])
		"flow":
			main.show_menu(); await _wait(1.0)
			main.start_mission(int(arg)); await _wait(3.0)
			await shot("flow_brief")
			print("[autotest] flow state=", main.state)
			_key(KEY_ESCAPE); await _wait(2.0)
			print("[autotest] flow after esc state=", main.state)
			for i in 40:
				await _wait(1.0)
				if main.state == "cutscene": break
			await shot("flow_cut")
			print("[autotest] flow state=", main.state)
			_key(KEY_ESCAPE)
			for i in 20:
				await _wait(1.0)
				if main.state == "play": break
			await _wait(1.5)
			await shot("flow_play")
			print("[autotest] flow state=", main.state, " input=", main.mission.player.input_enabled, " cut_active=", main.mission.cut_active, " entered0=", main.mission.rooms[0].entered)
			_key(KEY_ESCAPE); await _wait(1.0)
			print("[autotest] flow paused state=", main.state, " tree paused=", tree.paused)
			await shot("flow_pause")
			_key(KEY_ESCAPE); await _wait(1.0)
			print("[autotest] flow resumed state=", main.state, " tree paused=", tree.paused)
		"board":
			main.clear_world()
			var cb := CaseBoard.new(); cb.main = main; cb.bi = int(arg); main.state = "board"; main.set_screen(cb)
			await _wait(1.5); await shot("board%s_a" % arg)
			var th: Array = cb.B["threads"]
			var wrong := ""
			for t in cb.B["concepts"].keys():
				if t != th[0]["a"]: wrong = t; break
			cb._try_link(0, wrong)
			cb._try_link(0, th[0]["a"]); cb._try_link(1, th[1]["a"])
			cb.selected_ev = 2
			await _wait(1.0); await shot("board%s_b" % arg)
			cb.selected_ev = -1
			for i in range(2, th.size()): cb._try_link(i, th[i]["a"])
			for kk in cb.tokens.size():
				cb._try_place(kk, cb._token_answer(cb.tokens[kk]["i"]))
			await _wait(1.0); await shot("board%s_c" % arg)
			cb._open_summary()
			await _wait(1.5); await shot("board%s_d" % arg)
			Audio.clear_dialogue()
		"boardflow":
			main.next_after(0); await _wait(3.0)
			print("[autotest] boardflow state=", main.state, " screen=", main.screen)
			(main.screen as CaseBoard)._close(); await _wait(3.0)
			print("[autotest] boardflow after close state=", main.state)
			Audio.clear_dialogue()
		"rifle":
			main.show_menu(); await _wait(1.0)
			var bgm: MenuBG = main.menu_bg
			if main.screen: main.screen.visible = false
			var extra := Humanoid.new(); extra.team = "neutral"; bgm.add_child(extra); extra.setup("css"); extra.set_physics_process(false)
			extra.position = Vector3(-0.6, 0, -0.6); extra.rotation.y = deg_to_rad(150); extra.play("soldier_forward")
			bgm.set_process(false)
			for ang in [0.0, 1.2, -1.2, 2.6]:
				bgm.cam.position = Vector3(0.2, 1.5, -1.0) + Vector3(sin(ang), 0, cos(ang)) * 2.6
				bgm.cam.look_at(Vector3(0.3, 1.1, -1.0))
				await _wait(0.6); await shot("rifle_%d" % int(ang * 10))
			# close-ups on the hands of the extra soldier, idle and walking
			for an in ["soldier_idle", "soldier_forward"]:
				extra.play_once(an, 0.0)
				for ang in [0.6, -0.9, 2.2]:
					var c: Vector3 = extra.global_position + Vector3(0, 1.25, 0)
					bgm.cam.position = c + Vector3(sin(ang + extra.rotation.y), 0.15, cos(ang + extra.rotation.y)) * 1.1
					bgm.cam.look_at(c)
					await _wait(0.4); await shot("hands_%s_%d" % [an, int(ang * 10)])
		"bot":
			await _bot(int(arg))
		"resume":
			main.start_mission(int(arg), 2)
			for i in 30:
				await _wait(1.0)
				if main.state == "play": break
			main.mission.player.global_position = Vector3(0, 0.1, main.mission.rooms[2].z0 - 2.0)
			await _wait(2.0)
			print("[autotest] resume state=", main.state, " cut_active=", main.mission.cut_active, " room2 entered=", main.mission.rooms[2].entered, " input=", main.mission.player.input_enabled)
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
	main.mission.cut_active = false
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
			if r.panels and not r.calls_done:
				_kill_all(mis, r)
				for q in 12:
					await _wait(0.2)
					var opts: Array = r.panels.interactables()
					if r.calls_done: break
					if opts.is_empty(): continue
					var right := (r.panels.order as Array).find(0)
					mis.player.global_position = Vector3(opts[right]["pos"].x, 0.1, opts[right]["pos"].z)
					(opts[right]["cb"] as Callable).call()
					await _wait(6.0)
			elif r.mode.uses_terminal() and r.terminal and not r.calls_done and r.mode.terminal_ready():
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


func _key(k: Key) -> void:
	var e := InputEventKey.new(); e.keycode = k; e.physical_keycode = k; e.pressed = true
	Input.parse_input_event(e)
	await tree.process_frame
	var e2 := InputEventKey.new(); e2.keycode = k; e2.physical_keycode = k; e2.pressed = false
	Input.parse_input_event(e2)


# ---------------------------------------------------------------- aiming bot: actually shoots its way through
func _aim_at(pl: Player, target: Vector3) -> void:
	var to := target - pl.cam.global_position
	pl.yaw = atan2(-to.x, -to.z)
	pl.pitch = atan2(to.y, Vector2(to.x, to.z).length())

func _bot(mi: int) -> void:
	await _build(mi)
	var mis: Mission = main.mission
	var pl := mis.player
	pl.input_enabled = true
	for r in mis.rooms.slice(0, 3):
		pl.global_position = Vector3(0, 0.1, r.z0 - 2.0)
		await _wait(0.5)
		var t0 := Time.get_ticks_msec()
		var shots0: int = Game.stats["shots"]
		var frames := 0
		while r.alive_enemies().size() > 0 and frames < 1500:
			frames += 1
			pl.hp = 100.0
			var best = null; var bd := 1e9
			for e in r.alive_enemies():
				var d: float = (e.global_position - pl.global_position).length()
				if d < bd: bd = d; best = e
			if best == null: break
			if bd > 14.0:
				pl.global_position = pl.global_position.move_toward(best.global_position, 0.25)
			_aim_at(pl, best.global_position + Vector3(0, 1.3 * best.scale.y, 0))
			Input.action_press("fire")
			await tree.physics_frame
			await tree.process_frame
		Input.action_release("fire")
		print("[autotest] bot room ", r.ri, " cleared=", r.alive_enemies().is_empty(), " frames=", frames, " shots=", int(Game.stats["shots"]) - shots0, " hits=", Game.stats["hits"], " kills=", Game.stats["kills"])
		await shot("bot%d_r%d" % [mi, r.ri])
		_kill_all(mis, r)
		for it in r.intel.duplicate():
			if is_instance_valid(it):
				mis._read_intel(it); await _resolve_overlay()
		if r.terminal and not r.calls_done:
			mis._open_terminal(); await _resolve_overlay()
		await _wait(0.5)
		if not r.done: r.mode.complete()

## Level-design review renders: overhead plan with gameplay overlay, cutaway 3/4 view, entry view.
func _blueprints(mi: int, rooms_s: Array) -> void:
	var ms: Mission = main.mission
	main.hud_layer.visible = false
	ms.player.visible = false
	if ms.ally: ms.ally.visible = false; ms.ally.process_mode = Node.PROCESS_MODE_DISABLED
	for rr in ms.rooms:
		for e in rr.enemies:
			if is_instance_valid(e): e.set_physics_process(false)
	ms.player.set_physics_process(false); ms.player.hp = 1e9
	var we: WorldEnvironment = null
	for n in ms.env.find_children("*", "WorldEnvironment", true, false): we = n
	var cam := Camera3D.new(); ms.add_child(cam)
	var sun := DirectionalLight3D.new(); ms.add_child(sun); sun.light_energy = 0.0
	var layer := CanvasLayer.new(); layer.layer = 50; main.add_child(layer)
	var bp := Blueprint.new(); layer.add_child(bp)
	bp.size = main.get_viewport().get_visible_rect().size
	for rs in rooms_s:
		var r: Room = ms.rooms[int(rs)]
		for o in ms.rooms: o.visible = o == r
		var ceil_nodes := r.get_tree().get_nodes_in_group("ceiling").filter(func(n): return r.is_ancestor_of(n))
		var vs := main.get_viewport().get_visible_rect().size
		for n in ceil_nodes: n.visible = false
		var fog_was := false
		if we: fog_was = we.environment.volumetric_fog_enabled; we.environment.volumetric_fog_enabled = false; we.environment.fog_enabled = false
		sun.light_energy = 0.9; sun.rotation = Vector3(-1.2, 0.4, 0)
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = maxf(r.D + 10.0, (r.W + 14.0) * vs.y / vs.x)
		cam.near = 0.5; cam.far = 200.0
		var c := r.center()
		cam.position = Vector3(c.x, r.H + 40.0 if not r.outdoor else 60.0, c.z)
		cam.look_at(c, Vector3(0, 0, -1))
		cam.current = true
		bp.cam = cam; bp.room = r
		bp.title = "M%d · SECTOR %d · %s   (%s, %dx%d m)%s" % [mi + 1, r.ri + 1, String(r.data.get("n", "")).to_upper(), r.kind, int(r.W), int(r.D), "   hand-built" if r.authored else "   procedural"]
		bp.visible = true; bp.queue_redraw()
		await _wait(0.6)
		await shot("bp_m%d_r%d_plan" % [mi, r.ri])
		bp.visible = false
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE; cam.fov = 50.0
		cam.position = Vector3(r.W * 0.75, r.H + 16.0, r.z0 + 10.0)
		cam.look_at(c + Vector3(0, 0, 2.0))
		sun.light_energy = 0.35
		await _wait(0.5)
		await shot("bp_m%d_r%d_cutaway" % [mi, r.ri])
		for n in ceil_nodes: n.visible = true
		if we: we.environment.volumetric_fog_enabled = fog_was; we.environment.fog_enabled = true
		sun.light_energy = 0.0
		cam.fov = 70.0
		cam.position = Vector3(0, 1.65, r.z0 - 1.0); cam.look_at(Vector3(0, 1.4, r.z0 - 12.0))
		await _wait(0.6)
		await shot("bp_m%d_r%d_entry" % [mi, r.ri])
		cam.position = Vector3(r.W * 0.3, 1.65, r.z1 + 2.0); cam.look_at(Vector3(-r.W * 0.1, 1.2, r.z0 - 4.0))
		await _wait(0.5)
		await shot("bp_m%d_r%d_back" % [mi, r.ri])
