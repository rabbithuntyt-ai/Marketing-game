class_name HUD
extends Control
## In-game HUD. Built in code; driven by the mission, player and audio signals.

var main: Node
var accent := Color(1.0, 0.7, 0.3)
var obj_mission: Label
var obj_sector: Label
var obj_text: Label
var obj_box: VBoxContainer
var prompt_box: HBoxContainer
var prompt_lbl: Label
var prompt_key: Label
var sub_box: PanelContainer
var sub_who: Label
var sub_txt: Label
var toast_box: VBoxContainer
var toast_big: Label
var toast_small: Label
var toast_t := 0.0
var card: VBoxContainer
var card_t := 0.0
var cross: Control
var cross_lines: Array = []
var hitm: Control
var hitm_t := 0.0
var vignette: TextureRect
var blood := 0.0
var dmg_arrows: Array = []
var ammo_lbl: Label
var ammo_sub: Label
var nade_lbl: Label
var hp_bar: ColorRect
var hp_bg: ColorRect
var xp_feed: VBoxContainer
var rank_lbl: Label
var compass: Control
var marker: Control
var marker_lbl: Label
var marks := {}
var drill_box: PanelContainer
var drill_title: Label
var drill_sub: Label
var drill_chips: HBoxContainer
var focus_box: VBoxContainer
var focus_name: Label
var focus_hint: Label
var prog_box: VBoxContainer
var prog_lbl: Label
var prog_fill: ColorRect
var icpt_box: PanelContainer
var icpt_line: Label
var icpt_opts: VBoxContainer
var icpt_bar: ColorRect
var icpt_cb: Callable
var icpt_t := 0.0
var icpt_max := 12.0
var icpt_n := 0
var det_box: Control
var det_fill: ColorRect
var tail_box: VBoxContainer
var tail_lbl: Label
var tail_fill: ColorRect
var timer_lbl: Label
var boss_box: VBoxContainer
var boss_name: Label
var boss_fill: ColorRect
var scope: Control
var nade_warn: Control
var nade_ref = null
var player: Player
var mission: Mission

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	Audio.line_started.connect(_on_line)
	Audio.line_finished.connect(func(): sub_box.visible = false)
	Game.xp_changed.connect(_on_xp)

func bind(m: Mission) -> void:
	mission = m; player = m.player; accent = Color(m.M["color"])
	m.objective_changed.connect(func(t): obj_text.text = t; _flash_obj())
	player.hurt.connect(_on_hurt)
	player.hit_marker.connect(hitmarker)
	obj_mission.text = ("FINAL MISSION" if m.M.get("final", false) else "MISSION %d" % (m.mi + 1)) + "  ·  " + m.M["code"]
	obj_mission.add_theme_color_override("font_color", accent)
	for c in [drill_box, prog_box, icpt_box, det_box, tail_box, boss_box, focus_box]: c.visible = false
	timer_lbl.visible = false
	marks.clear()

