class_name MenuUI
extends Control
## Main menu over the live 3D backdrop: continue, campaign, intel archive, settings, credits, quit.

var main: Node
var accent := Color(1.0, 0.68, 0.28)
var left: VBoxContainer
var page: Control
var page_name := ""
var btns := {}
var sel_mi := 0

func _ready() -> void:
	UIKit.full(self)
	var shade := TextureRect.new(); UIKit.full(shade); shade.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(shade)
	var g := Gradient.new(); g.set_color(0, Color(0, 0, 0, 0.88)); g.add_point(0.45, Color(0, 0, 0, 0.55)); g.set_color(g.get_point_count() - 1, Color(0, 0, 0, 0.0))
	var gt := GradientTexture2D.new(); gt.gradient = g; gt.fill_from = Vector2(0, 0.5); gt.fill_to = Vector2(1, 0.5); shade.texture = gt
	left = UIKit.vbox(4); add_child(left); left.name = "Left"
	left.add_child(UIKit.label("LEDGER PRESENTS", UIKit.mono(15), accent))
	var t1 := UIKit.label("OPERATION", UIKit.head(40), UIKit.DIM); left.add_child(t1)
	var t2 := UIKit.label("VALUE CHAIN", UIKit.head(108)); left.add_child(t2)
	t2.add_theme_constant_override("line_spacing", -20)
	left.add_child(UIKit.label("A tactical thriller in seven chapters of marketing", UIKit.body(20), UIKit.DIM))
	left.add_child(UIKit.spacer(46))
	var cp = Game.save.get("checkpoint")
	var can_continue: bool = cp != null or int(Game.save["unlocked"]) > 0
	if can_continue:
		var sub := ""
		if cp != null: sub = "  ·  %s, sector %d" % [String(Game.missions[int(cp["m"])]["code"]), int(cp["r"]) + 1]
		else: sub = "  ·  " + String(Game.missions[mini(int(Game.save["unlocked"]), Game.missions.size() - 1)]["code"])
		_btn("continue", "Continue", _continue, sub)
	_btn("campaign", "Campaign" if can_continue else "New operation", func(): open_page("campaign"))
	_btn("archive", "Intel archive", func(): open_page("archive"))
	_btn("settings", "Settings", func(): open_page("settings"))
	_btn("credits", "Credits", func(): open_page("credits"))
	_btn("quit", "Quit", func(): get_tree().quit())
	left.add_child(UIKit.spacer(30))
	var xp: int = int(Game.save["xp"])
	left.add_child(UIKit.label("%s  ·  %d XP" % [String(Game.rank_of(xp)[1]).to_upper(), xp], UIKit.mono(14), UIKit.DIM))
	var ver := UIKit.label("v1.0  ·  Kotler, Armstrong, Trifts & Buchwitz, Marketing: An Introduction (7th Cdn ed.), Ch. 1–7", UIKit.mono(12), Color(1, 1, 1, 0.3)); ver.name = "Ver"; add_child(ver)
	page = Control.new(); page.name = "Page"; add_child(page)
	(btns.values()[0] as Button).call_deferred("grab_focus")
	left.modulate.a = 0.0; create_tween().tween_property(left, "modulate:a", 1.0, 1.0).set_delay(0.3)

func _btn(key: String, text: String, cb: Callable, sub := "") -> void:
	var b := UIKit.button(text, accent, 36); left.add_child(b); b.pressed.connect(cb); btns[key] = b
	if sub != "":
		b.text = text.to_upper() + sub.to_upper()
		b.add_theme_font_size_override("font_size", 32)

func _process(_dt: float) -> void:
	var vs := get_viewport_rect().size
	left.position = Vector2(110, vs.y * 0.5 - left.size.y * 0.5 - 20)
	var ver: Control = get_node("Ver"); ver.position = Vector2(110, vs.y - 44)
	page.position = Vector2(maxf(560.0, vs.x * 0.36), 70); page.size = Vector2(vs.x - page.position.x - 70, vs.y - 140)

