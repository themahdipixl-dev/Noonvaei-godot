class_name Iso
extends RefCounted
## Isometric helpers. Grid (x, y) -> screen (px). z is height in px.
## Port of src/scene/iso.js  (makeProjector, pts, shade, boxColors)
##
## ratio = tileH / tileW  (2:1 game iso = 0.5, true isometric = 0.577)
##
## Usage:
##   var iso := Iso.new(96.0, Vector2(1100, 200), 0.577)
##   var screen_pos := iso.project(gx, gy, z)

var tile_w: float
var tile_h: float
var origin: Vector2
var ratio: float


func _init(p_tile_w: float, p_origin: Vector2, p_ratio: float = 0.5) -> void:
	tile_w = p_tile_w
	origin = p_origin
	ratio = p_ratio
	tile_h = p_tile_w * p_ratio


## Grid (x, y) + height z (px)  ->  position in world px.
func project(x: float, y: float, z: float = 0.0) -> Vector2:
	return Vector2(
		origin.x + (x - y) * tile_w / 2.0,
		origin.y + (x + y) * tile_h / 2.0 - z
	)


## NEW (not in the JS version, needed by the actors in Part 4):
## world px (at z = 0)  ->  grid coordinates.
func unproject(p: Vector2) -> Vector2:
	var diff := (p.x - origin.x) * 2.0 / tile_w   # x - y
	var sum := (p.y - origin.y) * 2.0 / tile_h    # x + y
	return Vector2((sum + diff) / 2.0, (sum - diff) / 2.0)


## Projects several grid points at once (replaces `pts()` which built an SVG points string).
func polygon(grid_points: Array, z: float = 0.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	for gp in grid_points:
		var v: Vector2 = gp
		out.append(project(v.x, v.y, z))
	return out


## Multiplies the RGB of a color by f (clamped).
static func shade(c: Color, f: float) -> Color:
	return Color(minf(1.0, c.r * f), minf(1.0, c.g * f), minf(1.0, c.b * f), c.a)


## Light comes from the top-left: left face lit, right face darker.
## Returns { top, left, right }
static func box_colors(base: Color) -> Dictionary:
	return {
		"top": shade(base, 1.15),
		"left": shade(base, 0.9),
		"right": shade(base, 0.68),
	}
