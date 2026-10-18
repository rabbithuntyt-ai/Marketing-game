extends ModeBase
## Training range: Marr loads concepts onto pop-up targets. Shoot the right ones (in order if required).

var drills: Array = []
var drill := -1
var state := "idle"
var wait := 0.0
var next_i := 0
var mistakes := 0
var t := 0.0
var targets: Array = []
var board_labels := {}

func setup() -> void:
	drills = r.data.get("drills", [])
	var board: Node3D = r.get_meta("board")
	var mk := func(txt: String, pos: Vector3, size: int, col: Color, font := "Rajdhani-Bold") -> Label3D:
		var l := Label3D.new(); l.text = txt; l.font = load("res://assets/fonts/%s.ttf" % font); l.font_size = size; l.pixel_size = 0.004
		l.modulate = col; l.position = pos + Vector3(0, 0, 0.06); l.shaded = false; board.add_child(l); return l
	board_labels["tag"] = mk.call("CASTELLAN SECURITY · TRAINING FLOOR", Vector3(-3.9, 0.8, 0), 34, Color(m.M["color"]), "IBMPlexMono-Medium")
	board_labels["title"] = mk.call("STAND BY", Vector3(-3.9, 0.25, 0), 110, Color(1, 1, 1))
	board_labels["title"].horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	board_labels["tag"].horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	board_labels["prog"] = mk.call("", Vector3(-3.9, -0.45, 0), 52, Color(0.85, 0.88, 0.9), "Barlow-SemiBold")
	board_labels["prog"].horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	board_labels["mist"] = mk.call("", Vector3(3.9, -0.45, 0), 52, Color(1, 0.45, 0.4), "Barlow-SemiBold")
	board_labels["mist"].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for l in board_labels.values(): (l as Label3D).modulate *= Color(1.8, 1.8, 1.8)

func uses_terminal() -> bool: return false
func requires_clear() -> bool: return false

func enter() -> void:
	state = "idle"; wait = 4.0
	m.main.hud.drill_show(true)

func skip() -> void: state = "done"

func objective() -> String:
	if r.done: return "Advance to the next sector"
	if drill >= 0 and drill < drills.size(): return "Range  ·  %s" % drills[drill]["t"].capitalize()
	return "Training range  ·  stand by"

func music() -> String: return "tension"

func tick(dt: float) -> void:
	for tg in targets: _anim_target(tg, dt)
	if not r.entered or state == "done": return
	match state:
		"idle", "between":
			wait -= dt
			if wait <= 0.0:
				drill += 1
				if drill >= drills.size(): _complete(); return
				var d: Dictionary = drills[drill]
				Audio.say("MARR", d["call"], d.get("vo", ""))
				m.main.hud.drill_set(d["t"], "Shoot them in order" if d["ordered"] else "Shoot every correct one · leave the decoys", d, 0)
				state = "calling"; wait = 2.4
				_board()
		"calling":
			wait -= dt
			if wait <= 0.0: _spawn()
		"live":
			t += dt
			_board()

func _board() -> void:
	var d: Dictionary = drills[clampi(drill, 0, drills.size() - 1)]
	board_labels["title"].text = d["t"] if state != "done" else "RANGE COMPLETE"
	board_labels["prog"].text = ("IN ORDER · %d/%d" if d["ordered"] else "HIT ALL · %d/%d") % [next_i, d["items"].size()] + "     %.1fs" % t
	board_labels["mist"].text = "MISTAKES %d" % mistakes

func _spawn() -> void:
	for tg in targets: tg["node"].queue_free()
	targets.clear(); next_i = 0; t = 0.0
	var d: Dictionary = drills[drill]
	var labels: Array = []
	for i in d["items"].size(): labels.append({"t": d["items"][i], "i": i, "ok": true})
	for x in d["decoys"]: labels.append({"t": x, "i": -1, "ok": false})
	labels.shuffle()
	var spots: Array = []
	var hw := r.W * 0.5
	for k in labels.size():
		var p := Vector3.ZERO
		for tries in 40:
			p = Vector3(randf_range(-hw + 2, hw - 2), 0, randf_range(r.z1 + 3, r.z0 - 12))
			var ok := true
			for s in spots:
				if (s - p).length() < 2.4: ok = false
			if ok: break
		spots.append(p)
		var node := Node3D.new(); r.add_child(node); node.position = p
		var pole := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.04; cm.bottom_radius = 0.04; cm.height = 1.1; pole.mesh = cm; pole.material_override = Mats.pbr("steel", 1.0); pole.position.y = 0.55; node.add_child(pole)
		var piv := Node3D.new(); piv.position.y = 1.1; node.add_child(piv)
		var board := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(1.7, 1.05, 0.06); board.mesh = bm
		var bmat := StandardMaterial3D.new(); bmat.albedo_color = Color(0.93, 0.9, 0.82); bmat.roughness = 0.8; board.material_override = bmat; board.position.y = 0.53; piv.add_child(board)
		var lab := Label3D.new(); lab.text = labels[k]["t"]; lab.font = load("res://assets/fonts/Rajdhani-Bold.ttf"); lab.font_size = 64; lab.pixel_size = 0.0035
		lab.modulate = Color(0.08, 0.08, 0.08); lab.outline_size = 0; lab.width = 420; lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; lab.position = Vector3(0, 0, 0.035); lab.shaded = true
		board.add_child(lab)
		var sb := StaticBody3D.new(); sb.collision_layer = 1; var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = bm.size; cs.shape = sh; sb.add_child(cs); board.add_child(sb)
		var tg := {"node": node, "piv": piv, "mat": bmat, "label": labels[k]["t"], "i": labels[k]["i"], "ok": labels[k]["ok"], "state": "up", "anim": 0.0, "delay": k * 0.12, "flash": 0.0}
		sb.set_meta("target", tg)
		piv.rotation.x = -PI * 0.5
		targets.append(tg)
	state = "live"
	m.main.hud.drill_set(d["t"], "Shoot them in order" if d["ordered"] else "Shoot every correct one · leave the decoys", d, 0)

