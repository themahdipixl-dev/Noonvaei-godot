class_name CarModel3D
extends Node2D
## A real 3D car shown inside the 2D isometric world.
##
## How it works: the model lives in its own SubViewport (transparent background) with an orthographic
## camera at the isometric angle. The viewport texture is shown by a Sprite2D, so the rest of the game
## (Node2D layers, camera) does not change.
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
##       "sun": 1.1,              # main light strength
##       "ambient": 0.5,          # fill light strength
##       "shadow_opacity": 0.55,  # strength of the ground shadow (same default as the Front / ShopLighting)
##       "spin_wheels": true,     # wheels roll with the distance driven (default true)
##       "steer_wheels": true,    # front wheels turn in corners (default true)
##       "max_steer": 35.0,       # max steering angle in degrees
##       "wheel_names": [],       # optional: exact node names of the wheels in the .glb (see below)
##   }
## The car length on screen is taken from car["shadow"]["length"] (tiles).
##
## Model convention: the car must look towards +Z (glTF default). The model is automatically centred,
## put on the ground and scaled, so the original size / origin of the file does not matter.
##
## Wheels: the wheels of the .glb are separate nodes. They are found by name (wheel / tire / tyre / rim / hubcap),
## or - when the names say nothing - by shape (round, low, on the sides). Each wheel gets its own pivot at its
## own centre (so the pivot of the node inside the .glb does not matter): front wheels steer, all wheels roll.
## If no wheel is found, the node tree of the model is printed in the Output: put the wheel node names
## in "wheel_names".
##
## Shadow: no 2D drawn shadow any more. Like the Front (ShopLighting) the car is lit by a sun with a real
## soft (PCF) shadow, and a transparent "shadow catcher" ground shows only the shadow.

const VIEW_PX := 448
const ORTHO_SIZE := 7.0
## the car is normalised to this length (3D units)
const CAR_LENGTH := 4.0
## asin(1 / sqrt(3)): the camera pitch that matches the 0.577 (tileH / tileW) ground ratio of the world
const PITCH_DEG := 35.264
const EXTENSIONS: Array[String] = ["glb", "gltf"]

## true = the sun of the car has the same direction as the sun of the Front (ShopLighting.SUN_ROTATION),
## so the shadows of the car and of the shop fall to the same side.
const FRONT_SUN_DIRECTION := true
## the Front camera looks from azimuth 45 deg (30,30,30), this camera from azimuth 0 -> turn the sun by -45 deg
const CAM_YAW_FIX := -45.0
## size (3D units) of the transparent ground that catches the shadow
const GROUND_SIZE := 16.0
## the steering is measured over at least this much driven distance (tiles)
const STEER_MIN_STEP := 0.02
const FALLBACK_WHEELBASE := 2.4
## node names that contain these words are not wheels (steering wheel, wheel arch ...)
const BAD_WHEEL_WORDS: Array[String] = ["arch", "well", "house", "fender", "guard", "flap", "brake", "caliper", "steering"]

static var _shadows_ready := false
## "tire / tyre / rim / hubcap" as a separate word (so "trim" or "primary" are not wheels)
static var _re_word: RegEx = RegEx.create_from_string("(^|[^a-z])(tire|tyre|rim|hubcap)")
static var _re_camel: RegEx = RegEx.create_from_string("[a-z](Tire|Tyre|Rim|Hubcap)")

var _viewport: SubViewport
var _sprite: Sprite2D
var _pivot: Node3D
var _yaw := 0.0
var _yaw_offset := 0.0
var _has_yaw := false
var _from_file := false

