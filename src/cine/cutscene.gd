class_name Cutscene
extends Node3D
## In-engine cutscenes. Each script places actors around an anchor in the level and assigns a shot to
## every line of dialogue: close-ups with shallow depth of field and a slow push, over-the-shoulder,
## wide crane/dolly moves, and holographic transmissions for characters who aren't in the room.

var main: Node
var mission: Mission
var cid := ""
var done_cb: Callable
var cam: Camera3D
var ca: CameraAttributesPractical
var actors := {}
var anchors := {}
var lines: Array = []
var script_d: Dictionary
var li := -1
var holo: Node3D
var holo_mat: ShaderMaterial
var cam_tw: Tween
var frozen: Array = []
var hidden: Array = []
var finished := false
var t := 0.0
var cur_dur := 4.0
var lights: Array = []

# Shot formats:
#   ["close", actor, side]            3/4 close-up, slow push-in, focus on face
#   ["ots", from_actor, target]       over the shoulder of from_actor toward target (actor name or local Vector3)
#   ["wide", from, look, to, anchor]  dolly from -> to while looking at look (anchor-local)
#   ["low", actor]                    low-angle hero shot rising slowly
#   ["holo"]                          the hologram transmission, framed between the squad
const S := {
	"m1_intro": {"anchor": "start", "light": Color(0.6, 0.7, 0.9), "actors": {"wren": ["wren", Vector3(-0.5, 0, 0.6), 0.0, "soldier_idle"], "ruiz": ["ally", Vector3(0.9, 0, 0.2), -15.0, "soldier_idle"]},
		"pre": ["wide", Vector3(3.2, 0.5, 1.8), Vector3(0, 1.2, -4), Vector3(2.2, 0.9, 1.4)],
		"shots": [["close", "ruiz", 1], ["wide", Vector3(-2.5, 3.6, 1.8), Vector3(0, 1.5, -12), Vector3(-1.0, 4.8, 1.5)], ["ots", "wren", Vector3(0, 1.4, -12)]]},
	"m1_outro": {"anchor": "end", "light": Color(1.0, 0.8, 0.6), "holo": Vector3(0, 1.5, -3.2), "actors": {"ost": ["civilian", Vector3(0, 0, -1.6), 180.0, "GroundSit_Idle"], "ruiz": ["ally", Vector3(1.4, 0, -0.4), 120.0, "soldier_idle"], "wren": ["wren", Vector3(-1.2, 0, 0.4), 200.0, "soldier_idle"]},
		"shots": [["close", "ost", -1], ["close", "ruiz", 1], ["holo"], ["wide", Vector3(3, 2.2, 3), Vector3(0, 1.2, -1.5), Vector3(-3, 2.6, 3)]]},
	"m2_intro": {"anchor": "start", "light": Color(0.6, 0.75, 1.0), "actors": {"wren": ["wren", Vector3(-0.6, 0, 0.5), 0.0, "soldier_idle"], "ruiz": ["ally", Vector3(0.8, 0, 0.1), -10.0, "soldier_idle"]},
		"pre": ["wide", Vector3(0.4, 0.4, -6), Vector3(0, 1.5, 0), Vector3(0.2, 0.8, -4.5)],
		"shots": [["low", "ruiz"], ["ots", "wren", Vector3(0, 1.6, -12)]]},
	"m2_outro": {"anchor": "end", "light": Color(1.0, 0.5, 0.35), "holo": Vector3(0, 1.6, -3.0), "actors": {"ruiz": ["ally", Vector3(0.9, 0, 0), 160.0, "soldier_idle"], "wren": ["wren", Vector3(-0.7, 0, 0.3), 180.0, "soldier_idle"]},
		"shots": [["close", "ruiz", 1], ["holo"], ["ots", "wren", Vector3(0, 1.6, -3.0)]]},
	"m3_intro": {"anchor": "start", "light": Color(0.5, 0.65, 0.8), "actors": {"wren": ["wren", Vector3(-0.6, 0, 0.5), 0.0, "soldier_idle"], "ruiz": ["ally", Vector3(0.9, 0, 0.2), -20.0, "soldier_idle"]},
		"shots": [["wide", Vector3(-4, 5, 1.8), Vector3(0, 1, -10), Vector3(-2, 6, 1.5)], ["close", "ruiz", -1]]},
	"m3_outro": {"anchor": "end", "light": Color(0.6, 0.7, 0.85), "actors": {"kessler": ["kessler", Vector3(0, 0, -9), 0.0, "Idle"], "ruiz": ["ally", Vector3(1.0, 0, 0.5), 180.0, "soldier_idle"], "wren": ["wren", Vector3(-0.8, 0, 0.8), 180.0, "soldier_idle"]},
		"shots": [["close", "kessler", 1], ["close", "ruiz", -1]]},
	"m4_intro": {"anchor": "start", "light": Color(0.55, 0.6, 0.9), "actors": {"wren": ["wren", Vector3(-0.6, 0, 0.5), 0.0, "Crouch_Idle"], "ruiz": ["ally", Vector3(0.9, 0, 0.3), -15.0, "Crouch_Idle"]},
		"shots": [["wide", Vector3(3, 0.5, -5), Vector3(0, 0.9, 0.3), Vector3(1.5, 0.7, -3.5)], ["close", "ruiz", 1]]},
	"m4_outro": {"anchor": "end", "light": Color(0.7, 0.6, 1.0), "actors": {"ruiz": ["ally", Vector3(0.6, 0, 0), 200.0, "Idle_Tired"], "wren": ["wren", Vector3(-0.8, 0, 0.5), 160.0, "soldier_idle"]},
		"shots": [["close", "ruiz", 1], ["wide", Vector3(4, 2.5, 4), Vector3(0, 1.2, 0), Vector3(2, 3, 5)], ["ots", "ruiz", "wren"]]},
	"m5_intro": {"anchor": "start", "light": Color(0.9, 0.7, 0.8), "actors": {"wren": ["wren", Vector3(-0.6, 0, 0.5), 0.0, "soldier_idle"], "ruiz": ["ally", Vector3(0.8, 0, 0.2), -15.0, "soldier_idle"]},
		"shots": [["close", "ruiz", -1], ["wide", Vector3(0, 5, 1.8), Vector3(0, 0, -14), Vector3(0, 6.5, -1)]]},
	"m5_outro": {"anchor": "end", "light": Color(1.0, 0.45, 0.35), "actors": {"hale": ["hale", Vector3(0, 0, -4.5), 0.0, "soldier_idle"], "css1": ["css", Vector3(-1.6, 0, -5.2), 10.0, "soldier_idle"], "css2": ["css", Vector3(1.7, 0, -5.0), -10.0, "soldier_idle"], "wren": ["wren", Vector3(0, 0, 1.0), 180.0, "soldier_idle"]},
		"shots": [["close", "hale", 1], ["ots", "hale", "wren"]]},
	"m6_intro": {"anchor": "cell", "light": Color(0.9, 0.8, 0.7), "actors": {"kessler": ["kessler", Vector3(0, 0, -1.4), 180.0, "Idle"], "ruiz": ["ally", Vector3(0, 0, 0), 0.0, "GroundSit_Idle"]},
		"shots": [["close", "kessler", 1], ["ots", "kessler", "ruiz"], ["wide", Vector3(-3, 2.4, 2.5), Vector3(0, 0.9, -0.6), Vector3(-2.2, 1.8, 3.4)]]},
	"m6_outro": {"anchor": "end", "light": Color(1.0, 0.85, 0.7), "actors": {"ruiz": ["ally", Vector3(0.7, 0, 0), 200.0, "soldier_idle"], "wren": ["wren", Vector3(-0.7, 0, 0.3), 160.0, "soldier_idle"]},
		"shots": [["close", "ruiz", 1], ["wide", Vector3(5, 3, 5), Vector3(0, 1.2, 0), Vector3(-5, 3.5, 5)]]},
	"m7_intro": {"anchor": "start", "light": Color(0.8, 0.75, 0.6), "holo": Vector3(0, 2.0, -4.0), "holo_scale": 2.2, "actors": {"wren": ["wren", Vector3(-0.7, 0, 0.5), 0.0, "soldier_idle"], "ruiz": ["ally", Vector3(0.8, 0, 0.2), -10.0, "soldier_idle"]},
		"shots": [["holo"], ["close", "ruiz", 1], ["ots", "wren", Vector3(0, 2.0, -4.0)]]},
	"m7_outro": {"anchor": "end", "light": Color(0.8, 0.75, 0.6), "actors": {"ruiz": ["ally", Vector3(0.7, 0, 0), 180.0, "soldier_idle"], "wren": ["wren", Vector3(-0.7, 0, 0.3), 180.0, "soldier_idle"]},
		"shots": [["wide", Vector3(0, 1.2, -5), Vector3(0, 1.5, 0), Vector3(0, 0.5, -3)]]},
	"m8_intro": {"anchor": "end", "light": Color(0.9, 0.85, 0.75), "actors": {"voss": ["director", Vector3(0, 0, -1), 0.0, "Idle"], "hale": ["hale", Vector3(1.6, 0, -1.4), -30.0, "soldier_idle"]},
		"shots": [["close", "voss", 1], ["close", "hale", -1], ["low", "voss"]]},
	"m8_outro": {"anchor": "end", "light": Color(1.0, 0.8, 0.6), "actors": {"ruiz": ["ally", Vector3(0.8, 0, 0), 190.0, "soldier_idle"], "wren": ["wren", Vector3(-0.8, 0, 0.2), 170.0, "soldier_idle"]},
		"shots": [["wide", Vector3(4, 1.8, 4), Vector3(0, 1.3, 0), Vector3(2.5, 1.6, 3.5)], ["ots", "ruiz", "wren"], ["close", "ruiz", 1], ["close", "wren", -1],
			["wide", Vector3(-3, 2.5, 4), Vector3(0, 1.4, 0), Vector3(-1.5, 2.0, 3)], ["wide", Vector3(0, 2, 5), Vector3(0, 1.6, 0), Vector3(0, 8, 12)]]},
}

