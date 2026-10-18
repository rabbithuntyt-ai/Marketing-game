extends Node3D
var frames=0
var shots=[]
func _ready():
	var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color(.15,.17,.2);e.ambient_light_color=Color(.6,.6,.65);e.ambient_light_energy=.6;e.tonemap_mode=Environment.TONE_MAPPER_ACES;env.environment=e;add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-50,30,0);sun.light_energy=2;sun.shadow_enabled=true;add_child(sun)
	var fl=MeshInstance3D.new();fl.mesh=PlaneMesh.new();fl.mesh.size=Vector2(20,20);add_child(fl)
	var lib1:AnimationLibrary=load("res://assets/anim/UAL1.glb");var lib2:AnimationLibrary=load("res://assets/anim/UAL2.glb")
	print("lib1 anims ",lib1.get_animation_list().slice(0,6));var an=lib1.get_animation(lib1.get_animation_list()[30]);print(an.get_track_count()," ",an.track_get_path(0)," ",an.track_get_path(1))
	var names=["soldier_idle","Jog_Fwd","Pistol_Aim_Neutral","Idle_Talking","Crouch_Idle","Walk_Carry"]
	for i in names.size():
		var s=load("res://assets/models/soldier.gltf").instantiate();add_child(s);s.position=Vector3(-3.75+i*1.5,0,0)
		var ap:AnimationPlayer=s.find_children("*","AnimationPlayer",true,false)[0]
		if i==0: print("soldier libs ",ap.get_animation_library_list()," tracks0: ",ap.get_animation("soldier_idle").track_get_path(0))
		ap.add_animation_library("u1",lib1);ap.add_animation_library("u2",lib2)
		var n=names[i];if not ap.has_animation(n): n="u1/"+n
		if not ap.has_animation(n): n="u2/"+names[i]
		ap.play(n);ap.seek(0.4,true)
	var c=Camera3D.new();c.position=Vector3(0,1.3,4.2);c.fov=60;add_child(c);c.look_at(Vector3(0,0.95,0))
func _process(d):
	frames+=1
	if frames==12:
		get_viewport().get_texture().get_image().save_png("res://tools/rt.png");get_tree().quit()
