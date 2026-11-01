class_name Background
extends Control
## Warm sky gradient, glowing sun and a turquoise Persian-tile strip at the bottom.
## Port of src/ui/Background.js (react-native-svg -> _draw()).
##
## NOTE: like in the RN app, App.js does NOT use this node (the world map covers the whole screen),
## so main.gd doesn't add it. It's ported so it's available (e.g. for menus / loading screen).

var _sun: GradientTexture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1.0, 0.976, 0.863, 0.95), Color(1.0, 0.914, 0.627, 0.0)])
	_sun = GradientTexture2D.new()
	_sun.gradient = g
	_sun.fill = GradientTexture2D.FILL_RADIAL
	_sun.fill_from = Vector2(0.5, 0.5)
	_sun.fill_to = Vector2(1.0, 0.5)
	_sun.width = 128
	_sun.height = 128

	resized.connect(queue_redraw)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var dp := UiKit.dp_scale(w)

	# sky: 3-stop vertical gradient (two quads)
	var c0 := Color("#ffeec4")
	var c1 := Color("#f6c987")
	var c2 := Color("#e39a4f")
	var y1 := h * 0.6
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, y1), Vector2(0, y1)]),
		PackedColorArray([c0, c0, c1, c1]))
	draw_polygon(PackedVector2Array([Vector2(0, y1), Vector2(w, y1), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([c1, c1, c2, c2]))

	# sun
	var r := 120.0 * dp
	var c := Vector2(w * 0.82, 110.0 * dp)
	draw_texture_rect(_sun, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false)

	# tile strip
	var tile := 30.0 * dp
	var count := int(ceil(w / tile)) + 1
	var y := h - tile - 6.0 * dp
	draw_rect(Rect2(0, y - 4.0 * dp, w, tile + 12.0 * dp), Color("#14605f"))
	for i in count:
		var cx := float(i) * tile
		var dark := i % 2 == 0
		var outer := Color("#1d8b8b") if dark else Color("#f7e7c3")
		var inner := Color("#f0b93a") if dark else Color("#1d8b8b")
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx, y), Vector2(cx + tile / 2.0, y + tile / 2.0),
			Vector2(cx, y + tile), Vector2(cx - tile / 2.0, y + tile / 2.0)]), outer)
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx, y + 8.0 * dp), Vector2(cx + 7.0 * dp, y + tile / 2.0),
			Vector2(cx, y + tile - 8.0 * dp), Vector2(cx - 7.0 * dp, y + tile / 2.0)]), inner)
