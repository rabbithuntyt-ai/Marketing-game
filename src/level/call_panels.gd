class_name CallPanels
extends Node3D
## Routing consoles: Marr's analysis calls answered in the world instead of at a menu. The question is
## on the big wall screen and the HUD; each lettered console carries one answer. Walk to the console
## you'd route the data to and press E. Same questions, explanations, recall and scoring as the uplink;
## a wrong route trips the alarm (reinforcements) and the question comes back later.

var room: Room
var m: Mission
var screen_lbl: Label3D
var consoles: Array = []     # {letter, label, pos, light}
var active := false
var cur_key := ""
var cur_recall := false
var cur_q: Dictionary
var order: Array = []
var asked := 0
var total := 0
var ok_all := true
var cool := 0.0

func setup(r: Room, sec: Sector, screen: Array, spots: Array) -> void:
	room = r
	var b := sec.b
	var sx: Transform3D = sec.XF(screen[0], screen[1], screen[2], 0.0)
	var frame := b.box(sec.geo, Vector3(5.2, 2.9, 0.12), sx.origin + Vector3(0, 2.6, 0), Mats.pbr("gunmetal", 1.0), false); frame.basis = sx.basis
	var pane := b.box(sec.geo, Vector3(5.0, 2.7, 0.04), sx.origin + Vector3(0, 2.6, 0) + sx.basis.z * 0.07, Mats.flat(Color(0.015, 0.02, 0.03), 0.2), false, false); pane.basis = sx.basis
	b.box(sec.geo, Vector3(5.0, 0.06, 0.05), sx.origin + Vector3(0, 3.92, 0) + sx.basis.z * 0.09, Mats.glow(Color(0.5, 0.82, 1.0), 3.0), false, false).basis = sx.basis
	screen_lbl = Label3D.new(); add_child(screen_lbl)
	screen_lbl.global_transform = Transform3D(sx.basis, sx.origin + Vector3(0, 2.75, 0) + sx.basis.z * 0.1)
	screen_lbl.font = load("res://assets/fonts/Barlow-Medium.ttf"); screen_lbl.font_size = 44; screen_lbl.pixel_size = 0.004
	screen_lbl.width = 1150; screen_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; screen_lbl.modulate = Color(0.85, 0.93, 1.0) * 1.5
	screen_lbl.text = "ROUTING OFFLINE"
	for i in spots.size():
		var s: Array = spots[i]
		var t: Transform3D = sec.XF(s[0], s[1], s[2], 0.0)
		var body := b.box(sec.geo, Vector3(1.1, 1.0, 0.7), t.origin + Vector3(0, 0.5, 0), Mats.pbr("gunmetal", 1.0)); body.basis = t.basis
		var scr := b.box(sec.geo, Vector3(0.95, 0.6, 0.04), t.origin + Vector3(0, 1.25, 0) + t.basis.z * 0.2, Mats.glow(Color(0.12, 0.3, 0.5), 1.2), false, false); scr.basis = t.basis * Basis(Vector3.RIGHT, -0.35)
		var letter := Label3D.new(); add_child(letter); letter.font = load("res://assets/fonts/Rajdhani-Bold.ttf"); letter.font_size = 160; letter.pixel_size = 0.004
		letter.global_transform = Transform3D(t.basis, t.origin + Vector3(0, 2.0, 0)); letter.text = "ABCD"[i]; letter.modulate = Color(0.5, 0.82, 1.0) * 1.6
		letter.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		var lab := Label3D.new(); add_child(lab); lab.font = load("res://assets/fonts/Barlow-SemiBold.ttf"); lab.font_size = 22; lab.pixel_size = 0.004
		lab.global_transform = Transform3D(t.basis * Basis(Vector3.RIGHT, -0.35), t.origin + Vector3(0, 1.27, 0) + t.basis.z * 0.23)
		lab.width = 230; lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; lab.modulate = Color(0.9, 0.95, 1.0) * 1.4; lab.text = ""
		var lt := b.omni(r, t.origin + Vector3(0, 1.8, 0) + t.basis.z * 0.6, Color(0.5, 0.82, 1.0), 0.6, 3.5)
		consoles.append({"letter": letter, "label": lab, "pos": t.origin + t.basis.z * 1.1, "light": lt})