func _anim_target(tg: Dictionary, dt: float) -> void:
	if tg["delay"] > 0.0: tg["delay"] -= dt; return
	tg["anim"] = minf(1.0, tg["anim"] + dt * 3.0) if tg["state"] == "up" else maxf(0.0, tg["anim"] - dt * 4.0)
	var a: float = tg["anim"]
	(tg["piv"] as Node3D).rotation.x = -PI * 0.5 * (1.0 - a * a * (3.0 - 2.0 * a))
	if tg["flash"] > 0.0:
		tg["flash"] -= dt
		if tg["flash"] <= 0.0 and tg["state"] == "up": (tg["mat"] as StandardMaterial3D).albedo_color = Color(0.93, 0.9, 0.82)

func target_hit(col: Node, _pos: Vector3) -> void:
	var tg: Dictionary = col.get_meta("target")
	if state != "live" or tg["state"] != "up": return
	var d: Dictionary = drills[drill]
	var good: bool = tg["ok"] and (not d["ordered"] or tg["i"] == next_i)
	if good:
		tg["state"] = "down"; next_i += 1; (tg["mat"] as StandardMaterial3D).albedo_color = Color(0.45, 0.95, 0.55)
		Audio.play2d("kenney_weapon_change", -6.0, 0.1); m.main.hud.hitmarker(true, false); Game.add_xp(15, "TARGET")
		m.main.hud.drill_set(d["t"], "", d, next_i)
		if next_i >= d["items"].size():
			state = "between"; wait = 1.8
			for o in targets:
				if o["state"] == "up": o["state"] = "drop"
	else:
		mistakes += 1; t += 3.0; tg["flash"] = 0.6; (tg["mat"] as StandardMaterial3D).albedo_color = Color(1.0, 0.35, 0.3)
		Audio.play2d("empty", -2.0)
		var nxt: String = d["items"][next_i] if d["ordered"] else ""
		m.main.hud.toast("✖  OUT OF ORDER" if tg["ok"] else "✖  DECOY: %s" % tg["label"], ("Next is: %s" % nxt) if d["ordered"] else ("“%s” isn't one of them" % tg["label"]), Color(1.0, 0.35, 0.3))
		var mk := "drill:%s|%s" % [d["t"], " → ".join(d["items"]) if d["ordered"] else " · ".join(d["items"])]
		if not Game.stats["missed"].has(mk): Game.stats["missed"].append(mk)
		if randf() < 0.4: Audio.say_generic("g_wrongtarget")
	_board()

func _complete() -> void:
	state = "done"
	var medal := "gold" if mistakes == 0 else ("silver" if mistakes <= 2 else "bronze")
	var key := "range%d" % m.mi
	var prev = String(Game.save["medals"].get(key, ""))
	var order := {"": 0, "bronze": 1, "silver": 2, "gold": 3}
	if order[medal] > order.get(prev, 0):
		Game.save["medals"][key] = medal
		Game.persist()
	Game.add_xp({"gold": 250, "silver": 150, "bronze": 75}[medal], medal.to_upper() + " MEDAL")
	m.main.hud.toast("%s MEDAL" % medal.to_upper(), "%d mistake%s · %.1fs" % [mistakes, "" if mistakes == 1 else "s", t], {"gold": Color(1, 0.83, 0.42), "silver": Color(0.85, 0.87, 0.88), "bronze": Color(0.85, 0.6, 0.36)}[medal])
	Audio.say_generic("g_" + medal)
	m.main.hud.drill_show(false)
	board_labels["title"].text = "RANGE COMPLETE"
	get_tree().create_timer(1.5).timeout.connect(func(): complete(); Audio.say_generic("g_rangeclear"))
