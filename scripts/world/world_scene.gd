class_name WorldScene
extends Node2D
## The world content: ground + bakery (+ actors in Part 4). Port of src/world/WorldScene.js
##
## JS: ground = one SVG polygon; bakery = <Image> layers on top.
## Godot: ground = _draw() polygon; bakery = Bakery node (Sprite2D layers).
##
## Draw order (back to front) is the child order, like the JS file:
##   ground (_draw of this node) -> Bakery -> Actors (BakerWalker, CarDriver in Part 4)

var projector: Iso
var content_size := Vector2.ZERO
var bakery: Bakery
## Part 4 adds BakerWalker and CarDriver nodes here.
var actors: Node2D

var _ground := PackedVector2Array()


func setup(p_content_size: Vector2) -> void:
	content_size = p_content_size
	projector = WorldConfig.make_projector()

	var g := float(WorldConfig.GRID)
	_ground = projector.polygon([
		Vector2(0, 0), Vector2(g, 0), Vector2(g, g), Vector2(0, g),
	])

	bakery = Bakery.new()
	bakery.name = "Bakery"
	add_child(bakery)
	bakery.setup(projector, WorldConfig.TILE_W, WorldConfig.CENTER_LOT.x, WorldConfig.CENTER_LOT.y)

	actors = Node2D.new()
	actors.name = "Actors"
	add_child(actors)

	queue_redraw()


func _draw() -> void:
	if _ground.size() > 0:
		draw_colored_polygon(_ground, WorldConfig.GROUND_COLOR)
