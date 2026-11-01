class_name UpgradePanel
extends Control
## Four upgrade cards (one per bakery section), shown above the bottom bar on the "upgrade" tab.
## Port of src/ui/UpgradePanel.js
##
## React props -> Godot:  levels / costs / money / bottleneck  ->  `refresh()`;  onUpgrade  ->  `upgrade_requested`.

signal upgrade_requested(section: String)

var _k := 0.0
var _bottom := 0.0
var _row: HBoxContainer
var _cards := {}

var _levels: Dictionary = {}
var _costs: Dictionary = {}
var _money := 0.0
var _bottleneck := ""


class Card extends BaseButton:
	var k := 1.0
	var box: VBoxContainer
	var level_label: Label
	var cost_label: Label
	var warn: Label
	var chip_style: StyleBoxFlat

	var _face := StyleBoxFlat.new()
	var _lip := StyleBoxFlat.new()
	var _affordable := true
	var _bottleneck := false

	func _init() -> void:
		focus_mode = Control.FOCUS_NONE

	func setup(p_k: float, key: String) -> void:
		k = p_k
		var meta: Dictionary = Strings.SECTIONS[key]

		box = VBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", int(round(1.0 * k)))
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		box.offset_left = 2.0 * k
		box.offset_right = -2.0 * k
		box.offset_top = 5.0 * k
		box.offset_bottom = -5.0 * k
		add_child(box)

		box.add_child(UiKit.make_label(String(meta["icon"]), 20.0 * k, Color.WHITE, "regular"))

		var name_label := UiKit.make_label(String(meta["name"]), 12.0 * k, Color.WHITE, "bold")
		name_label.clip_text = true
		box.add_child(name_label)

		level_label = UiKit.make_label("", 11.0 * k, Color("#ffeccb"), "regular")
		level_label.clip_text = true
		box.add_child(level_label)

		var gap := Control.new()
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gap.custom_minimum_size = Vector2(0.0, 2.0 * k)
		box.add_child(gap)

		var chip := PanelContainer.new()
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		chip_style = UiKit.flat(Color("#7a3b0c"), 10.0 * k)
		chip_style.content_margin_left = 6.0 * k
		chip_style.content_margin_right = 6.0 * k
		chip_style.content_margin_top = 3.0 * k
		chip_style.content_margin_bottom = 3.0 * k
		chip.add_theme_stylebox_override("panel", chip_style)
		cost_label = UiKit.make_label("", 12.0 * k, Color("#ffe9a8"), "bold")
		chip.add_child(cost_label)
		box.add_child(chip)

		# bottleneck warning, sticks out of the top-right corner
		warn = UiKit.make_label(Icons.get_emoji("warn"), 13.0 * k, Color.WHITE, "regular")
		warn.anchor_left = 1.0
		warn.anchor_right = 1.0
		warn.offset_left = -14.0 * k
		warn.offset_right = 6.0 * k
		warn.offset_top = -9.0 * k
		warn.offset_bottom = 11.0 * k
		warn.visible = false
		add_child(warn)

		button_down.connect(func() -> void: scale = Vector2(0.95, 0.95))
		button_up.connect(func() -> void: scale = Vector2.ONE)
		_restyle()

	func update_state(level: int, cost: float, affordable: bool, is_bottleneck: bool) -> void:
		level_label.text = "%s %s" % [Strings.SECTION_LEVEL, FaFormat.to_fa(level)]
		cost_label.text = "%s %s" % [Icons.get_emoji("coin"), FaFormat.format_number(cost)]
		_affordable = affordable
		_bottleneck = is_bottleneck
		disabled = not affordable
		warn.visible = is_bottleneck
		_restyle()

	func _restyle() -> void:
		var bg := Color("#e8892a") if _affordable else Color("#bfae92")
		var lip := Color("#a65a12") if _affordable else Color("#8f806a")
		var border := Color("#ff5a4d") if _bottleneck else Color("#fff0cc")
		_lip = UiKit.flat(lip, 16.0 * k)
		_face = UiKit.flat(bg, 16.0 * k, 2.0 * k, border)
		_face.border_width_bottom = 0  # the lip takes the place of the bottom border
		chip_style.bg_color = Color("#7a3b0c") if _affordable else Color("#6b5a44")
		queue_redraw()

	func _get_minimum_size() -> Vector2:
		if box == null:
			return Vector2.ZERO
		return Vector2(0.0, box.get_combined_minimum_size().y + 10.0 * k)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			pivot_offset = size * 0.5
			queue_redraw()

	func _draw() -> void:
		draw_style_box(_lip, Rect2(Vector2.ZERO, size))
		draw_style_box(_face, Rect2(Vector2.ZERO, Vector2(size.x, maxf(0.0, size.y - 5.0 * k))))


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## `bottom` = distance (px) from the bottom of the screen to the bottom of the cards.
func configure(dp: float, bottom: float) -> void:
	if _row != null and is_equal_approx(dp, _k) and is_equal_approx(bottom, _bottom):
		return
	_k = dp
	_bottom = bottom
	_build()
	_apply()


func refresh(levels: Dictionary, costs: Dictionary, money: float, bottleneck: String) -> void:
	_levels = levels
	_costs = costs
	_money = money
	_bottleneck = bottleneck
	_apply()


func _build() -> void:
	if _row != null:
		_row.queue_free()
	_cards.clear()

	_row = HBoxContainer.new()
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_theme_constant_override("separation", int(round(6.0 * _k)))
	_row.anchor_left = 0.0
	_row.anchor_right = 1.0
	_row.anchor_top = 1.0
	_row.anchor_bottom = 1.0
	_row.offset_left = 11.0 * _k
	_row.offset_right = -11.0 * _k
	_row.offset_top = -_bottom
	_row.offset_bottom = -_bottom
	_row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_row)

	for key in Balance.SECTION_KEYS:
		var section := String(key)
		var card := Card.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.setup(_k, section)
		card.pressed.connect(func() -> void: upgrade_requested.emit(section))
		_row.add_child(card)
		card.update_minimum_size()
		_cards[section] = card


func _apply() -> void:
	if _row == null or _levels.is_empty() or _costs.is_empty():
		return
	for key in Balance.SECTION_KEYS:
		var section := String(key)
		var card: Card = _cards[section]
		var cost := float(_costs[section])
		card.update_state(int(_levels[section]), cost, _money >= cost, section == _bottleneck)