func _lbl(text: String, f: Dictionary, col := UIKit.TEXT, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := UIKit.label(text, f, col, align)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75)); l.add_theme_constant_override("shadow_offset_x", 1); l.add_theme_constant_override("shadow_offset_y", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _build() -> void:
	# damage vignette
	vignette = TextureRect.new(); UIKit.full(vignette); vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g := Gradient.new(); g.set_color(0, Color(0.5, 0, 0, 0)); g.add_point(0.55, Color(0.45, 0, 0, 0.0)); g.set_color(g.get_point_count() - 1, Color(0.55, 0.02, 0.02, 0.95))
	var gt := GradientTexture2D.new(); gt.gradient = g; gt.fill = GradientTexture2D.FILL_RADIAL; gt.fill_from = Vector2(0.5, 0.5); gt.fill_to = Vector2(1.0, 1.0); gt.width = 256; gt.height = 256
	vignette.texture = gt; vignette.stretch_mode = TextureRect.STRETCH_SCALE; vignette.modulate.a = 0.0; add_child(vignette)
	# scope overlay
	scope = Control.new(); UIKit.full(scope); scope.mouse_filter = Control.MOUSE_FILTER_IGNORE; scope.visible = false; add_child(scope)
	scope.draw.connect(_draw_scope)
	# objective block (top-left)
	obj_box = UIKit.vbox(2); obj_box.position = Vector2(42, 34); add_child(obj_box)
	obj_mission = _lbl("", UIKit.mono(15), accent); obj_box.add_child(obj_mission)
	obj_sector = _lbl("", UIKit.body(18), UIKit.DIM); obj_box.add_child(obj_sector)
	var orow := UIKit.hbox(10); obj_box.add_child(orow)
	var bar := ColorRect.new(); bar.color = accent; bar.custom_minimum_size = Vector2(4, 30); orow.add_child(bar); bar.name = "Bar"
	obj_text = _lbl("", UIKit.head(30)); orow.add_child(obj_text)
	# compass (top-centre)
	compass = Control.new(); compass.custom_minimum_size = Vector2(560, 40); compass.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(compass)
	compass.draw.connect(_draw_compass)
	# waypoint marker
	marker = Control.new(); marker.mouse_filter = Control.MOUSE_FILTER_IGNORE; marker.size = Vector2(40, 40); add_child(marker); marker.draw.connect(_draw_marker)
	marker_lbl = _lbl("", UIKit.mono(14), Color(1, 1, 1, 0.9), HORIZONTAL_ALIGNMENT_CENTER); add_child(marker_lbl); marker_lbl.custom_minimum_size = Vector2(80, 0)
	# crosshair
	cross = Control.new(); cross.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(cross); cross.draw.connect(_draw_cross)
	hitm = Control.new(); hitm.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(hitm); hitm.draw.connect(_draw_hitm)
	# damage direction arrows
	for i in 4:
		var a := Control.new(); a.mouse_filter = Control.MOUSE_FILTER_IGNORE; a.set_meta("t", 0.0); a.set_meta("ang", 0.0); add_child(a); a.draw.connect(_draw_arrow.bind(a)); dmg_arrows.append(a)
	# grenade warning
	nade_warn = Control.new(); nade_warn.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(nade_warn); nade_warn.draw.connect(_draw_nade)
	# subtitles
	sub_box = PanelContainer.new(); sub_box.visible = false; add_child(sub_box)
	var ss := StyleBoxFlat.new(); ss.bg_color = Color(0, 0, 0, 0.55); ss.content_margin_left = 20; ss.content_margin_right = 20; ss.content_margin_top = 10; ss.content_margin_bottom = 12; ss.set_corner_radius_all(3)
	sub_box.add_theme_stylebox_override("panel", ss)
	var sv := UIKit.vbox(2); sub_box.add_child(sv)
	sub_who = _lbl("", UIKit.mono(15), accent, HORIZONTAL_ALIGNMENT_CENTER); sv.add_child(sub_who)
	sub_txt = _lbl("", UIKit.body(25), UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER); sub_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; sub_txt.custom_minimum_size = Vector2(900, 0); sv.add_child(sub_txt)
	# interaction prompt
	prompt_box = UIKit.hbox(10); prompt_box.visible = false; add_child(prompt_box)
	prompt_key = UIKit.kbd("E"); prompt_box.add_child(prompt_key)
	prompt_lbl = _lbl("", UIKit.body(22)); prompt_box.add_child(prompt_lbl)
	# toast
	toast_box = UIKit.vbox(0); toast_box.modulate.a = 0.0; add_child(toast_box)
	toast_big = _lbl("", UIKit.head(46), UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER); toast_box.add_child(toast_big)
	toast_small = _lbl("", UIKit.body(20), UIKit.DIM, HORIZONTAL_ALIGNMENT_CENTER); toast_small.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; toast_small.custom_minimum_size = Vector2(760, 0); toast_box.add_child(toast_small)
	# sector card
	card = UIKit.vbox(0); card.modulate.a = 0.0; add_child(card)
	# ammo + health (bottom-right / bottom-left)
	var ab := UIKit.vbox(0); ab.name = "Ammo"; add_child(ab)
	ammo_lbl = _lbl("30", UIKit.head(64), UIKit.TEXT, HORIZONTAL_ALIGNMENT_RIGHT); ab.add_child(ammo_lbl)
	ammo_sub = _lbl("CR-21 · ∞", UIKit.mono(14), UIKit.DIM, HORIZONTAL_ALIGNMENT_RIGHT); ab.add_child(ammo_sub)
	nade_lbl = _lbl("◆◆◆  [G]", UIKit.mono(15), UIKit.DIM, HORIZONTAL_ALIGNMENT_RIGHT); ab.add_child(nade_lbl)
	var hb := UIKit.vbox(6); hb.name = "Health"; add_child(hb)
	rank_lbl = _lbl("", UIKit.mono(14), UIKit.DIM); hb.add_child(rank_lbl)
	var hbg := Control.new(); hbg.custom_minimum_size = Vector2(260, 6); hb.add_child(hbg)
	hp_bg = ColorRect.new(); hp_bg.color = Color(1, 1, 1, 0.15); hp_bg.size = Vector2(260, 6); hbg.add_child(hp_bg)
	hp_bar = ColorRect.new(); hp_bar.color = UIKit.TEXT; hp_bar.size = Vector2(260, 6); hbg.add_child(hp_bar)
	# xp feed (right)
	xp_feed = UIKit.vbox(2); add_child(xp_feed)
	# drill panel
	drill_box = UIKit.panel(UIKit.BG, accent); add_child(drill_box)
	var dv := UIKit.vbox(4); drill_box.add_child(dv)
	dv.add_child(_lbl("TRAINING RANGE", UIKit.mono(14), UIKit.DIM))
	drill_title = _lbl("", UIKit.head(32)); dv.add_child(drill_title)
	drill_sub = _lbl("", UIKit.body(18), UIKit.DIM); dv.add_child(drill_sub)
	drill_chips = UIKit.hbox(6); dv.add_child(drill_chips)
	# HVT focus label
	focus_box = UIKit.vbox(0); add_child(focus_box)
	focus_name = _lbl("", UIKit.head(28), UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER); focus_box.add_child(focus_name)
	focus_hint = _lbl("", UIKit.mono(15), accent, HORIZONTAL_ALIGNMENT_CENTER); focus_box.add_child(focus_hint)
	# progress (uplink / Ruiz health)
	prog_box = UIKit.vbox(4); add_child(prog_box)
	prog_lbl = _lbl("", UIKit.mono(15), UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER); prog_box.add_child(prog_lbl)
	var pbg := ColorRect.new(); pbg.color = Color(1, 1, 1, 0.15); pbg.custom_minimum_size = Vector2(420, 8); prog_box.add_child(pbg)
	prog_fill = ColorRect.new(); prog_fill.color = accent; prog_fill.size = Vector2(0, 8); pbg.add_child(prog_fill)
	# intercept panel
	icpt_box = UIKit.panel(Color(0.03, 0.04, 0.05, 0.9), Color(0.4, 0.9, 1.0)); add_child(icpt_box)
	var iv := UIKit.vbox(6); icpt_box.add_child(iv)
	iv.add_child(_lbl("INTERCEPT  ·  CALL IT  [1] [2] [3]", UIKit.mono(14), Color(0.4, 0.9, 1.0)))
	icpt_line = _lbl("", UIKit.body(21)); icpt_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; icpt_line.custom_minimum_size = Vector2(560, 0); iv.add_child(icpt_line)
	icpt_opts = UIKit.vbox(2); iv.add_child(icpt_opts)
	var ibg := ColorRect.new(); ibg.color = Color(1, 1, 1, 0.1); ibg.custom_minimum_size = Vector2(560, 3); iv.add_child(ibg)
	icpt_bar = ColorRect.new(); icpt_bar.color = Color(0.4, 0.9, 1.0); icpt_bar.size = Vector2(560, 3); ibg.add_child(icpt_bar)
	# stealth detection
	det_box = Control.new(); det_box.custom_minimum_size = Vector2(120, 8); add_child(det_box)
	var dbg := ColorRect.new(); dbg.color = Color(1, 1, 1, 0.12); dbg.size = Vector2(120, 6); det_box.add_child(dbg)
	det_fill = ColorRect.new(); det_fill.color = Color(1, 0.8, 0.3); det_fill.size = Vector2(0, 6); det_box.add_child(det_fill)
	# tail status
	tail_box = UIKit.vbox(3); add_child(tail_box)
	tail_lbl = _lbl("", UIKit.mono(14), UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER); tail_box.add_child(tail_lbl)
	var tbg := ColorRect.new(); tbg.color = Color(1, 1, 1, 0.12); tbg.custom_minimum_size = Vector2(220, 4); tail_box.add_child(tbg)
	tail_fill = ColorRect.new(); tail_fill.color = Color(1, 0.5, 0.3); tail_fill.size = Vector2(0, 4); tbg.add_child(tail_fill)
	# timer
	timer_lbl = _lbl("", UIKit.head(44), UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER); add_child(timer_lbl)
	# boss
	boss_box = UIKit.vbox(4); add_child(boss_box)
	boss_name = _lbl("", UIKit.head(26), UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER); boss_box.add_child(boss_name)
	var bbg := ColorRect.new(); bbg.color = Color(1, 1, 1, 0.12); bbg.custom_minimum_size = Vector2(520, 6); boss_box.add_child(bbg)
	boss_fill = ColorRect.new(); boss_fill.color = UIKit.RED; boss_fill.size = Vector2(520, 6); bbg.add_child(boss_fill)

func _layout() -> void:
	var vs := get_viewport_rect().size
	var sc: float = Game.settings.get("hud_scale", 1.0)
	compass.position = Vector2(vs.x * 0.5 - 280, 22)
	sub_box.size = Vector2.ZERO; sub_box.reset_size()
	sub_box.position = Vector2(vs.x * 0.5 - sub_box.size.x * 0.5, vs.y - 150 - sub_box.size.y * 0.5)
	prompt_box.reset_size(); prompt_box.position = Vector2(vs.x * 0.5 - prompt_box.size.x * 0.5, vs.y * 0.66)
	toast_box.reset_size(); toast_box.position = Vector2(vs.x * 0.5 - toast_box.size.x * 0.5, vs.y * 0.24)
	card.reset_size(); card.position = Vector2(vs.x * 0.5 - card.size.x * 0.5, vs.y * 0.34)
	var ab: Control = get_node("Ammo"); ab.reset_size(); ab.position = Vector2(vs.x - ab.size.x - 46, vs.y - ab.size.y - 34)
	var hb: Control = get_node("Health"); hb.position = Vector2(46, vs.y - 64)
	xp_feed.position = Vector2(vs.x - 300, vs.y * 0.42)
	drill_box.reset_size(); drill_box.position = Vector2(vs.x - drill_box.size.x - 40, 120)
	focus_box.reset_size(); focus_box.position = Vector2(vs.x * 0.5 - focus_box.size.x * 0.5, vs.y * 0.5 + 40)
	prog_box.reset_size(); prog_box.position = Vector2(vs.x * 0.5 - 210, 76)
	icpt_box.reset_size(); icpt_box.position = Vector2(42, vs.y * 0.5 - icpt_box.size.y * 0.5)
	det_box.position = Vector2(vs.x * 0.5 - 60, vs.y * 0.5 - 60)
	tail_box.reset_size(); tail_box.position = Vector2(vs.x * 0.5 - 110, 76)
	timer_lbl.reset_size(); timer_lbl.position = Vector2(vs.x * 0.5 - timer_lbl.size.x * 0.5, 70)
	boss_box.reset_size(); boss_box.position = Vector2(vs.x * 0.5 - 260, 78)
	cross.position = vs * 0.5; hitm.position = vs * 0.5; nade_warn.position = vs * 0.5
	for a in dmg_arrows: a.position = vs * 0.5
	scale = Vector2.ONE * sc

func _process(dt: float) -> void:
	_layout()
	if mission == null or player == null: return
	_tick_tips(dt)
	# toasts / card
	toast_t -= dt; toast_box.modulate.a = clampf(toast_t / 0.4, 0.0, 1.0)
	card_t -= dt; card.modulate.a = clampf(card_t / 0.6, 0.0, 1.0) * clampf((3.6 - card_t) / 0.4 + 0.0, 0.0, 1.0)
	# health
	hp_bar.size.x = 260.0 * clampf(player.hp / 100.0, 0, 1); hp_bar.color = UIKit.RED if player.hp < 35 else UIKit.TEXT
	blood = maxf(0.0, blood - dt * 1.6)
	vignette.modulate.a = clampf((1.0 - player.hp / 100.0) * 0.95 + blood * 0.4, 0.0, 1.0)
	# ammo
	ammo_lbl.text = "··" if player.reload_t > 0.0 else str(player.ammo)
	ammo_lbl.add_theme_color_override("font_color", UIKit.RED if player.ammo <= 5 and player.reload_t <= 0 else UIKit.TEXT)
	ammo_sub.text = ("K-98 MARKSMAN" if player.sniper else ("CR-21 · SUPPRESSED" if player.suppressed else "CR-21 CARBINE")) + "  ·  ∞"
	nade_lbl.text = "◆".repeat(player.nades) + "◇".repeat(maxi(0, 3 - player.nades)) + "  [G]"
	rank_lbl.text = "%s  ·  %d XP" % [Game.rank_of(int(Game.save["xp"]))[1].to_upper(), int(Game.save["xp"])]
	if mission.cur_room: obj_sector.text = "Sector %d/%d  ·  %s" % [mission.cur_room.ri + 1, mission.rooms.size(), mission.cur_room.data["n"]]
	# scope / crosshair
	scope.visible = player.ads > 0.85
	cross.visible = not scope.visible and player.ads < 0.6 and not player.sprint
	cross.queue_redraw(); scope.queue_redraw(); compass.queue_redraw(); marker.queue_redraw(); nade_warn.queue_redraw()
	hitm_t -= dt; hitm.queue_redraw()
	for a in dmg_arrows:
		a.set_meta("t", maxf(0.0, a.get_meta("t") - dt)); a.queue_redraw()
	# intercept timer
	if icpt_box.visible:
		icpt_t -= dt
		icpt_bar.size.x = 560.0 * clampf(icpt_t / icpt_max, 0, 1)
		for i in 3:
			if Input.is_action_just_pressed("answer_%d" % (i + 1)) and i < icpt_n: _icpt_pick(i)
		if icpt_t <= 0.0: _icpt_pick(-1)
	# enemy marks
	for e in marks.keys():
		marks[e] -= dt
		if marks[e] <= 0.0 or not is_instance_valid(e) or e.dead: marks.erase(e)
	queue_redraw()

func _draw() -> void:
	if mission == null or player == null: return
	var cam := player.cam
	for e in marks.keys():
		if not is_instance_valid(e): continue
		var p: Vector3 = e.global_position + Vector3(0, 2.2, 0)
		if cam.is_position_behind(p): continue
		var sp := cam.unproject_position(p)
		var c := Color(1, 0.3, 0.25, 0.9)
		draw_colored_polygon(PackedVector2Array([sp + Vector2(0, -7), sp + Vector2(6, 0), sp + Vector2(0, 7), sp + Vector2(-6, 0)]), c)

func _draw_compass() -> void:
	if player == null: return
	var w := 560.0; var yaw := -player.yaw
	compass.draw_rect(Rect2(0, 18, w, 1), Color(1, 1, 1, 0.25))
	var dirs := {"N": 0.0, "E": PI * 0.5, "S": PI, "W": -PI * 0.5}
	var f := UIKit.font("Rajdhani-Bold")
	for k in 72:
		var a := k * TAU / 72.0
		var d := wrapf(a - yaw, -PI, PI)
		if absf(d) > PI * 0.42: continue
		var x := w * 0.5 + d / (PI * 0.42) * w * 0.5
		var big := k % 18 == 0
		compass.draw_line(Vector2(x, 18 - (6 if big else 3)), Vector2(x, 18), Color(1, 1, 1, 0.5 if big else 0.25), 1.0)
	for n in dirs.keys():
		var d2 := wrapf(dirs[n] - yaw, -PI, PI)
		if absf(d2) > PI * 0.42: continue
		var x2 := w * 0.5 + d2 / (PI * 0.42) * w * 0.5
		compass.draw_string(f, Vector2(x2 - 6, 40), n, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.7))
	var wp = mission.waypoint()
	if wp != null:
		var to: Vector3 = wp - player.global_position
		var a3 := atan2(to.x, -to.z)
		var d3 := wrapf(a3 - yaw, -PI, PI)
		var x3 := w * 0.5 + clampf(d3 / (PI * 0.42), -1, 1) * w * 0.5
		compass.draw_colored_polygon(PackedVector2Array([Vector2(x3, 6), Vector2(x3 + 6, 12), Vector2(x3, 18), Vector2(x3 - 6, 12)]), accent)

