class_name ShopLighting
extends RefCounted
## نور و محیط مغازه‌ی سه‌بعدی، مخصوص رندرر gl_compatibility.
##
## نسخه‌ی قبلی برای Forward+ نوشته شده بود و به این‌ها تکیه داشت که در Compatibility اصلاً کار نمی‌کنند:
##   - SSAO (سایه‌ی نرم گوشه‌ها و زیر اجسام)
##   - light_angular_distance (سایه‌ی PCSS)
## برای همین تصویر تخت و سوخته می‌شد. این‌جا فقط چیزهایی استفاده شده که در Compatibility پشتیبانی می‌شوند:
## نور محیطی + خورشید با سایه‌ی نرم (PCF) + نور پرکننده‌ی ضعیف.
##
## اصل این تنظیمات: رنگ شیء‌ها تغییر نکند و چیزی سوخته نشود.
##   - هر سه نور سفید خالص‌اند (نور رنگی، رنگ آلبیدو را به سمت خودش می‌برد).
##   - مجموع نور روی سطوح رو به بالا زیر 1.0 است (حدود 0.8 * LIGHT_SCALE)، پس حتی سفیدترین شیء
##     (دیوار، آلبیدو ~0.9) به 1.0 نمی‌رسد و clip نمی‌شود.
##
## اگر بعد از بیک هنوز روشن/تاریک بود، فقط LIGHT_SCALE را عوض کن (کش خودکار عوض می‌شود، signature() پایین):
##   کمتر از 1.0 = تیره‌تر ، بیشتر از 1.0 = روشن‌تر

## ضریب کلی روشنایی (روی خورشید، محیط و پرکننده با هم اعمال می‌شود).
## کم شد (از 1.0 به 0.6) چون رنگ شیء‌ها روشن‌تر از آلبیدوی واقعی‌شان دیده می‌شد.
const LIGHT_SCALE := 0.6

## مجموع روی سطح رو به بالا: 0.5 * 0.848 (sin 58) + 0.32 + 0.08 * 0.574 (sin 35) ~ 0.79 (قبل از LIGHT_SCALE)
const SUN_ENERGY := 0.5
const AMBIENT_ENERGY := 0.32
const FILL_ENERGY := 0.08

## همه سفید خالص: نور رنگ شیء‌ها را عوض نمی‌کند.
const SUN_COLOR := Color("ffffff")
const AMBIENT_COLOR := Color("ffffff")
const FILL_COLOR := Color("ffffff")

## جهت خورشید همان قبلی است تا جهت سایه‌ها با تصویر قبلی یکی بماند.
const SUN_ROTATION := Vector3(-58.0, 25.0, 0.0)
const FILL_ROTATION := Vector3(-35.0, 200.0, 0.0)

## Linear: بدون تغییر رنگ. (FILMIC میان‌تن‌ها و اشباع رنگ را عوض می‌کند، پس عمداً استفاده نشده.)
const TONEMAP := Environment.TONE_MAPPER_LINEAR
const EXPOSURE := 1.0


## امضای تنظیمات نور؛ در نام فایل کش می‌آید تا با عوض شدن هر عدد بالا، کش قدیمی خودکار کنار برود.
static func signature() -> String:
	var s := str([LIGHT_SCALE, SUN_ENERGY, AMBIENT_ENERGY, FILL_ENERGY, SUN_COLOR, AMBIENT_COLOR, FILL_COLOR, SUN_ROTATION, FILL_ROTATION, TONEMAP, EXPOSURE])
	return "%08x" % s.hash()


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
