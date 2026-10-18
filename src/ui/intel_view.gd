class_name IntelView
extends Control
## Recovered document viewer. Dr. Marr reads it over comms (toggle in settings); the text is the
## textbook material, formatted as an in-world document.

var main: Node
var doc: Dictionary
var M: Dictionary
var ri := 0
var archive := false        # opened from the menu archive (no pause/close semantics)
var paper: PanelContainer
var scroll: ScrollContainer
var reading := false
var read_b: Button

const KINDS := {"memo": "INTERNAL MEMO", "email": "EMAIL", "report": "REPORT", "deck": "PRESENTATION", "slide": "BOARD SLIDE", "file": "FILE", "log": "LOG", "brief": "BRIEFING", "note": "NOTE", "chat": "CHAT LOG", "manual": "HANDBOOK"}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIKit.full(self)
	if not archive: add_child(Blur.make(0.78))
	paper = PanelContainer.new(); add_child(paper)
	var s := StyleBoxFlat.new(); s.bg_color = Color(0.92, 0.91, 0.87); s.set_corner_radius_all(2)
	s.content_margin_left = 56; s.content_margin_right = 56; s.content_margin_top = 44; s.content_margin_bottom = 36
	s.shadow_color = Color(0, 0, 0, 0.6); s.shadow_size = 40; s.shadow_offset = Vector2(0, 12)
	paper.add_theme_stylebox_override("panel", s)
	var v := UIKit.vbox(10); paper.add_child(v)
	var top := UIKit.hbox(12); v.add_child(top)
	var col := Color(M.get("color", "#c84030"))
	var badge := UIKit.label(KINDS.get(String(doc.get("kind", "file")), String(doc.get("kind", "FILE")).to_upper()), UIKit.mono(14), Color(0.92, 0.91, 0.87), HORIZONTAL_ALIGNMENT_CENTER)
	var bs := StyleBoxFlat.new(); bs.bg_color = Color(0.12, 0.12, 0.13); bs.content_margin_left = 10; bs.content_margin_right = 10; bs.content_margin_top = 2; bs.content_margin_bottom = 2
	badge.add_theme_stylebox_override("normal", bs); top.add_child(badge)
	var conf := UIKit.label("CASTELLAN GROUP  ·  CONFIDENTIAL", UIKit.mono(14), Color(0.55, 0.12, 0.1)); top.add_child(conf)
	var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(sp)
	var mid := UIKit.label("%s  ·  SECTOR %d" % [String(M.get("code", "")), ri + 1], UIKit.mono(14), Color(0.35, 0.35, 0.36)); top.add_child(mid)
	var t := UIKit.label(String(doc.get("t", "")), UIKit.head(44), Color(0.08, 0.08, 0.09)); t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; t.custom_minimum_size = Vector2(860, 0); v.add_child(t)
	var src := UIKit.label(String(doc.get("src", "")), UIKit.mono(15), Color(0.32, 0.32, 0.34)); v.add_child(src)
	var rl := ColorRect.new(); rl.color = Color(0, 0, 0, 0.25); rl.custom_minimum_size = Vector2(0, 1); v.add_child(rl)
	scroll = ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; v.add_child(scroll)
	scroll.custom_minimum_size = Vector2(880, 560)
	var body := UIKit.rich(_ink(String(doc.get("bb", ""))), 22)
	body.add_theme_color_override("default_color", Color(0.1, 0.1, 0.11))
	body.custom_minimum_size = Vector2(860, 0); body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	var foot := UIKit.hbox(14); v.add_child(foot)
	read_b = UIKit.small_button("", col); foot.add_child(read_b); read_b.pressed.connect(_toggle_read)
	var sp2 := Control.new(); sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL; foot.add_child(sp2)
	if not archive:
		var close := UIKit.small_button("Close  [E]", col); foot.add_child(close); close.pressed.connect(_close)
	for b in [read_b]:
		b.add_theme_color_override("font_color", Color(0.1, 0.1, 0.12))
	_restyle_dark(foot)
	if Game.settings["read_intel"] and doc.get("vo", "") != "": _start_read()
	_upd_read()
	if not archive:
		paper.modulate.a = 0.0; paper.position.y += 30
		create_tween().tween_property(paper, "modulate:a", 1.0, 0.25)
		Audio.play2d("kenney_weapon_change", -10.0, 0.1, "UI")

## Intel body was authored for dark backgrounds; remap the highlight colours for paper.
func _ink(bb: String) -> String:
	return bb.replace("#f0c060", "#8a1d12").replace("#9fd3ff", "#1d4f8a").replace("#ffd27a", "#8a1d12").replace("#7fe0a0", "#1f6b3a").replace("#ff8f80", "#8a1d12")

func _restyle_dark(row: Control) -> void:
	for b in row.get_children():
		if b is Button:
			var n := StyleBoxFlat.new(); n.bg_color = Color(0, 0, 0, 0.06); n.set_border_width_all(1); n.border_color = Color(0, 0, 0, 0.25)
			n.content_margin_left = 18; n.content_margin_right = 18; n.content_margin_top = 6; n.content_margin_bottom = 6
			var h := n.duplicate(); h.bg_color = Color(0, 0, 0, 0.14); h.border_color = Color(0, 0, 0, 0.6)
			b.add_theme_stylebox_override("normal", n); b.add_theme_stylebox_override("hover", h); b.add_theme_stylebox_override("focus", h); b.add_theme_stylebox_override("pressed", h)
			b.add_theme_color_override("font_color", Color(0.1, 0.1, 0.12)); b.add_theme_color_override("font_hover_color", Color(0, 0, 0)); b.add_theme_color_override("font_focus_color", Color(0, 0, 0))

func _start_read() -> void:
	Audio.say("MARR", String(doc.get("t", "")), String(doc["vo"]), String(M.get("id", "")), true)
	reading = true

func _toggle_read() -> void:
	if reading:
		Audio.skip_line(); reading = false
	else:
		if doc.get("vo", "") != "": _start_read()
	_upd_read()

func _upd_read() -> void:
	read_b.text = ("■  STOP READING" if reading else "▶  READ ALOUD") + ("  [R]" if not archive else "")

func _process(_dt: float) -> void:
	if reading and not Audio.busy():
		reading = false; _upd_read()
	if archive:
		paper.position = Vector2.ZERO
		paper.size = size
		scroll.custom_minimum_size = Vector2(0, maxf(200.0, size.y - 300.0))
		return
	var vs := get_viewport_rect().size
	scroll.custom_minimum_size.y = clampf(vs.y - 380.0, 300.0, 640.0)
	paper.reset_size()
	var target := Vector2(vs.x * 0.5 - paper.size.x * 0.5, vs.y * 0.5 - paper.size.y * 0.5)
	paper.position = paper.position.lerp(target, 0.35)

func _close() -> void:
	if reading: Audio.skip_line()
	main.close_overlay()

func _exit_tree() -> void:
	if archive and reading: Audio.skip_line()

func _unhandled_input(e: InputEvent) -> void:
	if archive: return
	if e is InputEventKey and e.pressed and not e.echo:
		var k := (e as InputEventKey).keycode
		if k in [KEY_E, KEY_ESCAPE, KEY_SPACE, KEY_ENTER]:
			get_viewport().set_input_as_handled(); _close()
		elif k == KEY_R:
			get_viewport().set_input_as_handled(); _toggle_read()
	if e is InputEventMouseButton and e.pressed:
		var mb := e as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN: scroll.scroll_vertical += 60
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP: scroll.scroll_vertical -= 60
