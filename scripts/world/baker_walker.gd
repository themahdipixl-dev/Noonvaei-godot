class_name BakerWalker
extends Node2D
## Baker patrolling between stops inside the bakery. Port of src/world/BakerWalker.js
##
## One value (time in seconds) drives position, direction and frame.
## While waiting at a stop the static baker_view image is shown instead of a walk frame.
##
## React / Reanimated                       ->  Godot
##   useSharedValue(time) + withRepeat       ->  `_time` advanced in _process() and wrapped with fmod()
##   useAnimatedStyle (opacity / translate)  ->  `visible` / `frame` / `position`
##   walk strip clipped in a View            ->  Sprite2D with `hframes` (8 frames in one row)
##   Image.getSize                           ->  texture size (known immediately)
##   RadialGradient shadow                   ->  GradientTexture2D drawn by `_draw_body`
##
## If the walk sheets are not in the project yet, a simple placeholder figure is drawn instead.

## walk frame (legs together) that the walk starts / ends on, per direction (sw, se, ne, nw)
const IDLE_FRAME: Array[int] = [7, 3, 7, 6]

var _projector: Iso
var _table: Array[Dictionary] = []
var _total := 0.0
var _points: Array[Vector2] = []
var _time := 0.0
var _char_h := 56.0
var _debug := false

var _body: DrawProxy
var _layers: Array[Node2D] = []
var _walk: Array[Sprite2D] = []
var _idle: Array[Sprite2D] = []
var _has_art := false
var _shadow_tex: GradientTexture2D

var _cur_dir := 0
var _cur_frame := 0
var _cur_idle := true


## `bakery` is needed to convert the stop points (fractions of bakery_front.webp) to grid coordinates.
func setup(projector: Iso, bakery: Bakery) -> void:
	_projector = projector
	var cfg: Dictionary = WorldConfig.WALKER
	_char_h = float(cfg["char_h"])
	_debug = bool(cfg["debug"])

	# bakery_front.webp fraction -> world px -> grid (same result as the JS toGrid math)
	var stops: Array = cfg["stops"]
	for s in stops:
		var frac: Vector2 = s["p"]
		_points.append(projector.unproject(bakery.canvas_origin() + frac * bakery.canvas_size()))
	_build_timeline(stops, float(cfg["speed"]), float(cfg["stride"]))

	if _total <= 0.0:
		set_process(false)
		return

	_shadow_tex = _make_shadow_tex(float(cfg["shadow"]["opacity"]))
	_body = DrawProxy.new()
	_body.name = "Body"
	_body.draw_cb = _draw_body
	add_child(_body)
	_build_sprites(cfg)
	_step(0.0)
	queue_redraw()


# ------------------------------------------------------------------ timeline

## Table rows (Dictionary): t0, dur, x0, y0, dx, dy, dir, wait (bool), stride, len
func _build_timeline(stops: Array, speed: float, stride: float) -> void:
	_table.clear()
	_total = 0.0
	var n := stops.size()
	if n < 2:
		return
	var frames := int(EnvironmentAssets.BAKER_WALK_SHEET["frames"])
	var t := 0.0
	var last_dir := CarPhysics.move_dir(_points[0].x - _points[n - 1].x, _points[0].y - _points[n - 1].y)

	for i in n:
		var p0 := _points[i]
		var p1 := _points[(i + 1) % n]
		var stop: Dictionary = stops[i]

		var wait := float(stop.get("wait", 0.0))
		if wait > 0.0:
			var face := EnvironmentAssets.DIRS.find(String(stop.get("face", "")))
			_table.append({
				"t0": t, "dur": wait, "x0": p0.x, "y0": p0.y, "dx": 0.0, "dy": 0.0,
				"dir": face if face >= 0 else last_dir, "wait": true, "stride": 1.0, "len": 1.0,
			})
			t += wait

		var d := p1 - p0
		var length := d.length()
		if length > 0.0:
			var dir := CarPhysics.move_dir(d.x, d.y)
			# whole number of 8-frame cycles per leg, so the walk ends on the idle pose
			var cycles := maxi(1, int(round(length / (stride * float(frames)))))
			var seg_stride := length / (float(cycles) * float(frames))
			var dur := length / speed
			_table.append({
				"t0": t, "dur": dur, "x0": p0.x, "y0": p0.y, "dx": d.x, "dy": d.y,
				"dir": dir, "wait": false, "stride": seg_stride, "len": length,
			})
			last_dir = dir
			t += dur
	_total = t


