class_name LoadingUI
extends Control
## Loading card: mission title, location, chapter, and a concept tip pulled from that chapter's intel.

var mi := 0
var spin: Control
var status: Label
var t := 0.0

static func tip_for(mi: int) -> String:
	var M: Dictionary = Game.missions[clampi(mi, 0, Game.missions.size() - 1)]
	var pool: Array = []
	for R in M["rooms"]:
		for I in R.get("intel", []):
			for para in String(I["bb"]).split("\n\n"):
				if para.begins_with("[b]") and para.length() > 60 and para.length() < 420: pool.append(para)
		for C in R.get("calls", []):
			pool.append(String(C["why"]))
	if pool.is_empty(): return ""
	return String(pool[randi() % pool.size()])

func _ready() -> void:
	UIKit.full(self)
	var M: Dictionary = Game.missions[mi]
	var bg := ColorRect.new(); bg.color = Color(0.02, 0.025, 0.03); UIKit.full(bg); add_child(bg)
	var acc := Color(M["color"])
	var v := UIKit.vbox(6); add_child(v); v.position = Vector2(120, 0)
	v.add_child(UIKit.label(("FINAL MISSION" if M.get("final", false) else "MISSION %d" % (mi + 1)), UIKit.mono(18), acc))
	v.add_child(UIKit.label(String(M["code"]), UIKit.head(120)))
	v.add_child(UIKit.label("%s   ·   %s" % [String(M["loc"]), String(M["time"])], UIKit.body(24), UIKit.DIM))
	v.add_child(UIKit.label(Game.chapter_tag(M), UIKit.mono(16), UIKit.DIM))
	v.add_child(UIKit.spacer(50))
	var tip := UIKit.rich("[color=#8d969b]CONCEPT[/color]\n" + tip_for(mi), 22); tip.custom_minimum_size = Vector2(900, 0); v.add_child(tip)
	v.name = "V"
	status = UIKit.label("BUILDING SECTORS", UIKit.mono(15), UIKit.DIM); add_child(status)
	spin = Control.new(); add_child(spin); spin.draw.connect(_draw_spin)

func ready_to_go() -> void:
	status.text = "READY"

func _process(dt: float) -> void:
	t += dt
	var vs := get_viewport_rect().size
	var v: Control = get_node("V")
	v.position.y = vs.y * 0.5 - v.size.y * 0.5
	status.position = Vector2(vs.x - 300, vs.y - 80)
	spin.position = Vector2(vs.x - 330, vs.y - 68)
	spin.queue_redraw()

func _draw_spin() -> void:
	spin.draw_arc(Vector2.ZERO, 10, t * 5.0, t * 5.0 + 4.2, 24, Color(1, 1, 1, 0.7), 2.0)