func _draw_marker() -> void:
	marker_lbl.visible = false
	if mission == null or player == null: return
	var wp = mission.waypoint()
	if wp == null: return
	var cam := player.cam
	var p: Vector3 = wp + Vector3(0, 1.4, 0)
	var vs := get_viewport_rect().size
	var sp: Vector2
	if cam.is_position_behind(p): return
	sp = cam.unproject_position(p)
	sp.x = clampf(sp.x, 40, vs.x - 40); sp.y = clampf(sp.y, 60, vs.y - 120)
	marker.position = sp - Vector2(20, 20)
	var dist: float = (wp - player.global_position).length()
	if dist < 3.0: return
	var a := clampf((dist - 3.0) / 4.0, 0.0, 1.0) * 0.9
	var c := Color(accent.r, accent.g, accent.b, a)
	marker.draw_colored_polygon(PackedVector2Array([Vector2(20, 8), Vector2(30, 20), Vector2(20, 32), Vector2(10, 20)]), c)
	marker.draw_polyline(PackedVector2Array([Vector2(20, 4), Vector2(34, 20), Vector2(20, 36), Vector2(6, 20), Vector2(20, 4)]), Color(1, 1, 1, a * 0.6), 1.0)
	marker_lbl.visible = true; marker_lbl.text = "%dm" % int(dist); marker_lbl.position = sp + Vector2(-40, 18); marker_lbl.modulate.a = a

