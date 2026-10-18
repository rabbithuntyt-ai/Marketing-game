class_name CaseBoard
extends Control
## Between-mission case board. Story evidence is pinned to cork; the player strings each piece to the
## marketing concept that explains it, sorts a chapter framework, and earns Marr's case notes (the chapter
## summary, read aloud). Studying, dressed as detective work.

signal finished

var main: Node
var bi := 0                      # board index
var B: Dictionary
var replay := false              # opened from the archive
var stage: Control               # 1920x1080 design space, centred
var cork: Control
var yarn: Control
var drag_layer: Control
var notebook: VBoxContainer
var file_title: Label
var file_def: Label
var log_box: VBoxContainer
var prog_l: Label
var ev_cards: Array = []         # {node, pin(Vector2 local to stage), done, i}
var concept_cards := {}          # term -> {node, pin}
var links: Array = []            # [ev_index, term]
var slots: Array = []            # {node, idx, multi, filled:Array}
var tokens: Array = []           # {node, i, home:Vector2, placed}
var tray: Control
var drag = null                  # {"kind": "ev"/"tok", ...}
var press_pos := Vector2.ZERO
var selected_ev := -1
var mistakes := 0
var complete := false
var accent := Color(0.85, 0.2, 0.15)
var summary_view: Control
var hint_t := 0.0
var sum_paper: Control
var sum_scroll: ScrollContainer

const W := 1920.0
const H := 1080.0
const CORK := Rect2(36, 120, 1420, 930)
const YARN := Color(0.72, 0.06, 0.06)

func _ready() -> void:
	UIKit.full(self)
	B = Game.content["boards"][bi]
	var wall := ColorRect.new(); wall.color = Color(0.045, 0.04, 0.038); UIKit.full(wall); add_child(wall)
	var lamp := TextureRect.new(); UIKit.full(lamp); lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(lamp)
	var g := Gradient.new(); g.set_color(0, Color(1.0, 0.85, 0.6, 0.18)); g.set_color(1, Color(0, 0, 0, 0))
	var gt := GradientTexture2D.new(); gt.gradient = g; gt.fill = GradientTexture2D.FILL_RADIAL; gt.fill_from = Vector2(0.4, 0.35); gt.fill_to = Vector2(1.0, 1.1); lamp.texture = gt
	stage = Control.new(); stage.size = Vector2(W, H); stage.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(stage)
	_build_header()
	_build_cork()
	_build_evidence()
	_build_concepts()
	_build_framework()
	_build_notebook()
	yarn = Control.new(); yarn.size = Vector2(W, H); yarn.mouse_filter = Control.MOUSE_FILTER_IGNORE; stage.add_child(yarn); yarn.draw.connect(_draw_yarn)
	drag_layer = Control.new(); drag_layer.size = Vector2(W, H); drag_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE; stage.add_child(drag_layer)
	_update_progress()
	Audio.music("from_here", 2.0, -6.0)
	Audio.ambience("rain_inside", -16.0)
	Audio.voice_mission = "boards"
	for l in B.get("intro", []): Audio.say(String(l["spk"]), String(l["text"]), String(l["vo"]), "boards")
	modulate.a = 0.0; create_tween().tween_property(self, "modulate:a", 1.0, 0.6)

func _process(dt: float) -> void:
	var vs := get_viewport_rect().size
	var s := minf(vs.x / W, vs.y / H)
	stage.scale = Vector2(s, s)
	stage.position = (vs - Vector2(W, H) * s) * 0.5
	yarn.queue_redraw()
	if drag and drag["kind"] == "tok":
		var n: Control = drag["node"]
		n.position = _mouse() - drag["grab"]
	hint_t -= dt

func _mouse() -> Vector2:
	return (get_global_mouse_position() - stage.global_position) / stage.scale.x

