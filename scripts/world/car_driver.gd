class_name CarDriver
extends Node2D
## One car driving a looped route with a simple driver model: accelerates from rest, cruises,
## slows for corners, stops at (virtual) red lights. Port of src/world/CarDriver.js
##
## The wheels (rims) rotate with the distance travelled and are drawn as iso ellipses.
##
## React / Reanimated                          ->  Godot
##   useFrameCallback + shared values           ->  _process(delta) + plain variables
##   one <Image> per direction (opacity)        ->  one Node2D layer per direction (`visible`)
##   turn spritesheet (translateX / translateY) ->  Sprite2D with `hframes` / `vframes` / `frame`
##   Rim: rotate + scaleX on a View             ->  Node2D (rotation + scale.x) holding a spinning Sprite2D
##   Svg ground shadow                          ->  polygons drawn by `_draw_body`
##
## If the car images are not in the project yet, a simple iso box is drawn instead (placeholder).

## horizontal screen sign of each sprite's forward direction (JS: f[0] >= 0 ? 1 : -1) for sw, se, ne, nw
const SPIN_SIGN: Array[float] = [-1.0, 1.0, 1.0, -1.0]

var _car: Dictionary = {}
var _projector: Iso
var _path: Dictionary = {}

# driver state
var _s := 0.0      # distance along the route (tiles)
var _v := 0.0      # speed
var _a := 0.0      # acceleration
var _w := 0.0      # seconds waited at a light
var _k := -1       # light we were released from
var _clock := 0.0

# what the route says right now
var _dir := 0
var _frame := 0
var _ang := 0.0    # wheel angle (degrees)

var _body: DrawProxy
var _layers: Array[Node2D] = []
var _spinners: Array[Sprite2D] = []
var _turn: Sprite2D
var _turn_frames := 20
var _turn_offset := 0
## number of heading frames between two main directions (turn sheet) - 1 when there is no turn sheet
var _per := 1
var _has_art := false
var _shadow_rings: Array = []  # [parity 0 rings, parity 1 rings]; each ring is a PackedVector2Array


func setup(car: Dictionary, projector: Iso) -> void:
	_car = car
	_projector = projector
	var drive: Dictionary = car["drive"]

	var path := CarPhysics.build_path(car["route"], float(drive["corner_radius"]), 0.05, 0.4)
	if path.is_empty():
		set_process(false)
		return
	path["lights"] = CarPhysics.build_lights(car["lights"], path, float(drive["half_length"]))
	path["drive"] = drive
	_path = path
	_s = float(car.get("start_at", 0.0)) * float(path["L"])

	_shadow_rings = [_make_shadow(false), _make_shadow(true)]

	_body = DrawProxy.new()
	_body.name = "Body"
	_body.draw_cb = _draw_body
	add_child(_body)
	_build_sprites()
	_sync()


# ------------------------------------------------------------------ nodes