## State at time t: { gx, gy, dir, frame, idle }
func _sample(t: float) -> Dictionary:
	var seg: Dictionary = _table[_table.size() - 1]
	for row in _table:
		if t < float(row["t0"]) + float(row["dur"]):
			seg = row
			break
	var dir := int(seg["dir"])
	if bool(seg["wait"]):
		return {"gx": float(seg["x0"]), "gy": float(seg["y0"]), "dir": dir, "frame": IDLE_FRAME[dir], "idle": true}
	var frames := int(EnvironmentAssets.BAKER_WALK_SHEET["frames"])
	var local := clampf(t - float(seg["t0"]), 0.0, float(seg["dur"]))
	var k := local / float(seg["dur"])
	var step := int(floor(k * float(seg["len"]) / float(seg["stride"]) + 0.000001))
	return {
		"gx": float(seg["x0"]) + float(seg["dx"]) * k,
		"gy": float(seg["y0"]) + float(seg["dy"]) * k,
		"dir": dir,
		"frame": posmod(IDLE_FRAME[dir] + step, frames),
		"idle": false,
	}


# ------------------------------------------------------------------ nodes

func _build_sprites(cfg: Dictionary) -> void:
	var sheet: Dictionary = EnvironmentAssets.BAKER_WALK_SHEET
	var frames := int(sheet["frames"])
	var base := float(cfg["char_h"]) / float(sheet["ref_h"])
	var dir_scale: Dictionary = cfg["dir_scale"]
	var idle_scale: Dictionary = cfg["idle_scale"]
	var idle_offset: Dictionary = cfg["idle_offset"]

	var walk_tex: Array[Texture2D] = []
	var all_ok := true
	for d in EnvironmentAssets.DIRS:
		var t := EnvironmentAssets.get_texture(EnvironmentAssets.baker_walk_path(d))
		walk_tex.append(t)
		if t == null:
			all_ok = false
	_has_art = all_ok
	if not _has_art:
		return  # placeholder figure is drawn by _draw_body

	for i in 4:
		var d: String = EnvironmentAssets.DIRS[i]
		var sc := base * float(dir_scale.get(d, 1.0))
		var layer := Node2D.new()
		layer.name = "Dir_%s" % d
		_body.add_child(layer)

		# walk strip: 8 cells in one row, feet point = (cell_w / 2, feet_y)
		var wt := walk_tex[i]
		var fw := float(wt.get_width()) / float(frames)
		var fh := float(wt.get_height())
		var cw := float(sheet["cell_w"]) * sc
		var ch := float(sheet["cell_h"]) * sc
		var feet := float(sheet["feet_y"]) * sc
		var walk := Sprite2D.new()
		walk.texture = wt
		walk.hframes = frames
		walk.centered = false
		walk.scale = Vector2(cw / fw, ch / fh)
		walk.position = Vector2(-cw / 2.0, -feet)
		layer.add_child(walk)

		# static view (while waiting): bottom-center of the image sits on the ground point
		var idle: Sprite2D = null
		var view_tex := EnvironmentAssets.get_texture(EnvironmentAssets.BAKER_VIEWS[i])
		if view_tex != null:
			var ih := float(sheet["ref_h"]) * sc * float(idle_scale.get(d, 1.0))
			var iw := ih * float(view_tex.get_width()) / float(view_tex.get_height())
			var off: Vector2 = idle_offset.get(d, Vector2.ZERO)
			idle = Sprite2D.new()
			idle.texture = view_tex
			idle.centered = false
			idle.scale = Vector2(iw / float(view_tex.get_width()), ih / float(view_tex.get_height()))
			idle.position = Vector2(-iw / 2.0 + off.x, -ih + off.y)
			layer.add_child(idle)

		layer.visible = false
		_layers.append(layer)
		_walk.append(walk)
		_idle.append(idle)


