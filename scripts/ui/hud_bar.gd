class_name HudBar
extends Control
## Flat progress bar of the HUD (fills from the left). Part of src/ui/Hud.js (`Bar`).

const INK := Color("#0E1740")
const TRACK := Color("#16215A")
const FILL := Color("#5EE27A")

## 0..1
var value := 0.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
		queue_redraw()

## outline width in px
var border := 3.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	draw_style_box(UiKit.flat(TRACK, size.y * 0.5, border, INK), Rect2(Vector2.ZERO, size))
	var inner := Rect2(Vector2(border, border), size - Vector2(border, border) * 2.0)
	var fill_w := inner.size.x * value
	if fill_w < 0.5 or inner.size.y <= 0.0:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = FILL
	sb.corner_radius_top_left = int(inner.size.y * 0.5)
	sb.corner_radius_bottom_left = int(inner.size.y * 0.5)
	sb.anti_aliasing = true
	draw_style_box(sb, Rect2(inner.position, Vector2(fill_w, inner.size.y)))