func _draw_cross() -> void:
	if player == null: return
	var g := 6.0 + player.spread() * 420.0
	var c := Color(1, 1, 1, 0.85)
	for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		cross.draw_line(d * g, d * (g + 9), Color(0, 0, 0, 0.5), 3.0)
		cross.draw_line(d * g, d * (g + 9), c, 1.6)
	cross.draw_circle(Vector2.ZERO, 1.2, c)

var _hit_kill := false
var _hit_head := false
func hitmarker(kill: bool, head: bool) -> void:
	hitm_t = 0.22 if kill else 0.12; _hit_kill = kill; _hit_head = head
	Audio.play2d("kenney_weapon_change", -18.0 if not kill else -12.0, 0.2, "UI")

func _draw_hitm() -> void:
	if hitm_t <= 0.0: return
	var c := UIKit.RED if _hit_kill else Color(1, 1, 1)
	if _hit_head and _hit_kill: c = Color(1, 0.75, 0.3)
	var s := 9.0 if not _hit_kill else 12.0
	for d in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		hitm.draw_line(d * 5.0, d * s, c, 2.2)

func _on_hurt(amount: float, from: Vector3) -> void:
	blood = minf(1.0, blood + amount / 30.0)
	for a in dmg_arrows:
		if a.get_meta("t") <= 0.0:
			var to := from - player.global_position
			a.set_meta("ang", atan2(to.x, -to.z) + player.yaw); a.set_meta("t", 1.2); break

