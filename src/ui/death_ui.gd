class_name DeathUI
extends Control
## Death screen with a concept tip from the current chapter.

var main: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIKit.full(self)
	var bg := Blur.make(0.55); add_child(bg)
	var red := ColorRect.new(); UIKit.full(red); red.color = Color(0.4, 0.0, 0.0, 0.25); red.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(red)
	var v := UIKit.vbox(10); add_child(v)
	v.add_child(UIKit.label("SIGNAL LOST", UIKit.mono(16), UIKit.RED, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UIKit.label("YOU WERE KILLED", UIKit.head(84), UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	var tip := LoadingUI.tip_for(Game.mission_index)
	var tl := UIKit.rich("[center][color=#c9a25a]WHILE YOU'RE HERE[/color]\n" + tip + "[/center]", 21); tl.custom_minimum_size = Vector2(900, 0); v.add_child(tl)
	v.add_child(UIKit.spacer(20))
	var row := UIKit.hbox(16); row.alignment = BoxContainer.ALIGNMENT_CENTER; v.add_child(row)
	var acc := Color(Game.missions[Game.mission_index]["color"])
	var b1 := UIKit.small_button("Retry from checkpoint", acc); row.add_child(b1); b1.pressed.connect(func(): main.restart_room())
	var b2 := UIKit.small_button("Quit to menu", acc); row.add_child(b2); b2.pressed.connect(func(): main.quit_to_menu())
	b1.call_deferred("grab_focus")
	v.reset_size()
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	v.position = get_viewport_rect().size * 0.5 - v.size * 0.5
	modulate.a = 0.0; create_tween().tween_property(self, "modulate:a", 1.0, 0.6)
	if randf() < 0.6: Audio.say_generic("g_death_%d" % (randi() % 2), true)

func _process(_dt: float) -> void:
	var v: Control = get_child(2)
	v.position = get_viewport_rect().size * 0.5 - v.size * 0.5

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and (e as InputEventKey).keycode in [KEY_SPACE, KEY_ENTER]:
		get_viewport().set_input_as_handled(); main.restart_room()
