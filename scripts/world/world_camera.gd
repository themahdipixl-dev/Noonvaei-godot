class_name WorldCamera
extends RefCounted
## Pan + pinch-zoom camera math. Port of src/world/useWorldCamera.js
##
## It does NOT own any node. WorldMap feeds it input events and then calls apply(content_node).
##
## Model (same as the RN version): the content (a W x H canvas) is centered in the view,
## then translated by `pos` and scaled by `zoom` around its own center.
##   screen = view_size/2 + pos + zoom * (content_point - content_size/2)
##
## Gestures:
##   1 finger drag           -> pan
##   2 finger pinch          -> zoom around the fingers' midpoint (+ pan with the midpoint)
##   mouse wheel             -> zoom at the cursor   (NEW: desktop testing)
##   trackpad magnify        -> zoom at the cursor   (NEW)
## Mouse drag works through project setting input_devices/pointing/emulate_touch_from_mouse.

const MIN_SCALE := 0.25
const MAX_SCALE := 3.5
## Same exponent as the JS version (makes pinch feel a bit more sensitive).
const PINCH_EXPONENT := 1.4
const WHEEL_STEP := 1.1

enum Mode { IDLE, PAN, PINCH, DEAD }

var content_size: Vector2
var view_size := Vector2.ZERO
## translation (px) of the content center relative to the view center  (JS: x, y)
var pos := Vector2.ZERO
## current scale  (JS: s)
var zoom := 1.0
var initial_scale := 1.0
## Initial camera focus: offset of the point of interest from the content center. Used once, at first layout.
var focus := Vector2.ZERO

var _laid_out := false
var _mode := Mode.IDLE
var _touches := {}  # finger index -> Vector2

# pan snapshot
var _pan_start_touch := Vector2.ZERO
var _pan_base := Vector2.ZERO

# pinch snapshot
var _pinch_start_dist := 1.0
var _pinch_base_scale := 1.0
var _pinch_base_pos := Vector2.ZERO
var _pinch_focal_off := Vector2.ZERO


func _init(p_content_size: Vector2, p_initial_scale: float = 1.0) -> void:
	content_size = p_content_size
	initial_scale = p_initial_scale
	zoom = p_initial_scale


## Keeps the content inside the view: max offset = half of the part of the content that doesn't fit.
static func _limit(n: float, scale: float, content: float, view: float) -> float:
	var m := maxf(0.0, (content * scale - view) / 2.0)
	return clampf(n, -m, m)


func _place(new_pos: Vector2, new_zoom: float) -> void:
	pos = Vector2(
		_limit(new_pos.x, new_zoom, content_size.x, view_size.x),
		_limit(new_pos.y, new_zoom, content_size.y, view_size.y)
	)
	zoom = new_zoom


## Call whenever the map control is resized (JS: onLayout).
func set_view_size(size: Vector2) -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	view_size = size
	if not _laid_out:
		_laid_out = true
		zoom = initial_scale
		_place(-initial_scale * focus, initial_scale)
	else:
		_place(pos, zoom)


## Writes the camera into the node that holds the world (Node2D).
func apply(target: Node2D) -> void:
	target.scale = Vector2(zoom, zoom)
	target.position = view_size / 2.0 + pos - zoom * content_size / 2.0


## Zoom by `factor` keeping the content point under `point` (view coordinates) fixed.
func zoom_at(point: Vector2, factor: float) -> void:
	var new_zoom := clampf(zoom * factor, MIN_SCALE, MAX_SCALE)
	var f := point - view_size / 2.0
	var d := (f - pos) / zoom
	_place(f - new_zoom * d, new_zoom)


## Feed every input event of the map control. Returns true when the event was used.
func handle_input(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		_on_touch(event as InputEventScreenTouch)
		return true
	if event is InputEventScreenDrag:
		_on_drag(event as InputEventScreenDrag)
		return true
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_at(mb.position, WHEEL_STEP)
			return true
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_at(mb.position, 1.0 / WHEEL_STEP)
			return true
	if event is InputEventMagnifyGesture:
		var mg := event as InputEventMagnifyGesture
		zoom_at(mg.position, mg.factor)
		return true
	return false


func _on_touch(e: InputEventScreenTouch) -> void:
	if e.pressed:
		_touches[e.index] = e.position
		if _mode == Mode.DEAD:
			return
		if _touches.size() == 1:
			_mode = Mode.PAN
			_pan_start_touch = e.position
			_pan_base = pos
		elif _touches.size() == 2:
			_begin_pinch()
		# 3+ fingers: ignored
	else:
		_touches.erase(e.index)
		if _touches.is_empty():
			_mode = Mode.IDLE
		elif _mode == Mode.PINCH:
			# First finger lifted: the focal point would jump to the remaining finger,
			# so stop reacting until all fingers are up (JS: `locked`).
			_mode = Mode.DEAD


func _on_drag(e: InputEventScreenDrag) -> void:
	if not _touches.has(e.index):
		return
	_touches[e.index] = e.position
	if _mode == Mode.PAN:
		_place(_pan_base + (e.position - _pan_start_touch), zoom)
	elif _mode == Mode.PINCH:
		_update_pinch()


## The two fingers that drive the pinch (lowest finger indexes).
func _pinch_points() -> PackedVector2Array:
	var keys := _touches.keys()
	keys.sort()
	var a: Vector2 = _touches[keys[0]]
	var b: Vector2 = _touches[keys[1]]
	return PackedVector2Array([a, b])


func _begin_pinch() -> void:
	var p := _pinch_points()
	_mode = Mode.PINCH
	_pinch_start_dist = maxf(1.0, p[0].distance_to(p[1]))
	_pinch_base_scale = zoom
	_pinch_base_pos = pos
	_pinch_focal_off = (p[0] + p[1]) / 2.0 - view_size / 2.0


func _update_pinch() -> void:
	var p := _pinch_points()
	var ratio := p[0].distance_to(p[1]) / _pinch_start_dist
	var new_zoom := clampf(_pinch_base_scale * pow(ratio, PINCH_EXPONENT), MIN_SCALE, MAX_SCALE)
	var m := (p[0] + p[1]) / 2.0 - view_size / 2.0
	var d := (_pinch_focal_off - _pinch_base_pos) / _pinch_base_scale
	_place(m - new_zoom * d, new_zoom)