func _draw_arrow(a: Control) -> void:
	var t: float = a.get_meta("t")
	if t <= 0.0: return
	var ang: float = a.get_meta("ang")
	var dir := Vector2(sin(ang), -cos(ang)); var perp := Vector2(-dir.y, dir.x)
	var r := 140.0
	var pts := PackedVector2Array([dir * (r + 26), dir * r + perp * 22, dir * (r + 8), dir * r - perp * 22])
	a.draw_colored_polygon(pts, Color(1, 0.15, 0.1, clampf(t, 0, 1) * 0.8))

func grenade_warning(g: Node3D) -> void:
	nade_ref = g

func _draw_nade() -> void:
	if nade_ref == null or not is_instance_valid(nade_ref) or player == null: return
	var to: Vector3 = nade_ref.global_position - player.global_position
	if to.length() > 9.0: return
	var ang := atan2(to.x, -to.z) + player.yaw
	var dir := Vector2(sin(ang), -cos(ang)) * 110.0
	nade_warn.draw_circle(dir, 16, Color(0, 0, 0, 0.5))
	nade_warn.draw_string(UIKit.font("Rajdhani-Bold"), dir + Vector2(-6, 8), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, UIKit.RED)

func _draw_scope() -> void:
	if player and not player.sniper:
		_draw_optic(); return
	var vs := get_viewport_rect().size
	var c := vs * 0.5; var r := vs.y * 0.46
	var black := Color(0, 0, 0, 1)
	scope.draw_rect(Rect2(0, 0, c.x - r, vs.y), black); scope.draw_rect(Rect2(c.x + r, 0, vs.x - c.x - r, vs.y), black)
	var pts := PackedVector2Array()
	for i in 65: pts.append(c + Vector2(cos(i * TAU / 64.0), sin(i * TAU / 64.0)) * r)
	for i in 64:
		var a1 := c + Vector2(cos(i * TAU / 64.0), sin(i * TAU / 64.0)) * r
		var a2 := c + Vector2(cos((i + 1) * TAU / 64.0), sin((i + 1) * TAU / 64.0)) * r
		var b1 := c + Vector2(cos(i * TAU / 64.0), sin(i * TAU / 64.0)) * (r * 1.6)
		var b2 := c + Vector2(cos((i + 1) * TAU / 64.0), sin((i + 1) * TAU / 64.0)) * (r * 1.6)
		scope.draw_colored_polygon(PackedVector2Array([a1, a2, b2, b1]), black)
	scope.draw_polyline(pts, Color(0, 0, 0, 0.9), 6.0)
	scope.draw_line(c - Vector2(r, 0), c - Vector2(14, 0), Color(0, 0, 0, 0.9), 2.0); scope.draw_line(c + Vector2(14, 0), c + Vector2(r, 0), Color(0, 0, 0, 0.9), 2.0)
	scope.draw_line(c - Vector2(0, r), c - Vector2(0, 14), Color(0, 0, 0, 0.9), 2.0); scope.draw_line(c + Vector2(0, 14), c + Vector2(0, r), Color(0, 0, 0, 0.9), 2.0)
	for k in range(1, 5): scope.draw_line(c + Vector2(-6, k * 22), c + Vector2(6, k * 22), Color(0, 0, 0, 0.9), 1.5)
	scope.draw_circle(c, 1.6, Color(1, 0.2, 0.15))

