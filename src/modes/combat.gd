extends ModeBase
## Standard sector: breach, clear, read intel, answer Marr's analysis calls at the uplink.

var silent := false      # hand-built sector entered with guards still unaware

func setup() -> void:
	if r.authored and not r.guards.is_empty():
		spawn_guards(true); silent = true; return
	var n := maxi(2, int(r.data.get("e", 3)) + int(Game.diff()["cnt"]))
	populate(n)

func enter() -> void:
	if silent: return
	if r.alive_enemies().size() > 0 and r.ri > 0:
		m.breach()

func is_loud() -> bool: return not silent

func on_detected() -> void:
	if not silent: return
	silent = false
	for e in r.alive_enemies(): e.alert(false)

func tick(_dt: float) -> void:
	if not r.entered: return
	if silent:
		var aw := 0.0
		for e in r.alive_enemies(): aw = maxf(aw, e.awareness)
		for c in r.cams:
			if not c.dead: aw = maxf(aw, c.seen)
		m.main.hud.detection(aw)
	elif r.authored: m.main.hud.detection(0.0)
	if not r.cleared and r.alive_enemies().is_empty():
		r.cleared = true
		if silent: Game.add_xp(150, "SILENT CLEAR")
		m.main.hud.toast("SECTOR CLEAR", "Recover the intel, then the uplink" if intel_left() > 0 else "", Color(0.85, 0.9, 0.9))
		if m.ally and m.ally.visible: Audio.bark("RUIZ", "last")
		say_post()
	if r.cleared and not r.done and not has_calls() and intel_left() == 0:
		complete()

func objective() -> String: return default_objective()
