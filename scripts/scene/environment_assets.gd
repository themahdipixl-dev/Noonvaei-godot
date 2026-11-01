class_name EnvironmentAssets
extends RefCounted
## Texture paths + loading helpers. Port of src/scene/environmentAssets.js
##
## The JS version downloaded WEBP images from the Assets repo at runtime (raw.githubusercontent).
## In Godot the images are bundled in the project. Copy the same folders from
## `themahdipixl-dev/Assets/assets/` into `res://assets/` (see assets/README.md):
##
##   assets/environment/              bakery_*.webp, baker_view*.webp
##   assets/characters/baker/         baker_walk_<dir>.webp
##   assets/vehicles/<id>/            <id>_<dir>.webp, <id>_rim.webp, <id>_spritesheet.webp
##
## If an image is missing, get_texture() returns null and the scene draws a placeholder.
## (The '?v=3' cache-busting query strings are not needed anymore.)

const ENV_DIR := "res://assets/environment/"
const BAKER_DIR := "res://assets/characters/baker/"
const VEHICLE_DIR := "res://assets/vehicles/"

## Directions of the baker / vehicle sprites.
const DIRS: Array[String] = ["sw", "se", "ne", "nw"]

## Walking baker sprite sheets (8 frames each, one sheet per direction).
## All 4 sheets share the same layout: 8 cells of cell_w x cell_h,
## feet point = (cell_w / 2, feet_y), character height inside a cell = ref_h.
const BAKER_WALK_SHEET := {
	"frames": 8,
	"cell_w": 196,
	"cell_h": 314,
	"feet_y": 296,
	"ref_h": 288,
}

const BAKERY_FRONT := ENV_DIR + "bakery_front.webp"
const BAKERY_BELT := ENV_DIR + "bakery_belt.webp"
const BAKERY_CUTTER := ENV_DIR + "bakery_cutter.webp"

## Baker camera views (standing still).
const BAKER_VIEWS: Array[String] = [
	ENV_DIR + "baker_view1.webp",
	ENV_DIR + "baker_view2.webp",
	ENV_DIR + "baker_view3.webp",
	ENV_DIR + "baker_view4.webp",
]

## Lavash bread stages (1 -> 5).
const LAVASH: Array[String] = [
	ENV_DIR + "bakery_bread_1.webp",
	ENV_DIR + "bakery_bread_2.webp",
	ENV_DIR + "bakery_bread_3.webp",
	ENV_DIR + "bakery_bread_4.webp",
	ENV_DIR + "bakery_bread_5.webp",
]

## Vehicle ids = folder names (next car: "samand").
const VEHICLE_IDS: Array[String] = ["peugeot_pars"]


static func baker_walk_path(dir: String) -> String:
	return BAKER_DIR + "baker_walk_%s.webp" % dir


## assets/vehicles/<id>/<id>_<dir>.webp  (dir = sw | se | ne | nw)
static func vehicle_path(id: String, dir: String) -> String:
	return "%s%s/%s_%s.webp" % [VEHICLE_DIR, id, id, dir]


## Rim image (square, transparent corners).
static func vehicle_rim_path(id: String) -> String:
	return "%s%s/%s_rim.webp" % [VEHICLE_DIR, id, id]


## 90 degree turn spritesheet (20 frames, 5 cols x 4 rows).
static func vehicle_turn_path(id: String) -> String:
	return "%s%s/%s_spritesheet.webp" % [VEHICLE_DIR, id, id]


## Returns the texture or null when the file is not in the project (yet).
static func get_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static func all_paths() -> Array[String]:
	var out: Array[String] = [BAKERY_FRONT, BAKERY_BELT, BAKERY_CUTTER]
	out.append_array(BAKER_VIEWS)
	out.append_array(LAVASH)
	for d in DIRS:
		out.append(baker_walk_path(d))
	for id in VEHICLE_IDS:
		for d in DIRS:
			out.append(vehicle_path(id, d))
		out.append(vehicle_rim_path(id))
		out.append(vehicle_turn_path(id))
	return out


## Preload everything in background threads so images don't pop in during gameplay
## (replacement for Image.prefetch).
static func preload_all() -> void:
	for p in all_paths():
		if ResourceLoader.exists(p):
			ResourceLoader.load_threaded_request(p)