func _unlocked() -> bool:
	if room.calls_done or not room.mode.uses_terminal() or not room.mode.has_calls(): return false
	if room.alive_enemies().size() > 0 and room.mode.requires_clear(): return false
	if room.intel.filter(func(i): return is_instance_valid(i)).size() > 0: return false
	return room.mode.terminal_ready()

func _process(dt: float) -> void:
	if m == null or room != m.cur_room: return
	cool -= dt
	if not active and _unlocked(): _begin()
	if active and not _unlocked() and not room.calls_done:
		m.main.hud.call_hide()

func _begin() -> void:
	active = true
	if room.q_queue.is_empty():
		var keys: Array = []
		for k in room.data.get("calls", []).size(): keys.append(Game.q_key(m.mi, room.ri, k))
		var n_rec := int(room.data.get("recall", 0))
		if n_rec == 0 and (m.mi > 0 or room.ri >= 2) and not keys.is_empty(): n_rec = 1
		var rec := Game.recall_items(n_rec, keys, m.mi if not m.M.get("final", false) else 6)
		room.q_queue = keys + rec.map(func(k): return "R:" + k)
	total = room.q_queue.size()
	_show()

func _show() -> void:
	if not is_inside_tree() or room.calls_done: return
	if room.q_queue.is_empty(): _finish(); return
	cur_key = room.q_queue[0]
	cur_recall = cur_key.begins_with("R:")
	var k := cur_key.substr(2) if cur_recall else cur_key
	cur_q = Game.q_data(k)
	if cur_q.is_empty(): room.q_queue.pop_front(); _show(); return
	asked += 1
	var answers: Array = cur_q["a"]
	order = range(answers.size()); order.shuffle()
	var opts: Array = []
	for i in consoles.size():
		var c: Dictionary = consoles[i]
		var txt := String(answers[order[i]]) if i < order.size() else ""
		(c["label"] as Label3D).text = txt
		(c["letter"] as Label3D).visible = i < order.size()
		if i < order.size(): opts.append(txt)
	screen_lbl.text = String(cur_q["q"])
	var head := "ROUTING  ·  CALL %d / %d" % [mini(asked, total), total]
	if cur_recall: head += "  ·  RECALL"
	m.main.hud.call_show(head + "  ·  walk to a console, press E", String(cur_q["q"]), opts)

func interactables() -> Array:
	if not active or room.calls_done or cool > 0.0 or not _unlocked(): return []
	var out: Array = []
	for i in mini(consoles.size(), order.size()):
		out.append({"pos": consoles[i]["pos"], "radius": 1.6, "prompt": "Route to %s  ·  %s" % ["ABCD"[i], String(consoles[i]["label"].text).left(40)], "cb": _pick.bind(i)})
	return out

func _pick(i: int) -> void:
	var ok: bool = order[i] == 0
	var k := cur_key.substr(2) if cur_recall else cur_key
	Game.record_answer(k, ok, cur_recall)
	m.main.hud.call_result(ok, String(cur_q.get("why", "")))
	cool = 1.2
	if ok:
		room.q_queue.pop_front()
		Game.add_xp(75 if cur_recall else 50, "RECALL" if cur_recall else "RIGHT CALL")
		Audio.say_generic("g_right_%d" % (randi() % 4), true)
		Audio.play2d("kenney_weapon_change", -4.0, 0.0, "UI")
	else:
		ok_all = false
		room.q_queue.append(room.q_queue.pop_front())
		Audio.say_generic("g_wrong_%d" % (randi() % 3), true)
		m.on_wrong_answer()
	get_tree().create_timer(5.5).timeout.connect(_show)

func _finish() -> void:
	room.calls_done = true; active = false
	screen_lbl.text = "ROUTING COMPLETE"
	for c in consoles: (c["label"] as Label3D).text = ""
	get_tree().create_timer(3.0).timeout.connect(func(): if is_instance_valid(m): m.main.hud.call_hide())
	Audio.say_generic("g_bonus" if ok_all else "g_right_%d" % (randi() % 4))
	room.mode.on_calls_done()
