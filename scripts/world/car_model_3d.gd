class_name CarModel3D
extends Node2D
## A real 3D car shown inside the 2D isometric world.
##
## How it works: the model lives in its own SubViewport (transparent background) with an orthographic
## camera at the isometric angle. The viewport texture is shown by a Sprite2D, so the rest of the game
## (Node2D layers, shadows, camera) does not change.
##
## Which model is shown:
##   1. <id>.glb (or .gltf) found in the project  ->  the real model
##   2. nothing found                              ->  a light placeholder car built from boxes
##
## Folders searched for <id>.glb (first match wins), e.g. <id> = peugeot_pars:
##   res://assets/vehicles/peugeot_pars/peugeot_pars.glb   (recommended)
##   res://assets/vehicles/peugeot_pars.glb
##   res://assets/models/peugeot_pars.glb
##   res://models/peugeot_pars.glb
##   res://peugeot_pars.glb
##
## Optional tuning: add a "model" dictionary to the car in world_config.gd:
##   "model": {
##       "yaw_offset": 0.0,       # degrees; use 90 / 180 / -90 if the car drives sideways or backwards
##       "scale": 1.0,            # size multiplier on screen
##       "spin_wheels": false,    # spin nodes named *wheel* in the .glb (only if their pivots are at the wheel centres)
##   }
## The car length on screen is taken from car["shadow"]["length"] (tiles).
##
## Model convention: the car must look towards +Z (glTF default). The model is automatically centred,
## put on the ground and scaled, so the original size / origin of the file does not matter.

const VIEW_PX := 384
const ORTHO_SIZE := 6.0
## the car is normalised to this length (3D units)
const CAR_LENGTH := 4.0
## asin(1 / sqrt(3)): the camera pitch that matches the 0.577 (tileH / tileW) ground ratio of the world
const PITCH_DEG := 35.264
const EXTENSIONS: Array[String] = ["glb", "gltf"]

var _viewport: SubViewport
var _sprite: Sprite2D
var _pivot: Node3D
var _yaw := 0.0
var _yaw_offset := 0.0
var _has_yaw := false
## [{ "node": Node3D, "base": Basis }]
var _wheels: Array = []
var _from_file := false


## Path of the model file of this car id, or "" when there is none in the project.
static func find_model(id: String) -> String:
	var dirs: Array[String] = [
		"res://assets/vehicles/%s/" % id,
		"res://assets/vehicles/",
		"res://assets/models/",
		"res://models/",
		"res://",
	]
	for d in dirs:
		for ext in EXTENSIONS:
			var p := "%s%s.%s" % [d, id, ext]
			if ResourceLoader.exists(p):
				return p
	return ""


func is_from_file() -> bool:
	return _from_file


## `length_tiles` = car length in grid tiles, `tile_w` = tile width in px (Iso.tile_w).
func setup(car_id: String, tile_w: float, length_tiles: float, cfg: Dictionary = {}) -> void:
	_yaw_offset = float(cfg.get("yaw_offset", 0.0))

	# ---- viewport with its own 3D world
	_viewport = SubViewport.new()
	_viewport.name = "View3D"
	_viewport.size = Vector2i(VIEW_PX, VIEW_PX)
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_2X
	_viewport.gui_disable_input = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.5

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = ORTHO_SIZE
	cam.near = 0.1
	cam.far = 100.0
	cam.environment = env
	var pitch := deg_to_rad(PITCH_DEG)
	cam.rotation_degrees = Vector3(-PITCH_DEG, 0.0, 0.0)
	cam.position = Vector3(0.0, sin(pitch) * 30.0, cos(pitch) * 30.0)
	_viewport.add_child(cam)

	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.1
	sun.basis = Basis.looking_at(Vector3(0.45, -0.8, -0.35).normalized(), Vector3.UP)
	_viewport.add_child(sun)

	# ---- the car
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	_viewport.add_child(_pivot)

	var content: Node3D = null
	var path := find_model(car_id)
	if path != "":
		content = _load_model(path)
		if content != null:
			_from_file = true
			if bool(cfg.get("spin_wheels", false)):
				_collect_wheels(content)
			print("CarModel3D[%s]: using model %s" % [car_id, path])
	if content == null:
		content = _build_placeholder()
		print("CarModel3D[%s]: no .glb found, showing the placeholder car (put %s.glb in res://assets/vehicles/%s/)" % [car_id, car_id, car_id])
	_pivot.add_child(content)

	# ---- show the viewport as a sprite whose centre = the ground point under the car
	_sprite = Sprite2D.new()
	_sprite.name = "Render"
	_sprite.texture = _viewport.get_texture()
	_sprite.centered = true
	add_child(_sprite)

	# px per 3D unit on screen so that the car is `length_tiles` long on the iso ground
	var units_per_tile := CAR_LENGTH / maxf(length_tiles, 0.1)
	var px_per_unit := tile_w / (sqrt(2.0) * units_per_tile) * float(cfg.get("scale", 1.0))
	_sprite.scale = Vector2.ONE * (px_per_unit / (float(VIEW_PX) / ORTHO_SIZE))


