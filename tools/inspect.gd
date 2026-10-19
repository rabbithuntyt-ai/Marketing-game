extends SceneTree
func _init():
	for p in ["res://assets/models/soldier.gltf","res://assets/chars/director_2.glb"]:
		var s=load(p)
		if s==null: print("FAIL ",p); continue
		var n=s.instantiate(); print("== ",p); _dump(n,0)
		var sk=n.find_children("*","Skeleton3D",true,false)
		for k in sk: print("SKEL ",n.get_path_to(k)," bones=",k.get_bone_count()," first=",k.get_bone_name(0),",",k.get_bone_name(1),",",k.get_bone_name(2))
		var ap=n.find_children("*","AnimationPlayer",true,false)
		for a in ap: print("ANIMPLAYER ",n.get_path_to(a)," libs=",a.get_animation_library_list()," n=",a.get_animation_list().size()); 
	quit()
func _dump(n,d):
	if d>4: return
	print("  ".repeat(d),n.name," <",n.get_class(),">")
	for c in n.get_children(): _dump(c,d+1)
