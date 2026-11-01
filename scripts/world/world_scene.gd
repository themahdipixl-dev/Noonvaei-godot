class_name WorldScene
extends Node2D
## The world content: ground + bakery + actors. Port of src/world/WorldScene.js
##
## JS: ground = one SVG polygon; bakery = <Image> layers on top; then BakerWalker and the CarDrivers.
## Godot: ground = _draw() polygon; bakery = Bakery node (Sprite2D layers); actors = BakerWalker + CarDriver nodes.
##
## Draw order (back to front) is the child order, like the JS file:
##   ground (_draw of this node) -> Bakery -> Actors (BakerWalker, then the cars)

var projector: Iso
var content_size := Vector2.ZERO
var bakery: Bakery
var actors: Node2D
var baker: BakerWalker
var cars: Array[CarDriver] = []

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

	baker = BakerWalker.new()
	baker.name = "BakerWalker"
	actors.add_child(baker)
	baker.setup(projector, bakery)

	for car in WorldConfig.cars():
		var driver := CarDriver.new()
		driver.name = "Car_%s" % String(car["id"])
		actors.add_child(driver)
		driver.setup(car, projector)
		cars.append(driver)

	queue_redraw()


func _draw() -> void:
	if _ground.size() > 0:
		draw_colored_polygon(_ground, WorldConfig.GROUND_COLOR)
