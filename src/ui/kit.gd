class_name UIKit
extends RefCounted
## Shared UI building blocks: fonts, colours, styled panels, buttons, labels, sliders.

const BG := Color(0.035, 0.042, 0.05, 0.86)
const BG_SOLID := Color(0.03, 0.035, 0.042, 1.0)
const LINE := Color(1, 1, 1, 0.12)
const TEXT := Color(0.93, 0.945, 0.94)
const DIM := Color(0.62, 0.66, 0.68)
const RED := Color(1.0, 0.36, 0.3)
const GREEN := Color(0.45, 0.95, 0.62)
const GOLD := Color(1.0, 0.8, 0.4)

static var _fonts := {}
static func font(name: String) -> FontFile:
	if not _fonts.has(name): _fonts[name] = load("res://assets/fonts/%s.ttf" % name)
	return _fonts[name]

static func head(size := 40) -> Dictionary: return {"font": font("Rajdhani-Bold"), "size": size}
static func body(size := 22) -> Dictionary: return {"font": font("Barlow-Medium"), "size": size}
static func mono(size := 16) -> Dictionary: return {"font": font("IBMPlexMono-Medium"), "size": size}

static func label(text: String, f: Dictionary, col := TEXT, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new(); l.text = text
	l.add_theme_font_override("font", f["font"]); l.add_theme_font_size_override("font_size", f["size"])
	l.add_theme_color_override("font_color", col); l.horizontal_alignment = align
	return l

static func rich(bb: String, size := 21) -> RichTextLabel:
	var r := RichTextLabel.new(); r.bbcode_enabled = true; r.text = bb; r.fit_content = true; r.scroll_active = false
	r.add_theme_font_override("normal_font", font("Barlow-Regular")); r.add_theme_font_override("bold_font", font("Barlow-SemiBold"))
	r.add_theme_font_override("italics_font", font("Barlow-Italic")); r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size); r.add_theme_color_override("default_color", TEXT)
	r.add_theme_constant_override("line_separation", 6)
	return r

static func panel_style(bg := BG, accent := Color(0, 0, 0, 0), border := LINE, radius := 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color = bg; s.border_color = border; s.set_border_width_all(1)
	if accent.a > 0: s.border_width_left = 4; s.border_color = border
	s.set_corner_radius_all(radius); s.content_margin_left = 22; s.content_margin_right = 22; s.content_margin_top = 18; s.content_margin_bottom = 18
	s.shadow_color = Color(0, 0, 0, 0.35); s.shadow_size = 18
	return s

static func panel(bg := BG, accent := Color(0, 0, 0, 0)) -> PanelContainer:
	var p := PanelContainer.new()
	var s := panel_style(bg, accent)
	if accent.a > 0:
		s.set_border_width_all(0); s.border_width_left = 4; s.border_color = accent
	p.add_theme_stylebox_override("panel", s)
	return p

static func button(text: String, accent: Color, size := 30) -> Button:
	var b := Button.new(); b.text = text.to_upper(); b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_override("font", font("Rajdhani-Bold")); b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", Color(0.86, 0.88, 0.88)); b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE); b.add_theme_color_override("font_pressed_color", accent)
	b.add_theme_color_override("font_disabled_color", Color(0.4, 0.42, 0.44))
	var n := StyleBoxFlat.new(); n.bg_color = Color(0, 0, 0, 0); n.content_margin_left = 18; n.content_margin_right = 18; n.content_margin_top = 6; n.content_margin_bottom = 6
	var h := n.duplicate(); h.bg_color = Color(1, 1, 1, 0.06); h.border_width_left = 4; h.border_color = accent; h.content_margin_left = 26
	b.add_theme_stylebox_override("normal", n); b.add_theme_stylebox_override("hover", h); b.add_theme_stylebox_override("focus", h)
	b.add_theme_stylebox_override("pressed", h); b.add_theme_stylebox_override("disabled", n)
	b.mouse_entered.connect(func(): Audio.play2d("kenney_weapon_change", -24.0, 0.15, "UI"))
	b.pressed.connect(func(): Audio.play2d("empty", -16.0, 0.05, "UI"))
	return b

static func small_button(text: String, accent: Color) -> Button:
	var b := button(text, accent, 22)
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var n := StyleBoxFlat.new(); n.bg_color = Color(1, 1, 1, 0.05); n.set_border_width_all(1); n.border_color = Color(1, 1, 1, 0.18); n.content_margin_left = 22; n.content_margin_right = 22; n.content_margin_top = 8; n.content_margin_bottom = 8
	var h := n.duplicate(); h.bg_color = Color(accent.r, accent.g, accent.b, 0.22); h.border_color = accent
	b.add_theme_stylebox_override("normal", n); b.add_theme_stylebox_override("hover", h); b.add_theme_stylebox_override("focus", h); b.add_theme_stylebox_override("pressed", h)
	return b

static func vbox(sep := 8) -> VBoxContainer:
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", sep); return v

static func hbox(sep := 8) -> HBoxContainer:
	var h := HBoxContainer.new(); h.add_theme_constant_override("separation", sep); return h

static func rule(col := LINE, h := 1) -> ColorRect:
	var c := ColorRect.new(); c.color = col; c.custom_minimum_size = Vector2(0, h); c.mouse_filter = Control.MOUSE_FILTER_IGNORE; return c

static func spacer(h := 12.0) -> Control:
	var c := Control.new(); c.custom_minimum_size = Vector2(0, h); c.mouse_filter = Control.MOUSE_FILTER_IGNORE; return c

static func full(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); return c

static func slider(minv: float, maxv: float, step: float, val: float, cb: Callable) -> HSlider:
	var s := HSlider.new(); s.min_value = minv; s.max_value = maxv; s.step = step; s.value = val; s.custom_minimum_size = Vector2(320, 28)
	var g := StyleBoxFlat.new(); g.bg_color = Color(1, 1, 1, 0.12); g.content_margin_top = 3; g.content_margin_bottom = 3
	var f := StyleBoxFlat.new(); f.bg_color = Color(1.0, 0.75, 0.35); f.content_margin_top = 3; f.content_margin_bottom = 3
	s.add_theme_stylebox_override("slider", g); s.add_theme_stylebox_override("grabber_area", f); s.add_theme_stylebox_override("grabber_area_highlight", f)
	s.value_changed.connect(cb)
	return s

static func kbd(k: String) -> Label:
	var l := label(k, mono(15), Color(0.05, 0.06, 0.07), HORIZONTAL_ALIGNMENT_CENTER)
	var s := StyleBoxFlat.new(); s.bg_color = Color(0.92, 0.93, 0.92); s.set_corner_radius_all(3); s.content_margin_left = 7; s.content_margin_right = 7; s.content_margin_top = 1; s.content_margin_bottom = 1
	l.add_theme_stylebox_override("normal", s)
	return l
