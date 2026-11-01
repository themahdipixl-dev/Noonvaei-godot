class_name UiKit
extends RefCounted
## Small shared helpers for the Part 3 UI (labels, styleboxes, safe area, scale).
##
## UNITS: the RN code used dp (a ~400dp wide phone). Godot's reference viewport is 1080 px wide,
## so  1 dp  ==  width / 400  px  (see `dp_scale`). Everything in the UI is multiplied by it.

const DP_REF_WIDTH := 400.0


## px per dp for a given viewport width.
static func dp_scale(width: float) -> float:
	return width / DP_REF_WIDTH


## Safe-area insets (camera notch / gesture bar) in VIEWPORT pixels.
## Replaces react-native-safe-area-context. On desktop everything is 0.
static func safe_insets(viewport: Viewport) -> Dictionary:
	var out := {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}
	if not (OS.has_feature("android") or OS.has_feature("ios")):
		return out
	var win := DisplayServer.window_get_size()
	var safe := DisplayServer.get_display_safe_area()
	if win.x <= 0 or win.y <= 0 or safe.size.x <= 0 or safe.size.y <= 0:
		return out
	var vp := viewport.get_visible_rect().size
	var kx := vp.x / float(win.x)
	var ky := vp.y / float(win.y)
	out["top"] = maxf(0.0, float(safe.position.y)) * ky
	out["bottom"] = maxf(0.0, float(win.y - (safe.position.y + safe.size.y))) * ky
	out["left"] = maxf(0.0, float(safe.position.x)) * kx
	out["right"] = maxf(0.0, float(win.x - (safe.position.x + safe.size.x))) * kx
	return out


## Rounded flat box (optionally with an outline).
static func flat(bg: Color, radius: float, border_w: float = 0.0, border_c: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(int(round(radius)))
	if border_w > 0.0:
		sb.set_border_width_all(maxi(1, int(round(border_w))))
		sb.border_color = border_c
	sb.anti_aliasing = true
	return sb


## Persian-ready label (mouse ignored). `font_key` is an AppFonts key ("regular", "bold", "title"...).
static func make_label(text: String, size: float, color: Color, font_key: String = "regular",
		h_align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER,
		v_align: VerticalAlignment = VERTICAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.language = "fa"
	l.text = text
	l.horizontal_alignment = h_align
	l.vertical_alignment = v_align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", int(round(size)))
	l.add_theme_color_override("font_color", color)
	var f := AppFonts.get_font(font_key)
	if f != null:
		l.add_theme_font_override("font", f)
	return l


## Puts a label in a rectangle and keeps its text vertically centered in it.
## (A Label can't be smaller than its line height, so when the rect is shorter than one line we grow
## the label equally up and down instead of letting it grow downward only.)
static func place_label(l: Label, rect: Rect2) -> void:
	var fs := l.get_theme_font_size("font_size")
	var f := l.get_theme_font("font")
	var line_h := f.get_height(fs) if f != null else float(fs) * 1.3
	var h := maxf(rect.size.y, line_h)
	l.size = Vector2(rect.size.x, h)
	l.position = Vector2(rect.position.x, rect.position.y + (rect.size.y - h) * 0.5)


## JS `adjustsFontSizeToFit`: shrinks the font until the text fits `max_width`, then sets the text.
static func fit_text(label: Label, text: String, base_size: float, max_width: float, min_size: float = 10.0) -> void:
	var font := label.get_theme_font("font")
	var sz := base_size
	if font != null:
		while sz > min_size and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(round(sz))).x > max_width:
			sz -= 1.0
	label.add_theme_font_size_override("font_size", int(round(sz)))
	label.text = text
