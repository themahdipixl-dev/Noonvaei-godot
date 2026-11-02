class_name WorldConfig
extends RefCounted
## World layout + art + actor tuning. Port of src/world/worldConfig.js
## (WALKER and CARS are ported now but only used in Part 4.)

# ---------------------------------------------------------------- world

const GRID := 20
const TILE_W := 96.0
## tileH / tileW (must match the webp art)
const RATIO := 0.577
const PAD_X := 140.0
const PAD_TOP := 200.0
const PAD_BOTTOM := 100.0

const GROUND_COLOR := Color("#f3e6c8")
const WORLD_BG := Color("#ecdcb8")

const LOT_SIZE := 5
const LEVELS_PER_SEASON := 10

## The only shop: in the middle of the ground.
const CENTER_LOT := Vector2((GRID - LOT_SIZE) / 2.0, (GRID - LOT_SIZE) / 2.0)


## Size of the whole world canvas in px (JS: W and H in WorldMap.js).
static func content_size() -> Vector2:
	return Vector2(
		GRID * TILE_W + PAD_X * 2.0,
		GRID * TILE_W * RATIO + PAD_TOP + PAD_BOTTOM
	)


## Projector used by every world object (origin = top corner of the ground diamond).
static func make_projector() -> Iso:
	return Iso.new(TILE_W, Vector2(content_size().x / 2.0, PAD_TOP), RATIO)


# ---------------------------------------------------------------- art

const ART := {
	"bakery": {
		"floor_w": 0.84,
		"anchor": Vector2(0.507, 0.54),
	},
	"baker": {
		"scale": 0.28,                 # was 0.36 -> made smaller
		"feet": Vector2(0.51, 0.70),
		"at": Vector2(0.6, 0.68),
	},
}

# ---------------------------------------------------------------- walking baker (Part 4)

const WALKER := {
	"char_h": 56.0,
	"speed": 0.6,
	"stride": 0.06,
	"dir_scale": {"sw": 1.0, "se": 1.0, "ne": 1.0, "nw": 1.0},
	# idle view (baker_view1..4) while paused
	# height of the idle view relative to the walking character
	"idle_scale": {"sw": 1.0, "se": 1.0, "ne": 1.0, "nw": 1.0},
	# offset [x, y] in px
	"idle_offset": {"sw": Vector2(0, 0), "se": Vector2(0, 0), "ne": Vector2(0, 0), "nw": Vector2(0, 0)},
	"shadow": {
		"width": 0.62,
		"opacity": 0.38,
		"offset_x": 0.0,
		"offset_y": -1.0,
	},
	# true = draws red circles on the stop points
	"debug": false,
	# Points are in bakery_front.webp image coordinates (fraction of width/height, 0..1).
	# After the last point it loops back to the first.
	# wait: pause in seconds | face: look direction while paused (sw | se | ne | nw)
	"stops": [
		{"p": Vector2(0.586, 0.606), "wait": 4.0, "face": "ne"},  # next to the mesh table in front of the belt
		{"p": Vector2(0.476, 0.668), "wait": 4.0, "face": "nw"},  # next to the mesh table at the entrance
	],
}

# ---------------------------------------------------------------- cars (Part 4)

