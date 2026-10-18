class_name PauseUI
extends Control
## Pause menu: resume, restart from checkpoint, field notes (intel recovered so far), settings, quit.

var main: Node
var right: Control
var accent: Color

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIKit.full(self)
	add_child(Blur.make(0.6))
	var M: Dictionary = Game.missions[Game.mission_index]
	accent = Color(M["color"])
	var root := UIKit.hbox(60); add_child(root); root.position = Vector2(110, 110)
	var left := UIKit.vbox(6); root.add_child(left); left.custom_minimum_size = Vector2(420, 0)
	left.add_child(UIKit.label("PAUSED", UIKit.mono(16), accent))
	left.add_child(UIKit.label(String(M["code"]), UIKit.head(72)))
	var obj := ""
	if main.mission and main.mission.cur_room: obj = main.mission.cur_room.mode.objective()
	var ol := UIKit.label(obj, UIKit.body(20), UIKit.DIM); ol.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; ol.custom_minimum_size = Vector2(400, 0); left.add_child(ol)
	left.add_child(UIKit.spacer(24))
	var items := [["Resume", func(): main.resume_game()], ["Field notes", _notes], ["Settings", _settings],
		["Restart sector", func(): main.restart_room()], ["Quit to menu", func(): main.quit_to_menu()]]
	var first: Button = null
	for it in items:
		var b := UIKit.button(it[0], accent, 34); left.add_child(b); b.pressed.connect(it[1])
		if first == null: first = b
	first.call_deferred("grab_focus")
	right = UIKit.vbox(10); root.add_child(right); right.custom_minimum_size = Vector2(1000, 760)
	_notes()

func _clear() -> void:
	for c in right.get_children(): c.queue_free()

func _notes() -> void:
	_clear()
	var M: Dictionary = Game.missions[Game.mission_index]
	right.add_child(UIKit.label("FIELD NOTES  ·  " + Game.chapter_tag(M), UIKit.mono(15), accent))
	var docs: Array = []
	for ri in M["rooms"].size():
		var R: Dictionary = M["rooms"][ri]
		var intel: Array = R.get("intel", [])
		for k in intel.size():
			if Game.save["intel"].has("%s-%d-%d" % [M["id"], ri, k]): docs.append([intel[k], ri])
	if docs.is_empty():
		right.add_child(UIKit.label("Nothing recovered yet. Intel glows on desks and walls in each sector.", UIKit.body(20), UIKit.DIM))
		return
	var split := UIKit.hbox(20); right.add_child(split)
	var list := UIKit.vbox(2); split.add_child(list); list.custom_minimum_size = Vector2(330, 0)
	var view := Control.new(); view.custom_minimum_size = Vector2(650, 720); split.add_child(view)
	var show := func(d: Array):
		for c in view.get_children(): c.queue_free()
		var iv := IntelView.new(); iv.archive = true; iv.doc = d[0]; iv.M = M; iv.ri = d[1]; iv.main = main
		iv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); view.add_child(iv)
	for d in docs:
		var b := UIKit.button(String(d[0]["t"]), accent, 20); b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; b.custom_minimum_size = Vector2(330, 0)
		list.add_child(b); b.pressed.connect(show.bind(d))
	show.call(docs[0])

func _settings() -> void:
	_clear()
	var sp := SettingsPanel.new(); sp.accent = accent; right.add_child(sp)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and (e as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		main.resume_game()