# ---------------------------------------------------------------- tips
var tip_box: PanelContainer
var _tips: Array = []
var _tip_t := 0.0

## Queue a control hint: [[keys, text], ...] shown one after another in the lower left.
func tips(list: Array) -> void:
	_tips.append_array(list)
	if _tip_t <= 0.0: _next_tip()

func _next_tip() -> void:
	if tip_box and is_instance_valid(tip_box): tip_box.queue_free()
	if _tips.is_empty(): _tip_t = 0.0; return
	var t: Array = _tips.pop_front()
	tip_box = UIKit.panel(Color(0, 0, 0, 0.55), accent); add_child(tip_box)
	var h := UIKit.hbox(12); tip_box.add_child(h)
	for k in String(t[0]).split(" "): h.add_child(UIKit.kbd(k))
	h.add_child(_lbl(String(t[1]), UIKit.body(20)))
	tip_box.modulate.a = 0.0; create_tween().tween_property(tip_box, "modulate:a", 1.0, 0.3)
	_tip_t = 5.0

func _tick_tips(dt: float) -> void:
	if _tip_t > 0.0:
		_tip_t -= dt
		if tip_box and is_instance_valid(tip_box):
			var vs := get_viewport_rect().size
			tip_box.reset_size(); tip_box.position = Vector2(46, vs.y - 150 - tip_box.size.y)
		if _tip_t <= 0.0: _next_tip()