func _build_sprites() -> void:
	var id := String(_car["id"])
	var width := float(_car["width"])
	var anchor_y := float(_car["anchor_y"])
	var aspect: Dictionary = _car["aspect"]
	var scale_d: Dictionary = _car["scale"]
	var offset_d: Dictionary = _car["offset"]
	var rims: Dictionary = _car["rims"]
	var rim_scale := float(_car.get("rim_scale", 1.0))
	var rim_k := float(_car.get("rim_k", 0.566))
	var rim_rot: Dictionary = _car.get("rim_rot", {})

	var tex_list: Array[Texture2D] = []
	var all_ok := true
	for d in CarPhysics.DIRS:
		var t := EnvironmentAssets.get_texture(EnvironmentAssets.vehicle_path(id, d))
		tex_list.append(t)
		if t == null:
			all_ok = false
	_has_art = all_ok
	if not _has_art:
		return  # placeholder box is drawn by _draw_body

	var rim_tex := EnvironmentAssets.get_texture(EnvironmentAssets.vehicle_rim_path(id))

	for i in 4:
		var d: String = CarPhysics.DIRS[i]
		var w := width * float(scale_d.get(d, 1.0))
		var h := w / float(aspect.get(d, 1.45))
		var off: Vector2 = offset_d.get(d, Vector2.ZERO)

		# layer origin = top-left of the car image; ground point is `anchor_y` down the image
		var layer := Node2D.new()
		layer.name = "Dir_%s" % d
		layer.position = Vector2(-w / 2.0 + off.x, -h * anchor_y + off.y)
		_body.add_child(layer)

		var tex := tex_list[i]
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.centered = false
		spr.scale = Vector2(w / float(tex.get_width()), h / float(tex.get_height()))
		layer.add_child(spr)

		if rim_tex != null:
			var rim_list: Array = rims.get(d, [])
			for r in rim_list:
				var major := float(r["d"]) * w * rim_scale
				# the holder squashes the circle into the wheel ellipse (rotate, then scale x)
				var holder := Node2D.new()
				holder.position = Vector2(float(r["x"]) * w, float(r["y"]) * h)
				holder.rotation_degrees = float(rim_rot.get(d, 0.0))
				holder.scale = Vector2(rim_k, 1.0)
				layer.add_child(holder)
				var spin := Sprite2D.new()
				spin.texture = rim_tex
				spin.scale = Vector2(major / float(rim_tex.get_width()), major / float(rim_tex.get_height()))
				spin.set_meta("sign", SPIN_SIGN[i])
				holder.add_child(spin)
				_spinners.append(spin)

		layer.visible = false
		_layers.append(layer)

	# 90 degree turn spritesheet (the frames between the 4 main directions)
	var turn: Dictionary = _car.get("turn", {})
	var turn_tex := EnvironmentAssets.get_texture(EnvironmentAssets.vehicle_turn_path(id))
	if not turn.is_empty() and turn_tex != null:
		var cols := int(turn["cols"])
		var rows := int(turn["rows"])
		_turn_frames = int(turn["frames"])
		_turn_offset = int(turn.get("frame_offset", 0))
		_per = int(float(_turn_frames) / 4.0)
		var tw := float(turn["width"])
		var th := tw / float(turn["aspect"])
		var toff: Vector2 = turn.get("offset", Vector2.ZERO)
		_turn = Sprite2D.new()
		_turn.name = "Turn"
		_turn.texture = turn_tex
		_turn.hframes = cols
		_turn.vframes = rows
		_turn.centered = false
		_turn.scale = Vector2(
			tw / (float(turn_tex.get_width()) / float(cols)),
			th / (float(turn_tex.get_height()) / float(rows)))
		_turn.position = Vector2(-tw / 2.0 + toff.x, -th * float(turn.get("anchor_y", anchor_y)) + toff.y)
		_turn.visible = false
		_body.add_child(_turn)


## Ground shadow rings (3 soft ellipses) around the car, in `_body` local px.
func _make_shadow(along_x: bool) -> Array:
	var cfg: Dictionary = _car["shadow"]
	var a := float(cfg["length"]) / 2.0
	var b := float(cfg["width"]) / 2.0
	var rx := a if along_x else b
	var ry := b if along_x else a
	var shift := Vector2(float(cfg.get("dx", 0.0)), float(cfg.get("dy", 0.0)))
	var rings: Array = []
	for kk in [1.0, 0.78, 0.56]:
		var k := float(kk)
		var pts := PackedVector2Array()
		for i in 28:
			var th := float(i) / 28.0 * TAU
			pts.append(_grid_to_local(Vector2(cos(th) * rx * k, sin(th) * ry * k), 0.0) + shift)
		rings.append(pts)
	return rings


# ------------------------------------------------------------------ per frame

func _process(delta: float) -> void:
	if _path.is_empty():
		return
	var dt := minf(delta, 0.05)
	if dt <= 0.0:
		return
	_clock += dt
	var r := CarPhysics.step_car(_s, _v, _a, _clock, dt, _path, _w, _k)
	_s = float(r[0])
	_v = float(r[1])
	_a = float(r[2])
	_w = float(r[3])
	_k = int(r[4])
	_sync()


