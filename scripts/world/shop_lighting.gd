class_name ShopLighting
extends RefCounted
## نور و محیط مغازه‌ی سه‌بعدی، مخصوص رندرر gl_compatibility.
##
## نسخه‌ی قبلی برای Forward+ نوشته شده بود و به این‌ها تکیه داشت که در Compatibility اصلاً کار نمی‌کنند:
##   - SSAO (سایه‌ی نرم گوشه‌ها و زیر اجسام)
##   - light_angular_distance (سایه‌ی PCSS)
## برای همین تصویر تخت و سوخته می‌شد. این‌جا فقط چیزهایی استفاده شده که در Compatibility پشتیبانی می‌شوند:
## نور محیطی رنگی + خورشید با سایه‌ی نرم (PCF) + نور پرکننده‌ی ضعیف.
## عمق تصویر از کم بودن نور محیطی و سایه‌ی نرم خورشید می‌آید (ambient کمتر = سایه‌ها عمیق‌تر).
##
## اگر بعد از بیک کردن تصویر هنوز روشن/تاریک بود، فقط LIGHT_SCALE را عوض کن (و BAKE_VERSION را بالا ببر):
##   کمتر از 1.0 = تیره‌تر ، بیشتر از 1.0 = روشن‌تر

## ضریب کلی روشنایی (روی خورشید، محیط و پرکننده با هم اعمال می‌شود).
const LIGHT_SCALE := 1.0

## خورشید: قبلاً 0.8 بود و همراه نور محیطی 0.4 و پرکننده‌ی 0.15 مجموع روی سطوح رو به بالا بیشتر از 1.1 می‌شد
## (سفیدی‌ها clip می‌شدند). حالا مجموع حدود 1.0 است.
const SUN_ENERGY := 0.68
const AMBIENT_ENERGY := 0.36
const FILL_ENERGY := 0.12

## رنگ‌ها: خورشید کمی گرم‌تر، محیط و پرکننده کمی خنک (سایه‌ها خنک‌تر از نور دیده می‌شوند).
const SUN_COLOR := Color("fff3e2")
const AMBIENT_COLOR := Color("eef0f6")
const FILL_COLOR := Color("e6ecff")

## جهت خورشید همان قبلی است تا جهت سایه‌ها با تصویر قبلی یکی بماند.
const SUN_ROTATION := Vector3(-58.0, 25.0, 0.0)
const FILL_ROTATION := Vector3(-35.0, 200.0, 0.0)

## Linear: همان ریاضی قبلی. اگر بعد از تنظیم نور باز هم جاهایی سوخته بود می‌توانی FILMIC را امتحان کنی
## (در Compatibility پشتیبانی می‌شود ولی میان‌تن‌ها را عوض می‌کند و باید LIGHT_SCALE را دوباره تنظیم کنی).
const TONEMAP := Environment.TONE_MAPPER_LINEAR
const EXPOSURE := 1.0


## سایه‌ها: یک‌بار قبل از ساخت صحنه صدا بزن (برای یک بیک کافی است).
static func configure_shadows() -> void:
	RenderingServer.directional_shadow_atlas_set_size(4096, true)
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)


## محیط + خورشید + پرکننده + دوربین ارتوگرافیک ایزومتریک (30,30,30) را به world اضافه می‌کند.
## دوربین ساخته‌شده را برمی‌گرداند.
static func apply(world: Node3D, cam_size: float, target: Vector3, bg: Color) -> Camera3D:
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.background_color = bg
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = AMBIENT_COLOR
	env.ambient_light_energy = AMBIENT_ENERGY * LIGHT_SCALE
	env.tonemap_mode = TONEMAP
	env.tonemap_exposure = EXPOSURE
	# عمداً روشن نشده (در Compatibility اثری ندارند): ssao, ssil, ssr, sdfgi, volumetric_fog
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = SUN_ROTATION
	sun.light_color = SUN_COLOR
	sun.light_energy = SUN_ENERGY * LIGHT_SCALE
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 60.0
	# در Compatibility بایاس نرمال بزرگ‌تری لازم است تا روی سطوح نازک (کاشی، درز) لکه‌ی سایه نیفتد
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 0.8
	# سایه‌ی نرم با PCF (جایگزین PCSS که فقط در Forward+ است)
	sun.shadow_blur = 2.0
	sun.shadow_opacity = 0.55
	world.add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = FILL_ROTATION
	fill.light_color = FILL_COLOR
	fill.light_energy = FILL_ENERGY * LIGHT_SCALE
	fill.shadow_enabled = false
	world.add_child(fill)

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.size = cam_size
	cam.far = 120.0
	world.add_child(cam)
	cam.look_at_from_position(target + Vector3(30, 30, 30), target, Vector3.UP)
	cam.current = true
	return cam