## Carbine optic: 4x prism sight, soft tube vignette, illuminated chevron.
func _draw_optic() -> void:
	var vs := get_viewport_rect().size
	var c := vs * 0.5; var r := vs.y * 0.43
	var black := Color(0, 0, 0, 1)
	scope.draw_rect(Rect2(0, 0, c.x - r, vs.y), black); scope.draw_rect(Rect2(c.x + r, 0, vs.x - c.x - r, vs.y), black)
	for i in 64:
		var a1 := i * TAU / 64.0; var a2 := (i + 1) * TAU / 64.0
		for ring in [[1.0, 1.7, 1.0], [0.9, 1.0, 0.55], [0.82, 0.9, 0.25]]:
			var r0: float = r * float(ring[0]); var r1: float = r * float(ring[1])
			var p1: Vector2 = c + Vector2(cos(a1), sin(a1)) * r0; var p2: Vector2 = c + Vector2(cos(a2), sin(a2)) * r0
			var q1: Vector2 = c + Vector2(cos(a1), sin(a1)) * r1; var q2: Vector2 = c + Vector2(cos(a2), sin(a2)) * r1
			scope.draw_colored_polygon(PackedVector2Array([p1, p2, q2, q1]), Color(0, 0, 0, ring[2]))
	var red := Color(1.0, 0.25, 0.15)
	scope.draw_polyline(PackedVector2Array([c + Vector2(-9, 9), c, c + Vector2(9, 9)]), red, 2.5)
	scope.draw_line(c + Vector2(0, 14), c + Vector2(0, r * 0.55), Color(0, 0, 0, 0.85), 2.0)
	for k in range(1, 4): scope.draw_line(c + Vector2(-5 - k, 14 + k * 26), c + Vector2(5 + k, 14 + k * 26), Color(0, 0, 0, 0.8), 1.5)
	scope.draw_line(c - Vector2(r * 0.8, 0), c - Vector2(r * 0.25, 0), Color(0, 0, 0, 0.6), 1.5)
	scope.draw_line(c + Vector2(r * 0.25, 0), c + Vector2(r * 0.8, 0), Color(0, 0, 0, 0.6), 1.5)

# ---------------------------------------------------------------- API
func set_prompt(text: String, actionable: bool) -> void:
	prompt_box.visible = text != ""
	prompt_lbl.text = text; prompt_key.visible = actionable

func toast(big: String, small := "", col := UIKit.TEXT) -> void:
	toast_big.text = big; toast_small.text = small; toast_big.add_theme_color_override("font_color", col); toast_t = 2.8

