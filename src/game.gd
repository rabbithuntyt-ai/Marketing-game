extends Node
## Global game state: content, save data, settings, campaign progress and learning records.

signal settings_changed
signal xp_changed(total: int, delta: int, label: String)

const SAVE_PATH := "user://save.json"
const RANKS := [[0, "Probationary"], [700, "Operator"], [2000, "Specialist"], [4000, "Analyst"], [7000, "Senior Analyst"], [11000, "Strategist"]]
const DIFFS := [
	{"name": "Story", "acc": 0.16, "dmg": 6.0, "cnt": -1, "hp": 0.8, "regen": 1.4},
	{"name": "Regular", "acc": 0.26, "dmg": 9.0, "cnt": 0, "hp": 1.0, "regen": 1.0},
	{"name": "Veteran", "acc": 0.38, "dmg": 13.0, "cnt": 1, "hp": 1.25, "regen": 0.75},
]

var content: Dictionary = {}
var missions: Array = []
var cuts: Dictionary = {}
var cast: Dictionary = {}

var save := {
	"unlocked": 0, "xp": 0, "checkpoint": null, "intel": {}, "missed": {}, "seen": {}, "medals": {}, "best": {}, "boards": {},
	"settings": {
		"difficulty": 1, "quality": 2, "render_scale": 0.85, "fsr": true, "fullscreen": true, "vsync": true, "fov": 80.0,
		"sens": 1.0, "invert_y": false, "vol_master": 0.9, "vol_music": 0.55, "vol_sfx": 0.9, "vol_voice": 1.0,
		"subtitles": true, "subtitle_size": 1, "read_intel": true, "motion_blur": false, "hud_scale": 1.0, "aim_assist": true,
	},
}
var settings: Dictionary:
	get: return save["settings"]

# Session state
var mission_index := 0
var stats := {}
var autotest := ""       # set from command line for automated playthrough tests
var debug_start_room := -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	_load_content()
	_load_save()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autotest="): autotest = a.substr(11)
		if a.begins_with("--room="): debug_start_room = int(a.substr(7))
		if a == "--lowq":
			save["settings"]["quality"] = 0; save["settings"]["render_scale"] = 0.5; save["settings"]["fsr"] = false
	apply_settings()

func _setup_input() -> void:
	var keys := {
		"move_fwd": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN], "move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"sprint": [KEY_SHIFT], "crouch": [KEY_CTRL, KEY_C], "jump": [KEY_SPACE], "reload": [KEY_R], "grenade": [KEY_G],
		"melee": [KEY_F, KEY_V], "interact": [KEY_E], "pause": [KEY_ESCAPE, KEY_P],
		"answer_1": [KEY_1], "answer_2": [KEY_2], "answer_3": [KEY_3], "answer_4": [KEY_4],
	}
	for a in keys.keys():
		if not InputMap.has_action(a): InputMap.add_action(a)
		for k in keys[a]:
			var ev := InputEventKey.new(); ev.physical_keycode = k; InputMap.action_add_event(a, ev)
	for spec in [["fire", MOUSE_BUTTON_LEFT], ["aim", MOUSE_BUTTON_RIGHT]]:
		if not InputMap.has_action(spec[0]): InputMap.add_action(spec[0])
		var mb := InputEventMouseButton.new(); mb.button_index = spec[1]; InputMap.action_add_event(spec[0], mb)
	# gamepad
	var pad := {"jump": JOY_BUTTON_A, "reload": JOY_BUTTON_X, "interact": JOY_BUTTON_Y, "grenade": JOY_BUTTON_RIGHT_SHOULDER, "melee": JOY_BUTTON_RIGHT_STICK,
		"crouch": JOY_BUTTON_B, "sprint": JOY_BUTTON_LEFT_STICK, "pause": JOY_BUTTON_START}
	for a in pad.keys():
		var jb := InputEventJoypadButton.new(); jb.button_index = pad[a]; InputMap.action_add_event(a, jb)
	for spec2 in [["fire", JOY_AXIS_TRIGGER_RIGHT, 1.0], ["aim", JOY_AXIS_TRIGGER_LEFT, 1.0], ["move_fwd", JOY_AXIS_LEFT_Y, -1.0], ["move_back", JOY_AXIS_LEFT_Y, 1.0],
			["move_left", JOY_AXIS_LEFT_X, -1.0], ["move_right", JOY_AXIS_LEFT_X, 1.0]]:
		var ja := InputEventJoypadMotion.new(); ja.axis = spec2[1]; ja.axis_value = spec2[2]; InputMap.action_add_event(spec2[0], ja)

func _load_content() -> void:
	var f := FileAccess.open("res://data/content.json", FileAccess.READ)
	if f == null:
		push_error("content.json missing"); return
	content = JSON.parse_string(f.get_as_text())
	missions = content["missions"]
	cuts = content["cuts"]
	cast = content["cast"]

func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY: return
	var s: Dictionary = save["settings"].duplicate()
	for k in d.keys(): save[k] = d[k]
	for k in d.get("settings", {}).keys(): s[k] = d["settings"][k]
	save["settings"] = s

func persist() -> void:
	if autotest != "": return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(save))

