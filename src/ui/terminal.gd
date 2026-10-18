class_name TerminalUI
extends Control
## Analysis uplink: Marr asks for your read on what you just found. One question at a time, number keys
## or mouse to answer, explanation after every answer. Wrong answers return to the queue and trigger
## consequences in the field; recall questions come from earlier missions or past mistakes.

var main: Node
var room: Room
var queue: Array = []
var single: Dictionary = {}
var cb: Callable
var accent := Color(0.5, 0.82, 1.0)
var ok_all := true
var answered := false
var cur_key := ""
var cur_recall := false
var cur_q: Dictionary
var order: Array = []
var buttons: Array = []
var asked := 0
var total := 0
var last_ok := false
var said_recall := false

var panel: PanelContainer
var head_l: Label
var count_l: Label
var tag_l: Label
var q_l: Label
var ans_box: VBoxContainer
var fb_box: VBoxContainer
var verdict_l: Label
var why_l: RichTextLabel
var cont_b: Button
var hint_l: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIKit.full(self)
	add_child(Blur.make(0.72))
	total = queue.size() if single.is_empty() else 1
	panel = UIKit.panel(UIKit.BG_SOLID, accent); add_child(panel)
	panel.custom_minimum_size = Vector2(1040, 0)
	var v := UIKit.vbox(14); panel.add_child(v)
	var top := UIKit.hbox(10); v.add_child(top)
	head_l = UIKit.label("SECURE UPLINK  ·  DR. NADIA MARR", UIKit.mono(15), accent); top.add_child(head_l)
	var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(sp)
	count_l = UIKit.label("", UIKit.mono(15), UIKit.DIM); top.add_child(count_l)
	v.add_child(UIKit.rule())
	tag_l = UIKit.label("", UIKit.mono(15), UIKit.GOLD); v.add_child(tag_l)
	q_l = UIKit.label("", UIKit.body(30)); q_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; q_l.custom_minimum_size = Vector2(980, 0); v.add_child(q_l)
	v.add_child(UIKit.spacer(4))
	ans_box = UIKit.vbox(8); v.add_child(ans_box)
	fb_box = UIKit.vbox(8); fb_box.visible = false; v.add_child(fb_box)
	fb_box.add_child(UIKit.rule())
	verdict_l = UIKit.label("", UIKit.head(34)); fb_box.add_child(verdict_l)
	why_l = UIKit.rich("", 23); why_l.custom_minimum_size = Vector2(980, 0); fb_box.add_child(why_l)
	var row := UIKit.hbox(12); fb_box.add_child(row)
	cont_b = UIKit.small_button("Continue", accent); row.add_child(cont_b); cont_b.pressed.connect(_continue)
	row.add_child(UIKit.label("SPACE", UIKit.mono(13), UIKit.DIM))
	hint_l = UIKit.label("[1-4] answer    ·    [ESC] step away", UIKit.mono(14), UIKit.DIM); v.add_child(hint_l)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.18)
	Audio.play2d("kenney_weapon_change", -8.0, 0.0, "UI")
	_next()

func _layout() -> void:
	var vs := get_viewport_rect().size
	panel.reset_size()
	panel.position = Vector2(vs.x * 0.5 - panel.size.x * 0.5, vs.y * 0.5 - panel.size.y * 0.5)

func _process(_dt: float) -> void:
	_layout()

func _next() -> void:
	answered = false
	fb_box.visible = false; ans_box.visible = true; hint_l.visible = true
	for c in ans_box.get_children(): c.queue_free()
	buttons.clear()
	if single.is_empty():
		cur_key = queue[0]
		cur_recall = cur_key.begins_with("R:")
		var k := cur_key.substr(2) if cur_recall else cur_key
		cur_q = Game.q_data(k)
		if cur_q.is_empty():
			queue.pop_front()
			if queue.is_empty(): _finish(); return
			_next(); return
		asked += 1
		count_l.text = "QUESTION %d / %d" % [mini(asked, total), total]
		if cur_recall:
			var mi := Game.mi_of(k)
			var missed: bool = Game.save["missed"].has(k)
			tag_l.text = ("RECALL  ·  YOU MISSED THIS BEFORE" if missed else "RECALL  ·  FROM MISSION %d  ·  %s" % [mi + 1, String(Game.missions[mi]["code"])])
			tag_l.add_theme_color_override("font_color", UIKit.GOLD)
			if not said_recall:
				said_recall = true
				Audio.say_generic("g_recall_missed" if missed else "g_recall", true)
		else:
			var ch: String = String(Game.missions[Game.mission_index].get("chname", ""))
			tag_l.text = "CHAPTER %s  ·  %s" % [str(Game.missions[Game.mission_index].get("ch", "")), ch.to_upper()]
			tag_l.add_theme_color_override("font_color", UIKit.DIM)
	else:
		cur_q = single
		count_l.text = ""
		tag_l.text = String(single.get("tag", ""))
	q_l.text = String(cur_q["q"])
	var answers: Array = cur_q["a"]
	order = range(answers.size()); order.shuffle()
	for i in order.size():
		var b := _answer_button(i + 1, String(answers[order[i]]))
		ans_box.add_child(b); buttons.append(b)
		b.pressed.connect(_pick.bind(i))
	call_deferred("_focus_first")