func play(main_node: Node, m: Mission, cut_id: String, done: Callable) -> void:
	main = main_node; mission = m; cid = cut_id; done_cb = done
	lines = Game.cuts.get(cid, [])
	Audio.clear_dialogue()
	script_d = S.get(cid, {"anchor": "start", "actors": {}, "shots": []})
	_anchors()
	cam = Camera3D.new(); cam.fov = 40; cam.near = 0.05; cam.cull_mask = 0xFFFFF & ~2; add_child(cam)
	ca = CameraAttributesPractical.new(); ca.dof_blur_far_enabled = true; ca.dof_blur_amount = 0.08; ca.dof_blur_far_distance = 4.0; ca.dof_blur_far_transition = 3.0
	cam.attributes = ca
	cam.current = true
	var cl := OmniLight3D.new(); cl.light_energy = 0.9; cl.omni_range = 4.5; cl.light_color = Color(1.0, 0.92, 0.85); cl.position = Vector3(0.3, 0.2, 0.2); cam.add_child(cl)
	mission.cut_active = true
	_freeze_world(true)
	_spawn_actors()
	if script_d.has("holo"): _make_holo()
	var key := SpotLight3D.new(); key.light_color = script_d.get("light", Color(1, 0.9, 0.8)); key.light_energy = 5.0; key.spot_range = 12; key.spot_angle = 45; key.shadow_enabled = true
	add_child(key); lights.append(key)
	var a: Transform3D = anchors[script_d["anchor"]]
	key.look_at_from_position(a * Vector3(2.0, 3.6, -3.5), a * Vector3(0, 1.0, 0.0))
	var rim := SpotLight3D.new(); rim.light_color = Color(0.55, 0.7, 1.0); rim.light_energy = 4.0; rim.spot_range = 10; rim.spot_angle = 50
	add_child(rim); lights.append(rim)
	rim.look_at_from_position(a * Vector3(-1.5, 3.2, 3.0), a * Vector3(0, 1.2, -0.5))
	main.letterbox(true, 0.6)
	if script_d.has("pre"): _shot(script_d["pre"], 3.0)
	else: _shot(["wide", Vector3(3, 1.8, 1.8), Vector3(0, 1.3, -1), Vector3(2.2, 1.6, 1.5)], 3.0)
	main.fade(0.0, 0.9)
	await get_tree().create_timer(1.6 if script_d.has("pre") else 0.9).timeout
	if finished: return
	Audio.line_finished.connect(_on_line_done)
	_next_line()

