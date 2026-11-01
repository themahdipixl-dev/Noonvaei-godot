class_name Hud
extends Control
## Top HUD (cartoon style): level badge + progress bar, money, gems, rate tab under money,
## daily mission, season pass, settings and the "cities" button. Port of src/ui/Hud.js
##
## Layout uses absolute coordinates from the design (780 px wide) scaled to the screen width,
## exactly like the JS version. The root ignores the mouse (JS `box-none`), only the buttons catch it.
##
## React props -> Godot:  money / income / level  ->  `set_state()`;  onXxx callbacks  ->  signals.

signal settings_pressed
signal add_money_pressed
signal add_gems_pressed
signal mission_pressed
signal season_pass_pressed
signal cities_pressed

const DESIGN_W := 780.0
const DESIGN_H := 352.0
const MAX_SCALE_DP := 0.7   # JS MAX_SCALE (in dp) -> multiplied by px-per-dp
const LIP := 8.0
const TOP_H := 58.0
## The level bar looks smooth but is made of 10 hidden steps (levels inside the current page of 10).
const LEVEL_STEPS := 10

const NAVY := Color("#1F2E6C")
const NAVY_LIP := Color("#101A46")
const BLUE := Color("#4E76E7")
const BLUE_LIP := Color("#2A439B")
const RED := Color("#EF7358")
const RED_LIP := Color("#B7402E")
const GREEN := Color("#40BF65")
const GREEN_LIP := Color("#1F7A3A")
const MINT := Color("#7DFF9A")
const STAR_TEXT := Color("#2B2000")
const SHADOW := Color(10.0 / 255.0, 20.0 / 255.0, 60.0 / 255.0, 0.35)

## TODO (same as JS): replace with real values once gems / missions / season pass exist in the game state.
const PLACEHOLDER_GEMS := 350
const PLACEHOLDER_MISSION := 0.4
const PLACEHOLDER_SEASON := 0.25

var _s := 0.0
var _width := 0.0
var _holder: Control
var _rate_label: Label
var _money_label: Label
var _gems_label: Label
var _level_label: Label
var _level_bar: HudBar

var _money := 0.0
var _income := 0.0
var _level := 1
var _gems := PLACEHOLDER_GEMS


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## `width` = screen width (px), `dp` = px per dp, `top_inset` = camera / notch area the HUD must stay below.
func configure(width: float, dp: float, top_inset: float) -> void:
	var s := minf(width / DESIGN_W, MAX_SCALE_DP * dp)
	position = Vector2(0.0, top_inset)
	size = Vector2(width, DESIGN_H * s)
	if _holder != null and is_equal_approx(s, _s) and is_equal_approx(width, _width):
		return
	_s = s
	_width = width
	_build()
	_apply_values()


## Everything (levels, upgrades...) still works on the real level; only the visual bar is stepped.
func set_state(money: float, income: float, level: int, gems: int = -1) -> void:
	_money = money
	_income = income
	_level = level
	if gems >= 0:
		_gems = gems
	_apply_values()


func _apply_values() -> void:
	if _holder == null:
		return
	UiKit.fit_text(_money_label, FaFormat.format_grouped(_money), 25.0 * _s, 135.0 * _s)
	UiKit.fit_text(_gems_label, FaFormat.to_fa(_gems), 25.0 * _s, 112.0 * _s)
	_rate_label.text = "%s %s" % [FaFormat.format_rate(_income), Strings.PER_SEC_SHORT]
	_level_label.text = FaFormat.to_fa(_level)
	var filled := ((maxi(1, _level) - 1) % LEVEL_STEPS) + 1
	_level_bar.value = float(filled) / float(LEVEL_STEPS)


# ------------------------------------------------------------------ building blocks

