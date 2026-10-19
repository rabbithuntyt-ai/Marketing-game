extends ModeBase
## Portfolio vault: five SBU server stacks show growth and share. Classify each on the BCG matrix;
## plant charges only on the cash cows that fund Meridian.

var stacks: Array = []
var classified := {}
var charged := 0
var cows := 0

func setup() -> void:
	var sbus: Array = r.data.get("sbus", [])
	var hw := r.W * 0.5
	var b := Builder.new(m, m.M)
	for k in sbus.size():
		var s: Dictionary = sbus[k]
		if s["cls"] == "Cash cow": cows += 1
		var x: float = -hw + 3.0 + k * ((r.W - 6.0) / maxf(1, sbus.size() - 1))
		var z := r.z1 + 6.0
		var node := Node3D.new(); r.add_child(node); node.position = Vector3(x, 0, z)
		var rk: Array = anchor("racks", [])
		if k < rk.size(): node.position = rk[k][0]; node.rotation.y = rk[k][1]
		var rack := b.box(node, Vector3(1.6, 2.6, 1.2), Vector3(0, 1.3, 0), Mats.pbr("gunmetal", 1.0))
		b.box(node, Vector3(1.3, 1.0, 0.05), Vector3(0, 1.7, 0.62), Mats.flat(Color(0.02, 0.03, 0.03), 0.3), false, false)
		var t1 := b.label(node, String(s["name"]).to_upper(), Vector3(0, 2.1, 0.66), 0, 34, Color(1, 1, 1), "Rajdhani-Bold", 300, HORIZONTAL_ALIGNMENT_CENTER)
		b.label(node, "MARKET GROWTH  %d%%" % int(s["growth"]), Vector3(0, 1.75, 0.66), 0, 30, Color(0.55, 0.85, 1.0), "IBMPlexMono-Medium", 300, HORIZONTAL_ALIGNMENT_CENTER)
		b.label(node, "RELATIVE SHARE  %.1f×" % float(s["share"]), Vector3(0, 1.45, 0.66), 0, 30, Color(0.55, 0.85, 1.0), "IBMPlexMono-Medium", 300, HORIZONTAL_ALIGNMENT_CENTER)
		b.omni(node, Vector3(0, 1.8, 1.2), Color(0.5, 0.8, 1.0), 0.6, 3.0)
		stacks.append({"node": node, "sbu": s, "k": k, "charge": null})
	var n := maxi(3, int(r.data.get("e", 4)) + int(Game.diff()["cnt"]))
	m.spawn_room_enemies(r, n)

func enter() -> void:
	if r.alive_enemies().size() > 0: m.breach()

func objective() -> String:
	if r.done: return "Advance to the next sector"
	if r.alive_enemies().size() > 0: return "Eliminate hostiles  (%d)" % r.alive_enemies().size()
	if charged < cows: return "Classify the SBUs  ·  charge the cash cows  (%d/%d)" % [charged, cows]
	return default_objective()

func interactables() -> Array:
	var out: Array = []
	if r.alive_enemies().size() > 0: return out
	for st in stacks:
		if classified.has(st["k"]): continue
		out.append({"pos": st["node"].global_position + st["node"].global_basis.z * 1.2, "radius": 1.8, "prompt": "Classify  ·  %s" % st["sbu"]["name"], "cb": _classify.bind(st)})
	return out

func _classify(st: Dictionary) -> void:
	var s: Dictionary = st["sbu"]
	var opts := ["Cash cow", "Star", "Question mark", "Dog"]
	opts.erase(s["cls"]); opts.push_front(s["cls"])
	var q := {"q": "%s\nMarket growth: %d%%   ·   Relative market share: %.1f×\n\nWhere does this SBU sit on the BCG growth-share matrix?" % [s["name"], int(s["growth"]), float(s["share"])],
		"a": opts, "why": _why(s["cls"]), "tag": "TREASURY STACK %d" % (st["k"] + 1)}
	m.main.open_question(q, func(ok: bool): _answered(st, ok))

func _why(cls: String) -> String:
	match cls:
		"Cash cow": return "Low growth, high share: a cash cow. It generates the cash that funds stars and question marks. Plant the charge."
		"Star": return "High growth, high share: a star. It needs heavy investment to keep growing. Not a funding source."
		"Question mark": return "High growth, low share: a question mark. It eats cash. This is Meridian itself."
		"Dog": return "Low growth, low share: a dog. It may sustain itself but isn't a major source of cash."
	return ""

func _answered(st: Dictionary, ok: bool) -> void:
	var s: Dictionary = st["sbu"]
	if not ok:
		Audio.say_generic("g_plant_wrong", true)
		Game.stats["missed"].append("bcg:%s growth %d%%, share %.1fx|%s" % [s["name"], int(s["growth"]), float(s["share"]), s["cls"]])
		m.on_wrong_answer()
		return
	classified[st["k"]] = true
	Game.add_xp(40, "CLASSIFIED")
	if s["cls"] == "Cash cow":
		charged += 1
		var c := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.35, 0.22, 0.12); c.mesh = bm; c.material_override = Mats.flat(Color(0.25, 0.3, 0.2), 0.6)
		st["node"].add_child(c); c.position = Vector3(0, 1.0, 0.66)
		var led := OmniLight3D.new(); led.light_color = Color(1, 0.2, 0.1); led.omni_range = 1.5; led.light_energy = 1.5; c.add_child(led)
		st["charge"] = c
		Audio.say_generic("g_plant_ok")
		if charged >= cows:
			r.cleared = true; say_post()
			m.main.hud.toast("CHARGES SET", "Both cash cows wired", Color(1.0, 0.65, 0.3))
	else:
		m.main.hud.toast(String(s["cls"]).to_upper(), "Leave it. Not a funding source." if s["cls"] != "Question mark" else "That's Meridian itself.", Color(0.6, 0.85, 1.0))

func terminal_ready() -> bool: return charged >= cows
func terminal_locked_text() -> String: return "Uplink locked  ·  wire the cash cows first"

func tick(_dt: float) -> void:
	if r.entered and charged >= cows and not has_calls() and not r.done: complete()