func _continue() -> void:
	var cp = Game.save.get("checkpoint")
	if cp != null: main.start_mission(int(cp["m"]), int(cp["r"]))
	else: main.start_mission(mini(int(Game.save["unlocked"]), Game.missions.size() - 1))

func open_page(n: String) -> void:
	for c in page.get_children(): c.queue_free()
	if page_name == n: page_name = ""; return
	page_name = n
	var p := UIKit.panel(Color(0.03, 0.035, 0.04, 0.92), accent); page.add_child(p)
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v := UIKit.vbox(14); p.add_child(v)
	match n:
		"campaign": _campaign(v)
		"archive": _archive(v)
		"settings":
			v.add_child(UIKit.label("SETTINGS", UIKit.mono(15), accent))
			var sp := SettingsPanel.new(); sp.accent = accent; v.add_child(sp)
		"credits": _credits(v)
	p.modulate.a = 0.0; p.position.x += 30
	var tw := create_tween().set_parallel(true)
	tw.tween_property(p, "modulate:a", 1.0, 0.25); tw.tween_property(p, "position:x", p.position.x - 30, 0.25).set_trans(Tween.TRANS_CUBIC)

# ---------------------------------------------------------------- campaign
func _campaign(v: VBoxContainer) -> void:
	v.add_child(UIKit.label("CAMPAIGN  ·  EIGHT MISSIONS  ·  CHAPTERS 1–7", UIKit.mono(15), accent))
	var split := UIKit.hbox(30); v.add_child(split); split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var list := UIKit.vbox(2); split.add_child(list); list.custom_minimum_size = Vector2(380, 0)
	var detail := UIKit.vbox(10); split.add_child(detail); detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var unlocked: int = int(Game.save["unlocked"])
	sel_mi = clampi(unlocked, 0, Game.missions.size() - 1)
	var show := func(mi: int):
		sel_mi = mi
		for c in detail.get_children(): c.queue_free()
		_detail(detail, mi)
	for mi in Game.missions.size():
		var M: Dictionary = Game.missions[mi]
		var locked := mi > unlocked
		var medal: int = int(Game.save["medals"].get(str(mi), -1))
		var b := UIKit.button("", Color(M["color"]), 26)
		b.text = ("%02d   %s" % [mi + 1, String(M["code"])]) + ("" if not locked else "   ·  LOCKED")
		if medal >= 0: b.text += "   " + ["◆ BRONZE", "◆ SILVER", "◆ GOLD"][medal]
		b.disabled = locked
		list.add_child(b)
		b.pressed.connect(show.bind(mi))
		b.focus_entered.connect(show.bind(mi))
		if not locked: b.mouse_entered.connect(show.bind(mi))
	show.call(sel_mi)

func _detail(d: VBoxContainer, mi: int) -> void:
	var M: Dictionary = Game.missions[mi]
	var col := Color(M["color"])
	d.add_child(UIKit.label(("FINAL MISSION" if M.get("final", false) else "MISSION %d" % (mi + 1)), UIKit.mono(15), col))
	d.add_child(UIKit.label(String(M["code"]), UIKit.head(76)))
	var ll := UIKit.label("%s  ·  %s" % [String(M["loc"]), String(M["time"])], UIKit.body(22), UIKit.DIM); ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; ll.custom_minimum_size = Vector2(420, 0); d.add_child(ll)
	d.add_child(UIKit.rule(col, 2))
	d.add_child(UIKit.label("CHAPTER %s" % str(M["ch"]), UIKit.mono(14), UIKit.DIM))
	var cl := UIKit.label(String(M["chname"]), UIKit.head(34)); cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; cl.custom_minimum_size = Vector2(420, 0); d.add_child(cl)
	var topics: Array = []
	for R in M["rooms"]:
		for I in R.get("intel", []): topics.append(String(I["t"]))
	var tl := UIKit.label("  ·  ".join(topics.slice(0, 7)), UIKit.body(18), UIKit.DIM); tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; tl.custom_minimum_size = Vector2(420, 0); d.add_child(tl)
	var kinds := {}
	for R in M["rooms"]: kinds[String(R["kind"])] = true
	var ops := {"combat": "Assault", "range": "Training range", "hvt": "Identify the target", "plant": "Sabotage", "defend": "Hold the line", "stealth": "Stealth", "tail": "Surveillance", "sniper": "Overwatch", "evidence": "Investigation", "escape": "Escape", "holdout": "Holdout", "rescue": "Rescue", "ambush": "Ambush", "boss": "Boss fight"}
	var kl: Array = []
	for k in kinds.keys(): kl.append(ops.get(k, k))
	d.add_child(UIKit.label("  /  ".join(kl).to_upper(), UIKit.mono(14), col))
	d.add_child(UIKit.label("%d sectors  ·  %d analysis calls" % [M["rooms"].size(), M["rooms"].reduce(func(a, R): return a + R.get("calls", []).size(), 0)], UIKit.mono(14), UIKit.DIM))
	d.add_child(UIKit.spacer(10))
	var start := UIKit.small_button("Start mission", col); d.add_child(start); start.pressed.connect(func(): main.start_mission(mi))
	start.custom_minimum_size = Vector2(260, 0)