var _units_per_tile := CAR_LENGTH / 1.9
## direction of the front / of the wheel axle in the model's own space (depends on yaw_offset)
var _fwd := Vector3.BACK
var _axle := Vector3.RIGHT
var _spin_enabled := true
var _steer_enabled := true
var _max_steer := deg_to_rad(35.0)
var _wheelbase := FALLBACK_WHEELBASE
var _steer := 0.0
var _has_prev := false
var _prev_heading := 0.0
var _prev_travel := 0.0
## [{ "steer": Node3D, "spin": Node3D, "front": bool, "radius": float }]
var _wheels: Array = []


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
	_units_per_tile = CAR_LENGTH / maxf(length_tiles, 0.1)
	_spin_enabled = bool(cfg.get("spin_wheels", true))
	_steer_enabled = bool(cfg.get("steer_wheels", true))
	_max_steer = deg_to_rad(float(cfg.get("max_steer", 35.0)))
	# front / axle of the model: pivot.rotation.y = heading + yaw_offset, so the model's own front is Z turned back by the offset
	var back_rot := Basis(Vector3.UP, -deg_to_rad(_yaw_offset))
	_fwd = back_rot * Vector3.BACK
	_axle = back_rot * Vector3.RIGHT

	# same soft shadow quality as the Front (done once)
	if not _shadows_ready:
		ShopLighting.configure_shadows()
		_shadows_ready = true

	# ---- viewport with its own 3D world
	_viewport = SubViewport.new()
	_viewport.name = "View3D"
	_viewport.size = Vector2i(VIEW_PX, VIEW_PX)
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	# 4x MSAA smooths the edges (stair-steps) of the model; the render is small so it is cheap
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.gui_disable_input = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = float(cfg.get("ambient", 0.5))

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = ORTHO_SIZE
	cam.near = 0.1
	# the car is ~30 units away; a short far plane keeps the shadow map tight (sharper shadow)
	cam.far = 45.0
	cam.environment = env
	var pitch := deg_to_rad(PITCH_DEG)
	cam.rotation_degrees = Vector3(-PITCH_DEG, 0.0, 0.0)
	cam.position = Vector3(0.0, sin(pitch) * 30.0, cos(pitch) * 30.0)
	_viewport.add_child(cam)

	_add_sun(cfg)
	_add_ground_shadow()

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
			print("CarModel3D[%s]: using model %s" % [car_id, path])
	if content == null:
		content = _build_placeholder()
		print("CarModel3D[%s]: no .glb found, showing the placeholder car (put %s.glb in res://assets/vehicles/%s/)" % [car_id, car_id, car_id])
	_pivot.add_child(content)
	_rig_wheels(content, cfg)

	# ---- show the viewport as a sprite whose centre = the ground point under the car
	_sprite = Sprite2D.new()
	_sprite.name = "Render"
	_sprite.texture = _viewport.get_texture()
	_sprite.centered = true
	# smooth scaling (never nearest), whatever the parent nodes use
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_sprite)

	# px per 3D unit on screen so that the car is `length_tiles` long on the iso ground
	var px_per_unit := tile_w / (sqrt(2.0) * _units_per_tile) * float(cfg.get("scale", 1.0))
	_sprite.scale = Vector2.ONE * (px_per_unit / (float(VIEW_PX) / ORTHO_SIZE))


## Sun with the same shadow style as the Front (ShopLighting.apply): soft PCF shadow, same bias / blur / opacity.
func _add_sun(cfg: Dictionary) -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = float(cfg.get("sun", 1.1))
	if FRONT_SUN_DIRECTION:
		sun.rotation_degrees = Vector3(ShopLighting.SUN_ROTATION.x, ShopLighting.SUN_ROTATION.y + CAM_YAW_FIX, 0.0)
	else:
		sun.basis = Basis.looking_at(Vector3(0.45, -0.8, -0.35).normalized(), Vector3.UP)
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 45.0
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 0.8
	sun.shadow_blur = 2.0
	sun.shadow_opacity = float(cfg.get("shadow_opacity", 0.55))
	_viewport.add_child(sun)


## Invisible ground that only shows the shadow (shadow_to_opacity: shadowed = dark, lit = transparent).
func _add_ground_shadow() -> void:
	var plane := MeshInstance3D.new()
	plane.name = "ShadowGround"
	var pm := PlaneMesh.new()
	pm.size = Vector2(GROUND_SIZE, GROUND_SIZE)
	plane.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 0.0, 0.0, 1.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shadow_to_opacity = true
	mat.roughness = 1.0
	mat.metallic_specular = 0.0
	plane.material_override = mat
	plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_viewport.add_child(plane)


## `grid_fwd` = driving direction in grid coordinates, `wheel_deg` = wheel angle in degrees (only used when
## `travel` is not given), `travel` = total distance driven in tiles (wheels roll / steer from it).
func update_pose(grid_fwd: Vector2, wheel_deg: float, travel: float = -1.0) -> void:
	if _pivot == null:
		return
	if grid_fwd.length_squared() > 0.000001:
		# grid (x, y) -> ground plane of the 3D view: X = (x - y), Z = (x + y)  (Z points to the camera)
		var heading := atan2(grid_fwd.x - grid_fwd.y, grid_fwd.x + grid_fwd.y)
		var target := heading + deg_to_rad(_yaw_offset)
		if _has_yaw:
			_yaw = lerp_angle(_yaw, target, 0.4)
		else:
			_yaw = target
			_has_yaw = true
		_pivot.rotation.y = _yaw
		_update_steer(heading, travel)
	_update_wheels(travel, wheel_deg)


