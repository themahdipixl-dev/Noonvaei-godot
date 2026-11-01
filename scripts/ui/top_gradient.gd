class_name TopGradient
extends TextureRect
## Short black -> transparent gradient at the very top of the screen (replaces the hidden status bar).
## Port of src/ui/TopGradient.js (same smoothstep alpha values).

const HEIGHT_DP := 64.0

const ALPHAS: Array[float] = [
	1.0, 0.989, 0.957, 0.908, 0.844, 0.768, 0.684, 0.593, 0.5,
	0.407, 0.316, 0.232, 0.156, 0.092, 0.043, 0.011, 0.0,
]


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE

	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for i in ALPHAS.size():
		offsets.append(float(i) / float(ALPHAS.size() - 1))
		colors.append(Color(0, 0, 0, ALPHAS[i]))
	var g := Gradient.new()
	g.offsets = offsets
	g.colors = colors

	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 4
	tex.height = 64
	texture = tex


func configure(dp: float) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_bottom = HEIGHT_DP * dp