# ---------------------------------------------------------------- archive
func _archive(v: VBoxContainer) -> void:
	v.add_child(UIKit.label("INTEL ARCHIVE  ·  EVERYTHING YOU'VE RECOVERED", UIKit.mono(15), accent))
	var tabs := UIKit.hbox(6); v.add_child(tabs)
	var body := Control.new(); body.size_flags_vertical = Control.SIZE_EXPAND_FILL; v.add_child(body)
	var intel_b := UIKit.small_button("Intel files", accent); tabs.add_child(intel_b)
	var weak_b := UIKit.small_button("Weak spots", accent); tabs.add_child(weak_b)
	intel_b.pressed.connect(func(): _intel_tab(body))
	weak_b.pressed.connect(func(): _weak_tab(body))
	_intel_tab(body)

func _intel_tab(body: Control) -> void:
	for c in body.get_children(): c.queue_free()
	var split := UIKit.hbox(20); body.add_child(split); split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sc := ScrollContainer.new(); sc.custom_minimum_size = Vector2(400, 0); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; split.add_child(sc)
	var list := UIKit.vbox(2); sc.add_child(list); list.custom_minimum_size = Vector2(380, 0)
	var view := Control.new(); view.size_flags_horizontal = Control.SIZE_EXPAND_FILL; split.add_child(view)
	var show := func(doc: Dictionary, M: Dictionary, ri: int):
		for c in view.get_children(): c.queue_free()
		var iv := IntelView.new(); iv.archive = true; iv.doc = doc; iv.M = M; iv.ri = ri; iv.main = main
		iv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); view.add_child(iv)
	var first = null
	var total := 0; var got := 0
	for mi in Game.missions.size():
		var M: Dictionary = Game.missions[mi]
		list.add_child(UIKit.label("%02d  %s  ·  CH %s" % [mi + 1, String(M["code"]), str(M["ch"])], UIKit.mono(14), Color(M["color"])))
		for ri in M["rooms"].size():
			var intel: Array = M["rooms"][ri].get("intel", [])
			for k in intel.size():
				total += 1
				var have: bool = Game.save["intel"].has("%s-%d-%d" % [M["id"], ri, k])
				if have: got += 1
				var b := UIKit.button(String(intel[k]["t"]) if have else "— not recovered —", Color(M["color"]), 19)
				b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; b.custom_minimum_size = Vector2(370, 0); b.disabled = not have
				list.add_child(b)
				if have:
					b.pressed.connect(show.bind(intel[k], M, ri))
					if first == null: first = [intel[k], M, ri]
	list.add_child(UIKit.spacer(10))
	list.add_child(UIKit.label("%d / %d recovered" % [got, total], UIKit.mono(14), UIKit.DIM))
	if first != null: show.call(first[0], first[1], first[2])
	else:
		var l := UIKit.label("Recovered intel lands here. Every document is a section of the textbook, rewritten as evidence.", UIKit.body(22), UIKit.DIM)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.custom_minimum_size = Vector2(500, 0); view.add_child(l)

