class_name CartoonButton
extends BaseButton
## Cartoon button of the HUD. Port of `Btn` (+ `PlusBtn`) in src/ui/Hud.js
##
## One outer ink stroke around [face + bottom lip]. The face has no outline of its own and the lip
## has exactly the face width. Put child nodes in `content` (its origin = top-left of the face).
## All sizes are given in DESIGN px and multiplied by `s`.

const INK := Color("#0E1740")
const SW := 3.0        # outline width (design px)
const PRESS_DY := 5.0  # how far the button sinks when pressed (design px)

## Children of the face go here.
var content: Control

var _s := 1.0
var _plain := false
var _down := false
var _glow := 0.0
var _sb_outer: StyleBoxFlat
var _sb_face: StyleBoxFlat
var _sb_glow: StyleBoxFlat
var _face_rect := Rect2()


func _init() -> void:
	focus_mode = Control.FOCUS_NONE


## `face` = the face rectangle in design px (x, y, w, h). `interactive = false` -> like the JS `<View>` (no press).
func setup(s: float, face: Rect2, radius: float, color: Color, lip_color: Color,
		lip: float, glow: float, interactive: bool) -> void:
	_s = s
	_glow = glow
	position = Vector2(face.position.x - SW, face.position.y - SW) * s
	size = Vector2(face.size.x + SW * 2.0, face.size.y + lip + SW * 2.0) * s
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE

	_sb_outer = UiKit.flat(lip_color, (radius + SW) * s, SW * s, INK)
	_sb_face = UiKit.flat(color, radius * s)
	_sb_glow = StyleBoxFlat.new()
	_sb_glow.draw_center = false
	_sb_glow.set_corner_radius_all(int(round(radius * s)))
	_sb_glow.border_width_top = maxi(1, int(round(3.0 * s)))
	_sb_glow.border_color = Color(1, 1, 1, glow)
	_sb_glow.anti_aliasing = true

	_face_rect = Rect2(Vector2(SW, SW) * s, face.size * s)
	_make_content(_face_rect.position, _face_rect.size)
	button_down.connect(_on_down)
	button_up.connect(_on_up)


## Invisible button that only scales its content when pressed (the "+" in the money / gems pills).
## `rect` in design px, `slop` = extra touch area around it (JS hitSlop).
func setup_plain(s: float, rect: Rect2, slop: float) -> void:
	_s = s
	_plain = true
	position = (rect.position - Vector2(slop, slop)) * s
	size = (rect.size + Vector2(slop, slop) * 2.0) * s
	mouse_filter = Control.MOUSE_FILTER_STOP
	_make_content(Vector2(slop, slop) * s, rect.size * s)
	button_down.connect(_on_down)
	button_up.connect(_on_up)


func _make_content(pos: Vector2, sz: Vector2) -> void:
	content = Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.position = pos
	content.size = sz
	content.pivot_offset = sz * 0.5
	add_child(content)


func _on_down() -> void:
	_down = true
	_apply_press()


func _on_up() -> void:
	_down = false
	_apply_press()


func _apply_press() -> void:
	if _plain:
		content.scale = Vector2(0.9, 0.9) if _down else Vector2.ONE
	else:
		content.position = _face_rect.position + (Vector2(0.0, PRESS_DY * _s) if _down else Vector2.ZERO)
		queue_redraw()


func _draw() -> void:
	if _plain:
		return
	var off := Vector2(0.0, PRESS_DY * _s) if _down else Vector2.ZERO
	draw_style_box(_sb_outer, Rect2(off, size))
	draw_style_box(_sb_face, Rect2(off + _face_rect.position, _face_rect.size))
	if _glow > 0.0:
		draw_style_box(_sb_glow, Rect2(off + _face_rect.position, _face_rect.size))
