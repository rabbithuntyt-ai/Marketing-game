class_name EvidenceUI
extends Control
## The mole hunt, run as a marketing research project: each correct methodological call clears a suspect.

var main: Node
var ev: Dictionary
var cb: Callable
var step := 0
var cards: Array = []
var accent := Color(0.75, 0.65, 1.0)
var q_l: Label
var ans_box: VBoxContainer
var say_l: Label
var cont_b: Button
var order: Array = []
var answered := false
var panel: PanelContainer
var step_l: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIKit.full(self)
	add_child(Blur.make(0.82))
	panel = UIKit.panel(UIKit.BG_SOLID, accent); add_child(panel)
	var v := UIKit.vbox(14); panel.add_child(v)
	var top := UIKit.hbox(10); v.add_child(top)
	top.add_child(UIKit.label("CASE FILE  ·  THE LEDGER LEAK", UIKit.mono(15), accent))
	var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(sp)
	step_l = UIKit.label("", UIKit.mono(15), UIKit.DIM); top.add_child(step_l)
	v.add_child(UIKit.label("The marketing research process: define the problem, plan the research, collect and analyse, report.", UIKit.body(18), UIKit.DIM))
	var row := UIKit.hbox(14); v.add_child(row)
	for s in ev["suspects"]:
		var c := _card(s); row.add_child(c); cards.append(c)
	v.add_child(UIKit.rule())
	var mr := UIKit.label("DR. NADIA MARR", UIKit.mono(14), Color(0.5, 0.82, 1.0)); v.add_child(mr)
	q_l = UIKit.label("", UIKit.body(28)); q_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; q_l.custom_minimum_size = Vector2(1100, 0); v.add_child(q_l)
	ans_box = UIKit.vbox(8); v.add_child(ans_box)
	say_l = UIKit.label("", UIKit.body(22), UIKit.GREEN); say_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; say_l.custom_minimum_size = Vector2(1100, 0); v.add_child(say_l)
	var crow := UIKit.hbox(12); v.add_child(crow)
	cont_b = UIKit.small_button("Continue", accent); crow.add_child(cont_b); cont_b.pressed.connect(_continue); cont_b.visible = false
	modulate.a = 0.0; create_tween().tween_property(self, "modulate:a", 1.0, 0.2)
	_show_step()

func _card(s: Dictionary) -> Control:
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new(); st.bg_color = Color(0.86, 0.85, 0.8); st.content_margin_left = 14; st.content_margin_right = 14; st.content_margin_top = 12; st.content_margin_bottom = 12
	st.shadow_color = Color(0, 0, 0, 0.4); st.shadow_size = 8
	p.add_theme_stylebox_override("panel", st)
	p.custom_minimum_size = Vector2(206, 150)
	var v := UIKit.vbox(4); p.add_child(v)
	var pic := ColorRect.new(); pic.color = Color(0.2, 0.21, 0.23); pic.custom_minimum_size = Vector2(0, 54); v.add_child(pic)
	var ini := UIKit.label(_initials(String(s["name"])), UIKit.head(34), Color(0.75, 0.76, 0.78), HORIZONTAL_ALIGNMENT_CENTER); ini.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); pic.add_child(ini)
	var n := UIKit.label(String(s["name"]), UIKit.body(19), Color(0.08, 0.08, 0.09)); n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(n)
	var r := UIKit.label(String(s["role"]), UIKit.mono(12), Color(0.3, 0.3, 0.32)); r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(r)
	var stamp := UIKit.label("", UIKit.head(40), UIKit.RED, HORIZONTAL_ALIGNMENT_CENTER)
	stamp.name = "Stamp"; stamp.rotation = -0.3; stamp.position = Vector2(18, 54); stamp.modulate.a = 0.0
	p.add_child(stamp)
	return p

func _initials(n: String) -> String:
	var parts := n.replace(".", "").split(" ")
	var out := ""
	for i in range(maxi(0, parts.size() - 2), parts.size()): out += parts[i].substr(0, 1)
	return out

func _stamp(i: int, text: String, col: Color) -> void:
	if i < 0 or i >= cards.size(): return
	var c: Control = cards[i]
	var s: Label = c.get_node("Stamp")
	s.text = text; s.add_theme_color_override("font_color", col)
	s.pivot_offset = Vector2(80, 20)
	s.scale = Vector2(2.2, 2.2)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(s, "modulate:a", 0.9, 0.12); tw.tween_property(s, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	if text == "CLEARED": c.modulate = Color(0.75, 0.75, 0.75)
	Audio.play2d("tps_hit", -6.0, 0.05, "UI")

func _show_step() -> void:
	answered = false; cont_b.visible = false; say_l.text = ""
	var steps: Array = ev["steps"]
	var s: Dictionary = steps[step]
	step_l.text = "STEP %d / %d" % [step + 1, steps.size()]
	q_l.text = String(s["prompt"])
	for c in ans_box.get_children(): c.queue_free()
	var a: Array = s["a"]
	order = range(a.size()); order.shuffle()
	for i in order.size():
		var b := UIKit.small_button("%d   %s" % [i + 1, a[order[i]]], accent)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT; b.custom_minimum_size = Vector2(1100, 0)
		b.add_theme_font_override("font", UIKit.font("Barlow-SemiBold")); b.add_theme_font_size_override("font_size", 23)
		ans_box.add_child(b); b.pressed.connect(_pick.bind(i))

func _pick(i: int) -> void:
	if answered: return
	var s: Dictionary = ev["steps"][step]
	if order[i] == 0:
		answered = true
		for b in ans_box.get_children(): (b as Button).disabled = true
		(ans_box.get_child(i) as Button).modulate = UIKit.GREEN
		say_l.text = String(s["say"]); say_l.add_theme_color_override("font_color", UIKit.GREEN)
		Audio.say("MARR", String(s["say"]), String(s.get("vo", "")), Audio.voice_mission, true)
		var el = s.get("elim")
		if el != null:
			if int(el) >= 0: _stamp(int(el), "CLEARED", Color(0.15, 0.5, 0.25))
			else: _stamp(cards.size() - 1, "THE MOLE", UIKit.RED)
		Game.add_xp(60, "RESEARCH CALL")
		cont_b.visible = true; cont_b.grab_focus()
	else:
		var b: Button = ans_box.get_child(i); b.disabled = true; b.modulate = Color(1, 0.5, 0.45, 0.6)
		say_l.text = "Not that. Think about what the method actually does, then try again."
		say_l.add_theme_color_override("font_color", UIKit.RED)
		Audio.say_generic("g_wrong_%d" % (randi() % 3), true)
		panel.self_modulate = Color(1.6, 0.6, 0.6)
		create_tween().tween_property(panel, "self_modulate", Color.WHITE, 0.4)

func _continue() -> void:
	step += 1
	if step >= ev["steps"].size():
		main.close_overlay(); cb.call(); return
	_show_step()

func _process(_dt: float) -> void:
	var vs := get_viewport_rect().size
	panel.reset_size()
	panel.position = Vector2(vs.x * 0.5 - panel.size.x * 0.5, vs.y * 0.5 - panel.size.y * 0.5)

func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey) or not e.pressed or e.echo: return
	var k := (e as InputEventKey).keycode
	if not answered and k >= KEY_1 and k <= KEY_3:
		get_viewport().set_input_as_handled(); _pick(int(k - KEY_1))
	elif answered and k in [KEY_SPACE, KEY_ENTER, KEY_E]:
		get_viewport().set_input_as_handled(); _continue()
	elif k == KEY_ESCAPE and not answered and step == 0:
		get_viewport().set_input_as_handled(); main.close_overlay()
