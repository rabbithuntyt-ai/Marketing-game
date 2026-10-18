class_name CreditsRoll
extends Control
## End-of-campaign credits crawl. Any key speeds it up; Esc returns to the menu.

var main: Node
var col: VBoxContainer
var speed := 46.0
var y := 0.0

func _ready() -> void:
	UIKit.full(self)
	var bg := ColorRect.new(); bg.color = Color.BLACK; UIKit.full(bg); add_child(bg)
	col = UIKit.vbox(10); add_child(col)
	var add := func(t: String, f: Dictionary, c := UIKit.TEXT):
		var l := UIKit.label(t, f, c, HORIZONTAL_ALIGNMENT_CENTER); l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.custom_minimum_size = Vector2(1000, 0); col.add_child(l)
	add.call("OPERATION", UIKit.head(40), UIKit.DIM)
	add.call("VALUE CHAIN", UIKit.head(110))
	col.add_child(UIKit.spacer(30))
	add.call("Meridian's contracts are frozen. The towns keep their suppliers.", UIKit.body(24), UIKit.DIM)
	add.call("You've covered Chapters 1 to 7: customer value, strategy, the environment, information, buyer behaviour, segmentation and positioning, products, services and brands.", UIKit.body(24), UIKit.DIM)
	col.add_child(UIKit.spacer(60))
	for c in Game.content.get("credits", []):
		add.call(String(c["h"]).to_upper(), UIKit.mono(16), UIKit.GOLD)
		for l in c["l"]: add.call(String(l), UIKit.body(24))
		col.add_child(UIKit.spacer(36))
	add.call("CAST", UIKit.mono(16), UIKit.GOLD)
	for k in ["HALE", "MARR", "RUIZ", "VOSS", "KESSLER", "OSTROWSKI"]:
		var sp := Game.speaker(k)
		add.call("%s  ·  %s" % [String(sp.get("name", k)), String(sp.get("role", ""))], UIKit.body(24))
	col.add_child(UIKit.spacer(36))
	add.call("Every voice in this game was synthesized. Every character is fictional.\nCastellan Group, LEDGER and Project Meridian do not exist.", UIKit.body(20), UIKit.DIM)
	col.add_child(UIKit.spacer(120))
	add.call("Thank you for playing.", UIKit.head(48))
	y = get_viewport_rect().size.y + 40.0
	Audio.music("remember", 2.0, 0.0)

func _process(dt: float) -> void:
	var vs := get_viewport_rect().size
	var fast := Input.is_anything_pressed()
	y -= dt * speed * (5.0 if fast else 1.0)
	col.reset_size()
	col.position = Vector2(vs.x * 0.5 - col.size.x * 0.5, y)
	if y + col.size.y < vs.y * 0.45:
		set_process(false)
		await get_tree().create_timer(3.0).timeout
		main.show_menu()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and (e as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled(); set_process(false); main.show_menu()
