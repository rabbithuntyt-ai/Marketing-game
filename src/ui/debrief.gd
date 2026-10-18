class_name Debrief
extends Control
## Mission debrief: grade, stats, XP and rank, and a concept review of every call you got wrong,
## with an option to drill those questions on the spot.

var main: Node
var mi := 0
var stats: Dictionary
var accent: Color
var review: VBoxContainer
var xp_fill: ColorRect
var xp_lbl: Label

const MEDALS := ["BRONZE", "SILVER", "GOLD"]
const MEDAL_COL := [Color(0.8, 0.5, 0.3), Color(0.8, 0.84, 0.88), Color(1.0, 0.8, 0.35)]

static func grade(s: Dictionary) -> int:
	var seen: int = s.get("q_seen", {}).size()
	var acc := float(s.get("q_first_ok", 0)) / maxf(1.0, float(seen))
	var rec := float(s.get("recall_ok", 0)) / maxf(1.0, float(s.get("recall", 0))) if int(s.get("recall", 0)) > 0 else 1.0
	var score := acc * 0.7 + rec * 0.3 - minf(0.15, int(s.get("deaths", 0)) * 0.05)
	if score >= 0.85: return 2
	if score >= 0.6: return 1
	return 0

func _ready() -> void:
	UIKit.full(self)
	var M: Dictionary = Game.missions[mi]
	accent = Color(M["color"])
	var bg := ColorRect.new(); bg.color = Color(0.02, 0.025, 0.03); UIKit.full(bg); add_child(bg)
	var grad := TextureRect.new(); UIKit.full(grad); add_child(grad); grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g := Gradient.new(); g.set_color(0, Color(accent.r, accent.g, accent.b, 0.16)); g.set_color(1, Color(0, 0, 0, 0))
	var gt := GradientTexture2D.new(); gt.gradient = g; gt.fill_from = Vector2(0, 0); gt.fill_to = Vector2(0.8, 0.8); grad.texture = gt
	var medal := grade(stats)
	var root := UIKit.hbox(70); add_child(root); root.position = Vector2(110, 90); root.name = "Root"
	# ---- left column
	var L := UIKit.vbox(8); root.add_child(L); L.custom_minimum_size = Vector2(620, 0)
	L.add_child(UIKit.label(("FINAL MISSION" if M.get("final", false) else "MISSION %d" % (mi + 1)) + "  ·  COMPLETE", UIKit.mono(17), accent))
	L.add_child(UIKit.label(String(M["code"]), UIKit.head(104)))
	var mrow := UIKit.hbox(14); L.add_child(mrow)
	var badge := UIKit.label(MEDALS[medal], UIKit.head(34), Color(0.05, 0.05, 0.06), HORIZONTAL_ALIGNMENT_CENTER)
	var bs := StyleBoxFlat.new(); bs.bg_color = MEDAL_COL[medal]; bs.content_margin_left = 18; bs.content_margin_right = 18; bs.content_margin_top = 2; bs.content_margin_bottom = 2
	badge.add_theme_stylebox_override("normal", bs); mrow.add_child(badge)
	mrow.add_child(UIKit.label("Grade is based on first-try analysis calls, recall, and survival.", UIKit.body(17), UIKit.DIM))
	L.add_child(UIKit.spacer(18))
	var grid := GridContainer.new(); grid.columns = 2; grid.add_theme_constant_override("h_separation", 50); grid.add_theme_constant_override("v_separation", 8); L.add_child(grid)
	var seen: int = stats.get("q_seen", {}).size()
	var acc_shots := float(stats.get("hits", 0)) / maxf(1.0, float(stats.get("shots", 0)))
	var rows := [
		["Analysis calls right first time", "%d / %d" % [int(stats.get("q_first_ok", 0)), seen]],
		["Recall checks", "%d / %d" % [int(stats.get("recall_ok", 0)), int(stats.get("recall", 0))]],
		["Intel recovered", str(int(stats.get("intel", 0)))],
		["Time", "%d:%02d" % [int(stats.get("time", 0.0)) / 60, int(stats.get("time", 0.0)) % 60]],
		["Hostiles neutralised", str(int(stats.get("kills", 0)))],
		["Headshots", str(int(stats.get("heads", 0)))],
		["Accuracy", "%d%%" % int(acc_shots * 100.0)],
		["Deaths", str(int(stats.get("deaths", 0)))],
	]
	for r in rows:
		grid.add_child(UIKit.label(r[0], UIKit.body(22), UIKit.DIM))
		grid.add_child(UIKit.label(r[1], UIKit.head(28)))
	L.add_child(UIKit.spacer(24))
	var xp: int = int(Game.save["xp"])
	var rk := Game.rank_of(xp)
	var nxt: Array = []
	for k in Game.RANKS:
		if k[0] > xp: nxt = k; break
	xp_lbl = UIKit.label("", UIKit.mono(16), UIKit.GOLD); L.add_child(xp_lbl)
	xp_lbl.text = "RANK  ·  %s    +%d XP THIS MISSION" % [String(rk[1]).to_upper(), int(stats.get("xp", 0))]
	var bar := ColorRect.new(); bar.color = Color(1, 1, 1, 0.12); bar.custom_minimum_size = Vector2(560, 6); L.add_child(bar)
	xp_fill = ColorRect.new(); xp_fill.color = UIKit.GOLD; bar.add_child(xp_fill); xp_fill.size = Vector2(0, 6)
	var f := 1.0 if nxt.is_empty() else float(xp - int(rk[0])) / float(int(nxt[0]) - int(rk[0]))
	create_tween().tween_property(xp_fill, "size:x", 560.0 * f, 1.4).set_delay(0.6).set_trans(Tween.TRANS_CUBIC)
	if not nxt.is_empty(): L.add_child(UIKit.label("%d XP to %s" % [int(nxt[0]) - xp, nxt[1]], UIKit.body(17), UIKit.DIM))
	L.add_child(UIKit.spacer(30))
	var btns := UIKit.vbox(2); L.add_child(btns)
	var last := mi >= Game.missions.size() - 1
	var nb := UIKit.button("Roll credits" if last else "Next mission", accent, 34); btns.add_child(nb)
	nb.pressed.connect(func():
		if last: main.show_menu("credits")
		else: main.start_mission(mi + 1))
	var rb := UIKit.button("Replay mission", accent, 26); btns.add_child(rb); rb.pressed.connect(func(): main.start_mission(mi))
	var qb := UIKit.button("Main menu", accent, 26); btns.add_child(qb); qb.pressed.connect(func(): main.show_menu())
	nb.call_deferred("grab_focus")
	# ---- right column: concept review
	var R := UIKit.vbox(10); root.add_child(R); R.custom_minimum_size = Vector2(900, 0)
	R.add_child(UIKit.label("CONCEPT REVIEW  ·  " + Game.chapter_tag(M), UIKit.mono(16), accent))
	var sc := ScrollContainer.new(); sc.custom_minimum_size = Vector2(900, 780); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; R.add_child(sc)
	review = UIKit.vbox(14); review.custom_minimum_size = Vector2(880, 0); sc.add_child(review)
	_fill_review()
	# music + VO
	Audio.music(M["music"].get("ending", "home") if M.get("final", false) else "calm_before", 2.5, -2.0)
	Audio.ambience("", -40.0)
	await get_tree().create_timer(1.0).timeout
	if is_inside_tree(): Audio.say_lines(M.get("debrief", []), String(M["id"]))
	if is_inside_tree(): Audio.say_generic(["g_bronze", "g_silver", "g_gold"][medal])

