class_name Props
extends RefCounted
## Prop library (Godot TPS demo props, CC-BY 3.0) and city-kit models (Quaternius, CC0).

static var _tpl := {}
static var _bounds := {}
static var _city := {}

static func init() -> void:
	if not _tpl.is_empty(): return
	var root: Node = load("res://assets/props/props.gltf").instantiate()
	var matmap := {
		"mid_cargo_box": Mats.prop("cargo", {"metal": 0.5}), "container2": Mats.prop("cont2", {"metal": 0.5}),
		"container3": Mats.prop("cont3", {"metal": 0.5}), "container4": Mats.prop("cont4", {"metal": 0.5}),
		"tile_painted_gun_metal": Mats.pbr("gunmetal", 1.5), "reactor_cylinder": Mats.prop("reactor", {"metal": 0.5}),
		"flat_emitter_orange": Mats.glow(Color(1.0, 0.62, 0.25), 3.0), "flat_emitter_white": Mats.glow(Color(0.9, 0.95, 1.0), 3.0),
		"flat_emitter_powerful_white": Mats.glow(Color(0.95, 0.97, 1.0), 5.0), "scifi_car_glass": Mats.glass(),
	}
	var c4: ORMMaterial3D = matmap["container4"]
	c4.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR; c4.alpha_scissor_threshold = 0.5; c4.cull_mode = BaseMaterial3D.CULL_DISABLED
	for child in root.get_children():
		var n: Node3D = child
		root.remove_child(n)
		for mi in n.find_children("*", "MeshInstance3D", true, false) + ([n] if n is MeshInstance3D else []):
			var m := mi as MeshInstance3D
			for s in m.mesh.get_surface_count():
				var sm := m.mesh.surface_get_material(s)
				if sm and matmap.has(sm.resource_name): m.set_surface_override_material(s, matmap[sm.resource_name])
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		n.transform = Transform3D.IDENTITY
		_tpl[n.name] = n
		_bounds[n.name] = _aabb(n)
	root.free()

static func _aabb(n: Node3D) -> AABB:
	var box := AABB(); var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false) + ([n] if n is MeshInstance3D else []):
		var m := mi as MeshInstance3D
		var a := m.get_aabb()
		var xf := _rel(n, m)
		a = xf * a
		box = a if first else box.merge(a); first = false
	return box

static func _rel(root: Node3D, n: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY; var c: Node = n
	while c != root and c != null:
		t = (c as Node3D).transform * t; c = c.get_parent()
	return t

static func has(name: String) -> bool:
	init(); return _tpl.has(name)

static func size(name: String, rot := 0) -> Vector3:
	init()
	var b: AABB = _bounds.get(name, AABB(Vector3.ZERO, Vector3.ONE))
	return Vector3(b.size.z, b.size.y, b.size.x) if rot % 2 == 1 else b.size

## Spawn a prop. rot = quarter turns. Returns the node; adds a box collider unless col=false.
static func spawn(name: String, parent: Node3D, pos: Vector3, rot := 0, col := true, mat: Material = null) -> Node3D:
	init()
	if not _tpl.has(name): return null
	var n: Node3D = _tpl[name].duplicate()
	parent.add_child(n)
	n.position = pos; n.rotation.y = rot * PI * 0.5
	if mat:
		for mi in n.find_children("*", "MeshInstance3D", true, false) + ([n] if n is MeshInstance3D else []):
			for s in (mi as MeshInstance3D).mesh.get_surface_count(): (mi as MeshInstance3D).set_surface_override_material(s, mat)
	if col:
		var b: AABB = _bounds[name]
		var body := StaticBody3D.new(); body.collision_layer = 1; body.collision_mask = 0
		var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = b.size; cs.shape = sh; cs.position = b.get_center()
		body.add_child(cs); n.add_child(body)
	return n

## City kit model (glTF with its own materials). Collision optional (box).
static func city(name: String, parent: Node3D, pos: Vector3, rot_y := 0.0, scale := 1.0, col := false) -> Node3D:
	if not _city.has(name):
		var p := "res://assets/city/%s.gltf" % name
		_city[name] = load(p) if ResourceLoader.exists(p) else null
	if _city[name] == null: return null
	var n: Node3D = _city[name].instantiate()
	parent.add_child(n); n.position = pos; n.rotation.y = rot_y; n.scale = Vector3.ONE * scale
	if col:
		var b := _aabb(n)
		var body := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = b.size; cs.shape = sh; cs.position = b.get_center()
		body.add_child(cs); n.add_child(body)
	return n