func _anchors() -> void:
	var r0: Room = mission.rooms[0]
	var rl: Room = mission.rooms[mission.rooms.size() - 1]
	anchors["start"] = Transform3D(Basis.IDENTITY, Vector3(0, 0, r0.z0 - 2.5))
	anchors["end"] = Transform3D(Basis.IDENTITY, Vector3(0, 0, (rl.z0 + rl.z1) * 0.5 + 1.0))
	var cell := Vector3.ZERO
	for r in mission.rooms:
		if r.kind == "rescue" and r.mode and "cell" in r.mode: cell = r.mode.cell
	anchors["cell"] = Transform3D(Basis(Vector3.UP, -PI * 0.5), cell if cell != Vector3.ZERO else anchors["start"].origin)

func _freeze_world(on: bool) -> void:
	if on:
		for r in mission.rooms:
			for e in r.enemies:
				if is_instance_valid(e) and not e.dead:
					frozen.append(e); e.set_physics_process(false)
					if script_d["anchor"] == "end" and r == mission.rooms[mission.rooms.size() - 1]:
						e.visible = false; hidden.append(e)
					elif script_d["anchor"] == "cell" and r.kind == "rescue":
						e.visible = false; hidden.append(e)
		if mission.ally and mission.ally.visible:
			hidden.append(mission.ally); mission.ally.visible = false; mission.ally.set_physics_process(false)
		if script_d["anchor"] == "cell":
			for r in mission.rooms:
				if r.kind == "rescue" and r.mode and "prisoner" in r.mode and is_instance_valid(r.mode.prisoner):
					r.mode.prisoner.visible = false; hidden.append(r.mode.prisoner)
		# keep the anchor rooms visible even if they're far from the player
		var ar := _anchor_room()
		if ar: ar.visible = true
	else:
		for e in frozen:
			if is_instance_valid(e): e.set_physics_process(true)
		for h in hidden:
			if is_instance_valid(h):
				h.visible = true
				if h is CharacterBody3D: h.set_physics_process(true)
		frozen.clear(); hidden.clear()

