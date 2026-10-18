extends Node
## Root controller: menus, briefing, loading, gameplay, overlays (terminal, intel, evidence), cutscenes,
## debrief, death and pause. Everything UI-side is built in code from UIKit.

var world: Node3D
var mission: Mission
var menu_bg: Node3D
var hud: HUD
var hud_layer: CanvasLayer
var ui_layer: CanvasLayer
var top_layer: CanvasLayer
var fade_rect: ColorRect
var bar_top: ColorRect
var bar_bot: ColorRect
var cine_sub: Label
var cine_who: Label
var state := "boot"
var overlay: Control = null
var screen: Control = null          # current full-screen UI (menu, briefing, debrief...)
var cut: Cutscene = null
var _completing := false
var _letterbox := 0.0
var _letterbox_t := 0.0
var _pending_complete := false
var _closed_frame := -10
var _autotest: Autotest

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	world = Node3D.new(); world.name = "World"; world.process_mode = Node.PROCESS_MODE_PAUSABLE; add_child(world)
	hud_layer = CanvasLayer.new(); hud_layer.layer = 5; hud_layer.process_mode = Node.PROCESS_MODE_PAUSABLE; add_child(hud_layer)
	hud = HUD.new(); hud.main = self; hud_layer.add_child(hud); hud_layer.visible = false
	ui_layer = CanvasLayer.new(); ui_layer.layer = 10; add_child(ui_layer)
	top_layer = CanvasLayer.new(); top_layer.layer = 20; add_child(top_layer)
	bar_top = ColorRect.new(); bar_top.color = Color.BLACK; bar_top.mouse_filter = Control.MOUSE_FILTER_IGNORE; top_layer.add_child(bar_top)
	bar_bot = ColorRect.new(); bar_bot.color = Color.BLACK; bar_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE; top_layer.add_child(bar_bot)
	var cv := UIKit.vbox(2); cv.name = "CineSub"; top_layer.add_child(cv)
	cine_who = UIKit.label("", UIKit.mono(15), UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER); cv.add_child(cine_who)
	cine_sub = UIKit.label("", UIKit.body(26), UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER); cine_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; cine_sub.custom_minimum_size = Vector2(1100, 0); cv.add_child(cine_sub)
	cine_sub.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9)); cine_sub.add_theme_constant_override("shadow_offset_y", 2)
	cv.visible = false
	fade_rect = ColorRect.new(); fade_rect.color = Color.BLACK; fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE; UIKit.full(fade_rect); top_layer.add_child(fade_rect)
	Audio.line_started.connect(_on_line)
	Audio.line_finished.connect(func(): cv.visible = false)
	get_viewport().size_changed.connect(_layout_bars)
	_layout_bars()
	if Game.autotest != "":
		_autotest = Autotest.new()
		_autotest.run(self)
		return
	_boot()

func _boot() -> void:
	# studio card, then the menu
	var c := Control.new(); UIKit.full(c); ui_layer.add_child(c)
	var bg := ColorRect.new(); bg.color = Color.BLACK; UIKit.full(bg); c.add_child(bg)
	var v := UIKit.vbox(6); c.add_child(v); v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var t := UIKit.label("LEDGER", UIKit.head(64), UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER); v.add_child(t)
	var s := UIKit.label("A JOINT TASK FORCE ON MARKET CRIME", UIKit.mono(14), UIKit.DIM, HORIZONTAL_ALIGNMENT_CENTER); v.add_child(s)
	v.add_child(UIKit.spacer(40))
	var w := UIKit.label("Headphones recommended", UIKit.body(18), UIKit.DIM, HORIZONTAL_ALIGNMENT_CENTER); v.add_child(w)
	v.reset_size(); v.position = -v.size * 0.5
	v.modulate.a = 0.0
	fade_rect.color.a = 0.0
	var tw := create_tween()
	tw.tween_property(v, "modulate:a", 1.0, 1.2)
	tw.tween_interval(1.6)
	tw.tween_property(v, "modulate:a", 0.0, 0.8)
	tw.tween_callback(func(): c.queue_free(); show_menu())

func _layout_bars() -> void:
	var vs := get_viewport().get_visible_rect().size
	var h := vs.y * 0.11 * _letterbox
	bar_top.position = Vector2(0, 0); bar_top.size = Vector2(vs.x, h)
	bar_bot.position = Vector2(0, vs.y - h); bar_bot.size = Vector2(vs.x, h + 1)
	var cv: Control = top_layer.get_node("CineSub")
	cv.reset_size(); cv.position = Vector2(vs.x * 0.5 - cv.size.x * 0.5, vs.y - maxf(h, 60.0) - cv.size.y - 18.0)

func letterbox(on: bool, secs := 0.8) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(v): _letterbox = v; _layout_bars(), _letterbox, 1.0 if on else 0.0, secs)

func fade(to: float, secs := 0.6) -> Tween:
	var tw := create_tween(); tw.tween_property(fade_rect, "color:a", to, secs)
	return tw