func apply_settings() -> void:
	var s := settings
	if not autotest:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if s["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if s["vsync"] else DisplayServer.VSYNC_DISABLED)
	var vp := get_viewport()
	vp.scaling_3d_scale = clampf(float(s["render_scale"]), 0.5, 1.0)
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2 if (s["fsr"] and float(s["render_scale"]) < 0.99) else Viewport.SCALING_3D_MODE_BILINEAR
	vp.msaa_3d = Viewport.MSAA_DISABLED if s["fsr"] else (Viewport.MSAA_2X if int(s["quality"]) >= 1 else Viewport.MSAA_DISABLED)
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if not s["fsr"] else Viewport.SCREEN_SPACE_AA_DISABLED
	var q := int(s["quality"])
	RenderingServer.directional_shadow_atlas_set_size(4096 if q >= 2 else 2048, true)
	RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM if q >= 1 else RenderingServer.SHADOW_QUALITY_HARD)
	vp.positional_shadow_atlas_size = 4096 if q >= 1 else 2048
	settings_changed.emit()

func diff() -> Dictionary:
	return DIFFS[clampi(int(settings["difficulty"]), 0, 2)]

func rank_of(xp: int) -> Array:
	var r: Array = RANKS[0]
	for k in RANKS:
		if xp >= k[0]: r = k
	return r

func add_xp(n: int, label: String) -> void:
	save["xp"] = int(save["xp"]) + n
	if stats.has("xp"): stats["xp"] += n
	xp_changed.emit(int(save["xp"]), n, label)

func new_stats() -> Dictionary:
	return {"kills": 0, "heads": 0, "shots": 0, "hits": 0, "time": 0.0, "deaths": 0, "xp": 0, "q_seen": {}, "q_first_ok": 0,
		"missed": [], "recall": 0, "recall_ok": 0, "intel": 0, "takedowns": 0, "undetected": 0, "intercepts": 0, "intercepts_ok": 0}

func mission() -> Dictionary:
	return missions[mission_index]

## Learning records. Question keys are stable ids built from mission/room/index.
func q_key(mi: int, ri: int, qi: int) -> String:
	return "%d-%d-%d" % [mi, ri, qi]

func q_data(key: String) -> Dictionary:
	var p := key.split("-")
	if p.size() != 3 or not p[0].is_valid_int() or not p[1].is_valid_int() or not p[2].is_valid_int(): return {}
	var m: Dictionary = missions[int(p[0])]
	var r: Dictionary = m["rooms"][int(p[1])]
	var calls: Array = r.get("calls", [])
	var qi := int(p[2])
	if qi >= calls.size(): return {}
	return calls[qi]

func record_answer(key: String, ok: bool, recall: bool) -> void:
	var first: bool = not stats["q_seen"].has(key)
	if first:
		stats["q_seen"][key] = true
		if ok: stats["q_first_ok"] += 1
	if recall:
		stats["recall"] += 1
		if ok: stats["recall_ok"] += 1
	save["seen"][key] = int(save["seen"].get(key, 0)) + 1
	if ok:
		if save["missed"].has(key): save["missed"].erase(key)
	else:
		save["missed"][key] = int(save["missed"].get(key, 0)) + 1
		var q := q_data(key)
		if not q.is_empty() and not stats["missed"].has(key): stats["missed"].append(key)
	persist()

## Spaced recall: questions missed before come back first, then a random pick from earlier missions.
func recall_items(n: int, exclude: Array, upto_mission: int) -> Array:
	var out: Array = []
	var missed: Array = save["missed"].keys()
	missed.shuffle()
	for k in missed:
		if out.size() >= n: break
		if exclude.has(k) or q_data(k).is_empty(): continue
		var p: PackedStringArray = String(k).split("-")
		if int(p[0]) > upto_mission: continue
		out.append(k)
	var pool: Array = []
	for mi in range(0, mini(upto_mission + 1, missions.size())):
		var m: Dictionary = missions[mi]
		for ri in m["rooms"].size():
			var calls: Array = m["rooms"][ri].get("calls", [])
			for qi in calls.size():
				pool.append(q_key(mi, ri, qi))
	pool.shuffle()
	for k in pool:
		if out.size() >= n: break
		if exclude.has(k) or out.has(k): continue
		if mi_of(k) == mission_index and int(k.split("-")[1]) >= int(stats.get("room", 0)): continue
		out.append(k)
	return out

func mi_of(key: String) -> int:
	return int(key.split("-")[0])

## Index of the case board played after mission mi, or -1.
func board_after(mi: int) -> int:
	var bs: Array = content.get("boards", [])
	for i in bs.size():
		if int(bs[i]["after"]) == mi: return i
	return -1

func board_done(bi: int) -> bool:
	return save.get("boards", {}).has(str(bi))

func skip_cuts() -> bool:
	return autotest != "" and not autotest.begins_with("flow")

func chapter_tag(M: Dictionary, with_name := true) -> String:
	var ch := int(M.get("ch", 0))
	var head := "CHAPTERS 1–7" if ch == 0 else "CHAPTER %d" % ch
	return head + ("  ·  " + String(M.get("chname", "")).to_upper() if with_name and ch != 0 else "")

func speaker(spk: String) -> Dictionary:
	return cast.get(spk, {"name": spk, "role": "", "fx": "near"})
