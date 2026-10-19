extends ModeBase
## Mole hunt: clear the floor, then run Marr's investigation as a research project on the evidence board.

var solved := false
var board: Node3D

func setup() -> void:
	var n := maxi(3, int(r.data.get("e", 5)) + int(Game.diff()["cnt"]))
	populate(n)
	var b := Builder.new(m, m.M)
	board = Node3D.new(); r.add_child(board); board.position = r.get_meta("board_pos", Vector3(0, 0, r.z1 + 3.0))
	board.rotation.y = r.get_meta("board_rot", 0.0)
	b.box(board, Vector3(6.0, 3.0, 0.1), Vector3(0, 2.2, 0), Mats.flat(Color(0.03, 0.035, 0.04), 0.35), false, false)
	b.label(board, "CASE FILE · LEDGER LEAK", Vector3(-2.8, 3.45, 0.06), 0, 40, Color(0.75, 0.65, 1.0), "IBMPlexMono-Medium")
	var S: Array = r.data["evidence"]["suspects"]
	for k in S.size():
		var x := -2.4 + k * 1.2
		b.box(board, Vector3(1.0, 1.3, 0.04), Vector3(x, 2.1, 0.07), Mats.flat(Color(0.85, 0.83, 0.78), 0.9), false, false)
		var l := b.label(board, "%s\n%s" % [S[k]["name"], S[k]["role"]], Vector3(x, 1.6, 0.1), 0, 22, Color(0.1, 0.1, 0.1), "Barlow-SemiBold", 230, HORIZONTAL_ALIGNMENT_CENTER, true)
	b.omni(board, Vector3(0, 3.0, 2.0), Color(0.8, 0.75, 1.0), 1.0, 6.0)

func uses_terminal() -> bool: return false

func enter() -> void:
	if r.alive_enemies().size() > 0: m.breach()

func objective() -> String:
	if r.done: return "Advance to the next sector"
	if r.alive_enemies().size() > 0: return "Eliminate hostiles  (%d)" % r.alive_enemies().size()
	if not solved: return "Run the investigation at the evidence board"
	return default_objective()

func interactables() -> Array:
	if solved or r.alive_enemies().size() > 0: return []
	return [{"pos": board.global_position + board.global_basis.z * 1.6, "radius": 2.4, "prompt": "Open the case file", "cb": _open}]

func _open() -> void:
	m.main.open_evidence(r.data["evidence"], func():
		solved = true; say_post()
		Game.add_xp(300, "CASE SOLVED"))

func tick(_dt: float) -> void:
	if solved and not r.done and intel_left() == 0: complete()
