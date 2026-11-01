class_name DrawProxy
extends Node2D
## Tiny helper node: lets another script draw on a child node with draw_* calls.
## The owner sets `draw_cb` (a Callable taking one CanvasItem) and calls queue_redraw() when needed.
## Used by BakerWalker and CarDriver for ground shadows and the placeholder art.

var draw_cb: Callable


func _draw() -> void:
	if draw_cb.is_valid():
		draw_cb.call(self)