## Steering angle from how fast the heading changes per distance driven (bicycle model).
func _update_steer(heading: float, travel: float) -> void:
	if not _steer_enabled or travel < 0.0:
		return
	if not _has_prev:
		_prev_heading = heading
		_prev_travel = travel
		_has_prev = true
		return
	var d_tiles := travel - _prev_travel
	if d_tiles < STEER_MIN_STEP:
		return  # standing still: keep the wheels as they are
	var dpsi := angle_difference(_prev_heading, heading)
	var kappa := dpsi / (d_tiles * _units_per_tile)  # curvature (1 / unit); > 0 = turning to the same side as +yaw
	var want := clampf(atan(_wheelbase * kappa), -_max_steer, _max_steer)
	_steer = lerpf(_steer, want, 0.3)
	_prev_heading = heading
	_prev_travel = travel


func _update_wheels(travel: float, wheel_deg: float) -> void:
	for w in _wheels:
		if _spin_enabled:
			var ang := deg_to_rad(wheel_deg)
			if travel >= 0.0:
				# rolling without slipping: angle = distance / radius
				ang = fmod(travel * _units_per_tile / maxf(float(w["radius"]), 0.05), TAU)
			(w["spin"] as Node3D).basis = Basis(_axle, ang)
		if _steer_enabled and bool(w["front"]):
			(w["steer"] as Node3D).basis = Basis(Vector3.UP, _steer)


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


# ------------------------------------------------------------------ wheels

## AABB of all meshes under `node`, in the local space of `space` (a node that is inside the tree).
func _aabb_of(node: Node, space: Node3D) -> AABB:
	var inv := space.global_transform.affine_inverse()
	var box := AABB()
	var has := false
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var mi := n as MeshInstance3D
			var b: AABB = (inv * mi.global_transform) * mi.mesh.get_aabb()
			if has:
				box = box.merge(b)
			else:
				box = b
				has = true
		for c in n.get_children():
			stack.append(c)
	return box


## size of a box across the axle (car width direction) / along the car
func _axle_extent(bb: AABB) -> float:
	return absf(_axle.x) * bb.size.x + absf(_axle.z) * bb.size.z


func _fwd_extent(bb: AABB) -> float:
	return absf(_fwd.x) * bb.size.x + absf(_fwd.z) * bb.size.z


static func _is_wheel_name(n: String) -> bool:
	var l := n.to_lower()
	for bad in BAD_WHEEL_WORDS:
		if l.contains(bad):
			return false
	if l.contains("wheel"):
		return true
	return _re_word.search(l) != null or _re_camel.search(n) != null


## Top-most nodes whose name says "wheel". A node that spans both sides of the car (a "Wheels" group) is opened up.
func _find_by_name(node: Node, holder: Node3D, car_axle_extent: float, out: Array) -> void:
	for c in node.get_children():
		if not (c is Node3D):
			continue
		var n3 := c as Node3D
		if _is_wheel_name(String(n3.name)):
			var bb := _aabb_of(n3, holder)
			if _axle_extent(bb) > car_axle_extent * 0.5 and n3.get_child_count() > 1:
				_find_by_name(n3, holder, car_axle_extent, out)
			elif bb.size.length_squared() > 0.0:
				out.append(n3)
		else:
			_find_by_name(n3, holder, car_axle_extent, out)


## When the names say nothing ("Object_12" ...): meshes that look like a wheel (round, low, on the sides).
func _find_by_shape(node: Node, holder: Node3D, car_box: AABB, out: Array) -> void:
	for c in node.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
			if _looks_like_wheel(_aabb_of(c, holder), car_box):
				out.append(c)
		_find_by_shape(c, holder, car_box, out)


