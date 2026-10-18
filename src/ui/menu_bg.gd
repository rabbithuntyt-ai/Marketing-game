class_name MenuBG
extends Node3D
## Live 3D backdrop for the main menu: the LEDGER staging bay at night. Wren checks a rifle, Ruiz waits
## on a crate, rain on the skylight, emergency light sweeping through volumetric haze.

var cam: Camera3D
var t := 0.0
var beacon: SpotLight3D
var wren: Humanoid
var ruiz: Humanoid

func _ready() -> void:
	Props.init()
	var q := int(Game.settings["quality"])
	var we := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.01, 0.012, 0.016)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.3, 0.34, 0.42); e.ambient_light_energy = 0.25
	e.tonemap_mode = Environment.TONE_MAPPER_AGX; e.tonemap_exposure = 1.05
	e.glow_enabled = true; e.glow_intensity = 0.7; e.glow_bloom = 0.06; e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	e.ssao_enabled = q >= 1; e.ssao_intensity = 2.0
	e.volumetric_fog_enabled = q >= 1; e.volumetric_fog_density = 0.035; e.volumetric_fog_albedo = Color(0.8, 0.82, 0.9); e.volumetric_fog_anisotropy = 0.6
	e.fog_enabled = true; e.fog_density = 0.02; e.fog_light_color = Color(0.04, 0.05, 0.06)
	e.adjustment_enabled = true; e.adjustment_contrast = 1.1; e.adjustment_saturation = 0.9
	we.environment = e; add_child(we)
	var ca := CameraAttributesPractical.new(); ca.dof_blur_far_enabled = true; ca.dof_blur_far_distance = 9.0; ca.dof_blur_far_transition = 6.0; ca.dof_blur_amount = 0.06
	we.camera_attributes = ca
	# floor + walls
	var floor := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(40, 40); floor.mesh = pm; floor.material_override = Mats.pbr("floor", 3.0); add_child(floor)
	for spec in [[Vector3(0, 5, -7), Vector3(30, 10, 0.4), "tech"], [Vector3(-9, 5, 0), Vector3(0.4, 10, 30), "rivet"], [Vector3(9, 5, 0), Vector3(0.4, 10, 30), "rivet"]]:
		var w := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = spec[1]; w.mesh = bm; w.position = spec[0]; w.material_override = Mats.pbr(spec[2], 3.0); add_child(w)
	# set dressing
	Props.spawn("prop_container", self, Vector3(-4.5, 0, -5.0), 1, false)
	Props.spawn("prop_cargobox2", self, Vector3(4.0, 0, -3.8), 0, false)
	Props.spawn("prop_cargobox4", self, Vector3(5.2, 0, -1.8), 1, false)
	Props.spawn("prop_smallbox2", self, Vector3(-1.2, 0, -2.6), 0, false)
	Props.spawn("prop_barrel2", self, Vector3(-2.4, 0, -1.4), 0, false)
	Props.spawn("prop_floodlight", self, Vector3(6.5, 0, -5.6), 3, false)
	# light strips on the back wall
	for i in 5:
		var s := MeshInstance3D.new(); var bm2 := BoxMesh.new(); bm2.size = Vector3(2.2, 0.06, 0.05); s.mesh = bm2
		s.material_override = Mats.glow(Color(1.0, 0.75, 0.4), 4.0); s.position = Vector3(-6 + i * 3, 3.6, -6.75); add_child(s)
	var key := SpotLight3D.new(); key.light_color = Color(1.0, 0.82, 0.6); key.light_energy = 14.0; key.spot_range = 16; key.spot_angle = 28; key.shadow_enabled = true; key.light_volumetric_fog_energy = 1.5
	add_child(key); key.look_at_from_position(Vector3(-1.0, 6.0, 3.0), Vector3(1.4, 1.0, -1.6))
	var rim := SpotLight3D.new(); rim.light_color = Color(0.35, 0.55, 1.0); rim.light_energy = 10.0; rim.spot_range = 14; rim.spot_angle = 40; rim.shadow_enabled = q >= 1
	add_child(rim); rim.look_at_from_position(Vector3(3.5, 4.5, -6.0), Vector3(1.4, 1.2, -1.5))
	beacon = SpotLight3D.new(); beacon.light_color = Color(1.0, 0.25, 0.15); beacon.light_energy = 6.0; beacon.spot_range = 20; beacon.spot_angle = 18; beacon.light_volumetric_fog_energy = 3.0
	beacon.position = Vector3(-6.5, 6.5, -5.0); add_child(beacon)
	var fill := OmniLight3D.new(); fill.light_color = Color(1.0, 0.7, 0.45); fill.light_energy = 0.8; fill.omni_range = 7; fill.position = Vector3(0, 2, 2); add_child(fill)
	# characters
	wren = Humanoid.new(); wren.team = "neutral"; add_child(wren); wren.setup("wren")
	wren.set_physics_process(false); wren.position = Vector3(0.7, 0, -1.0); wren.rotation.y = deg_to_rad(205)
	wren.play("soldier_idle")
	ruiz = Humanoid.new(); ruiz.team = "neutral"; add_child(ruiz); ruiz.setup("ally")
	ruiz.set_physics_process(false); ruiz.position = Vector3(2.5, 0, -2.3); ruiz.rotation.y = deg_to_rad(150)
	ruiz.hide_weapon(); ruiz.play("Idle_FoldArms")
	# dust motes
	var p := GPUParticles3D.new(); p.amount = 300; p.lifetime = 12.0; p.preprocess = 12.0; p.visibility_aabb = AABB(Vector3(-8, 0, -8), Vector3(16, 8, 16))
	var pmat := ParticleProcessMaterial.new(); pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX; pmat.emission_box_extents = Vector3(6, 3, 4)
	pmat.gravity = Vector3(0, -0.01, 0); pmat.initial_velocity_min = 0.02; pmat.initial_velocity_max = 0.08; pmat.direction = Vector3(1, 0.2, 0); pmat.spread = 180
	pmat.scale_min = 0.6; pmat.scale_max = 1.2; p.process_material = pmat
	var qm := QuadMesh.new(); qm.size = Vector2(0.015, 0.015)
	var dm := StandardMaterial3D.new(); dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED; dm.albedo_color = Color(1, 0.9, 0.75, 0.5)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; dm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD; qm.material = dm; p.draw_pass_1 = qm
	p.position = Vector3(1, 3, -1); add_child(p)
	cam = Camera3D.new(); cam.fov = 38; add_child(cam); cam.current = true
	_cam(0.0)

func _cam(tt: float) -> void:
	var a := sin(tt * 0.06) * 0.18
	cam.position = Vector3(-0.6 + sin(tt * 0.05) * 0.5, 1.35 + sin(tt * 0.08) * 0.06, 3.6)
	cam.look_at(Vector3(1.9 + a, 1.25, -1.6))

func _process(dt: float) -> void:
	t += dt
	_cam(t)
	beacon.rotation = Vector3(-0.6, t * 1.8, 0)
