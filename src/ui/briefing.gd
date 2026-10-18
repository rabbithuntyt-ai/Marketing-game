class_name BriefingUI
extends Control
## Mission briefing: title sequence, then each briefing line with voice-over, transcript and a matching
## visual (map, dossier or document). SPACE advances, ESC skips.

var main: Node
var mi := 0
var M: Dictionary
var accent: Color
var lines: Array = []
var idx := -1
var vis: BriefVis
var title_box: VBoxContainer
var header: VBoxContainer
var who_l: Label
var role_l: Label
var text_l: Label
var log_box: VBoxContainer
var dots: HBoxContainer
var hint: Label
var waiting := false
var t := 0.0
var started := false
var finished := false

func _ready() -> void:
	UIKit.full(self)
	M = Game.missions[mi]; accent = Color(M["color"]); lines = M["briefing"]
	var bg := ColorRect.new(); bg.color = Color(0.018, 0.022, 0.026); UIKit.full(bg); add_child(bg)
	var glow := TextureRect.new(); UIKit.full(glow); glow.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(glow)
	var g := Gradient.new(); g.set_color(0, Color(accent.r, accent.g, accent.b, 0.1)); g.set_color(1, Color(0, 0, 0, 0))
	var gt := GradientTexture2D.new(); gt.gradient = g; gt.fill = GradientTexture2D.FILL_RADIAL; gt.fill_from = Vector2(0.3, 0.4); gt.fill_to = Vector2(1.1, 1.0); glow.texture = gt
	# header
	header = UIKit.vbox(2); add_child(header); header.modulate.a = 0.0
	header.add_child(UIKit.label("LEDGER  ·  OPERATION BRIEFING  ·  " + ("FINAL MISSION" if M.get("final", false) else "MISSION %d" % (mi + 1)), UIKit.mono(15), accent))
	header.add_child(UIKit.label(String(M["code"]) + "   ·   " + String(M["loc"]), UIKit.head(34)))
	# visual
	vis = BriefVis.new(); add_child(vis); vis.modulate.a = 0.0
	# right column
	var col := UIKit.vbox(10); col.name = "Col"; add_child(col); col.modulate.a = 0.0
	who_l = UIKit.label("", UIKit.head(34)); col.add_child(who_l)
	role_l = UIKit.label("", UIKit.mono(14), UIKit.DIM); col.add_child(role_l)
	col.add_child(UIKit.rule(accent, 2))
	text_l = UIKit.label("", UIKit.body(27)); text_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; col.add_child(text_l)
	col.add_child(UIKit.spacer(14))
	log_box = UIKit.vbox(8); col.add_child(log_box)
	dots = UIKit.hbox(6); add_child(dots)
	for i in lines.size():
		var d := ColorRect.new(); d.custom_minimum_size = Vector2(26, 3); d.color = Color(1, 1, 1, 0.15); dots.add_child(d)
	hint = UIKit.label("SPACE  next      ESC  skip briefing", UIKit.mono(14), UIKit.DIM); add_child(hint)
	# title sequence
	title_box = UIKit.vbox(4); add_child(title_box)
	title_box.add_child(UIKit.label(("FINAL MISSION" if M.get("final", false) else "MISSION %d" % (mi + 1)), UIKit.mono(18), accent, HORIZONTAL_ALIGNMENT_CENTER))
	title_box.add_child(UIKit.label(String(M["code"]), UIKit.head(150), UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	title_box.add_child(UIKit.label("%s   ·   %s" % [String(M["loc"]), String(M["time"])], UIKit.body(26), UIKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	title_box.add_child(UIKit.spacer(10))
	title_box.add_child(UIKit.label(Game.chapter_tag(M), UIKit.mono(16), UIKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	title_box.modulate.a = 0.0
	Audio.music(M["music"].get("tension", "ominosity"), 2.0, -4.0)
	Audio.ambience("", -40.0)
	Audio.voice_mission = String(M["id"])
	Audio.line_finished.connect(_on_line_done)
	var tw := create_tween()
	tw.tween_property(title_box, "modulate:a", 1.0, 1.2).set_delay(0.3)
	tw.tween_interval(2.4)
	tw.tween_property(title_box, "modulate:a", 0.0, 0.7)
	tw.tween_callback(_start)

func _start() -> void:
	if started: return
	started = true
	title_box.visible = false
	var tw := create_tween().set_parallel(true)
	for c in [header, vis, get_node("Col")]: tw.tween_property(c, "modulate:a", 1.0, 0.6)
	_advance()

func _layout() -> void:
	var vs := get_viewport_rect().size
	var pad := 70.0
	header.position = Vector2(pad, 52)
	var vw := vs.x * 0.6; var vh := minf(vw * 0.6, vs.y - 260)
	vis.position = Vector2(pad, 150); vis.size = Vector2(vw, vh)
	var col: Control = get_node("Col")
	col.position = Vector2(pad + vw + 50, 150); col.custom_minimum_size.x = vs.x - (pad + vw + 50) - pad
	text_l.custom_minimum_size.x = col.custom_minimum_size.x
	dots.position = Vector2(pad, 150 + vh + 30)
	hint.position = Vector2(vs.x - pad - 330, vs.y - 60)
	title_box.reset_size(); title_box.position = vs * 0.5 - title_box.size * 0.5

func _process(dt: float) -> void:
	t += dt
	_layout()

func _advance() -> void:
	if finished: return
	idx += 1
	if idx >= lines.size():
		_finish(); return
	var l: Dictionary = lines[idx]
	var sp := Game.speaker(String(l["spk"]))
	who_l.text = String(sp.get("name", l["spk"]))
	role_l.text = String(sp.get("role", "")).to_upper()
	text_l.text = String(l["text"])
	text_l.modulate.a = 0.0; create_tween().tween_property(text_l, "modulate:a", 1.0, 0.25)
	vis.set_vis(String(l.get("vis", "map:canada")), accent)
	for i in dots.get_child_count(): (dots.get_child(i) as ColorRect).color = accent if i <= idx else Color(1, 1, 1, 0.15)
	if idx > 0:
		var prev: Dictionary = lines[idx - 1]
		var pl := UIKit.label(String(prev["text"]), UIKit.body(18), Color(1, 1, 1, 0.35)); pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pl.custom_minimum_size.x = text_l.custom_minimum_size.x
		log_box.add_child(pl); log_box.move_child(pl, 0)
		while log_box.get_child_count() > 3: log_box.get_child(log_box.get_child_count() - 1).free()
	waiting = true
	Audio.say(String(l["spk"]), String(l["text"]), String(l.get("vo", "")), String(M["id"]), true)

func _on_line_done() -> void:
	if not waiting or finished: return
	waiting = false
	await get_tree().create_timer(0.35).timeout
	if is_inside_tree() and not waiting: _advance()

func _finish() -> void:
	if finished: return
	finished = true
	Audio.line_finished.disconnect(_on_line_done)
	Audio.clear_dialogue()
	main.briefing_done(mi)

func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey or e is InputEventMouseButton) or not e.pressed: return
	if e is InputEventKey and e.echo: return
	var key := (e as InputEventKey).keycode if e is InputEventKey else KEY_SPACE
	if key == KEY_ESCAPE:
		get_viewport().set_input_as_handled(); _finish()
	elif key in [KEY_SPACE, KEY_ENTER]:
		get_viewport().set_input_as_handled()
		if not started: _start()
		else:
			waiting = false
			Audio.skip_line()
			_advance()
