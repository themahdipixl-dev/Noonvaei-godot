extends Control
## PART 2 test screen: the pannable / zoomable isometric world.
##
## On top of the map there is still the temporary Part 1 debug overlay (money, 4 upgrade buttons,
## offline report). The real HUD / bottom bar / panels (port of App.js) arrive in Part 3.

var _map: WorldMap
var _info_label: Label
var _offline_label: Label
var _ok_button: Button
var _buttons := {}


func _ready() -> void:
	# Default Persian font (if the font files were added to assets/fonts/)
	var t := Theme.new()
	AppFonts.apply_to_theme(t)
	theme = t

	# --- world (bottom layer) ---
	_map = WorldMap.new()
	_map.name = "WorldMap"
	add_child(_map)
	_map.set_level(Game.level)

	# --- temporary overlay (top layer). IGNORE so touches reach the map between the buttons ---
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)

	_info_label = _make_label(34)
	box.add_child(_info_label)

	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	_offline_label = _make_label(34)
	box.add_child(_offline_label)

	_ok_button = Button.new()
	_ok_button.text = Strings.OK
	_ok_button.custom_minimum_size = Vector2(0, 100)
	_ok_button.add_theme_font_size_override("font_size", 36)
	_ok_button.pressed.connect(Game.dismiss_offline)
	box.add_child(_ok_button)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	box.add_child(grid)

	for key in Balance.SECTION_KEYS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 120)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 28)
		b.pressed.connect(Game.upgrade.bind(key))
		grid.add_child(b)
		_buttons[key] = b

	Game.changed.connect(_refresh)
	Game.offline_report_changed.connect(_refresh_offline)
	_refresh()
	_refresh_offline()


func _make_label(font_size: int) -> Label:
	var l := Label.new()
	l.language = "fa"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Palette.INK)
	l.add_theme_color_override("font_outline_color", Palette.CREAM)
	l.add_theme_constant_override("outline_size", 10)
	return l


func _refresh() -> void:
	_map.set_level(Game.level)
	_info_label.text = "%s: %s   |   %s: %s   |   %s: %s" % [
		Strings.MONEY, FaFormat.format_grouped(Game.money),
		Strings.PER_SEC, FaFormat.format_rate(Game.income),
		Strings.LEVEL, FaFormat.to_fa(Game.level),
	]
	for key in Balance.SECTION_KEYS:
		var b: Button = _buttons[key]
		var s: Dictionary = Strings.SECTIONS[key]
		var cost: float = Game.costs[key]
		var mark := "  ◀ " + Strings.BOTTLENECK if key == Game.info["bottleneck"] else ""
		b.text = "%s  %s %s\n%s %s%s" % [
			s["name"],
			Strings.SECTION_LEVEL, FaFormat.to_fa(Game.levels[key]),
			Strings.COST, FaFormat.format_grouped(cost),
			mark,
		]
		b.disabled = Game.money < cost


func _refresh_offline() -> void:
	var has_report := not Game.offline_report.is_empty()
	_offline_label.visible = has_report
	_ok_button.visible = has_report
	if has_report:
		_offline_label.text = "%s\n%s\n%s" % [
			Strings.WELCOME_BACK,
			Strings.OFFLINE_EARNED,
			FaFormat.format_grouped(float(Game.offline_report["amount"])),
		]