func _build() -> void:
	if _holder != null:
		_holder.queue_free()
	_holder = Control.new()
	_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_holder.position = Vector2((_width - DESIGN_W * _s) * 0.5, 0.0)
	_holder.size = Vector2(DESIGN_W, DESIGN_H) * _s
	add_child(_holder)

	# Rate tab (sits behind the money pill, centered on the full screen width)
	var rate := _btn(Rect2(311, 60, 158, 62), 18.0, NAVY, NAVY_LIP, 6.0, 0.0)
	_rate_label = _text(rate.content, Rect2(0, 12, 158, 40), 23.0, "", HORIZONTAL_ALIGNMENT_CENTER, MINT)

	# Level: flat thick bar. Star badge is drawn on top at the end.
	var level_btn := _btn(Rect2(20, 12, 266, TOP_H), 16.0, NAVY, NAVY_LIP, LIP, 0.12)
	_level_bar = _bar(level_btn.content, Rect2(82, 12, 168, 34))

	# Money
	var money_btn := _btn(Rect2(300, 12, 236, TOP_H), 16.0, NAVY, NAVY_LIP, LIP, 0.12)
	_icon(money_btn.content, "money", 7, 5, 48)
	_money_label = _text(money_btn.content, Rect2(42, 12, 135, 34), 25.0, "")
	_plus(money_btn.content, 186.0, add_money_pressed)

	# Gems
	var gems_btn := _btn(Rect2(552, 12, 213, TOP_H), 16.0, NAVY, NAVY_LIP, LIP, 0.12)
	_icon(gems_btn.content, "diamond", 7, 5, 48)
	_gems_label = _text(gems_btn.content, Rect2(42, 12, 112, 34), 25.0, "")
	_plus(gems_btn.content, 163.0, add_gems_pressed)

	# Season pass (right)
	var season := _btn(Rect2(500, 104, 265, 92), 20.0, RED, RED_LIP, LIP, 0.35, true)
	season.pressed.connect(func() -> void: season_pass_pressed.emit())
	_icon(season.content, "crown", 15, 10, 70)
	_text(season.content, Rect2(80, 10, 135, 44), 24.0, Strings.SEASON_PASS, HORIZONTAL_ALIGNMENT_RIGHT)
	_bar(season.content, Rect2(92, 56, 150, 26)).value = PLACEHOLDER_SEASON

	# Settings (under the season pass, right-aligned with it)
	var settings := _btn(Rect2(695, 220, 70, 70), 18.0, BLUE, BLUE_LIP, LIP, 0.35, true)
	settings.pressed.connect(func() -> void: settings_pressed.emit())
	_icon(settings.content, "gear", 7, 8, 55)

	# Daily mission (left)
	var mission := _btn(Rect2(20, 104, 265, 92), 20.0, BLUE, BLUE_LIP, LIP, 0.35, true)
	mission.pressed.connect(func() -> void: mission_pressed.emit())
	_icon(mission.content, "clipboard", 15, 13, 70)
	_text(mission.content, Rect2(82, 10, 155, 44), 24.0, Strings.DAILY_MISSION, HORIZONTAL_ALIGNMENT_RIGHT)
	_bar(mission.content, Rect2(92, 56, 150, 26)).value = PLACEHOLDER_MISSION

	# Cities
	var cities := _btn(Rect2(20, 220, 120, 114), 20.0, GREEN, GREEN_LIP, LIP, 0.35, true)
	cities.pressed.connect(func() -> void: cities_pressed.emit())
	_icon(cities.content, "buildings", 20, 8, 90)
	_text(cities.content, Rect2(0, 77, 120, 30), 23.0, Strings.CITIES)

	# Level star badge, on top of the level rectangle
	Icons.place(_holder, "star", Vector2(2, 2) * _s, 86.0 * _s)
	_level_label = _text(_holder, Rect2(2, 2, 76, 76), 30.0, "", HORIZONTAL_ALIGNMENT_CENTER, STAR_TEXT, "title", false)


func _btn(face: Rect2, radius: float, color: Color, lip_color: Color, lip: float, glow: float,
		interactive: bool = false) -> CartoonButton:
	var b := CartoonButton.new()
	b.setup(_s, face, radius, color, lip_color, lip, glow, interactive)
	_holder.add_child(b)
	return b


func _text(parent: Control, rect: Rect2, font_size: float, text: String,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER, color: Color = Color.WHITE,
		font_key: String = "bold", shadow: bool = true) -> Label:
	var l := UiKit.make_label(text, font_size * _s, color, font_key, align)
	if shadow:
		l.add_theme_color_override("font_shadow_color", SHADOW)
		l.add_theme_constant_override("shadow_offset_y", int(round(3.0 * _s)))
	parent.add_child(l)
	UiKit.place_label(l, Rect2(rect.position * _s, rect.size * _s))
	return l


func _icon(parent: Control, icon_name: String, x: float, y: float, box: float) -> void:
	Icons.place(parent, icon_name, Vector2(x, y) * _s, box * _s)


func _bar(parent: Control, rect: Rect2) -> HudBar:
	var b := HudBar.new()
	b.border = CartoonButton.SW * _s
	b.position = rect.position * _s
	b.size = rect.size * _s
	parent.add_child(b)
	return b


## The "+" icon inside a currency pill.
func _plus(parent: Control, left: float, pressed_signal: Signal) -> void:
	var b := CartoonButton.new()
	b.setup_plain(_s, Rect2(left, 5, 48, 48), 8.0)
	parent.add_child(b)
	Icons.place(b.content, "plus", Vector2.ZERO, 48.0 * _s)
	b.pressed.connect(func() -> void: pressed_signal.emit())
