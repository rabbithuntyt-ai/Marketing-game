class_name Mats
extends RefCounted
## PBR material library built from the TPS-demo and city-kit texture sets. World-triplanar so any box keeps scale.

static var _cache := {}

static func tex(path: String) -> Texture2D:
	if _cache.has(path): return _cache[path]
	var t: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_cache[path] = t
	return t

## name: texture set in assets/tex (e.g. "tech"); scale: metres per tile
static func pbr(name: String, scale := 3.0, tint := Color.WHITE, opts := {}) -> ORMMaterial3D:
	var key := "%s|%s|%s|%s" % [name, scale, tint.to_html(), str(opts)]
	if _cache.has(key): return _cache[key]
	var m := ORMMaterial3D.new()
	m.albedo_texture = tex("res://assets/tex/%s_albedo.png" % name)
	m.albedo_color = tint
	m.normal_enabled = true
	m.normal_texture = tex("res://assets/tex/%s_normal.png" % name)
	m.normal_scale = opts.get("normal", 1.0)
	m.orm_texture = tex("res://assets/tex/%s_orm.png" % name)
	m.metallic = opts.get("metal", 1.0)
	m.roughness = opts.get("rough", 1.0)
	m.uv1_triplanar = opts.get("triplanar", true)
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / scale
	m.uv1_triplanar_sharpness = 4.0
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var em := tex("res://assets/tex/%s_emission.png" % name)
	if em and opts.get("emission", true):
		m.emission_enabled = true; m.emission_texture = em; m.emission = opts.get("em_color", Color.WHITE); m.emission_energy_multiplier = opts.get("em_energy", 2.0)
	_cache[key] = m
	return m

## Material for an imported prop mesh (uses the mesh's own UVs)
static func prop(name: String, opts := {}) -> ORMMaterial3D:
	var o := opts.duplicate(); o["triplanar"] = false
	var m := pbr(name, 1.0, opts.get("tint", Color.WHITE), o)
	m.uv1_scale = Vector3.ONE
	return m

static func city(base: String, normal: String, orm: String, scale := 4.0, tint := Color.WHITE) -> ORMMaterial3D:
	var key := "city|" + base + str(scale) + tint.to_html()
	if _cache.has(key): return _cache[key]
	var m := ORMMaterial3D.new()
	m.albedo_texture = tex("res://assets/city/tex/%s.png" % base); m.albedo_color = tint
	m.normal_enabled = true; m.normal_texture = tex("res://assets/city/tex/%s.png" % normal)
	m.orm_texture = tex("res://assets/city/tex/%s.png" % orm)
	m.uv1_triplanar = true; m.uv1_world_triplanar = true; m.uv1_scale = Vector3.ONE / scale
	_cache[key] = m
	return m

static func flat(c: Color, rough := 0.7, metal := 0.0) -> StandardMaterial3D:
	var key := "flat|%s|%s|%s" % [c.to_html(), rough, metal]
	if _cache.has(key): return _cache[key]
	var m := StandardMaterial3D.new(); m.albedo_color = c; m.roughness = rough; m.metallic = metal
	_cache[key] = m
	return m

static func glow(c: Color, energy := 2.5) -> StandardMaterial3D:
	var key := "glow|%s|%s" % [c.to_html(), energy]
	if _cache.has(key): return _cache[key]
	var m := StandardMaterial3D.new(); m.albedo_color = c; m.emission_enabled = true; m.emission = c; m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cache[key] = m
	return m

static func glass() -> StandardMaterial3D:
	if _cache.has("glass"): return _cache["glass"]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.12, 0.17, 0.2, 0.28); m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.roughness = 0.05; m.metallic = 0.2
	m.metallic_specular = 0.9; m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cache["glass"] = m
	return m

static func screen(t: Texture2D, energy := 1.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_texture = t; m.emission_enabled = true; m.emission_texture = t; m.emission_energy_multiplier = energy
	m.roughness = 0.25; m.metallic = 0.0
	return m

static func decal_mat(t: Texture2D, alpha := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_texture = t; m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.albedo_color = Color(1, 1, 1, alpha)
	m.roughness = 0.9; m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