func _make_shadow_tex(opacity: float) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, opacity), Color(0, 0, 0, opacity * 0.55), Color(0, 0, 0, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	return tex


# ------------------------------------------------------------------ per frame

func _process(delta: float) -> void:
	_step(delta)


func _step(delta: float) -> void:
	if _total <= 0.0 or _body == null:
		return
	_time = fmod(_time + delta, _total)
	var p := _sample(_time)
	_body.position = _projector.project(float(p["gx"]), float(p["gy"]))
	_cur_dir = int(p["dir"])
	_cur_frame = int(p["frame"])
	_cur_idle = bool(p["idle"])

	if _has_art:
		for i in _layers.size():
			var on := i == _cur_dir
			_layers[i].visible = on
			if not on:
				continue
			var show_idle := _cur_idle and _idle[i] != null
			_walk[i].visible = not show_idle
			_walk[i].frame = _cur_frame
			if _idle[i] != null:
				_idle[i].visible = show_idle
	else:
		_body.queue_redraw()


# ------------------------------------------------------------------ drawing

## Debug: red dots on the stop points (WALKER.debug).
func _draw() -> void:
	if not _debug or _projector == null:
		return
	for g in _points:
		draw_circle(_projector.project(g.x, g.y), 4.0, Color.RED)


## Ground shadow (+ placeholder figure when there is no art). Drawn in `_body` local space (feet = origin).
func _draw_body(c: CanvasItem) -> void:
	var sh: Dictionary = WorldConfig.WALKER["shadow"]
	var w := _char_h * float(sh["width"])
	var h := w * _projector.ratio
	c.draw_texture_rect(_shadow_tex,
		Rect2(-w / 2.0 + float(sh["offset_x"]), -h / 2.0 + float(sh["offset_y"]), w, h), false)
	if not _has_art:
		_draw_placeholder(c)


## Simple stand-in figure (cream body, hat, bobbing legs) so the patrol can be tested without art.
func _draw_placeholder(c: CanvasItem) -> void:
	var h := _char_h
	var frames := float(EnvironmentAssets.BAKER_WALK_SHEET["frames"])
	var phase := float(_cur_frame) / frames * TAU
	var swing := 0.0 if _cur_idle else sin(phase) * 0.05 * h
	var bob := 0.0 if _cur_idle else -absf(sin(phase)) * 0.025 * h
	var leg := Color("#3a2214")

	c.draw_rect(Rect2(-0.1 * h + swing, -0.3 * h, 0.07 * h, 0.3 * h), leg)
	c.draw_rect(Rect2(0.03 * h - swing, -0.3 * h, 0.07 * h, 0.3 * h), leg)
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(-0.17 * h, -0.62 * h + bob), Vector2(0.17 * h, -0.62 * h + bob),
		Vector2(0.14 * h, -0.28 * h + bob), Vector2(-0.14 * h, -0.28 * h + bob),
	]), Palette.CREAM)
	var head := Vector2(0.0, -0.74 * h + bob)
	c.draw_circle(head, 0.1 * h, Color("#f0c9a0"))
	c.draw_rect(Rect2(-0.11 * h, -0.88 * h + bob, 0.22 * h, 0.07 * h), Color.WHITE)
	# eye only when facing the camera (sw / se); side shows the facing direction
	if _cur_dir == 0 or _cur_dir == 1:
		var side := -1.0 if _cur_dir == 0 else 1.0
		c.draw_circle(head + Vector2(side * 0.035 * h, 0.01 * h), 0.014 * h, Palette.INK)
