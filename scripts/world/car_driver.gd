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
##   Svg ground shadow                          ->  sprite mode: polygons drawn by `_draw_body`
##                                                  3D mode: real sun shadow inside CarModel3D (same style as the Front)
##
## What is shown as the car body (first match wins):
##   1. a 3D model file  <id>.glb  in the project           -> CarModel3D (real model)
##   2. all 4 direction sprites (+ optional rims / turn sheet) -> sprites (original RN look)
##   3. nothing of the above                                 -> CarModel3D placeholder car (simple 3D boxes)
## So dropping `peugeot_pars.glb` into the project replaces the placeholder (see scripts/world/car_model_3d.gd).

## horizontal screen sign of each sprite's forward direction (JS: f[0] >= 0 ? 1 : -1) for sw, se, ne, nw
const SPIN_SIGN: Array[float] = [-1.0, 1.0, 1.0, -1.0]
## how far ahead (tiles) the 3D model looks to find its heading
const MODEL_LOOKAHEAD := 0.2

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
## 3D car (real .glb model or the placeholder); null when the sprites are used
var _model: CarModel3D
## 2D shadow rings, only used in sprite mode: [parity 0 rings, parity 1 rings]; each ring is a PackedVector2Array
var _shadow_rings: Array = []


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

	_body = DrawProxy.new()
	_body.name = "Body"
	_body.draw_cb = _draw_body
	add_child(_body)
	_build_sprites()
	# The 2D ellipse shadow is only for the old sprite mode. The 3D car casts a real sun shadow (see CarModel3D).
	if _model == null:
		_shadow_rings = [_make_shadow(false), _make_shadow(true)]
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

	var has_glb := CarModel3D.find_model(id) != ""

	var tex_list: Array[Texture2D] = []
	var all_ok := true
	for d in CarPhysics.DIRS:
		var t := EnvironmentAssets.get_texture(EnvironmentAssets.vehicle_path(id, d))
		tex_list.append(t)
		if t == null:
			all_ok = false

	# a 3D model file wins; with no sprites either, a simple 3D placeholder car is shown
	if has_glb or not all_ok:
		_build_model()
		return
	_has_art = true

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


## 3D car: the real <id>.glb when it exists in the project, otherwise a simple placeholder car.
func _build_model() -> void:
	var len_tiles := float(_car["shadow"]["length"])
	_model = CarModel3D.new()
	_model.name = "Model3D"
	_body.add_child(_model)
	_model.setup(String(_car["id"]), _projector.tile_w, len_tiles, _car.get("model", {}))


## Ground shadow rings (3 soft ellipses) around the car, in `_body` local px. Sprite mode only.
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

	if _model != null:
		# heading = direction of the route a little ahead of the car
		var q := CarPhysics.path_at(_path, _s + MODEL_LOOKAHEAD)
		# `_s` (distance driven, tiles) makes the wheels roll at the real speed and steer in corners
		_model.update_pose(Vector2(float(q[0]) - float(p[0]), float(q[1]) - float(p[1])), _ang, _s)
	else:
		_body.queue_redraw()


# ------------------------------------------------------------------ drawing

## grid offset (relative to the car) + height z (px) -> `_body` local px
func _grid_to_local(u: Vector2, z: float) -> Vector2:
	return Vector2((u.x - u.y) * _projector.tile_w / 2.0, (u.x + u.y) * _projector.tile_h / 2.0 - z)


## 2D shadow on the ground (sprite mode only). `_body` local space, origin = ground point.
## With a 3D car nothing is drawn here: the shadow comes from the sun inside CarModel3D.
func _draw_body(c: CanvasItem) -> void:
	if _model != null or _shadow_rings.is_empty():
		return
	var rings: Array = _shadow_rings[_dir % 2]
	var alpha := float(_car["shadow"]["opacity"]) * 0.5
	for ring in rings:
		c.draw_colored_polygon(ring, Color(0, 0, 0, alpha))
