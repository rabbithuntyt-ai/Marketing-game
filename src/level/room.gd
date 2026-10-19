class_name Room
extends Node3D
## One sector of a mission. Holds geometry references and runtime state; a mode script drives its gameplay.

var ri := 0
var data: Dictionary = {}
var kind := "combat"
var W := 22.0
var D := 28.0
var H := 6.5
var z0 := 0.0
var z1 := -28.0
var cz0 := 0.0
var cz1 := 0.0
var outdoor := false
var entered := false
var cleared := false
var done := false          # objective complete: exit door unlocked
var door: Node3D
var door_body: StaticBody3D
var door_t := -1.0
var door_closed_y := 0.0
var entry_door: Node3D
var enemies: Array = []
var intel: Array = []      # pickup nodes
var terminal: Node3D
var spawn_points: Array[Vector3] = []
var cover_points: Array[Vector3] = []
var lights: Array = []
var shadow_lights: Array = []
var mode: Node = null
var nav: NavigationRegion3D
var calls_done := false
var q_queue: Array = []
var bonus_mark := false
# hand-built sectors (levels/<mission>/s<ri>.gd)
var authored := false
var guards: Array = []         # {pos, yaw, patrol, waits, looks, variant, veteran}
var dark_zones: Array = []     # Rect2 in world XZ
var cams: Array = []
var sector: RefCounted = null
var panels: Node = null          # CallPanels: in-world answer consoles replace the uplink menu
var extra: Array = []            # sector interactables: {pos, radius, prompt, cb}

func in_dark(p: Vector3) -> bool:
	for z in dark_zones:
		if (z as Rect2).has_point(Vector2(p.x, p.z)): return true
	return false

func center() -> Vector3: return Vector3(0, 0, (z0 + z1) * 0.5)

func contains(p: Vector3) -> bool:
	return p.z <= z0 + 0.5 and p.z > cz1 - 0.3

func alive_enemies() -> Array:
	return enemies.filter(func(e): return is_instance_valid(e) and not e.dead)

func open_exit(instant := false) -> void:
	if door == null or door_t >= 0.0: return
	door_t = 1.0 if instant else 0.0
	if door_body: door_body.process_mode = Node.PROCESS_MODE_DISABLED; door_body.collision_layer = 0
	if instant: door.position.y = door_closed_y + 3.5
	else: Audio.play3d("door_open", door.global_position, 2.0, 0.02, 10.0)

func _process(dt: float) -> void:
	if door_t >= 0.0 and door_t < 1.0:
		door_t = minf(1.0, door_t + dt * 0.8)
		var t := door_t * door_t * (3.0 - 2.0 * door_t)
		door.position.y = door_closed_y + t * 3.5
