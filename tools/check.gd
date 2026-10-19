extends Node
## Loads every script under res://src and res://levels so parse/compile errors for all files show up in one run.
func _ready():
	var files: Array = []
	_scan("res://src", files)
	if DirAccess.dir_exists_absolute("res://levels"): _scan("res://levels", files)
	var bad := 0
	for f in files:
		var s = ResourceLoader.load(f, "", ResourceLoader.CACHE_MODE_IGNORE)
		if s == null or not (s as GDScript).can_instantiate():
			bad += 1
			print("FAIL ", f)
	var sm := StandardMaterial3D.new(); print("PROPS z_clip=", "use_z_clip_scale" in sm, " fov=", "use_fov_override" in sm)
	print("checked %d scripts, %d failed" % [files.size(), bad])
	get_tree().quit()

func _scan(d: String, out: Array) -> void:
	var da := DirAccess.open(d)
	for f in da.get_files():
		if f.ends_with(".gd"): out.append(d + "/" + f)
	for sd in da.get_directories(): _scan(d + "/" + sd, out)