## Every car has an id equal to its image folder name and to the key in EnvironmentAssets.
## Units for `drive`: tiles and seconds.
const DEFAULT_CAR := {
	"width": 110.0,        # car width in px
	"anchor_y": 0.6,      # ground contact point: fraction of image height (top=0, bottom=1)
	"aspect": {"sw": 1.4085, "se": 1.4085, "ne": 1.504, "nw": 1.504},  # width / height of each image
	"scale": {"sw": 1.0, "se": 1.0, "ne": 1.0, "nw": 1.0},          # per-direction size tweak
	"offset": {"sw": Vector2(0, 0), "se": Vector2(0, 0), "ne": Vector2(0, 0), "nw": Vector2(0, 0)},  # px
	"start_at": 0.0,      # start at this fraction of the route (0..1)
	# grid coordinates; the last point joins the first automatically
	"route": [Vector2(4, 4), Vector2(15, 4), Vector2(15, 15), Vector2(4, 15)],

	# 90 degree turn with a spritesheet (20 frames, 18 degrees each)
	"turn": {
		"frames": 20, "cols": 5, "rows": 4,
		"width": 114.0,       # width of one frame in px (tune if the car size jumps when a turn starts)
		"aspect": 1.408,      # frame width / height (642/456)
		"anchor_y": 0.6,      # ground contact point
		"offset": Vector2(0, 0),
		"frame_offset": 0,    # use if frame 0 is not the 'se' direction
	},

	# driver
	"drive": {
		"cruise": 2.2,        # normal city speed
		"accel": 1.1,
		"brake": 1.4,         # normal (soft) braking
		"brake_max": 3.2,     # emergency braking
		"jerk": 2.4,          # lower = smoother acceleration changes
		"corner_speed": 1.2,
		"corner_radius": 1.5, # tiles
		"start_delay": 1.5,   # seconds standing still at the start
		"reaction": 1.2,      # driver pause after the light turns green
		"margin": 0.2,        # stop distance before the line
		"half_length": 0.85,  # half car length (to stop behind the line)
	},

	# Imaginary traffic lights: each time the car stops completely here, waits stop_for seconds and goes on.
	"lights": [
		{"at": Vector2(12, 4), "stop_for": 5.0},
		{"at": Vector2(15, 10), "stop_for": 5.0},
	],

	# length (tiles) = size of the 3D car on the ground; width / opacity / dx / dy are only used by the old 2D sprite shadow
	"shadow": {"length": 1.9, "width": 0.85, "opacity": 0.3, "dx": 3.0, "dy": 2.0},

	# Rims: x, y = center (fraction of image width/height), d = long diameter of the ellipse (fraction of image width)
	"wheel_circ": 0.735,  # distance (tiles) for one full wheel turn
	"rim_scale": 1.0,     # scale all rims
	"rim_k": 0.566,       # short / long diameter of the ellipse
	"rim_rot": {"sw": 28.0, "se": -28.0, "ne": 28.0, "nw": -28.0},  # ellipse tilt (degrees)
	"debug": false,       # true = red outline around every rim
	"rims": {
		"sw": [
			{"x": 0.4458, "y": 0.8897, "d": 0.1150},
			{"x": 0.8767, "y": 0.5399, "d": 0.1077},
		],
		"se": [
			{"x": 0.5542, "y": 0.8897, "d": 0.1150},
			{"x": 0.1233, "y": 0.5399, "d": 0.1077},
		],
		"ne": [
			{"x": 0.9017, "y": 0.4724, "d": 0.1068},
			{"x": 0.4633, "y": 0.8785, "d": 0.1171},
		],
		"nw": [
			{"x": 0.0983, "y": 0.4724, "d": 0.1068},
			{"x": 0.5367, "y": 0.8785, "d": 0.1171},
		],
	},
}


## JS: CARS = [{ ...DEFAULT_CAR, id: 'peugeot_pars' }]
static func cars() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var car: Dictionary = DEFAULT_CAR.duplicate(true)
	car["id"] = "peugeot_pars"
	# 3D model options (see scripts/world/car_model_3d.gd). The 4 wheels of peugeot_pars.glb are separate nodes
	# named part_0..part_3 (each has a child mesh convert_part_N): they roll with the distance driven and the
	# front pair steers in corners. The other nodes (part_4 .. part_11 ...) are the body and are not touched.
	car["model"] = {
		"wheel_names": ["part_0", "part_1", "part_2", "part_3"],
	}
	out.append(car)
	return out


# ---------------------------------------------------------------- seasons

## All seasons use the same middle shop.
const SEASONS := [
	{"id": 1, "title": "نان تازه", "sub": "سنگک", "lot": CENTER_LOT},
	{"id": 2, "title": "نان داغ", "sub": "بربری", "lot": CENTER_LOT},
	{"id": 3, "title": "نان لواش", "sub": "لواش", "lot": CENTER_LOT},
	{"id": 4, "title": "تافتون", "sub": "تافتون", "lot": CENTER_LOT},
]


static func season_label(id: int) -> String:
	return "فصل %s" % FaFormat.to_fa(id)


static func current_season_index(level: int) -> int:
	var i := floori(float(maxi(1, level) - 1) / float(LEVELS_PER_SEASON))
	return mini(i, SEASONS.size() - 1)
