class_name LevelEnv
extends Node3D
## Per-mission environment: sky, fog, post-processing, moonlight, and weather (rain, storm, snow, fog).

var env: Environment
var we: WorldEnvironment
var moon: DirectionalLight3D
var rain: GPUParticles3D
var splash: GPUParticles3D
var snow: GPUParticles3D
var weather := ""
var _lightning_t := 6.0
var _flash := 0.0
var outdoor_now := false
var base_moon := 0.25
var theme := ""

const LOOKS := {
	"compound": {"sky_top": Color(0.03, 0.04, 0.06), "sky_hor": Color(0.12, 0.11, 0.1), "amb": Color(0.32, 0.34, 0.4), "amb_e": 0.35, "fog": Color(0.07, 0.08, 0.1), "fog_d": 0.012, "vol": 0.018, "exp": 1.0},
	"bunker": {"sky_top": Color(0.02, 0.03, 0.05), "sky_hor": Color(0.08, 0.09, 0.12), "amb": Color(0.3, 0.36, 0.45), "amb_e": 0.3, "fog": Color(0.05, 0.06, 0.08), "fog_d": 0.01, "vol": 0.014, "exp": 1.0},
	"port": {"sky_top": Color(0.02, 0.03, 0.04), "sky_hor": Color(0.07, 0.1, 0.11), "amb": Color(0.26, 0.34, 0.38), "amb_e": 0.32, "fog": Color(0.06, 0.08, 0.09), "fog_d": 0.02, "vol": 0.03, "exp": 1.05},
	"data": {"sky_top": Color(0.02, 0.02, 0.04), "sky_hor": Color(0.08, 0.07, 0.12), "amb": Color(0.3, 0.3, 0.45), "amb_e": 0.25, "fog": Color(0.06, 0.06, 0.09), "fog_d": 0.016, "vol": 0.025, "exp": 0.95},
	"mall": {"sky_top": Color(0.02, 0.02, 0.04), "sky_hor": Color(0.1, 0.08, 0.1), "amb": Color(0.42, 0.38, 0.42), "amb_e": 0.38, "fog": Color(0.07, 0.06, 0.08), "fog_d": 0.007, "vol": 0.01, "exp": 1.05},
	"array": {"sky_top": Color(0.18, 0.22, 0.3), "sky_hor": Color(0.55, 0.5, 0.5), "amb": Color(0.45, 0.48, 0.55), "amb_e": 0.45, "fog": Color(0.42, 0.45, 0.5), "fog_d": 0.018, "vol": 0.02, "exp": 1.0},
	"vault": {"sky_top": Color(0.02, 0.03, 0.06), "sky_hor": Color(0.12, 0.1, 0.12), "amb": Color(0.4, 0.38, 0.36), "amb_e": 0.35, "fog": Color(0.06, 0.06, 0.08), "fog_d": 0.006, "vol": 0.01, "exp": 1.0},
	"board": {"sky_top": Color(0.02, 0.03, 0.06), "sky_hor": Color(0.14, 0.11, 0.12), "amb": Color(0.4, 0.4, 0.42), "amb_e": 0.35, "fog": Color(0.06, 0.06, 0.08), "fog_d": 0.005, "vol": 0.008, "exp": 1.0},
}

func setup(mission: Dictionary) -> void:
	theme = mission["theme"]
	var L: Dictionary = LOOKS.get(theme, LOOKS["compound"])
	var q := int(Game.settings["quality"])
	env = Environment.new()
	var sky := Sky.new(); var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = L["sky_top"]; sm.sky_horizon_color = L["sky_hor"]; sm.ground_horizon_color = L["sky_hor"]; sm.ground_bottom_color = Color(0.01, 0.01, 0.015)
	sm.sun_angle_max = 0.0; sm.sky_energy_multiplier = 1.0
	sky.sky_material = sm; env.sky = sky; env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = L["amb"]; env.ambient_light_energy = L["amb_e"] * 2.0
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX; env.tonemap_exposure = L["exp"] * 1.15; env.tonemap_white = 6.0
	env.glow_enabled = true; env.glow_intensity = 0.55; env.glow_strength = 0.9; env.glow_bloom = 0.04; env.glow_hdr_threshold = 1.1; env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.set_glow_level(1, 0.6); env.set_glow_level(3, 0.9); env.set_glow_level(5, 0.6)
	env.ssao_enabled = q >= 1; env.ssao_radius = 1.2; env.ssao_intensity = 2.2; env.ssao_detail = 0.6
	env.ssil_enabled = q >= 2; env.ssil_intensity = 0.6
	env.ssr_enabled = q >= 3; env.ssr_max_steps = 48; env.ssr_fade_in = 0.2
	env.fog_enabled = true; env.fog_light_color = L["fog"]; env.fog_density = L["fog_d"]; env.fog_aerial_perspective = 0.3; env.fog_sky_affect = 0.6
	env.volumetric_fog_enabled = q >= 2; env.volumetric_fog_density = L["vol"]; env.volumetric_fog_albedo = Color(0.85, 0.85, 0.9)
	env.volumetric_fog_emission = Color(0, 0, 0); env.volumetric_fog_length = 48.0; env.volumetric_fog_gi_inject = 0.0; env.volumetric_fog_anisotropy = 0.5
	env.adjustment_enabled = true; env.adjustment_contrast = 1.08; env.adjustment_saturation = 0.92; env.adjustment_brightness = 1.0
	we = WorldEnvironment.new(); we.environment = env; add_child(we)
	var ca := CameraAttributesPractical.new(); ca.auto_exposure_enabled = false
	we.camera_attributes = ca
	moon = DirectionalLight3D.new(); moon.rotation_degrees = Vector3(-38, -35, 0)
	moon.light_color = Color(0.6, 0.7, 0.9) if theme != "array" else Color(1.0, 0.85, 0.7)
	base_moon = 0.22 if theme != "array" else 0.9
	moon.light_energy = base_moon; moon.shadow_enabled = q >= 1; moon.directional_shadow_max_distance = 55.0
	moon.light_volumetric_fog_energy = 0.4
	add_child(moon)
	var wset := {}
	for r in mission["rooms"]:
		if r.get("weather", "") != "": wset[r["weather"]] = true
	if wset.has("rain") or wset.has("storm"): _make_rain(wset.has("storm"))
	if wset.has("snow"): _make_snow()