func _weak_tab(body: Control) -> void:
	for c in body.get_children(): c.queue_free()
	var v := UIKit.vbox(12); body.add_child(v); v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var keys: Array = Game.save["missed"].keys().filter(func(k): return not Game.q_data(k).is_empty())
	var seen: int = Game.save["seen"].size()
	v.add_child(UIKit.label("%d concept%s to shore up" % [keys.size(), "" if keys.size() == 1 else "s"] if not keys.is_empty() else ("Nothing outstanding." if seen > 0 else "No calls answered yet."), UIKit.head(40)))
	v.add_child(UIKit.label("Every analysis call you miss is logged here and comes back later as a recall check in the field. Clear them here to stay ahead.", UIKit.body(19), UIKit.DIM))
	if keys.is_empty(): return
	var b := UIKit.small_button("Drill all  (%d)" % keys.size(), accent); v.add_child(b); b.custom_minimum_size = Vector2(260, 0)
	b.pressed.connect(func():
		var q: Array = keys.duplicate(); q.shuffle()
		Game.stats = Game.new_stats()
		main.open_terminal(null, q, func(_ok): _weak_tab(body)))
	var sc := ScrollContainer.new(); sc.size_flags_vertical = Control.SIZE_EXPAND_FILL; sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; v.add_child(sc)
	var list := UIKit.vbox(10); sc.add_child(list)
	for k in keys:
		var q := Game.q_data(k)
		var mi := Game.mi_of(k)
		var p := UIKit.panel(Color(1, 1, 1, 0.03), Color(Game.missions[mi]["color"])); list.add_child(p)
		var pv := UIKit.vbox(4); p.add_child(pv)
		pv.add_child(UIKit.label("MISSION %d  ·  CH %s  ·  missed %d×" % [mi + 1, str(Game.missions[mi]["ch"]), int(Game.save["missed"][k])], UIKit.mono(13), UIKit.DIM))
		var ql := UIKit.label(String(q["q"]), UIKit.body(19)); ql.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; ql.custom_minimum_size = Vector2(900, 0); pv.add_child(ql)

# ---------------------------------------------------------------- credits
func _credits(v: VBoxContainer) -> void:
	v.add_child(UIKit.label("CREDITS", UIKit.mono(15), accent))
	var sc := ScrollContainer.new(); sc.size_flags_vertical = Control.SIZE_EXPAND_FILL; sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; v.add_child(sc)
	var list := UIKit.vbox(6); sc.add_child(list); list.custom_minimum_size = Vector2(900, 0)
	list.add_child(UIKit.label("OPERATION VALUE CHAIN", UIKit.head(56)))
	list.add_child(UIKit.spacer(10))
	for c in Game.content.get("credits", []):
		list.add_child(UIKit.label(String(c["h"]).to_upper(), UIKit.mono(15), accent))
		for l in c["l"]:
			var ll := UIKit.label(String(l), UIKit.body(20)); ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; ll.custom_minimum_size = Vector2(880, 0); list.add_child(ll)
		list.add_child(UIKit.spacer(12))
	list.add_child(UIKit.label("PER-FILE AUDIO CREDITS", UIKit.mono(15), accent))
	var f := FileAccess.open("res://data/CREDITS_AUDIO.txt", FileAccess.READ)
	if f:
		var txt := f.get_as_text()
		var ll2 := UIKit.label(txt, UIKit.mono(13), UIKit.DIM); ll2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; ll2.custom_minimum_size = Vector2(880, 0); list.add_child(ll2)
	list.add_child(UIKit.spacer(20))
	list.add_child(UIKit.label("Thank you for playing.", UIKit.head(30)))

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and (e as InputEventKey).keycode == KEY_ESCAPE and page_name != "":
		get_viewport().set_input_as_handled()
		for c in page.get_children(): c.queue_free()
		page_name = ""