func _looks_like_wheel(bb: AABB, car_box: AABB) -> bool:
	var car_len := _fwd_extent(car_box)
	var dia := bb.size.y
	if dia < car_len * 0.10 or dia > car_len * 0.30:
		return false
	if absf(dia - _fwd_extent(bb)) > dia * 0.25:
		return false  # not round
	if _axle_extent(bb) > dia * 0.8:
		return false  # too wide for a tyre
	if bb.position.y > car_box.position.y + car_box.size.y * 0.2:
		return false  # not at the bottom
	var side := absf((bb.get_center() - car_box.get_center()).dot(_axle))
	return side > _axle_extent(car_box) * 0.25


## Groups nodes that belong to the same wheel (tyre + rim + hubcap have almost the same centre).
func _cluster(nodes: Array, holder: Node3D) -> Array:
	var clusters: Array = []
	for n in nodes:
		var bb := _aabb_of(n, holder)
		var placed := false
		for cl in clusters:
			var d: float = (cl["center"] as Vector3).distance_to(bb.get_center())
			if d < 0.3 * maxf(float(cl["dia"]), bb.size.y):
				(cl["nodes"] as Array).append(n)
				if bb.size.y > float(cl["dia"]):
					cl["dia"] = bb.size.y
					cl["center"] = bb.get_center()
				placed = true
				break
		if not placed:
			clusters.append({"nodes": [n], "center": bb.get_center(), "dia": bb.size.y})
	return clusters


## Gives every wheel its own pivot at the wheel centre: holder -> WheelSteer (turns left / right) -> WheelSpin (rolls)
## -> the wheel node(s). The wheel keeps its exact place, whatever the pivot inside the .glb is.
func _rig_wheels(holder: Node3D, cfg: Dictionary) -> void:
	if not _spin_enabled and not _steer_enabled:
		return
	var car_box := _aabb_of(holder, holder)
	var found: Array = []
	var names: Array = cfg.get("wheel_names", [])
	if not names.is_empty():
		for wn in names:
			var f: Node = holder.find_child(String(wn), true, false)
			if f is Node3D:
				found.append(f)
			else:
				push_warning("CarModel3D: wheel node '%s' not found in the model" % String(wn))
	else:
		_find_by_name(holder, holder, _axle_extent(car_box), found)
	var clusters := _cluster(found, holder)
	if names.is_empty() and clusters.size() < 2:
		var by_shape: Array = []
		_find_by_shape(holder, holder, car_box, by_shape)
		var shape_clusters := _cluster(by_shape, holder)
		if shape_clusters.size() > clusters.size():
			clusters = shape_clusters
	if clusters.is_empty():
		var lines := PackedStringArray()
		_tree_lines(holder, 0, lines)
		push_warning("CarModel3D: no wheels found in the model (set \"wheel_names\" in the car's \"model\" config). Node tree:\n%s" % "\n".join(lines))
		return

	var k := holder.scale.x
	var car_center := car_box.get_center()
	var front_pos := 0.0
	var rear_pos := 0.0
	var front_n := 0
	var rear_n := 0
	var holder_inv := holder.global_transform.affine_inverse()
	for cl in clusters:
		var center: Vector3 = cl["center"]
		var steer := Node3D.new()
		steer.name = "WheelSteer"
		steer.position = center
		holder.add_child(steer)
		var spin := Node3D.new()
		spin.name = "WheelSpin"
		steer.add_child(spin)
		for n in (cl["nodes"] as Array):
			var wn3 := n as Node3D
			var rel: Transform3D = holder_inv * wn3.global_transform
			wn3.get_parent().remove_child(wn3)
			spin.add_child(wn3)
			wn3.transform = Transform3D(Basis.IDENTITY, -center) * rel
		var along := (center - car_center).dot(_fwd)
		var is_front := along > 0.0
		if is_front:
			front_pos += along
			front_n += 1
		else:
			rear_pos += along
			rear_n += 1
		_wheels.append({
			"steer": steer,
			"spin": spin,
			"front": is_front,
			"radius": float(cl["dia"]) * 0.5 * k,
		})
	if front_n > 0 and rear_n > 0:
		_wheelbase = (front_pos / float(front_n) - rear_pos / float(rear_n)) * k
	print("CarModel3D: %d wheels rigged (%d front), wheelbase %.2f" % [_wheels.size(), front_n, _wheelbase])


func _tree_lines(node: Node, depth: int, out: PackedStringArray) -> void:
	if out.size() > 80:
		return
	out.append("%s%s (%s)" % ["  ".repeat(depth), String(node.name), node.get_class()])
	for c in node.get_children():
		_tree_lines(c, depth + 1, out)


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