func _anchor_room() -> Room:
	var o: Vector3 = anchors[script_d["anchor"]].origin
	for r in mission.rooms:
		if r.contains(o): return r
	return null

func _spawn_actors() -> void:
	var defs: Dictionary = script_d.get("actors", {})
	var a: Transform3D = anchors[script_d["anchor"]]
	for k in defs.keys():
		var d: Array = defs[k]
		var h := Humanoid.new(); h.team = "neutral"; add_child(h); h.setup(String(d[0]))
		h.set_physics_process(false)
		for ar in h.find_children("*", "Area3D", true, false): (ar as Area3D).collision_layer = 0
		h.collision_layer = 0
		h.global_position = a * (d[1] as Vector3)
		h.rotation.y = a.basis.get_euler().y + deg_to_rad(float(d[2]))
		if String(d[0]) in ["director", "civilian"]: h.hide_weapon()
		h.forced_anim = String(d[3])
		h.play(String(d[3]))
		actors[k] = h

func _make_holo() -> void:
	var scn: PackedScene = load("res://assets/models/head/LeePerrySmith.glb")
	holo = Node3D.new(); add_child(holo)
	var head: Node3D = scn.instantiate(); holo.add_child(head)
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;
uniform vec4 col : source_color = vec4(0.35, 0.75, 1.0, 1.0);
uniform float flicker = 1.0;
uniform float tm = 0.0;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	float scan = 0.55 + 0.45 * sin(wp.y * 140.0 - tm * 6.0);
	float band = smoothstep(0.0, 0.02, abs(fract(wp.y * 1.5 - tm * 0.4) - 0.5) - 0.46);
	ALBEDO = col.rgb * (0.25 + fres * 1.6) * scan * flicker * (0.7 + 0.3 * band);
	ALPHA = 1.0;
}
"""
	holo_mat = ShaderMaterial.new(); holo_mat.shader = sh
	var aabb := AABB(); var first := true
	for mi in head.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = holo_mat
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var b: AABB = (mi as MeshInstance3D).get_aabb()
		aabb = b if first else aabb.merge(b); first = false
	var sc := float(script_d.get("holo_scale", 1.0)) * 0.42 / maxf(0.01, aabb.size.y)
	head.scale = Vector3.ONE * sc
	head.position = -aabb.get_center() * sc
	var a: Transform3D = anchors[script_d["anchor"]]
	holo.global_position = a * (script_d["holo"] as Vector3)
	holo.rotation.y = 0.0
	# projector base + light
	var base := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.18; cm.bottom_radius = 0.22; cm.height = 0.06; base.mesh = cm
	base.material_override = Mats.glow(Color(0.35, 0.75, 1.0), 2.0); add_child(base)
	base.global_position = holo.global_position - Vector3(0, 0.55 * float(script_d.get("holo_scale", 1.0)), 0)
	var cone := MeshInstance3D.new(); var cn := CylinderMesh.new(); cn.top_radius = 0.28 * float(script_d.get("holo_scale", 1.0)); cn.bottom_radius = 0.18; cn.height = 0.5 * float(script_d.get("holo_scale", 1.0)); cone.mesh = cn
	var cmat := StandardMaterial3D.new(); cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; cmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; cmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	cmat.albedo_color = Color(0.3, 0.6, 1.0, 0.08); cmat.cull_mode = BaseMaterial3D.CULL_DISABLED; cone.material_override = cmat; add_child(cone)
	cone.global_position = base.global_position + Vector3(0, cn.height * 0.5, 0)
	var l := OmniLight3D.new(); l.light_color = Color(0.4, 0.75, 1.0); l.light_energy = 1.5; l.omni_range = 5.0; holo.add_child(l)
	holo.visible = false

func _process(dt: float) -> void:
	t += dt
	if holo and holo_mat:
		holo_mat.set_shader_parameter("tm", t)
		holo_mat.set_shader_parameter("flicker", 0.85 + 0.15 * sin(t * 37.0) * sin(t * 13.0) + (0.0 if randf() > 0.02 else -0.5))
		holo.rotation.y = sin(t * 0.4) * 0.15
	# look-at actors toward whoever is speaking
	if li >= 0 and li < lines.size():
		var spk := String(lines[li]["spk"]).to_lower()
		var who: Humanoid = actors.get(_actor_key(spk))
		for k in actors.keys():
			var h: Humanoid = actors[k]
			if who and h != who and not (h.forced_anim in ["GroundSit_Idle"]):
				var d := who.global_position - h.global_position; d.y = 0
				if d.length() > 0.3 and d.length() < 6.0:
					var want := atan2(-d.x, -d.z)
					h.rotation.y = lerp_angle(h.rotation.y, want, 1.0 - exp(-1.5 * dt))

func _actor_key(spk: String) -> String:
	match spk:
		"ostrowski": return "ost"
		_: return spk

func _next_line() -> void:
	if finished: return
	li += 1
	if li >= lines.size():
		_end(); return
	var l: Dictionary = lines[li]
	var shots: Array = script_d.get("shots", [])
	var shot: Array = shots[li] if li < shots.size() else (shots[shots.size() - 1] if not shots.is_empty() else ["wide", Vector3(3, 2, 4), Vector3(0, 1.3, 0), Vector3(2, 2, 3)])
	var s := Audio.stream("res://assets/audio/vo/cuts/%s.ogg" % String(l.get("vo", "")))
	cur_dur = (s.get_length() if s else 1.6 + String(l["text"]).length() * 0.055) + 0.6
	if holo: holo.visible = shot[0] == "holo" or (String(l["spk"]) in ["VOSS", "KESSLER"] and not actors.has(String(l["spk"]).to_lower()))
	_shot(shot, cur_dur)
	for k in actors.keys():
		var h: Humanoid = actors[k]
		var base: String = script_d["actors"][k][3]
		if base in ["Idle", "Idle_FoldArms"] and String(script_d["actors"][k][0]) in ["director", "civilian"]:
			h.forced_anim = "Idle_Talking" if k == _actor_key(String(l["spk"]).to_lower()) else base
	Audio.say(String(l["spk"]), String(l["text"]), String(l.get("vo", "")), "cuts", true)

func _on_line_done() -> void:
	if finished: return
	await get_tree().create_timer(0.35).timeout
	_next_line()

func _local(v, a: Transform3D) -> Vector3:
	if v is Vector3: return a * (v as Vector3)
	var h: Humanoid = actors.get(String(v))
	if h: return h.global_position + Vector3(0, 1.55 * h.scale.y, 0)
	return a.origin + Vector3(0, 1.4, 0)

func _head(h: Humanoid) -> Vector3:
	var hy := 1.58
	if h.forced_anim in ["GroundSit_Idle", "Sitting_Idle"]: hy = 0.95
	elif h.forced_anim == "Crouch_Idle": hy = 1.1
	return h.global_position + Vector3(0, hy * h.scale.y, 0)

func _shot(shot: Array, dur: float) -> void:
	if cam_tw and cam_tw.is_valid(): cam_tw.kill()
	var a: Transform3D = anchors[script_d["anchor"]]
	var kind := String(shot[0])
	var from := Vector3.ZERO; var to := Vector3.ZERO; var look_a := Vector3.ZERO; var look_b := Vector3.ZERO
	var focus := 4.0
	match kind:
		"close":
			var h: Humanoid = actors.get(String(shot[1]))
			if h == null: _shot(["wide", Vector3(3, 2, 4), Vector3(0, 1.3, 0), Vector3(2, 2, 3)], dur); return
			var side := float(shot[2]) if shot.size() > 2 else 1.0
			var fwd := -h.global_transform.basis.z; var right := h.global_transform.basis.x
			var hd := _head(h)
			from = hd + fwd * 1.55 + right * 0.55 * side + Vector3(0, -0.05, 0)
			to = hd + fwd * 1.15 + right * 0.42 * side + Vector3(0, -0.03, 0)
			look_a = hd + Vector3(0, -0.04, 0); look_b = look_a
			cam.fov = 32.0; focus = 1.4
		"low":
			var h2: Humanoid = actors.get(String(shot[1]))
			if h2 == null: return
			var f2 := -h2.global_transform.basis.z
			from = h2.global_position + f2 * 2.0 + Vector3(0, 0.35, 0) + h2.global_transform.basis.x * 0.4
			to = from + Vector3(0, 0.35, 0) + f2 * -0.2
			look_a = _head(h2); look_b = look_a + Vector3(0, 0.05, 0)
			cam.fov = 44.0; focus = 2.0
		"ots":
			var h3: Humanoid = actors.get(String(shot[1]))
			if h3 == null: return
			var tgt := _local(shot[2], a)
			var dir := (tgt - h3.global_position); dir.y = 0; dir = dir.normalized() if dir.length() > 0.01 else Vector3(0, 0, -1)
			var rt := dir.cross(Vector3.UP).normalized()
			var hd3 := _head(h3)
			from = hd3 - dir * 0.95 + rt * 0.42 + Vector3(0, 0.12, 0)
			to = hd3 - dir * 0.75 + rt * 0.38 + Vector3(0, 0.1, 0)
			look_a = tgt; look_b = tgt
			cam.fov = 38.0; focus = maxf(1.5, hd3.distance_to(tgt))
		"wide":
			var aa: Transform3D = anchors.get(String(shot[4]), a) if shot.size() > 4 else a
			from = aa * (shot[1] as Vector3); to = aa * (shot[3] as Vector3)
			look_a = aa * (shot[2] as Vector3); look_b = look_a
			cam.fov = 46.0; focus = from.distance_to(look_a)
		"holo":
			if holo == null: _shot(["wide", Vector3(3, 2, 4), Vector3(0, 1.3, 0), Vector3(2, 2, 3)], dur); return
			var hp := holo.global_position
			from = hp + Vector3(0.9, -0.1, 2.4); to = hp + Vector3(0.5, -0.05, 1.6)
			look_a = hp; look_b = hp
			cam.fov = 36.0; focus = 2.0
	from = _clear_path(look_a, from); to = _clear_path(look_b, to)
	ca.dof_blur_far_distance = focus + 0.6
	ca.dof_blur_far_transition = maxf(1.5, focus * 0.8)
	cam.global_position = from
	cam.look_at(look_a)
	cam_tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	cam_tw.tween_method(func(k: float):
		cam.global_position = from.lerp(to, k)
		var lk := look_a.lerp(look_b, k)
		if cam.global_position.distance_to(lk) > 0.05: cam.look_at(lk), 0.0, 1.0, maxf(1.0, dur))

## Keep the camera on the near side of any wall between it and its subject.
func _clear_path(target: Vector3, p: Vector3) -> Vector3:
	var ss := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(target, p, 1)
	var hit := ss.intersect_ray(q)
	if hit.is_empty(): return p
	var hp: Vector3 = hit["position"]
	return hp + (target - hp).normalized() * 0.35

func _end() -> void:
	if finished: return
	finished = true
	if Audio.line_finished.is_connected(_on_line_done): Audio.line_finished.disconnect(_on_line_done)
	await get_tree().create_timer(0.6).timeout
	var tw: Tween = main.fade(1.0, 0.7)
	await tw.finished
	_cleanup()
	main.letterbox(false, 0.01)
	done_cb.call()

func _cleanup() -> void:
	_freeze_world(false)
	if mission and is_instance_valid(mission): mission.cut_active = false
	if mission and is_instance_valid(mission) and mission.player: mission.player.cam.current = true
	queue_free()

## Hard stop (menu quit while a cut is playing).
func abort() -> void:
	finished = true
	if Audio.line_finished.is_connected(_on_line_done): Audio.line_finished.disconnect(_on_line_done)
	main.letterbox(false, 0.01)

func skip() -> void:
	if finished: return
	Audio.clear_dialogue()
	finished = true
	if Audio.line_finished.is_connected(_on_line_done): Audio.line_finished.disconnect(_on_line_done)
	var tw: Tween = main.fade(1.0, 0.35)
	await tw.finished
	_cleanup()
	main.letterbox(false, 0.01)
	done_cb.call()

func _unhandled_input(e: InputEvent) -> void:
	if finished: return
	if e is InputEventKey and e.pressed and not e.echo:
		var k := (e as InputEventKey).keycode
		if k == KEY_ESCAPE:
			get_viewport().set_input_as_handled(); skip()
		elif k in [KEY_SPACE, KEY_ENTER]:
			get_viewport().set_input_as_handled(); Audio.skip_line()