# ---------------------------------------------------------------- building
func _build_header() -> void:
	var h := UIKit.vbox(2); h.position = Vector2(40, 18); stage.add_child(h)
	var t := "CASE BOARD  ·  %d / %d  ·  AFTER MISSION %d" % [bi + 1, Game.content["boards"].size(), int(B["after"]) + 1]
	h.add_child(UIKit.label(t, UIKit.mono(15), Color(0.95, 0.55, 0.4)))
	var title := UIKit.label(String(B["title"]), UIKit.head(46)); h.add_child(title)
	var tw: float = UIKit.font("Rajdhani-Bold").get_string_size(String(B["title"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 46).x
	var lx := maxf(560.0, 40.0 + tw + 50.0)
	var lead := UIKit.label(String(B["lead"]), UIKit.body(18 if lx > 600.0 else 19), UIKit.DIM); lead.position = Vector2(lx, 46); lead.custom_minimum_size = Vector2(1450.0 - lx, 0)
	lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; stage.add_child(lead)

func _build_cork() -> void:
	var frame := Panel.new(); frame.position = CORK.position - Vector2(14, 14); frame.size = CORK.size + Vector2(28, 28); frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fs := StyleBoxFlat.new(); fs.bg_color = Color(0.25, 0.16, 0.09); fs.set_corner_radius_all(4); fs.shadow_color = Color(0, 0, 0, 0.6); fs.shadow_size = 30; fs.shadow_offset = Vector2(0, 12)
	fs.border_color = Color(0.35, 0.23, 0.13); fs.set_border_width_all(3); frame.add_theme_stylebox_override("panel", fs); stage.add_child(frame)
	cork = TextureRect.new(); cork.texture = load("res://assets/ui/cork.png"); cork.stretch_mode = TextureRect.STRETCH_TILE
	cork.position = CORK.position; cork.size = CORK.size; cork.mouse_filter = Control.MOUSE_FILTER_IGNORE; stage.add_child(cork)
	var shade := ColorRect.new(); shade.color = Color(0, 0, 0, 0.12); shade.position = CORK.position; shade.size = CORK.size; shade.mouse_filter = Control.MOUSE_FILTER_IGNORE; stage.add_child(shade)

func _paper(bg: Color, rot: float) -> PanelContainer:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new(); s.bg_color = bg; s.shadow_color = Color(0, 0, 0, 0.45); s.shadow_size = 10; s.shadow_offset = Vector2(3, 6)
	s.content_margin_left = 16; s.content_margin_right = 16; s.content_margin_top = 14; s.content_margin_bottom = 12
	p.add_theme_stylebox_override("panel", s)
	p.rotation = deg_to_rad(rot)
	return p

func _ink(text: String, f: Dictionary, col := Color(0.1, 0.1, 0.11), width := 0.0) -> Label:
	var l := UIKit.label(text, f, col)
	if width > 0: l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.custom_minimum_size = Vector2(width, 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _build_evidence() -> void:
	var th: Array = B["threads"]
	var rng := RandomNumberGenerator.new(); rng.seed = 100 + bi
	for i in th.size():
		var T: Dictionary = th[i]
		var kind := String(T.get("kind", "memo"))
		var bg: Color = {"memo": Color(0.95, 0.94, 0.9), "note": Color(1.0, 0.9, 0.45), "clipping": Color(0.86, 0.84, 0.78), "photo": Color(0.97, 0.97, 0.95)}.get(kind, Color(0.95, 0.94, 0.9))
		var p := _paper(bg, rng.randf_range(-1.6, 1.6))
		p.position = Vector2(64, 142 + i * 180); p.custom_minimum_size = Vector2(400, 158); p.size = Vector2(400, 158)
		p.pivot_offset = Vector2(200, 79)
		stage.add_child(p)
		var v := UIKit.vbox(4); v.mouse_filter = Control.MOUSE_FILTER_IGNORE; p.add_child(v)
		var tag := {"memo": "MEMO", "note": "NOTE", "clipping": "CLIPPING", "photo": "SURVEILLANCE"}.get(kind, "EVIDENCE")
		var top := UIKit.hbox(8); top.mouse_filter = Control.MOUSE_FILTER_IGNORE; v.add_child(top)
		top.add_child(_ink("%s %d" % [tag, i + 1], UIKit.mono(12), Color(0.55, 0.12, 0.1)))
		top.add_child(_ink(String(T["t"]), UIKit.mono(12), Color(0.3, 0.3, 0.32)))
		var f := UIKit.body(17) if kind != "note" else {"font": UIKit.font("Barlow-Italic"), "size": 18}
		v.add_child(_ink(String(T["ev"]), f, Color(0.1, 0.1, 0.11), 366))
		var stamp := _ink("", UIKit.head(30), Color(0.1, 0.45, 0.2)); stamp.position = p.position + Vector2(250, 104); stamp.rotation = -0.2; stage.add_child(stamp)
		p.gui_input.connect(_ev_input.bind(i))
		p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		ev_cards.append({"node": p, "i": i, "done": false, "stamp": stamp})

func _build_concepts() -> void:
	var terms: Array = B["concepts"].keys()
	var rng := RandomNumberGenerator.new(); rng.seed = 200 + bi
	terms.shuffle()
	for k in terms.size():
		var term: String = terms[k]
		var p := _paper(Color(0.98, 0.98, 0.96), rng.randf_range(-3.0, 3.0))
		var col := k % 2; var row := k / 2
		p.position = Vector2(510 + col * 232 + rng.randf_range(-8, 8), 160 + row * 212 + rng.randf_range(-14, 14))
		p.custom_minimum_size = Vector2(212, 96); p.size = Vector2(212, 96); p.pivot_offset = Vector2(106, 48)
		stage.add_child(p)
		var v := UIKit.vbox(0); v.mouse_filter = Control.MOUSE_FILTER_IGNORE; p.add_child(v)
		var rule := ColorRect.new(); rule.color = Color(0.85, 0.25, 0.25, 0.7); rule.custom_minimum_size = Vector2(0, 2); rule.mouse_filter = Control.MOUSE_FILTER_IGNORE; v.add_child(rule)
		v.add_child(UIKit.spacer(6))
		var l := _ink(term, UIKit.head(25), Color(0.08, 0.1, 0.18), 180); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(l)
		var stamp := _ink("", UIKit.head(30), Color(0.1, 0.45, 0.2)); stamp.position = p.position + Vector2(176, 56); stamp.rotation = -0.25; stage.add_child(stamp)
		p.mouse_entered.connect(_show_file.bind(term))
		p.gui_input.connect(_concept_input.bind(term))
		p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		concept_cards[term] = {"node": p, "stamp": stamp}

func _build_framework() -> void:
	var F: Dictionary = B["framework"]
	var px := 990.0; var pw := 440.0
	var paper := _paper(Color(0.95, 0.94, 0.9), 0.6)
	paper.position = Vector2(px, 140); paper.size = Vector2(pw, 890); paper.custom_minimum_size = paper.size; paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(paper)
	var hv := UIKit.vbox(4); hv.mouse_filter = Control.MOUSE_FILTER_IGNORE; paper.add_child(hv)
	hv.add_child(_ink(String(F["title"]), UIKit.head(26), Color(0.55, 0.12, 0.1)))
	hv.add_child(_ink(String(F.get("note", "")), UIKit.body(15), Color(0.3, 0.3, 0.32), pw - 40))
	var kind := String(F["kind"])
	var sl: Array = F["slots"]
	var top := 250.0
	var multi := kind == "columns"
	var area_h := 470.0
	for k in sl.size():
		var r := Rect2()
		if kind == "grid":
			var cw := (pw - 44) * 0.5; var ch := 200.0
			r = Rect2(px + 18 + (k % 2) * (cw + 8), top + (k / 2) * (ch + 10), cw, ch)
		else:
			var bh := (area_h - (sl.size() - 1) * 8) / sl.size()
			if multi: bh = (area_h + 60 - (sl.size() - 1) * 8) / sl.size()
			r = Rect2(px + 18, top + k * (bh + 8), pw - 40, bh)
		var box := Panel.new(); box.position = r.position; box.size = r.size; box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bs := StyleBoxFlat.new(); bs.bg_color = Color(0, 0, 0, 0.04); bs.border_color = Color(0.2, 0.2, 0.25, 0.45); bs.set_border_width_all(2)
		bs.set_corner_radius_all(3); box.add_theme_stylebox_override("panel", bs); stage.add_child(box)
		var lab := _ink(String(sl[k]), UIKit.mono(12) if kind != "order" else UIKit.head(26), Color(0.35, 0.35, 0.4), r.size.x - 16)
		lab.position = Vector2(8, 4); box.add_child(lab)
		slots.append({"node": box, "idx": k, "multi": multi, "filled": [], "style": bs})
	# token tray
	tray = Control.new(); tray.position = Vector2(px + 18, top + area_h + (70 if multi else 20)); tray.size = Vector2(pw - 40, 890 - (top - 140) - area_h - 40); tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(tray)
	var tk: Array = F["tokens"]
	var order: Array = range(tk.size()); order.shuffle()
	var x := 0.0; var y := 0.0; var row_h := 0.0
	for j in order.size():
		var i: int = order[j]
		var chip := _paper(Color(1.0, 0.97, 0.72) if kind != "order" else Color(0.88, 0.93, 1.0), 0.0)
		var st: StyleBoxFlat = chip.get_theme_stylebox("panel"); st.content_margin_left = 8; st.content_margin_right = 8; st.content_margin_top = 5; st.content_margin_bottom = 5; st.shadow_size = 4
		var tw := (pw - 52) if kind == "order" else ((pw - 52) * 0.5)
		var l := _ink(String(tk[i]), UIKit.body(14), Color(0.1, 0.1, 0.12), tw - 16); chip.add_child(l)
		chip.custom_minimum_size = Vector2(tw, 0)
		stage.add_child(chip); chip.reset_size()
		if x + tw > tray.size.x + 1:
			x = 0.0; y += row_h + 8.0; row_h = 0.0
		row_h = maxf(row_h, chip.size.y)
		var home := tray.position + Vector2(x, y)
		chip.position = home
		x += tw + 12
		if kind == "order":
			x = 0.0; y += maxf(40.0, chip.size.y + 6); row_h = 0.0
		chip.gui_input.connect(_tok_input.bind(tokens.size()))
		chip.mouse_default_cursor_shape = Control.CURSOR_DRAG
		tokens.append({"node": chip, "i": i, "home": home, "placed": false})

func _build_notebook() -> void:
	var p := UIKit.panel(Color(0.06, 0.065, 0.07, 0.97), Color(0.5, 0.82, 1.0)); p.position = Vector2(1486, 20); p.size = Vector2(410, 1040); p.custom_minimum_size = p.size
	stage.add_child(p)
	notebook = UIKit.vbox(10); p.add_child(notebook)
	notebook.add_child(UIKit.label("DR. MARR  ·  CASE NOTEBOOK", UIKit.mono(14), Color(0.5, 0.82, 1.0)))
	prog_l = UIKit.label("", UIKit.mono(14), UIKit.DIM); notebook.add_child(prog_l)
	var how := UIKit.label("Drag from a piece of evidence to the concept that explains it. Hover a card to read its file. Then sort the framework on the right.", UIKit.body(16), UIKit.DIM)
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; how.custom_minimum_size = Vector2(370, 0); notebook.add_child(how)
	notebook.add_child(UIKit.rule())
	notebook.add_child(UIKit.label("FILE CARD", UIKit.mono(12), UIKit.GOLD))
	file_title = UIKit.label("—", UIKit.head(28)); file_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; file_title.custom_minimum_size = Vector2(370, 0); notebook.add_child(file_title)
	file_def = UIKit.label("Hover over a concept card.", UIKit.body(18), UIKit.TEXT); file_def.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; file_def.custom_minimum_size = Vector2(370, 0); notebook.add_child(file_def)
	notebook.add_child(UIKit.rule())
	notebook.add_child(UIKit.label("WHAT WE KNOW", UIKit.mono(12), UIKit.GOLD))
	var sc := ScrollContainer.new(); sc.custom_minimum_size = Vector2(380, 520); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; notebook.add_child(sc)
	log_box = UIKit.vbox(10); log_box.custom_minimum_size = Vector2(360, 0); sc.add_child(log_box)
	var row := UIKit.hbox(10); notebook.add_child(row)
	var skip := UIKit.small_button("Skip to case notes" if not replay else "Close", Color(0.5, 0.82, 1.0)); row.add_child(skip)
	skip.pressed.connect(func():
		if replay and not complete: _close()
		else: _open_summary())

func _show_file(term: String) -> void:
	file_title.text = term
	file_def.text = String(B["concepts"].get(term, ""))

func _log(text: String, col := UIKit.TEXT) -> void:
	var l := UIKit.label(text, UIKit.body(17), col); l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.custom_minimum_size = Vector2(350, 0)
	log_box.add_child(l); log_box.move_child(l, 0)
	l.modulate.a = 0.0; create_tween().tween_property(l, "modulate:a", 1.0, 0.4)

func _update_progress() -> void:
	var nd := ev_cards.filter(func(e): return e["done"]).size()
	var tp := tokens.filter(func(t): return t["placed"]).size()
	prog_l.text = "EVIDENCE LINKED %d/%d   ·   FRAMEWORK %d/%d" % [nd, ev_cards.size(), tp, tokens.size()]

# ---------------------------------------------------------------- pins and yarn
func _ev_pin(i: int) -> Vector2:
	var n: Control = ev_cards[i]["node"]
	return n.position + Vector2(n.size.x - 14, n.size.y * 0.5)

func _concept_pin(term: String) -> Vector2:
	var n: Control = concept_cards[term]["node"]
	return n.position + Vector2(n.size.x * 0.5, 4)

func _draw_pin(c: Vector2, col := Color(0.85, 0.12, 0.1)) -> void:
	yarn.draw_circle(c + Vector2(2, 3), 8, Color(0, 0, 0, 0.35))
	yarn.draw_circle(c, 8, col)
	yarn.draw_circle(c + Vector2(-2.5, -2.5), 3, Color(1, 1, 1, 0.55))

func _string(a: Vector2, b: Vector2) -> void:
	var sag := 26.0 + a.distance_to(b) * 0.07
	var mid := (a + b) * 0.5 + Vector2(0, sag)
	var pts := PackedVector2Array(); var sh := PackedVector2Array()
	for k in 25:
		var t := k / 24.0
		var p := a.lerp(mid, t).lerp(mid.lerp(b, t), t)
		pts.append(p); sh.append(p + Vector2(3, 6))
	yarn.draw_polyline(sh, Color(0, 0, 0, 0.3), 4.0, true)
	yarn.draw_polyline(pts, YARN, 3.2, true)
	yarn.draw_polyline(pts, Color(1, 0.5, 0.45, 0.35), 1.0, true)

func _draw_yarn() -> void:
	for l in links: _string(_ev_pin(l[0]), _concept_pin(l[1]))
	if drag and drag["kind"] == "ev": _string(_ev_pin(drag["i"]), _mouse())
	elif selected_ev >= 0: _string(_ev_pin(selected_ev), _mouse())
	for e in ev_cards: _draw_pin(_ev_pin(e["i"]), Color(0.85, 0.12, 0.1) if not e["done"] else Color(0.2, 0.6, 0.3))
	for term in concept_cards.keys(): _draw_pin(_concept_pin(term), Color(0.15, 0.35, 0.8))

# ---------------------------------------------------------------- input
func _ev_input(e: InputEvent, i: int) -> void:
	if complete or ev_cards[i]["done"]: return
	if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			drag = {"kind": "ev", "i": i}; press_pos = _mouse()
			Audio.play2d("kenney_weapon_change", -22.0, 0.2, "UI")
		else:
			_release()

func _concept_input(e: InputEvent, term: String) -> void:
	if e is InputEventMouseButton and e.pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and selected_ev >= 0:
		var i := selected_ev; selected_ev = -1
		_try_link(i, term)

func _tok_input(e: InputEvent, k: int) -> void:
	if complete or tokens[k]["placed"]: return
	if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			var n: Control = tokens[k]["node"]
			drag = {"kind": "tok", "k": k, "node": n, "grab": _mouse() - n.position}
			stage.move_child(n, stage.get_child_count() - 1)
			n.rotation = deg_to_rad(-2.0)
		else:
			_release()

func _input(e: InputEvent) -> void:
	# releases outside the pressed control still end the drag
	if drag and e is InputEventMouseButton and not e.pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_release()

func _release() -> void:
	if drag == null: return
	var d: Dictionary = drag; drag = null
	var m := _mouse()
	if d["kind"] == "ev":
		var hit := _concept_at(m)
		if hit != "": _try_link(d["i"], hit)
		elif m.distance_to(press_pos) < 8.0: selected_ev = d["i"]     # click-to-select, then click a concept
	else:
		var k: int = d["k"]
		var n: Control = d["node"]; n.rotation = 0.0
		var s := _slot_at(m)
		if s >= 0: _try_place(k, s)
		else: _return_token(k)

func _concept_at(m: Vector2) -> String:
	for term in concept_cards.keys():
		var n: Control = concept_cards[term]["node"]
		if Rect2(n.position, n.size).grow(6).has_point(m): return term
	return ""

func _slot_at(m: Vector2) -> int:
	for s in slots:
		var n: Control = s["node"]
		if Rect2(n.position, n.size).has_point(m): return s["idx"]
	return -1

# ---------------------------------------------------------------- rules
func _try_link(i: int, term: String) -> void:
	var T: Dictionary = B["threads"][i]
	var n: Control = concept_cards[term]["node"]
	if term == String(T["a"]):
		links.append([i, term]); ev_cards[i]["done"] = true
		(ev_cards[i]["stamp"] as Label).text = "LINKED"
		(concept_cards[term]["stamp"] as Label).text = "✓"
		_log("◆ " + String(T["reveal"]))
		Audio.say("MARR", String(T["reveal"]), String(T.get("vo", "")), "boards", true)
		Audio.play2d("tps_hit", -14.0, 0.1, "UI")
		Game.add_xp(40, "CASE LINK")
		_show_file(term)
	else:
		mistakes += 1
		var x := n.position.x
		var tw := create_tween()
		for k in 4: tw.tween_property(n, "position:x", x + (7 if k % 2 == 0 else -7), 0.04)
		tw.tween_property(n, "position:x", x, 0.04)
		Audio.play2d("empty", -10.0, 0.1, "UI")
		_log("✖ %s: %s Doesn't fit this evidence." % [term, String(B["concepts"].get(term, ""))], Color(1.0, 0.55, 0.5))
		if hint_t <= 0.0:
			hint_t = 8.0
			Audio.say_generic("g_wrong_%d" % (randi() % 3), true)
	_update_progress(); _check_done()

func _token_answer(i: int) -> int:
	var F: Dictionary = B["framework"]
	if F.has("answers"): return int(F["answers"][i])
	return i

func _try_place(k: int, s: int) -> void:
	var t: Dictionary = tokens[k]
	var slot: Dictionary = slots[s]
	if _token_answer(t["i"]) == s and (slot["multi"] or slot["filled"].is_empty()):
		t["placed"] = true; slot["filled"].append(k)
		var box: Control = slot["node"]; var n: Control = t["node"]
		var idx: int = slot["filled"].size() - 1
		if slot["multi"]:
			var cw := (box.size.x - 24) * 0.5
			n.custom_minimum_size.x = cw; n.reset_size()
			n.position = box.position + Vector2(8 + (idx % 2) * (cw + 8), 26 + (idx / 2) * 44)
		else:
			var lx := 44.0 if String(B["framework"]["kind"]) == "order" else 8.0
			n.custom_minimum_size.x = box.size.x - lx - 8; n.reset_size()
			n.position = box.position + Vector2(lx, maxf(8.0 if lx > 10.0 else 26.0, (box.size.y - n.size.y) * (0.5 if lx > 10.0 else 1.0) - (0.0 if lx > 10.0 else 8.0)))
		(slot["style"] as StyleBoxFlat).border_color = Color(0.15, 0.55, 0.25, 0.8)
		Audio.play2d("tps_hit", -16.0, 0.1, "UI")
		Game.add_xp(15, "FRAMEWORK")
	else:
		mistakes += 1
		_return_token(k)
		var F: Dictionary = B["framework"]
		var right: String = String(F["slots"][_token_answer(t["i"])]).split("\n")[0]
		_log("✖ \"%s\" doesn't go there. Think about where it sits in %s." % [String(F["tokens"][t["i"]]), String(F["title"]).to_lower()], Color(1.0, 0.55, 0.5))
		Audio.play2d("empty", -10.0, 0.1, "UI")
		if mistakes % 3 == 0: _log("Hint: it belongs in \"%s\"." % right, UIKit.GOLD)
	_update_progress(); _check_done()

func _return_token(k: int) -> void:
	var n: Control = tokens[k]["node"]
	create_tween().tween_property(n, "position", tokens[k]["home"], 0.25).set_trans(Tween.TRANS_BACK)

func _check_done() -> void:
	if complete: return
	if ev_cards.any(func(e): return not e["done"]): return
	if tokens.any(func(t): return not t["placed"]): return
	complete = true
	Game.save["boards"] = Game.save.get("boards", {})
	Game.save["boards"][str(bi)] = true
	Game.add_xp(200 if mistakes == 0 else 100, "CASE CLOSED" if mistakes == 0 else "CASE UPDATED")
	Game.persist()
	var st := _ink("CASE UPDATED", UIKit.head(110), Color(0.75, 0.08, 0.06)); st.rotation = -0.18; st.position = Vector2(420, 430); st.modulate.a = 0.0; stage.add_child(st)
	st.pivot_offset = Vector2(330, 60); st.scale = Vector2(2.2, 2.2)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(st, "modulate:a", 0.85, 0.15); tw.tween_property(st, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)
	Audio.play2d("tps_hit", -4.0, 0.0, "UI")
	await get_tree().create_timer(0.8).timeout
	Audio.say("MARR", String(B["outro"]), String(B.get("outro_vo", "")), "boards", true)
	_log("▶ " + String(B["outro"]), UIKit.GOLD)
	await get_tree().create_timer(1.5).timeout
	while Audio.busy() and is_inside_tree() and summary_view == null:
		await get_tree().create_timer(0.3).timeout
	if is_inside_tree() and summary_view == null: _open_summary()

# ---------------------------------------------------------------- summary (the actual chapter summary)
func _open_summary() -> void:
	if summary_view: return
	Audio.clear_dialogue()
	var S: Dictionary = B["summary"]
	summary_view = Control.new(); UIKit.full(summary_view); add_child(summary_view)
	summary_view.add_child(Blur.make(0.7))
	var paper := _paper(Color(0.94, 0.93, 0.89), 0.0)
	var ps: StyleBoxFlat = paper.get_theme_stylebox("panel"); ps.content_margin_left = 60; ps.content_margin_right = 60; ps.content_margin_top = 44; ps.content_margin_bottom = 36
	summary_view.add_child(paper); paper.name = "Paper"
	var v := UIKit.vbox(12); paper.add_child(v)
	var top := UIKit.hbox(12); v.add_child(top)
	top.add_child(_ink("LEDGER · CASE NOTES · DR. N. MARR", UIKit.mono(13), Color(0.55, 0.12, 0.1)))
	top.add_child(_ink("   " + ("%d mistake%s on the board" % [mistakes, "" if mistakes == 1 else "s"] if complete else "board not finished"), UIKit.mono(13), Color(0.35, 0.35, 0.38)))
	v.add_child(_ink(String(S["t"]), UIKit.head(38), Color(0.08, 0.08, 0.09)))
	var sc := ScrollContainer.new(); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; sc.custom_minimum_size = Vector2(1040, 600); v.add_child(sc)
	sum_scroll = sc; sum_paper = paper
	var body := UIKit.vbox(16); body.custom_minimum_size = Vector2(1020, 0); sc.add_child(body)
	for para in S["paras"]:
		var r := UIKit.rich(_bold_terms(String(para)), 21); r.add_theme_color_override("default_color", Color(0.1, 0.1, 0.11)); r.custom_minimum_size = Vector2(1010, 0)
		body.add_child(r)
	body.add_child(_ink("KEY TERMS ON THIS BOARD", UIKit.mono(13), Color(0.55, 0.12, 0.1)))
	for T in B["threads"]:
		var a := String(T["a"])
		var r2 := UIKit.rich("[b]%s[/b]  —  %s" % [a, String(B["concepts"][a])], 18); r2.add_theme_color_override("default_color", Color(0.15, 0.15, 0.17)); r2.custom_minimum_size = Vector2(1010, 0)
		body.add_child(r2)
	var row := UIKit.hbox(14); v.add_child(row)
	var read := UIKit.small_button("■  Stop reading", Color(0.2, 0.2, 0.25)); row.add_child(read)
	var reading := [true]
	read.pressed.connect(func():
		if reading[0]:
			Audio.skip_line()
			reading[0] = false
			read.text = "▶  READ ALOUD"
		else:
			Audio.say("MARR", " ".join(S["paras"]), String(S["vo"]), "boards", true)
			reading[0] = true
			read.text = "■  STOP READING")
	var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(sp)
	var go := UIKit.small_button("Close" if replay else "Continue to next briefing", Color(0.75, 0.15, 0.1)); row.add_child(go)
	go.pressed.connect(_close)
	for b in [read, go]: _dark_button(b)
	if Game.settings["read_intel"]:
		Audio.say("MARR", " ".join(S["paras"]), String(S["vo"]), "boards", true)
	else:
		reading[0] = false
		read.text = "▶  READ ALOUD"
	summary_view.modulate.a = 0.0; create_tween().tween_property(summary_view, "modulate:a", 1.0, 0.35)
	go.call_deferred("grab_focus")

func _dark_button(b: Button) -> void:
	var n := StyleBoxFlat.new(); n.bg_color = Color(0, 0, 0, 0.06); n.set_border_width_all(1); n.border_color = Color(0, 0, 0, 0.3)
	n.content_margin_left = 18; n.content_margin_right = 18; n.content_margin_top = 7; n.content_margin_bottom = 7
	var h := n.duplicate(); h.bg_color = Color(0, 0, 0, 0.14); h.border_color = Color(0, 0, 0, 0.7)
	for s in ["normal", "focus", "pressed"]: b.add_theme_stylebox_override(s, n)
	b.add_theme_stylebox_override("hover", h); b.add_theme_stylebox_override("focus", h)
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]: b.add_theme_color_override(c, Color(0.1, 0.1, 0.12))

## Bold every concept named on the board where it appears in the summary.
func _bold_terms(t: String) -> String:
	for term in B["concepts"].keys():
		var low := String(term).to_lower()
		var at := t.to_lower().find(low)
		if at >= 0: t = t.substr(0, at) + "[b]" + t.substr(at, low.length()) + "[/b]" + t.substr(at + low.length())
	return t

func _close() -> void:
	Audio.clear_dialogue()
	finished.emit()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and (e as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if summary_view: _close()
		elif selected_ev >= 0: selected_ev = -1
		elif replay: _close()

func _physics_process(_dt: float) -> void:
	if sum_paper:
		var vs := get_viewport_rect().size
		sum_scroll.custom_minimum_size.y = clampf(vs.y - 330.0, 280.0, 700.0)
		sum_paper.reset_size()
		sum_paper.position = (vs - sum_paper.size) * 0.5
