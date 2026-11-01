class_name BottomBar
extends Control
## Cartoon bottom tab bar (shop | cards | home | upgrade | minigames). Port of src/ui/BottomBar.js
##
## Dark chocolate bar, five sections split by full-height divider lines. The selected section gets a
## bigger icon and pushes the dividers apart (spring animation = JS LayoutAnimation).
## Bottom safe-area aware: content never sits on the very edge of the screen.

signal tab_changed(key: String)

## Visual order, left -> right (kept fixed regardless of text direction).
const TAB_ORDER: Array[String] = ["shop", "cards", "home", "upgrade", "minigames"]

# All sizes below are in dp (multiplied by px-per-dp).
const BAR_CONTENT_H := 70.0
const EXTRA_BOTTOM := 4.0   # extra breathing room under the labels
const MIN_INSET := 6.0      # used when the device reports no bottom inset
const ICON_BOX := 40.0      # fixed icon area so labels never jump
const ICON_OFF := 50.0
const ICON_ON := 60.0
const LABEL_H := 18.0
const TOP_LINE := 2.0
const HIGHLIGHT_H := 2.0
const W_OFF := 1.0
const W_ON := 1.7

const BAR_BG := Color("#3A2214")
const LINE := Color("#1A0E07")
const HIGHLIGHT := Color("#5E3A20")
const LABEL := Color("#F6DCB4")

var active := "home"

var _k := 0.0
var _w := 0.0
var _inset := -1.0
var _pad := 0.0
var _slots: Array[Slot] = []
var _weights: Array[float] = []
var _tween: Tween


class Slot extends BaseButton:
	var key := ""
	var icon: Label
	var caption: Label
	var down := false

	func _init() -> void:
		focus_mode = Control.FOCUS_NONE


## JS getBottomPad
static func get_bottom_pad(inset_bottom: float, k: float) -> float:
	return maxf(inset_bottom, MIN_INSET * k) + EXTRA_BOTTOM * k


## JS useBottomBarHeight: other overlays use this to stay above the bar.
static func bar_height(inset_bottom: float, k: float) -> float:
	return BAR_CONTENT_H * k + get_bottom_pad(inset_bottom, k)


func configure(width: float, dp: float, inset_bottom: float) -> void:
	if not _slots.is_empty() and is_equal_approx(width, _w) and is_equal_approx(dp, _k) \
			and is_equal_approx(inset_bottom, _inset):
		return
	_w = width
	_k = dp
	_inset = inset_bottom
	_pad = get_bottom_pad(inset_bottom, dp)
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	offset_top = -bar_height(inset_bottom, dp)
	offset_bottom = 0.0
	_build_slots()


## Change the active tab from code (no signal).
func set_active(key: String, animate: bool = false) -> void:
	active = key
	if _slots.is_empty():
		return
	_refresh_captions()
	var target := _target_weights()
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if not animate:
		_weights = target
		_layout()
		return
	var from := _weights.duplicate()
	_tween = create_tween()
	_tween.tween_method(_anim_step.bind(from, target), 0.0, 1.0, 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _anim_step(t: float, from: Array[float], target: Array[float]) -> void:
	for i in _weights.size():
		_weights[i] = lerpf(from[i], target[i], t)
	_layout()


func _target_weights() -> Array[float]:
	var out: Array[float] = []
	for key in TAB_ORDER:
		out.append(W_ON if key == active else W_OFF)
	return out


func _build_slots() -> void:
	for s in _slots:
		s.queue_free()
	_slots.clear()
	for key in TAB_ORDER:
		var slot := Slot.new()
		slot.key = key
		slot.icon = UiKit.make_label(Icons.tab_emoji(key), ICON_ON * _k * 0.78, Color.WHITE, "regular")
		slot.caption = UiKit.make_label(String(Strings.TABS[key]), 11.5 * _k, LABEL, "medium")
		slot.add_child(slot.icon)
		slot.add_child(slot.caption)
		slot.pressed.connect(_on_slot_pressed.bind(key))
		slot.button_down.connect(_on_slot_down.bind(slot, true))
		slot.button_up.connect(_on_slot_down.bind(slot, false))
		add_child(slot)
		_slots.append(slot)
	_refresh_captions()
	_weights = _target_weights()
	_layout()


func _refresh_captions() -> void:
	for slot in _slots:
		var on := slot.key == active
		var f := AppFonts.get_font("bold" if on else "medium")
		if f != null:
			slot.caption.add_theme_font_override("font", f)


func _on_slot_pressed(key: String) -> void:
	if key == active:
		return
	set_active(key, true)
	tab_changed.emit(key)


func _on_slot_down(slot: Slot, is_down: bool) -> void:
	slot.down = is_down
	_layout()


func _layout() -> void:
	if _slots.is_empty():
		return
	var k := _k
	var top_off := (TOP_LINE + HIGHLIGHT_H) * k
	var row_h := size.y - top_off
	var total := 0.0
	for w in _weights:
		total += w
	var x := 0.0
	for i in _slots.size():
		var slot := _slots[i]
		var slot_w := size.x * _weights[i] / total
		slot.position = Vector2(x, top_off)
		slot.size = Vector2(slot_w, row_h)
		# 0 = inactive, 1 = fully active
		var t := clampf(inverse_lerp(W_OFF, W_ON, _weights[i]), 0.0, 1.0)
		var label_top := row_h - _pad - LABEL_H * k
		UiKit.place_label(slot.caption, Rect2(0.0, label_top + 5.0 * k * t, slot_w, LABEL_H * k))
		var box := ICON_ON * k
		var cy := label_top - 1.0 * k - ICON_BOX * k * 0.5
		UiKit.place_label(slot.icon, Rect2(slot_w * 0.5 - box * 0.5, cy - box * 0.5, box, box))
		slot.icon.pivot_offset = slot.icon.size * 0.5
		var sc := lerpf(ICON_OFF / ICON_ON, 1.0, t)
		if slot.down:
			sc *= 0.9
		slot.icon.scale = Vector2(sc, sc)
		x += slot_w
	queue_redraw()


func _draw() -> void:
	var k := _k
	draw_rect(Rect2(Vector2.ZERO, size), BAR_BG)
	draw_rect(Rect2(0.0, 0.0, size.x, TOP_LINE * k), LINE)
	draw_rect(Rect2(0.0, TOP_LINE * k, size.x, HIGHLIGHT_H * k), HIGHLIGHT)
	var top_off := (TOP_LINE + HIGHLIGHT_H) * k
	var row_h := size.y - top_off
	for i in range(1, _slots.size()):
		var x := _slots[i].position.x
		draw_rect(Rect2(x, top_off, 2.0 * k, row_h), LINE)
		draw_rect(Rect2(x + 2.0 * k, top_off, maxf(1.0, k), row_h), HIGHLIGHT)
