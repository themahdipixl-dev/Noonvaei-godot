class_name WorldMap
extends Control
## Full-screen pannable / zoomable world. Port of src/world/WorldMap.js
## (Zoom / recenter buttons don't exist: zoom is by pinch gesture only; mouse wheel added for desktop.)
##
## JS                                        Godot
##   <GestureDetector> + Animated.View   ->   _gui_input() + WorldCamera + _content (Node2D)
##   <WorldScene/>                       ->   WorldScene node inside _content
##   onLayout                            ->   `resized` signal
##   preloadEnvironment()                ->   EnvironmentAssets.preload_all()
##
## Input: _gui_input only receives touches that STARTED on this control, so a finger that
## starts on a HUD button never pans the map (like box-none in the RN HUD).

var world_scene: WorldScene
var camera: WorldCamera

var _content: Node2D
var _season_idx := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.color = WorldConfig.WORLD_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var content_size := WorldConfig.content_size()

	_content = Node2D.new()
	_content.name = "Content"
	add_child(_content)

	world_scene = WorldScene.new()
	world_scene.name = "WorldScene"
	_content.add_child(world_scene)
	world_scene.setup(content_size)

	camera = WorldCamera.new(content_size, 1.0)
	camera.focus = _compute_focus()

	# Start loading the art right away so it doesn't pop in.
	EnvironmentAssets.preload_all()

	resized.connect(_on_resized)
	_on_resized()
	call_deferred("_on_resized")


## JS: the `level` prop. Only the season matters. Like the JS version the focus is used at first layout only.
func set_level(level: int) -> void:
	_season_idx = WorldConfig.current_season_index(level)
	if camera != null:
		camera.focus = _compute_focus()


## Camera focus = current season bakery (offset from content center).
func _compute_focus() -> Vector2:
	var lot: Vector2 = WorldConfig.SEASONS[_season_idx]["lot"]
	var half := float(WorldConfig.LOT_SIZE) / 2.0
	var p := world_scene.projector.project(lot.x + half, lot.y + half, 40.0)
	return p - WorldConfig.content_size() / 2.0


func _on_resized() -> void:
	camera.set_view_size(size)
	camera.apply(_content)


func _gui_input(event: InputEvent) -> void:
	if camera.handle_input(event):
		camera.apply(_content)
		accept_event()