func _on_line(spk: String, text: String, _d: float) -> void:
	var cv: Control = top_layer.get_node("CineSub")
	if not (state in ["cutscene", "debrief"]) or not Game.settings["subtitles"]:
		cv.visible = false; return
	var sp := Game.speaker(spk)
	cine_who.text = String(sp.get("name", spk)).to_upper()
	cine_sub.text = text
	cv.visible = true
	_layout_bars()

func _process(_dt: float) -> void:
	if state == "play" and Input.is_action_just_pressed("pause") and overlay == null and Engine.get_process_frames() - _closed_frame > 2:
		pause_game()
	if state == "play" and overlay == null and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and DisplayServer.window_is_focused():
		if Input.is_action_just_pressed("fire"): Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "play" and overlay == null and Game.autotest == "":
		pause_game()

# ---------------------------------------------------------------- screens
func set_screen(c: Control) -> void:
	if screen and is_instance_valid(screen): screen.queue_free()
	screen = c
	if c: ui_layer.add_child(c)

func clear_world() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	if cut and is_instance_valid(cut): cut.abort()
	cut = null
	for c in world.get_children(): c.queue_free()
	mission = null; menu_bg = null
	Audio.clear_dialogue()
	hud_layer.visible = false
	if overlay and is_instance_valid(overlay): overlay.queue_free()
	overlay = null

func show_menu(page := "") -> void:
	clear_world()
	state = "menu"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu_bg = MenuBG.new(); world.add_child(menu_bg)
	var m := MenuUI.new(); m.main = self; set_screen(m)
	if page != "": m.call_deferred("open_page", page)
	Audio.music("tps_menu", 2.0, -3.0)
	Audio.ambience("rain_inside", -18.0)
	fade(0.0, 1.0)

func start_mission(mi: int, from_room := 0) -> void:
	Game.mission_index = mi
	Game.stats = Game.new_stats()
	if from_room <= 0:
		fade(1.0, 0.5).tween_callback(func():
			clear_world()
			state = "briefing"
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			var b := BriefingUI.new(); b.main = self; b.mi = mi; set_screen(b)
			fade(0.0, 0.6))
	else:
		_load_mission(mi, from_room)

## Called by the briefing when it ends (or is skipped).
func briefing_done(mi: int) -> void:
	_load_mission(mi, 0)

func _load_mission(mi: int, from_room: int) -> void:
	fade(1.0, 0.4).tween_callback(func():
		clear_world()
		state = "loading"
		var l := LoadingUI.new(); l.mi = mi; set_screen(l)
		fade(0.0, 0.3)
		await get_tree().create_timer(0.45).timeout
		await get_tree().process_frame
		await get_tree().process_frame
		_build_mission(mi, from_room)
		await get_tree().process_frame
		l.ready_to_go()
		await get_tree().create_timer(0.6 if Game.autotest == "" else 0.0).timeout
		fade(1.0, 0.4).tween_callback(func():
			set_screen(null)
			_begin_mission(from_room)))

func _build_mission(mi: int, from_room: int) -> void:
	_completing = false
	mission = Mission.new(); mission.name = "Mission"
	world.add_child(mission)
	if Game.stats.is_empty(): Game.stats = Game.new_stats()
	Game.stats["room"] = from_room
	mission.build(self, mi, from_room)
	hud.bind(mission)
	var cid: String = mission.M.get("intro_cut", "")
	mission.cut_active = from_room == 0 and cid != "" and Game.cuts.has(cid) and not Game.skip_cuts()

func _begin_mission(from_room: int) -> void:
	var cid: String = mission.M.get("intro_cut", "")
	if from_room == 0 and cid != "" and Game.cuts.has(cid) and not Game.skip_cuts():
		play_cut(cid, func(): _enter_play(true))
	else:
		_enter_play(true)

func _enter_play(fade_in: bool) -> void:
	state = "play"
	hud_layer.visible = true
	mission.player.input_enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if fade_in: fade(0.0, 0.8)

func play_cut(cid: String, done: Callable) -> void:
	state = "cutscene"
	hud_layer.visible = false
	if mission: mission.player.input_enabled = false
	cut = Cutscene.new(); world.add_child(cut)
	cut.play(self, mission, cid, func():
		cut = null
		done.call())

# ---------------------------------------------------------------- pause
func pause_game() -> void:
	if state != "play": return
	state = "paused"
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var p := PauseUI.new(); p.main = self; overlay = p; ui_layer.add_child(p)

func resume_game() -> void:
	_closed_frame = Engine.get_process_frames()
	if overlay and is_instance_valid(overlay): overlay.queue_free()
	overlay = null
	get_tree().paused = false
	state = "play"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func quit_to_menu() -> void:
	get_tree().paused = false
	fade(1.0, 0.5).tween_callback(func(): show_menu())

# ---------------------------------------------------------------- overlays used by the mission
func _open_overlay(o: Control) -> void:
	if overlay and is_instance_valid(overlay): overlay.queue_free()
	overlay = o
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.set_prompt("", false)
	ui_layer.add_child(o)

