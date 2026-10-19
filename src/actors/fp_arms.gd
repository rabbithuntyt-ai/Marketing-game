class_name FPArms
extends Node3D
## First-person arms (CC0 "FPS Arms Rig" by the OpenGameArt community, MakeHuman base) posed on the
## rifle at runtime: each hand is placed on its grip point with a hand frame (wrist position, finger
## direction, palm normal), fingers are curled per joint, and a two-bone IK chain brings each forearm
## to its wrist with the elbow pulled toward a magnet. Everything lives in the rifle's local space, so
## the arms ride every bob, kick and reload the viewmodel does.

const ARMS := "res://assets/fps/arms.fbx"

var skel: Skeleton3D
var rifle: Node3D
var _iks: Array = []

## Rifle-space hold. Rifle: +z forward, +y up, -x is the shooter's right side.
## wrist, finger direction, palm normal, curls [01, 02, 03] for index/middle/ring/pinky, thumb [01, 02, 03]
var HOLD := {
	"R": {"wrist": Vector3(-0.045, -0.015, -0.275), "fwd": Vector3(0.05, -0.62, 0.78), "palm": Vector3(1, 0, 0.05),
		"curl": {"index": [18, 30, 18], "middle": [72, 62, 40], "ring": [76, 64, 40], "pinky": [80, 64, 40]},
		"thumb": [-10, 25, 20], "elbow": Vector3(-0.35, -0.45, -0.45)},
	"L": {"wrist": Vector3(0.075, -0.05, 0.11), "fwd": Vector3(-0.62, 0.12, 0.78), "palm": Vector3(-0.35, 0.94, 0.0),
		"curl": {"index": [40, 45, 30], "middle": [48, 48, 32], "ring": [52, 50, 32], "pinky": [55, 50, 32]},
		"thumb": [0, 18, 15], "elbow": Vector3(0.45, -0.5, -0.2)},
}
const SHOULDER_MID := Vector3(0.2, -0.085, -0.4)   # rifle-space point between the shoulders (below and behind the eye)
const SCALE := 1.2

func setup(r: Node3D) -> bool:
	rifle = r
	if not ResourceLoader.exists(ARMS): return false
	var inst: Node3D = (load(ARMS) as PackedScene).instantiate()
	add_child(inst)
	var found := inst.find_children("*", "Skeleton3D", true, false)
	if found.is_empty(): return false
	skel = found[0]
	scale = Vector3.ONE * SCALE
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/fps/arms_gear.png")
	mat.normal_enabled = true; mat.normal_texture = load("res://assets/fps/arms_gear_n.png"); mat.normal_scale = 0.35
	mat.roughness = 0.82
	for m in inst.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).material_override = mat
		(m as MeshInstance3D).layers = 2
		(m as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# put the shoulders where they belong: midpoint of the two upper-arm heads at SHOULDER_MID
	var ra := skel.find_bone("upper_arm.R"); var la := skel.find_bone("upper_arm.L")
	var to_self := _skel_to_self()
	var mid := (to_self * skel.get_bone_global_rest(ra).origin + to_self * skel.get_bone_global_rest(la).origin) * 0.5
	position = SHOULDER_MID - mid * SCALE
	for side in ["R", "L"]: _pose_hand(side)
	for side in ["R", "L"]: _arm_ik(side)
	return true

## skeleton space -> this node's local space (before our own scale)
func _skel_to_self() -> Transform3D:
	var t := Transform3D.IDENTITY; var n: Node = skel
	while n != null and n != self:
		if n is Node3D: t = (n as Node3D).transform * t
		n = n.get_parent()
	return t

## rifle space -> skeleton space
func _rifle_to_skel() -> Transform3D:
	return (transform * _skel_to_self()).affine_inverse()

func _frame(f: Vector3, a: Vector3, n: Vector3) -> Basis:
	return Basis(f, a, n)

func _pose_hand(side: String) -> void:
	var h: Dictionary = HOLD[side]
	var ctrl := skel.find_bone("hand.%s.control" % side)
	var hand := skel.find_bone("hand.%s" % side)
	if ctrl < 0 or hand < 0: return
	var g := func(b: String) -> Vector3: return skel.get_bone_global_rest(skel.find_bone(b)).origin
	# rest-pose hand frame in skeleton space
	var w: Vector3 = g.call("hand." + side)
	var f_r: Vector3 = (g.call("f_middle.01." + side) - w).normalized()
	var a_r: Vector3 = (g.call("f_index.01." + side) - g.call("f_pinky.01." + side))
	a_r = (a_r - f_r * a_r.dot(f_r)).normalized()
	var n_r: Vector3 = a_r.cross(f_r) if side == "R" else f_r.cross(a_r)
	# desired frame, rifle space -> skeleton space
	var rs := _rifle_to_skel()
	var f_d: Vector3 = (rs.basis * Vector3(h["fwd"])).normalized()
	var n_d: Vector3 = (rs.basis * Vector3(h["palm"])).normalized()
	n_d = (n_d - f_d * n_d.dot(f_d)).normalized()
	var a_d: Vector3 = f_d.cross(n_d) if side == "R" else n_d.cross(f_d)
	var rot := _frame(f_d, a_d, n_d) * _frame(f_r, a_r, n_r).inverse()
	var rest := skel.get_bone_global_rest(ctrl)
	var pose := Transform3D(rot * rest.basis, rs * Vector3(h["wrist"]))
	skel.set_bone_pose(ctrl, pose)   # root bone: pose == global pose
	# finger curls about the knuckle axis, toward the palm
	var sgn := 1.0 if side == "R" else -1.0
	for finger in ["index", "middle", "ring", "pinky"]:
		var angles: Array = h["curl"][finger]
		for j in 3:
			var b := skel.find_bone("f_%s.0%d.%s" % [finger, j + 1, side])
			if b < 0: continue
			var gb := skel.get_bone_global_rest(b).basis
			var axis := (gb.inverse() * a_r).normalized()
			skel.set_bone_pose_rotation(b, skel.get_bone_rest(b).basis.get_rotation_quaternion() * Quaternion(axis, sgn * deg_to_rad(float(angles[j]))))
	# thumb: swing toward the palm, then curl its joints
	var th: Array = h["thumb"]
	for j in 3:
		var b := skel.find_bone("thumb.0%d.%s" % [j + 1, side])
		if b < 0: continue
		var gb := skel.get_bone_global_rest(b).basis
		var ax: Vector3 = (f_r if j == 0 else a_r)
		var axis := (gb.inverse() * ax).normalized()
		skel.set_bone_pose_rotation(b, skel.get_bone_rest(b).basis.get_rotation_quaternion() * Quaternion(axis, sgn * deg_to_rad(float(th[j]))))

func _arm_ik(side: String) -> void:
	var h: Dictionary = HOLD[side]
	var tgt := Node3D.new(); tgt.name = "Wrist" + side
	rifle.add_child(tgt); tgt.position = h["wrist"]
	var ik := SkeletonIK3D.new(); ik.name = "IK" + side
	ik.root_bone = "upper_arm." + side; ik.tip_bone = "forearm.%s_end" % side
	ik.override_tip_basis = false
	ik.use_magnet = true; ik.magnet = _rifle_to_skel() * Vector3(h["elbow"])
	ik.max_iterations = 10; ik.min_distance = 0.001
	skel.add_child(ik)
	ik.target_node = ik.get_path_to(tgt)
	ik.start()
	_iks.append(ik)
