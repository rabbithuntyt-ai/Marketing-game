class_name SettingsPanel
extends VBoxContainer
## Tabbed settings: Gameplay, Video, Audio, Controls. Changes apply immediately and persist.

var accent := Color(1.0, 0.72, 0.3)
var tabs: HBoxContainer
var body: VBoxContainer
var cur := "gameplay"
var tab_btns := {}

const QUALITY := ["Low", "Medium", "High", "Ultra"]
const DIFF := ["Story", "Regular", "Veteran"]
const SUB := ["Small", "Medium", "Large"]

func _ready() -> void:
	add_theme_constant_override("separation", 16)
	tabs = UIKit.hbox(4); add_child(tabs)
	for t in [["gameplay", "Gameplay"], ["video", "Video"], ["audio", "Audio"], ["controls", "Controls"]]:
		var b := UIKit.small_button(t[1], accent); tabs.add_child(b); tab_btns[t[0]] = b
		b.pressed.connect(show_tab.bind(t[0]))
	add_child(UIKit.rule())
	body = UIKit.vbox(10); add_child(body)
	show_tab("gameplay")

func show_tab(t: String) -> void:
	cur = t
	for k in tab_btns.keys(): (tab_btns[k] as Button).modulate = Color.WHITE if k == t else Color(0.65, 0.65, 0.65)
	for c in body.get_children(): c.queue_free()
	var s := Game.settings
	match t:
		"gameplay":
			_choice("Difficulty", DIFF, int(s["difficulty"]), func(i): _apply("difficulty", i), "Story: forgiving combat, focus on the material.  Veteran: they shoot back properly.")
			_slider("Mouse sensitivity", 0.2, 3.0, 0.05, float(s["sens"]), func(v): _apply("sens", v), "%.2f")
			_toggle("Invert Y axis", bool(s["invert_y"]), func(v): _apply("invert_y", v))
			_slider("Field of view", 65, 105, 1, float(s["fov"]), func(v): _apply("fov", v), "%d°")
			_toggle("Aim assist", bool(s["aim_assist"]), func(v): _apply("aim_assist", v))
			_toggle("Dr. Marr reads recovered intel aloud", bool(s["read_intel"]), func(v): _apply("read_intel", v))
			_toggle("Subtitles", bool(s["subtitles"]), func(v): _apply("subtitles", v))
			_choice("Subtitle size", SUB, int(s["subtitle_size"]), func(i): _apply("subtitle_size", i))
			_slider("HUD scale", 0.8, 1.25, 0.05, float(s["hud_scale"]), func(v): _apply("hud_scale", v), "%.2f")
		"video":
			_choice("Display", ["Fullscreen", "Windowed"], 0 if s["fullscreen"] else 1, func(i): _apply("fullscreen", i == 0))
			_toggle("V-Sync", bool(s["vsync"]), func(v): _apply("vsync", v))
			_choice("Graphics quality", QUALITY, int(s["quality"]), func(i): _apply("quality", i), "High adds volumetric fog. Ultra adds indirect lighting and screen-space reflections. Applies on the next sector load.")
			_slider("Render scale", 0.5, 1.0, 0.05, float(s["render_scale"]), func(v): _apply("render_scale", v), "%d%%", 100.0)
			_toggle("AMD FSR 2 upscaling", bool(s["fsr"]), func(v): _apply("fsr", v))
		"audio":
			_slider("Master", 0, 1, 0.01, float(s["vol_master"]), func(v): _apply("vol_master", v), "%d%%", 100.0)
			_slider("Music", 0, 1, 0.01, float(s["vol_music"]), func(v): _apply("vol_music", v), "%d%%", 100.0)
			_slider("Effects", 0, 1, 0.01, float(s["vol_sfx"]), func(v): _apply("vol_sfx", v), "%d%%", 100.0)
			_slider("Voice", 0, 1, 0.01, float(s["vol_voice"]), func(v): _apply("vol_voice", v), "%d%%", 100.0)
		"controls":
			for row in [["Move", "W A S D"], ["Look", "Mouse"], ["Fire", "Left mouse"], ["Aim down sights", "Right mouse"], ["Sprint", "Shift"], ["Crouch", "Ctrl / C"],
					["Jump", "Space"], ["Reload", "R"], ["Grenade", "G"], ["Melee takedown", "F / V"], ["Interact · read intel · use uplink", "E"], ["Answer", "1  2  3  4"], ["Pause", "Esc"]]:
				var h := UIKit.hbox(10); body.add_child(h)
				var l := UIKit.label(row[0], UIKit.body(22)); l.custom_minimum_size = Vector2(420, 0); h.add_child(l)
				h.add_child(UIKit.kbd(row[1]))

func _apply(k: String, v) -> void:
	Game.settings[k] = v
	Game.apply_settings()
	Game.persist()

func _row(label: String, hint := "") -> HBoxContainer:
	var wrap := UIKit.vbox(0); body.add_child(wrap)
	var h := UIKit.hbox(16); wrap.add_child(h)
	var l := UIKit.label(label, UIKit.body(22)); l.custom_minimum_size = Vector2(420, 0); h.add_child(l)
	if hint != "":
		var hl := UIKit.label(hint, UIKit.body(16), UIKit.DIM); hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; hl.custom_minimum_size = Vector2(760, 0); wrap.add_child(hl)
	return h

func _choice(label: String, opts: Array, val: int, cb: Callable, hint := "") -> void:
	var h := _row(label, hint)
	var state := [clampi(val, 0, opts.size() - 1)]
	var left := UIKit.small_button("◀", accent); h.add_child(left)
	var v := UIKit.label(String(opts[state[0]]), UIKit.head(26), UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER); v.custom_minimum_size = Vector2(200, 0); h.add_child(v)
	var right := UIKit.small_button("▶", accent); h.add_child(right)
	var step := func(d: int):
		state[0] = wrapi(state[0] + d, 0, opts.size()); v.text = String(opts[state[0]]); cb.call(state[0])
	left.pressed.connect(step.bind(-1)); right.pressed.connect(step.bind(1))

func _toggle(label: String, val: bool, cb: Callable) -> void:
	var h := _row(label)
	var b := UIKit.small_button("ON" if val else "OFF", accent); b.custom_minimum_size = Vector2(120, 0); h.add_child(b)
	b.toggle_mode = true; b.button_pressed = val
	b.toggled.connect(func(on): b.text = "ON" if on else "OFF"; cb.call(on))

func _slider(label: String, mn: float, mx: float, st: float, val: float, cb: Callable, fmt := "%.2f", mul := 1.0) -> void:
	var h := _row(label)
	var vl := UIKit.label(fmt % (val * mul), UIKit.mono(18), UIKit.DIM); vl.custom_minimum_size = Vector2(80, 0)
	var s := UIKit.slider(mn, mx, st, val, func(v): vl.text = fmt % (v * mul); cb.call(v))
	h.add_child(s); h.add_child(vl)
