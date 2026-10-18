class_name Blur
extends RefCounted
## Full-screen frosted backdrop for modal overlays: blurred, darkened copy of the game view.

static var _shader: Shader

static func make(dark := 0.7) -> Control:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float dark = 0.7;
uniform float lod = 3.0;
void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 c = textureLod(screen_tex, uv, lod).rgb * 0.5;
	c += textureLod(screen_tex, uv + vec2(0.004, 0.0), lod).rgb * 0.125;
	c += textureLod(screen_tex, uv - vec2(0.004, 0.0), lod).rgb * 0.125;
	c += textureLod(screen_tex, uv + vec2(0.0, 0.006), lod).rgb * 0.125;
	c += textureLod(screen_tex, uv - vec2(0.0, 0.006), lod).rgb * 0.125;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, 0.5) * (1.0 - dark);
	float v = distance(uv, vec2(0.5)) * 1.1;
	c *= 1.0 - v * v * 0.8;
	COLOR = vec4(c, 1.0);
}
"""
	var r := ColorRect.new()
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := ShaderMaterial.new(); m.shader = _shader; m.set_shader_parameter("dark", dark)
	r.material = m
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	return r
