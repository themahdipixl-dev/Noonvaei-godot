class_name ComingSoon
extends Control
## Small placeholder card for tabs that are not built yet (shop / cards / minigames).
## Port of src/ui/ComingSoon.js  (touches pass through it, like `pointerEvents="none"`).

var _k := 0.0
var _bottom := 0.0
var _title := ""
var _wrap: CenterContainer
var _title_label: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## `bottom` = distance (px) from the bottom of the screen to the bottom of the card.
func configure(dp: float, bottom: float) -> void:
	if _wrap != null and is_equal_approx(dp, _k) and is_equal_approx(bottom, _bottom):
		return
	_k = dp
	_bottom = bottom
	_build()


func set_title(title: String) -> void:
	_title = title
	if _title_label != null:
		_title_label.text = title


func _build() -> void:
	if _wrap != null:
		_wrap.queue_free()
	var k := _k

	_wrap = CenterContainer.new()
	_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wrap.anchor_left = 0.0
	_wrap.anchor_right = 1.0
	_wrap.anchor_top = 1.0
	_wrap.anchor_bottom = 1.0
	_wrap.offset_top = -_bottom
	_wrap.offset_bottom = -_bottom
	_wrap.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_wrap)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UiKit.flat(Color("#fff3d1"), 20.0 * k, 3.0 * k, Palette.INK)
	sb.border_width_bottom = int(round(6.0 * k))
	sb.content_margin_left = 28.0 * k
	sb.content_margin_right = 28.0 * k
	sb.content_margin_top = 10.0 * k
	sb.content_margin_bottom = 10.0 * k
	panel.add_theme_stylebox_override("panel", sb)
	_wrap.add_child(panel)

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", int(2.0 * k))
	panel.add_child(col)

	_title_label = UiKit.make_label(_title, 20.0 * k, Color("#7a3b0c"), "title")
	col.add_child(_title_label)
	col.add_child(UiKit.make_label(Strings.COMING_SOON, 13.0 * k, Color("#6b3f1d"), "regular"))
