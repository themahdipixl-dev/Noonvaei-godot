class_name OfflineCard
extends Control
## "Welcome back" card with the offline earnings. Port of src/ui/OfflineCard.js
##
## React props -> Godot:  report -> `show_report()`;  onClose -> `closed` signal.
## The overlay blocks touches, so the map can't be dragged behind it.

signal closed

var _report: Dictionary = {}
var _k := 1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func show_report(report: Dictionary, dp: float) -> void:
	_report = report
	_k = dp
	_build()
	visible = true


## Re-layout after the screen size changed (only does something while the card is visible).
func rebuild(dp: float) -> void:
	_k = dp
	if visible:
		_build()


func hide_card() -> void:
	visible = false


## JS formatDuration
static func format_duration(sec: float) -> String:
	var h := int(floor(sec / 3600.0))
	var m := int(floor(fmod(sec, 3600.0) / 60.0))
	if h > 0:
		return "%s %s و %s %s" % [FaFormat.to_fa(h), Strings.HOURS, FaFormat.to_fa(m), Strings.MINUTES]
	return "%s %s" % [FaFormat.to_fa(maxi(1, m)), Strings.MINUTES]


func _build() -> void:
	for c in get_children():
		c.queue_free()
	var k := _k

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", int(28.0 * k))
	margin.add_theme_constant_override("margin_right", int(28.0 * k))
	add_child(margin)

	var center := VBoxContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(center)

	var panel := PanelContainer.new()
	var sb := UiKit.flat(Color("#fff8e8"), 20.0 * k)
	sb.set_content_margin_all(22.0 * k)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", int(8.0 * k))
	panel.add_child(col)

	col.add_child(UiKit.make_label(Strings.WELCOME_BACK, 24.0 * k, Color("#5a2e0e"), "title"))
	col.add_child(_wrapped(Strings.OFFLINE_EARNED, 14.0 * k, Color("#6b3f1d"), "regular"))
	var amount := float(_report.get("amount", 0.0))
	col.add_child(UiKit.make_label("%s %s" % [FaFormat.format_number(amount), Icons.get_emoji("coin")],
			34.0 * k, Color("#c26a10"), "title"))
	var seconds := float(_report.get("seconds", 0.0))
	col.add_child(_wrapped("%s: %s" % [Strings.AWAY, format_duration(seconds)], 14.0 * k, Color("#6b3f1d"), "regular"))

	var btn := Button.new()
	btn.text = Strings.OK
	btn.language = "fa"
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", int(16.0 * k))
	var bold := AppFonts.get_font("bold")
	if bold != null:
		btn.add_theme_font_override("font", bold)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(c, Color.WHITE)
	for state in ["normal", "hover", "pressed", "focus"]:
		var bs := UiKit.flat(Color("#c0731f") if state == "pressed" else Color("#d9822b"), 12.0 * k)
		bs.content_margin_left = 36.0 * k
		bs.content_margin_right = 36.0 * k
		bs.content_margin_top = 10.0 * k
		bs.content_margin_bottom = 10.0 * k
		btn.add_theme_stylebox_override(state, bs)
	btn.pressed.connect(func() -> void: closed.emit())

	var btn_wrap := MarginContainer.new()
	btn_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_wrap.add_theme_constant_override("margin_top", int(6.0 * k))
	btn_wrap.add_child(btn)
	col.add_child(btn_wrap)


func _wrapped(text: String, size: float, color: Color, font_key: String) -> Label:
	var l := UiKit.make_label(text, size, color, font_key)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l