func _drop_mat(c: Color, size: Vector2) -> Array:
	var qm := QuadMesh.new(); qm.size = size
	var m := StandardMaterial3D.new(); m.albedo_color = c; m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y; m.billboard_keep_scale = true
	return [qm, m]

func _make_rain(storm: bool) -> void:
	rain = GPUParticles3D.new(); rain.amount = 5000 if storm else 3600; rain.lifetime = 1.1; rain.visibility_aabb = AABB(Vector3(-20, -20, -20), Vector3(40, 40, 40))
	var pm := ParticleProcessMaterial.new(); pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX; pm.emission_box_extents = Vector3(16, 1, 16)
	pm.direction = Vector3(0.18 if storm else 0.05, -1, 0.05); pm.spread = 2.0; pm.initial_velocity_min = 18.0; pm.initial_velocity_max = 22.0; pm.gravity = Vector3(0, -9.8, 0)
	rain.process_material = pm
	var dm := _drop_mat(Color(0.7, 0.75, 0.82, 0.32), Vector2(0.015, 0.55))
	rain.draw_pass_1 = dm[0]; dm[0].material = dm[1]
	rain.emitting = false; add_child(rain)
	splash = GPUParticles3D.new(); splash.amount = 900; splash.lifetime = 0.35; splash.visibility_aabb = rain.visibility_aabb
	var sp := ParticleProcessMaterial.new(); sp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX; sp.emission_box_extents = Vector3(14, 0.02, 14)
	sp.direction = Vector3.UP; sp.spread = 60.0; sp.initial_velocity_min = 0.8; sp.initial_velocity_max = 1.8; sp.gravity = Vector3(0, -9, 0); sp.scale_min = 0.5; sp.scale_max = 1.0
	splash.process_material = sp
	var sm2 := _drop_mat(Color(0.8, 0.85, 0.9, 0.35), Vector2(0.04, 0.06))
	splash.draw_pass_1 = sm2[0]; sm2[0].material = sm2[1]
	splash.emitting = false; add_child(splash)
	weather = "storm" if storm else "rain"

func _make_snow() -> void:
	snow = GPUParticles3D.new(); snow.amount = 4200; snow.lifetime = 5.5; snow.visibility_aabb = AABB(Vector3(-20, -20, -20), Vector3(40, 40, 40))
	var pm := ParticleProcessMaterial.new(); pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX; pm.emission_box_extents = Vector3(18, 1, 18)
	pm.direction = Vector3(0.6, -1, 0.2); pm.spread = 25.0; pm.initial_velocity_min = 1.5; pm.initial_velocity_max = 3.0; pm.gravity = Vector3(0, -1.2, 0)
	pm.turbulence_enabled = true; pm.turbulence_noise_strength = 1.2; pm.turbulence_noise_scale = 3.0; pm.scale_min = 0.6; pm.scale_max = 1.4
	snow.process_material = pm
	var qm := QuadMesh.new(); qm.size = Vector2(0.04, 0.04)
	var m := StandardMaterial3D.new(); m.albedo_color = Color(1, 1, 1, 0.85); m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.material = m; snow.draw_pass_1 = qm; snow.emitting = false; add_child(snow)
	weather = "snow"

## Called every frame by the mission with the camera position and whether the current room is outdoors.
func update(dt: float, cam: Vector3, outdoor: bool, room_weather: String) -> void:
	outdoor_now = outdoor
	var w_on := outdoor and room_weather != "" and room_weather != "fog"
	if rain:
		rain.emitting = w_on and room_weather in ["rain", "storm"]; splash.emitting = rain.emitting
		rain.global_position = cam + Vector3(0, 9, 0); splash.global_position = Vector3(cam.x, 0.02, cam.z)
	if snow:
		snow.emitting = w_on and room_weather == "snow"; snow.global_position = cam + Vector3(0, 10, 0)
	if room_weather == "storm" and outdoor:
		_lightning_t -= dt
		if _lightning_t <= 0:
			_lightning_t = randf_range(7.0, 16.0); _flash = 1.0
			get_tree().create_timer(randf_range(0.4, 1.6)).timeout.connect(func(): Audio.play2d("thunder_near" if randf() < 0.5 else "thunder_far", -2.0, 0.08))
	_flash = maxf(0.0, _flash - dt * 2.6)
	var flick := _flash * (0.6 + 0.4 * sin(_flash * 60.0))
	moon.light_energy = (base_moon if outdoor else base_moon * 0.4) + flick * 4.0
	env.ambient_light_energy = LOOKS.get(theme, LOOKS["compound"])["amb_e"] + flick * 0.8
