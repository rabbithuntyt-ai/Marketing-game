extends ModeBase
## Standard sector: breach, clear, read intel, answer Marr's analysis calls at the uplink.

func setup() -> void:
	var n := maxi(2, int(r.data.get("e", 3)) + int(Game.diff()["cnt"]))
	m.spawn_room_enemies(r, n)

func enter() -> void:
	if r.alive_enemies().size() > 0 and r.ri > 0:
		m.breach()

func tick(_dt: float) -> void:
	if not r.entered: return
	if not r.cleared and r.alive_enemies().is_empty():
		r.cleared = true
		m.main.hud.toast("SECTOR CLEAR", "Recover the intel, then the uplink" if intel_left() > 0 else "", Color(0.85, 0.9, 0.9))
		if m.ally and m.ally.visible: Audio.bark("RUIZ", "last")
		say_post()
	if r.cleared and not r.done and not has_calls() and intel_left() == 0:
		complete()

func objective() -> String: return default_objective()