func sector_card(i: int, n: int, name: String, col: String) -> void:
	for c in card.get_children(): c.queue_free()
	card.add_child(_lbl("SECTOR %d / %d" % [i, n], UIKit.mono(16), Color(col), HORIZONTAL_ALIGNMENT_CENTER))
	card.add_child(_lbl(name.to_upper(), UIKit.head(54), UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	card_t = 3.6

func mark_enemy(e, secs: float) -> void:
	marks[e] = secs

func _flash_obj() -> void:
	var b: ColorRect = obj_box.get_child(2).get_node("Bar")
	b.color = Color.WHITE; create_tween().tween_property(b, "color", accent, 0.8)
	Audio.play2d("kenney_weapon_change", -20.0, 0.0, "UI")

func _on_line(spk: String, text: String, _dur: float) -> void:
	if not Game.settings["subtitles"]: return
	var sp := Game.speaker(spk)
	sub_who.text = ("%s  ·  %s" % [sp.get("name", spk), sp.get("role", "")]).to_upper()
	var col := {"HALE": Color(1.0, 0.76, 0.24), "MARR": Color(0.5, 0.82, 1.0), "RUIZ": Color(0.6, 0.95, 0.55), "VOSS": Color(0.9, 0.9, 0.95), "KESSLER": Color(1.0, 0.4, 0.35)}.get(spk, Color(1.0, 0.45, 0.4) if spk.begins_with("CSS") else Color(0.85, 0.85, 0.85))
	sub_who.add_theme_color_override("font_color", col)
	sub_txt.text = text
	sub_txt.add_theme_font_size_override("font_size", [22, 25, 30][clampi(int(Game.settings["subtitle_size"]), 0, 2)])
	sub_box.visible = true

func _on_xp(total: int, delta: int, label: String) -> void:
	var l := _lbl("+%d  %s" % [delta, label], UIKit.mono(15), Color(1.0, 0.85, 0.45), HORIZONTAL_ALIGNMENT_RIGHT)
	xp_feed.add_child(l); l.custom_minimum_size = Vector2(260, 0)
	var tw := create_tween(); tw.tween_interval(1.3); tw.tween_property(l, "modulate:a", 0.0, 0.4); tw.tween_callback(l.queue_free)
	var before := Game.rank_of(total - delta); var after := Game.rank_of(total)
	if before != after:
		get_tree().create_timer(0.5).timeout.connect(func(): toast("PROMOTED", String(after[1]).to_upper(), UIKit.GOLD))

func drill_show(on: bool) -> void: drill_box.visible = on

func drill_set(title: String, sub: String, d: Dictionary, done_n: int) -> void:
	drill_box.visible = true
	drill_title.text = title
	if sub != "": drill_sub.text = sub
	for c in drill_chips.get_children(): c.queue_free()
	var items: Array = d["items"]
	for i in items.size():
		var shown := i < done_n
		var l := _lbl(items[i] if (shown or not d["ordered"]) and shown else ("?" if d["ordered"] else "·"), UIKit.mono(14), UIKit.GREEN if shown else UIKit.DIM)
		drill_chips.add_child(l)
	if not d["ordered"]:
		for c in drill_chips.get_children(): c.queue_free()
		drill_chips.add_child(_lbl("%d of %d found" % [done_n, items.size()], UIKit.mono(15), UIKit.GREEN))

func focus_label(n: String, hint: String) -> void:
	focus_box.visible = n != ""; focus_name.text = n; focus_hint.text = hint

func progress_show(on: bool, label: String) -> void:
	prog_box.visible = on; prog_lbl.text = label

func progress_set(f: float) -> void:
	prog_fill.size.x = 420.0 * clampf(f, 0, 1)
	prog_lbl.text = prog_lbl.text.split("  ")[0] + "  %d%%" % int(clampf(f, 0, 1) * 100)

func intercept_show(line: String, opts: Array, timeout: float, cb: Callable) -> void:
	icpt_box.visible = true; icpt_line.text = line; icpt_cb = cb; icpt_t = timeout; icpt_max = timeout; icpt_n = opts.size()
	for c in icpt_opts.get_children(): c.queue_free()
	for i in opts.size():
		var row := UIKit.hbox(10); row.add_child(UIKit.kbd(str(i + 1))); row.add_child(_lbl(opts[i], UIKit.body(20))); icpt_opts.add_child(row)
	Audio.play2d("kenney_weapon_change", -10.0, 0.0, "UI")

func intercept_hide() -> void: icpt_box.visible = false

func _icpt_pick(i: int) -> void:
	if not icpt_box.visible: return
	icpt_box.visible = false
	if icpt_cb.is_valid(): icpt_cb.call(i)

func detection(level: float) -> void:
	det_box.visible = level > 0.02
	det_fill.size.x = 120.0 * level
	det_fill.color = Color(1, 0.8, 0.3).lerp(UIKit.RED, level)

func tail_show(on: bool) -> void: tail_box.visible = on

func tail_status(text: String, level: float) -> void:
	tail_lbl.text = text; tail_fill.size.x = 220.0 * clampf(level, 0, 1)

func timer_show(on: bool) -> void: timer_lbl.visible = on

func timer_set(t: float) -> void:
	t = maxf(0.0, t)
	timer_lbl.text = "%d:%02d" % [int(t) / 60, int(t) % 60]
	timer_lbl.add_theme_color_override("font_color", UIKit.RED if t < 15.0 else UIKit.TEXT)

func boss_show(n: String, on: bool) -> void:
	boss_box.visible = on; boss_name.text = n

func boss_set(f: float, armor: float) -> void:
	boss_fill.size.x = 520.0 * clampf(f, 0, 1)