func _fill_review() -> void:
	for c in review.get_children(): c.queue_free()
	var missed: Array = stats.get("missed", [])
	var still: Array = missed.filter(func(k): return Game.save["missed"].has(k) and not Game.q_data(k).is_empty())
	if missed.is_empty():
		review.add_child(UIKit.label("Clean sheet. Every analysis call right first time.", UIKit.head(30), UIKit.GREEN))
	else:
		var hdr := UIKit.hbox(14); review.add_child(hdr)
		hdr.add_child(UIKit.label("%d call%s to revisit" % [still.size(), "" if still.size() == 1 else "s"] if not still.is_empty() else "All revisited. They'll still come back as recall later.", UIKit.head(30), UIKit.TEXT if not still.is_empty() else UIKit.GREEN))
		if not still.is_empty():
			var pb := UIKit.small_button("Drill these now", accent); hdr.add_child(pb)
			pb.pressed.connect(func():
				var q: Array = still.duplicate()
				main.open_terminal(null, q, func(_ok): _fill_review()))
		for k in missed:
			var ks := String(k)
			if ks.contains(":") and Game.q_data(ks).is_empty():
				var tag := ks.substr(0, ks.find(":"))
				var parts := ks.substr(ks.find(":") + 1).split("|")
				var pi := UIKit.panel(Color(1, 1, 1, 0.03), Color(0.4, 0.9, 1.0)); review.add_child(pi)
				var vi := UIKit.vbox(6); pi.add_child(vi)
				vi.add_child(UIKit.label({"icpt": "INTERCEPT", "hvt": "TARGET IDENTIFICATION", "bcg": "BCG CLASSIFICATION", "drill": "RANGE DRILL", "predict": "BEHAVIOUR PREDICTION"}.get(tag, tag.to_upper()), UIKit.mono(13), Color(0.4, 0.9, 1.0)))
				var il := UIKit.label(parts[0], UIKit.body(20), UIKit.DIM); il.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; il.custom_minimum_size = Vector2(820, 0); vi.add_child(il)
				vi.add_child(UIKit.label("→  " + (parts[1] if parts.size() > 1 else ""), UIKit.head(26), UIKit.TEXT))
				continue
			var q := Game.q_data(k)
			if q.is_empty(): continue
			var p := UIKit.panel(Color(1, 1, 1, 0.03), UIKit.RED if Game.save["missed"].has(k) else UIKit.GREEN)
			review.add_child(p)
			var v := UIKit.vbox(6); p.add_child(v)
			var ql := UIKit.label(String(q["q"]), UIKit.body(20), UIKit.DIM); ql.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; ql.custom_minimum_size = Vector2(820, 0); v.add_child(ql)
			v.add_child(UIKit.label("→  " + String(q["a"][0]), UIKit.head(26), UIKit.TEXT))
			var w := UIKit.rich(String(q["why"]), 19); w.custom_minimum_size = Vector2(820, 0); v.add_child(w)
	review.add_child(UIKit.spacer(10))
	review.add_child(UIKit.label("KEY TERMS FROM THIS CHAPTER", UIKit.mono(15), UIKit.DIM))
	var M: Dictionary = Game.missions[mi]
	var terms: Array = []
	for R in M["rooms"]:
		for I in R.get("intel", []):
			var bb: String = I["bb"]
			var rx := RegEx.new(); rx.compile("\\[b\\]([^\\[]{3,60})\\[/b\\]")
			for m in rx.search_all(bb):
				var t := m.get_string(1).strip_edges().trim_suffix(":").trim_suffix(".")
				if not terms.has(t): terms.append(t)
	var flow := HFlowContainer.new(); flow.custom_minimum_size = Vector2(860, 0); flow.add_theme_constant_override("h_separation", 8); flow.add_theme_constant_override("v_separation", 8); review.add_child(flow)
	for t in terms:
		var l := UIKit.label(t, UIKit.body(17), UIKit.TEXT)
		var s := StyleBoxFlat.new(); s.bg_color = Color(1, 1, 1, 0.06); s.content_margin_left = 10; s.content_margin_right = 10; s.content_margin_top = 3; s.content_margin_bottom = 3; s.set_corner_radius_all(2)
		l.add_theme_stylebox_override("normal", s); flow.add_child(l)

func _process(_dt: float) -> void:
	var r: Control = get_node("Root")
	var vs := get_viewport_rect().size
	r.position = Vector2(maxf(60.0, (vs.x - r.size.x) * 0.5), maxf(40.0, (vs.y - r.size.y) * 0.5))
