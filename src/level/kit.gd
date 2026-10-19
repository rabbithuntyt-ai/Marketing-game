class_name Kit
extends RefCounted
## Asset catalogue for hand-built sectors.
##   "q:<Piece>"  Quaternius Modular Sci-Fi MegaKit (CC0), 4 m grid, walls 3 m + 2 m top band
##   "ph:<id>"    Poly Haven model (CC0), real-world scale
##   "tps:<name>" Godot TPS-demo prop (CC BY 3.0) via Props
## Collision: "box" (AABB), "mesh" (trimesh, for stairs/ramps/walls), "none".

static var _scenes := {}
static var _bounds := {}
static var _shapes := {}

static func path_of(id: String) -> String:
	if id.begins_with("q:"): return "res://assets/kit/scifi/%s.gltf" % id.substr(2)
	if id.begins_with("ph:"):
		var n := id.substr(3)
		return "res://assets/ph/%s/%s.gltf" % [n, n]
	return ""

static func scene(id: String) -> PackedScene:
	if _scenes.has(id): return _scenes[id]
	var p := path_of(id)
	var ps: PackedScene = load(p) if p != "" and ResourceLoader.exists(p) else null
	if ps == null: push_warning("Kit: missing " + id)
	_scenes[id] = ps
	return ps

## Local-space bounds of a piece (cached).
static func bounds(id: String) -> AABB:
	if _bounds.has(id): return _bounds[id]
	var ps := scene(id)
	var b := AABB()
	if ps:
		var n: Node3D = ps.instantiate()
		b = Props._aabb(n)
		n.free()
	_bounds[id] = b
	return b

static func spawn(id: String, parent: Node3D, xf: Transform3D, col := "box", shadow := true) -> Node3D:
	if id.begins_with("tps:"):
		var t := Props.spawn(id.substr(4), parent, xf.origin, 1, col != "none")
		if t: t.basis = xf.basis
		return t
	var ps := scene(id)
	if ps == null: return null
	var n: Node3D = ps.instantiate()
	parent.add_child(n)
	n.transform = xf
	for m in n.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	match col:
		"box":
			var b := bounds(id)
			if b.size.y < 0.02: b = b.grow(0.01)
			var body := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
			sh.size = b.size; cs.shape = sh; cs.position = b.get_center(); body.add_child(cs); n.add_child(body)
		"mesh":
			for m in n.find_children("*", "MeshInstance3D", true, false):
				var mi := m as MeshInstance3D
				var key := "%s|%s" % [id, mi.mesh.resource_path if mi.mesh.resource_path != "" else str(mi.mesh.get_instance_id())]
				if not _shapes.has(key): _shapes[key] = mi.mesh.create_trimesh_shape()
				var body2 := StaticBody3D.new(); var cs2 := CollisionShape3D.new(); cs2.shape = _shapes[key]; body2.add_child(cs2); mi.add_child(body2)
	return n