func _focus_first() -> void:
	if not buttons.is_empty() and is_instance_valid(buttons[0]): (buttons[0] as Button).grab_focus()

func _answer_button(n: int, text: String) -> Button:
	var b := UIKit.button("", accent, 26)
	b.text = "%d    %s" % [n, text]
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_override("font", UIKit.font("Barlow-SemiBold"))
	var n_s := StyleBoxFlat.new(); n_s.bg_color = Color(1, 1, 1, 0.04); n_s.set_border_width_all(1); n_s.border_color = Color(1, 1, 1, 0.1)
	n_s.content_margin_left = 22; n_s.content_margin_right = 22; n_s.content_margin_top = 12; n_s.content_margin_bottom = 12
	var h := n_s.duplicate(); h.bg_color = Color(accent.r, accent.g, accent.b, 0.16); h.border_color = accent; h.border_width_left = 4
	b.add_theme_stylebox_override("normal", n_s); b.add_theme_stylebox_override("hover", h); b.add_theme_stylebox_override("focus", h); b.add_theme_stylebox_override("pressed", h)
	b.custom_minimum_size = Vector2(980, 0)
	return b

func _style(b: Button, col: Color) -> void:
	var s := StyleBoxFlat.new(); s.bg_color = Color(col.r, col.g, col.b, 0.2); s.border_color = col; s.set_border_width_all(1); s.border_width_left = 6
	s.content_margin_left = 22; s.content_margin_right = 22; s.content_margin_top = 12; s.content_margin_bottom = 12
	for st in ["normal", "hover", "focus", "pressed", "disabled"]: b.add_theme_stylebox_override(st, s)
	b.add_theme_color_override("font_disabled_color", Color.WHITE)

func _pick(i: int) -> void:
	if answered: return
	answered = true
	var ok: bool = order[i] == 0
	last_ok = ok
	for j in buttons.size():
		var b: Button = buttons[j]; b.disabled = true
		if order[j] == 0: _style(b, UIKit.GREEN)
		elif j == i: _style(b, UIKit.RED)
		else: b.modulate.a = 0.45
	hint_l.visible = false
	fb_box.visible = true
	why_l.text = String(cur_q.get("why", ""))
	if ok:
		verdict_l.text = "RIGHT CALL"; verdict_l.add_theme_color_override("font_color", UIKit.GREEN)
		Audio.play2d("kenney_weapon_change", -4.0, 0.0, "UI")
	else:
		verdict_l.text = "WRONG CALL"; verdict_l.add_theme_color_override("font_color", UIKit.RED)
		Audio.play2d("tps_hit", -8.0, 0.0, "UI")
	if single.is_empty():
		var k := cur_key.substr(2) if cur_recall else cur_key
		Game.record_answer(k, ok, cur_recall)
		if ok:
			queue.pop_front()
			Game.add_xp(75 if cur_recall else 50, "RECALL" if cur_recall else "RIGHT CALL")
			Audio.say_generic("g_right_%d" % (randi() % 4), true)
		else:
			ok_all = false
			queue.append(queue.pop_front())
			Audio.say_generic("g_wrong_%d" % (randi() % 3), true)
			if room and not (room.kind in ["range", "evidence"]):
				why_l.text += "\n\n[color=#ff7a6e]The uplink tripped an alarm. Hostiles inbound. Come back when it's clear.[/color]"
	else:
		Audio.say_generic("g_right_%d" % (randi() % 4) if ok else "g_wrong_%d" % (randi() % 3), true)
	cont_b.grab_focus()

func _continue() -> void:
	if not answered: return
	if not single.is_empty():
		_close(); cb.call(last_ok); return
	if not last_ok:
		_close(); cb.call(false); return
	if queue.is_empty():
		_finish(); return
	_next()

func _finish() -> void:
	_close()
	cb.call(ok_all)

func _close() -> void:
	main.close_overlay()

func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey) or not e.pressed or e.echo: return
	var k := (e as InputEventKey).keycode
	if not answered:
		if k >= KEY_1 and k <= KEY_4:
			var i := int(k - KEY_1)
			if i < buttons.size(): _pick(i)
			get_viewport().set_input_as_handled()
		elif k == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_close()
	else:
		if k in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_E]:
			get_viewport().set_input_as_handled()
			_continue()
