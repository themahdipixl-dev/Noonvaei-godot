extends Control
## PART 1 smoke-test screen.
##
## The real screen (world map + HUD + bottom bar, i.e. the port of App.js) arrives in Parts 2-3.
## For now this scene only proves that the ported logic works:
##   - money grows by itself (idle income)
##   - 4 upgrade buttons, costs scale, the bottleneck section is marked
##   - saving / loading / offline report

var _info_label: Label
var _offline_label: Label
var _ok_button: Button
var _buttons := {}


func _ready() -> void:
	# Default Persian font (if the font files were added to assets/fonts/)
	var t := Theme.new()
	AppFonts.apply_to_theme(t)
	theme = t

	var bg := ColorRect.new()
	bg.color = Palette.GRASS
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	margin.add_child(box)

	_info_label = _make_label(48)
	box.add_child(_info_label)

	_offline_label = _make_label(38)
	box.add_child(_offline_label)

	_ok_button = Button.new()
	_ok_button.text = Strings.OK
	_ok_button.custom_minimum_size = Vector2(0, 110)
	_ok_button.add_theme_font_size_override("font_size", 40)
	_ok_button.pressed.connect(Game.dismiss_offline)
	box.add_child(_ok_button)

	for key in Balance.SECTION_KEYS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 120)
		b.add_theme_font_size_override("font_size", 36)
		b.pressed.connect(Game.upgrade.bind(key))
		box.add_child(b)
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
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Palette.BROWN)
	return l


func _refresh() -> void:
	_info_label.text = "%s\n%s: %s\n%s: %s\n%s: %s" % [
		Strings.TITLE,
		Strings.MONEY, FaFormat.format_grouped(Game.money),
		Strings.PER_SEC, FaFormat.format_rate(Game.income),
		Strings.LEVEL, FaFormat.to_fa(Game.level),
	]
	for key in Balance.SECTION_KEYS:
		var b: Button = _buttons[key]
		var s: Dictionary = Strings.SECTIONS[key]
		var cost: float = Game.costs[key]
		var text := "%s | %s %s | %s %s" % [
			s["name"],
			Strings.SECTION_LEVEL, FaFormat.to_fa(Game.levels[key]),
			Strings.COST, FaFormat.format_grouped(cost),
		]
		if key == Game.info["bottleneck"]:
			text += " | " + Strings.BOTTLENECK
		b.text = text
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
