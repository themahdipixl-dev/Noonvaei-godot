class_name Bakery
extends Node2D
## Season bakery drawn with plain Sprite2D layers. Port of src/world/Bakery.js
##
## Cropped layers: offsets are in pixels of a shared 2048x2048 reference canvas
## (same canvas as bakery_front.webp, which is NOT cropped).
##
## Layer order: front, belt, lavash, cutter.
## If bakery_front.webp is missing, a placeholder box is drawn instead (so the scene is testable without art).

const REF := 2048.0

# Crop boxes: [up, down, left, right]  (pixels cut from each side of the 2048 canvas)
const BELT_BOX := [916, 930, 931, 771]
const CUTTER_BOX := [869, 973, 973, 924]
const LAVASH_BOXES := [
	[909, 1050, 922, 973],
	[987, 972, 1056, 837],
	[1091, 861, 1221, 669],
	[1089, 855, 547, 1339],
	[1137, 805, 632, 1252],
]
## All 4 baker views are cropped to the same rectangle (used by BakerWalker in Part 4).
const BAKER_BOX := [1024, 802, 927, 1024]

var _projector: Iso
var _gx := 0.0
var _gy := 0.0
## top-left of the 2048 canvas in world px
var _origin := Vector2.ZERO
## side of the 2048 canvas in world px (JS: S)
var _canvas_size := 0.0
## world px per reference px (JS: k)
var _k := 1.0

var _front: Sprite2D
var _belt: Sprite2D
var _lavash: Sprite2D
var _cutter: Sprite2D


## gx, gy = top-left grid cell of the lot.
func setup(projector: Iso, tile_w: float, gx: float, gy: float) -> void:
	_projector = projector
	_gx = gx
	_gy = gy
	var lot := float(WorldConfig.LOT_SIZE)
	var c := projector.project(gx + lot / 2.0, gy + lot / 2.0, 0.0)
	_canvas_size = (lot * tile_w) / float(WorldConfig.ART["bakery"]["floor_w"])
	var anchor: Vector2 = WorldConfig.ART["bakery"]["anchor"]
	_origin = c - anchor * _canvas_size
	_k = _canvas_size / REF

	_front = _add_layer(EnvironmentAssets.BAKERY_FRONT, Rect2(_origin, Vector2(_canvas_size, _canvas_size)))
	_belt = _add_layer(EnvironmentAssets.BAKERY_BELT, crop_rect(BELT_BOX))
	_lavash = _add_layer(EnvironmentAssets.LAVASH[0], crop_rect(LAVASH_BOXES[0]))
	_cutter = _add_layer(EnvironmentAssets.BAKERY_CUTTER, crop_rect(CUTTER_BOX))
	queue_redraw()


## Position / size in world px of a layer cropped with box [up, down, left, right].
## Also used by Part 4 to place the baker views.
func crop_rect(box: Array) -> Rect2:
	var up := float(box[0])
	var down := float(box[1])
	var left := float(box[2])
	var right := float(box[3])
	return Rect2(
		_origin + Vector2(left, up) * _k,
		Vector2(REF - left - right, REF - up - down) * _k
	)


## Top-left of the 2048 reference canvas in world px.
func canvas_origin() -> Vector2:
	return _origin


## Side of the reference canvas in world px.
func canvas_size() -> float:
	return _canvas_size


## NEW (data existed in the JS file, but only stage 1 was shown): switch the lavash bread stage, 0..4.
func set_lavash_stage(stage: int) -> void:
	var i := clampi(stage, 0, LAVASH_BOXES.size() - 1)
	_set_layer(_lavash, EnvironmentAssets.LAVASH[i], crop_rect(LAVASH_BOXES[i]))


func _add_layer(path: String, rect: Rect2) -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	add_child(s)
	_set_layer(s, path, rect)
	return s


## The JS version stretched every image to its box (resizeMode="stretch"): do the same.
func _set_layer(s: Sprite2D, path: String, rect: Rect2) -> void:
	var tex := EnvironmentAssets.get_texture(path)
	s.texture = tex
	s.position = rect.position
	if tex != null:
		s.scale = rect.size / tex.get_size()


# ---------------------------------------------------------------- placeholder

func _draw() -> void:
	if _projector == null or (_front != null and _front.texture != null):
		return
	# lot footprint
	var lot := float(WorldConfig.LOT_SIZE)
	var footprint := _projector.polygon([
		Vector2(_gx, _gy), Vector2(_gx + lot, _gy),
		Vector2(_gx + lot, _gy + lot), Vector2(_gx, _gy + lot),
	])
	draw_colored_polygon(footprint, Iso.shade(WorldConfig.GROUND_COLOR, 0.93))
	_draw_box(_gx + 1.0, _gy + 1.0, lot - 2.0, lot - 2.0, 90.0, Palette.WHEAT)
	var label_pos := _projector.project(_gx + lot / 2.0, _gy + lot / 2.0, 90.0 + 40.0)
	draw_string(
		ThemeDB.fallback_font, label_pos - Vector2(150, 0), Strings.TITLE,
		HORIZONTAL_ALIGNMENT_CENTER, 300.0, 28, Palette.INK
	)


## Draws an iso box: grid rect (x, y, w, d) and height h (px).
func _draw_box(x: float, y: float, w: float, d: float, h: float, base: Color) -> void:
	var col := Iso.box_colors(base)
	var p := _projector
	# visible side faces are the ones at y + d (left) and x + w (right)
	var left_face := PackedVector2Array([
		p.project(x, y + d, 0.0), p.project(x + w, y + d, 0.0),
		p.project(x + w, y + d, h), p.project(x, y + d, h),
	])
	var right_face := PackedVector2Array([
		p.project(x + w, y, 0.0), p.project(x + w, y + d, 0.0),
		p.project(x + w, y + d, h), p.project(x + w, y, h),
	])
	var top_face := PackedVector2Array([
		p.project(x, y, h), p.project(x + w, y, h),
		p.project(x + w, y + d, h), p.project(x, y + d, h),
	])
	draw_colored_polygon(left_face, col["left"])
	draw_colored_polygon(right_face, col["right"])
	draw_colored_polygon(top_face, col["top"])