## `grid_fwd` = driving direction in grid coordinates, `wheel_deg` = wheel angle in degrees.
func update_pose(grid_fwd: Vector2, wheel_deg: float) -> void:
	if _pivot == null:
		return
	if grid_fwd.length_squared() > 0.000001:
		# grid (x, y) -> ground plane of the 3D view: X = (x - y), Z = (x + y)  (Z points to the camera)
		var target := atan2(grid_fwd.x - grid_fwd.y, grid_fwd.x + grid_fwd.y) + deg_to_rad(_yaw_offset)
		if _has_yaw:
			_yaw = lerp_angle(_yaw, target, 0.4)
		else:
			_yaw = target
			_has_yaw = true
		_pivot.rotation.y = _yaw
	var spin := deg_to_rad(wheel_deg)
	for w in _wheels:
		(w["node"] as Node3D).basis = (w["base"] as Basis) * Basis(Vector3.RIGHT, spin)


# ------------------------------------------------------------------ real model

func _load_model(path: String) -> Node3D:
	var res := load(path)
	if res is PackedScene:
		var inst := (res as PackedScene).instantiate()
		if inst is Node3D:
			return _normalize(inst as Node3D)
		inst.free()
	push_warning("CarModel3D: could not use %s, showing the placeholder car instead" % path)
	return null


## Centres the model on the ground point, puts it on y = 0 and scales its length to CAR_LENGTH.
func _normalize(root: Node3D) -> Node3D:
	var box: Array = []
	_collect_aabb(root, Transform3D.IDENTITY, box)
	var holder := Node3D.new()
	holder.name = "Normalized"
	holder.add_child(root)
	if box.is_empty():
		return holder
	var bb: AABB = box[0]
	var longest := maxf(bb.size.x, bb.size.z)
	if longest <= 0.0001:
		return holder
	var k := CAR_LENGTH / longest
	holder.scale = Vector3(k, k, k)
	var c := bb.get_center()
	holder.position = Vector3(-c.x * k, -bb.position.y * k, -c.z * k)
	return holder


func _collect_aabb(node: Node, xform: Transform3D, box: Array) -> void:
	var t := xform
	if node is Node3D:
		t = xform * (node as Node3D).transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var b: AABB = t * (node as MeshInstance3D).mesh.get_aabb()
		if box.is_empty():
			box.append(b)
		else:
			box[0] = (box[0] as AABB).merge(b)
	for c in node.get_children():
		_collect_aabb(c, t, box)


func _collect_wheels(node: Node) -> void:
	for c in node.get_children():
		if c is Node3D and String(c.name).to_lower().contains("wheel"):
			_wheels.append({"node": c, "base": (c as Node3D).basis})
		else:
			_collect_wheels(c)


# ------------------------------------------------------------------ placeholder

## A small car made of boxes + 4 wheels, looking towards +Z. Headlights (yellow) show the front.
func _build_placeholder() -> Node3D:
	var root := Node3D.new()
	root.name = "PlaceholderCar"

	var body := _box(Vector3(1.8, 0.6, 4.0), Palette.TEAL)
	body.position = Vector3(0.0, 0.55, 0.0)
	root.add_child(body)

	var cabin := _box(Vector3(1.5, 0.55, 2.0), Palette.CREAM)
	cabin.position = Vector3(0.0, 1.125, -0.2)
	root.add_child(cabin)

	for sx in [-1.0, 1.0]:
		var lamp := _box(Vector3(0.4, 0.18, 0.06), Color(1.0, 0.9, 0.4))
		lamp.position = Vector3(float(sx) * 0.55, 0.6, 2.0)
		root.add_child(lamp)
		var tail := _box(Vector3(0.4, 0.18, 0.06), Color(0.85, 0.15, 0.15))
		tail.position = Vector3(float(sx) * 0.55, 0.6, -2.0)
		root.add_child(tail)

	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var wheel := Node3D.new()
			wheel.name = "Wheel"
			wheel.position = Vector3(float(sx) * 0.92, 0.35, float(sz) * 1.3)
			root.add_child(wheel)
			var tyre := CylinderMesh.new()
			tyre.top_radius = 0.35
			tyre.bottom_radius = 0.35
			tyre.height = 0.28
			var tyre_node := MeshInstance3D.new()
			tyre_node.mesh = tyre
			tyre_node.material_override = _mat(Color(0.12, 0.12, 0.13))
			tyre_node.rotation_degrees = Vector3(0.0, 0.0, 90.0)  # axle along X
			wheel.add_child(tyre_node)
			# a light bar across the wheel so that the spinning can be seen
			wheel.add_child(_box(Vector3(0.32, 0.08, 0.5), Color(0.8, 0.8, 0.82)))
			_wheels.append({"node": wheel, "base": wheel.basis})
	return root


static func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _mat(color)
	return node


static func _mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	return mat