## Puts the node on the route position and updates which sprite is visible.
func _sync() -> void:
	var p := CarPhysics.path_at(_path, _s)
	_dir = int(p[2])
	_frame = int(p[3])
	var drive: Dictionary = _car["drive"]
	# tiny road vibration, only while moving
	var bob := sin(_s * 10.0) * 0.35 * minf(_v / float(drive["cruise"]), 1.0)
	_body.position = _projector.project(float(p[0]), float(p[1])) + Vector2(0.0, bob)
	_ang = fmod(_s / float(_car["wheel_circ"]) * 360.0, 360.0)

	if _has_art:
		# between two main directions (middle of a turn) the direction layers hide and the turn sheet shows
		var main_frame := _frame % _per == 0
		for i in _layers.size():
			_layers[i].visible = _dir == i and main_frame
		if _turn != null:
			_turn.visible = not main_frame
			if not main_frame:
				_turn.frame = posmod(_frame + _turn_offset + _turn_frames, _turn_frames)
		for sp in _spinners:
			sp.rotation_degrees = float(sp.get_meta("sign")) * _ang
	_body.queue_redraw()


# ------------------------------------------------------------------ drawing

## grid offset (relative to the car) + height z (px) -> `_body` local px
func _grid_to_local(u: Vector2, z: float) -> Vector2:
	return Vector2((u.x - u.y) * _projector.tile_w / 2.0, (u.x + u.y) * _projector.tile_h / 2.0 - z)


## Shadow on the ground (+ placeholder box when there is no art). `_body` local space, origin = ground point.
func _draw_body(c: CanvasItem) -> void:
	var rings: Array = _shadow_rings[_dir % 2]
	var alpha := float(_car["shadow"]["opacity"]) * 0.5
	for ring in rings:
		c.draw_colored_polygon(ring, Color(0, 0, 0, alpha))
	if _has_art:
		return

	# placeholder: a body + cabin box pointing along the route
	var a := CarPhysics.path_at(_path, _s)
	var b := CarPhysics.path_at(_path, _s + 0.25)
	var fwd := Vector2(float(b[0]) - float(a[0]), float(b[1]) - float(a[1]))
	fwd = fwd.normalized() if fwd.length() > 0.0001 else Vector2.RIGHT
	var sh: Dictionary = _car["shadow"]
	var half_len := float(sh["length"]) * 0.42
	var half_w := float(sh["width"]) * 0.42
	_draw_prism(c, fwd, half_len, half_w, 0.0, 14.0, Palette.TEAL, 0.0)
	_draw_prism(c, fwd, half_len * 0.5, half_w * 0.9, 14.0, 26.0, Palette.CREAM, -half_len * 0.1)


## Iso box on the ground plane: 4 side faces (back to front), then the top.
func _draw_prism(c: CanvasItem, fwd: Vector2, half_len: float, half_w: float,
		z0: float, z1: float, color: Color, shift: float) -> void:
	var right := Vector2(-fwd.y, fwd.x)
	var ctr := fwd * shift
	var corners: Array[Vector2] = [
		ctr + fwd * half_len + right * half_w,
		ctr + fwd * half_len - right * half_w,
		ctr - fwd * half_len - right * half_w,
		ctr - fwd * half_len + right * half_w,
	]
	var light := Vector2(-1.0, 1.0).normalized()
	var faces: Array = []
	for i in 4:
		var pa := corners[i]
		var pb := corners[(i + 1) % 4]
		var mid := (pa + pb) / 2.0
		var normal := (mid - ctr).normalized()
		faces.append({
			"depth": mid.x + mid.y,
			"quad": PackedVector2Array([
				_grid_to_local(pa, z0), _grid_to_local(pb, z0), _grid_to_local(pb, z1), _grid_to_local(pa, z1)]),
			"color": Iso.shade(color, 0.8 + 0.2 * normal.dot(light)),
		})
	faces.sort_custom(func(f1: Dictionary, f2: Dictionary) -> bool: return float(f1["depth"]) < float(f2["depth"]))
	for f in faces:
		c.draw_colored_polygon(f["quad"], f["color"])
	c.draw_colored_polygon(PackedVector2Array([
		_grid_to_local(corners[0], z1), _grid_to_local(corners[1], z1),
		_grid_to_local(corners[2], z1), _grid_to_local(corners[3], z1)]), Iso.shade(color, 1.12))