func close_overlay() -> void:
	_closed_frame = Engine.get_process_frames()
	if overlay and is_instance_valid(overlay): overlay.queue_free()
	overlay = null
	get_tree().paused = false
	if state == "play": Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func open_intel(doc: Dictionary, M: Dictionary, ri: int) -> void:
	var v := IntelView.new(); v.main = self; v.doc = doc; v.M = M; v.ri = ri
	_open_overlay(v)

func open_terminal(room: Room, queue: Array, cb: Callable) -> void:
	var t := TerminalUI.new(); t.main = self; t.room = room; t.queue = queue; t.cb = cb
	_open_overlay(t)

func open_question(q: Dictionary, cb: Callable) -> void:
	var t := TerminalUI.new(); t.main = self; t.single = q; t.cb = cb
	_open_overlay(t)

func open_evidence(ev: Dictionary, cb: Callable) -> void:
	var e := EvidenceUI.new(); e.main = self; e.ev = ev; e.cb = cb
	_open_overlay(e)

# ---------------------------------------------------------------- mission flow
func mission_complete_after_dialogue() -> void:
	if _pending_complete: return
	_pending_complete = true
	while Audio.busy():
		await get_tree().create_timer(0.3).timeout
	await get_tree().create_timer(1.2).timeout
	_pending_complete = false
	if mission and not _completing: mission_complete()

func mission_complete() -> void:
	if _completing or mission == null: return
	_completing = true
	mission.finished = true
	var mi := mission.mi
	Game.save["unlocked"] = maxi(int(Game.save["unlocked"]), mi + 1)
	Game.save["checkpoint"] = null
	var medal := Debrief.grade(Game.stats)
	var prev: int = int(Game.save["medals"].get(str(mi), -1))
	if medal > prev: Game.save["medals"][str(mi)] = medal
	Game.add_xp(500, "MISSION COMPLETE")
	Game.persist()
	var cid: String = mission.M.get("outro_cut", "")
	if cid != "" and Game.cuts.has(cid) and not Game.skip_cuts():
		hud.set_prompt("", false)
		play_cut(cid, func(): _show_debrief(mi))
	else:
		_show_debrief(mi)

func _show_debrief(mi: int) -> void:
	fade(1.0, 0.6).tween_callback(func():
		var stats := Game.stats.duplicate(true)
		clear_world()
		state = "debrief"
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var d := Debrief.new(); d.main = self; d.mi = mi; d.stats = stats; set_screen(d)
		fade(0.0, 0.8))

## Case board between missions (or replayed from the archive).
func open_case_board(bi: int, replay := false) -> void:
	fade(1.0, 0.5).tween_callback(func():
		clear_world()
		state = "board"
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var b := CaseBoard.new(); b.main = self; b.bi = bi; b.replay = replay; set_screen(b)
		var after := int(Game.content["boards"][bi]["after"])
		b.finished.connect(func():
			if replay: show_menu("archive")
			else: start_mission(after + 1))
		fade(0.0, 0.8))

## After a mission: its case board if there is one, else straight to the next briefing.
func next_after(mi: int) -> void:
	var bi := Game.board_after(mi)
	if bi >= 0: open_case_board(bi)
	else: start_mission(mi + 1)

func roll_credits() -> void:
	fade(1.0, 0.8).tween_callback(func():
		clear_world()
		state = "credits"
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		var c := CreditsRoll.new(); c.main = self; set_screen(c)
		fade(0.0, 1.5))

func player_died() -> void:
	if state != "play": return
	state = "dead"
	Game.stats["deaths"] = int(Game.stats.get("deaths", 0)) + 1
	Audio.clear_dialogue()
	Engine.time_scale = 0.3
	hud_layer.visible = false
	var tw := create_tween(); tw.set_ignore_time_scale(true)
	tw.tween_interval(1.4)
	tw.tween_callback(func():
		Engine.time_scale = 1.0
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var d := DeathUI.new(); d.main = self; overlay = d; ui_layer.add_child(d))

func restart_room() -> void:
	var mi := Game.mission_index
	var cp = Game.save.get("checkpoint")
	var ri := 0
	if cp != null and int(cp["m"]) == mi: ri = int(cp["r"])
	if mission and mission.cur_room: ri = mission.cur_room.ri
	var keep := Game.stats.duplicate(true)
	get_tree().paused = false
	if overlay and is_instance_valid(overlay): overlay.queue_free()
	overlay = null
	fade(1.0, 0.4).tween_callback(func():
		clear_world()
		Game.stats = keep
		state = "loading"
		await get_tree().process_frame
		_build_mission(mi, ri)
		await get_tree().process_frame
		_enter_play(true))

func fade_reset(cb: Callable) -> void:
	var tw := fade(1.0, 0.45)
	tw.tween_callback(cb)
	tw.tween_interval(0.25)
	tw.tween_property(fade_rect, "color:a", 0.0, 0.5)
