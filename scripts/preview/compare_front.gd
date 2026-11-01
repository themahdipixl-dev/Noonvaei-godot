extends Control
## مقایسه‌ی نور و سایه‌ی مغازه روی رندرر Compatibility (بدون AO تقلبی).
##
## بالا/چپ  = «قبلی»: دقیقاً همان تنظیمات نور اصلی (SSAO و PCSS روشن‌اند ولی Compatibility نادیده‌شان می‌گیرد).
## پایین/راست = «COMPAT BEST»: بهترین چیزی که در Compatibility هست:
##   - نور محیط از Sky (آسمان روشن + زمین تیره) به جای یک رنگ ثابت  -> سطح‌های رو به پایین / زیر اجسام طبیعی تیره‌تر می‌شوند
##   - بازه‌ی سایه‌ی تنگ (near/far دوربین + max_distance کم) -> وضوح سایه تقریباً دو برابر
##   - خورشید گرم + fill سرد، سایه‌ی پررنگ‌تر، bias و blur تنظیم‌شده
##
## اجرا: این صحنه را باز کن و F6 بزن (Run Current Scene). یک انگشت = جابه‌جایی، دو انگشت یا دکمه‌ها = زوم.
## دکمه‌های پایین کیفیت سایه را برای هر دو تصویر عوض می‌کنند (این تنظیمات سراسری‌اند).

const REF_SIZE := 13.0
const TARGET := Vector3(-3.0, 1.2, -2.0)
const STEEL := ShopFront3D.STEEL
const DSTEEL := ShopFront3D.DSTEEL
const WALL := ShopFront3D.WALL
const BREAD := ShopFront3D.BREAD

var _cams: Array[Camera3D] = []
var _panels: Array[Control] = []
var _split: BoxContainer
var _info: Label
var _atlas := 4096
var _quality := RenderingServer.SHADOW_QUALITY_SOFT_HIGH
var _touches: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	RenderingServer.directional_shadow_atlas_set_size(_atlas, true)
	RenderingServer.directional_soft_shadow_filter_set_quality(_quality)

	var bg := ColorRect.new()
	bg.color = Color("202020")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 6)
	margin.add_child(main)

	_split = BoxContainer.new()
	_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_split.add_theme_constant_override("separation", 6)
	main.add_child(_split)

	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 20)
	_info.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	main.add_child(_info)

	main.add_child(_row([
		_btn("Zoom +", _zoom.bind(1.25)),
		_btn("Zoom -", _zoom.bind(0.8)),
		_btn("Reset", _reset_view),
	]))
	main.add_child(_row([
		_btn("Atlas 2048", _set_atlas.bind(2048)),
		_btn("4096", _set_atlas.bind(4096)),
		_btn("8192", _set_atlas.bind(8192)),
	]))
	main.add_child(_row([
		_btn("Hard", _set_quality.bind(RenderingServer.SHADOW_QUALITY_HARD)),
		_btn("Low", _set_quality.bind(RenderingServer.SHADOW_QUALITY_SOFT_LOW)),
		_btn("Med", _set_quality.bind(RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM)),
		_btn("High", _set_quality.bind(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)),
		_btn("Ultra", _set_quality.bind(RenderingServer.SHADOW_QUALITY_SOFT_ULTRA)),
	]))

	_make_panel("BEFORE (original lighting)", false)
	_make_panel("COMPAT BEST", true)

	resized.connect(_update_layout)
	_update_layout()
	_update_info()


func _update_layout() -> void:
	# عمودی (پرتره): دو تصویر زیر هم؛ افقی: کنار هم
	_split.vertical = size.y >= size.x


func _update_info() -> void:
	_info.text = "renderer: %s | shadow atlas: %d | filter: %d (0 hard .. 5 ultra)" % [
		RenderingServer.get_current_rendering_method(), _atlas, int(_quality)]


func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 70)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	return b


func _row(buttons: Array) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 6)
	for b in buttons:
		r.add_child(b)
	return r


func _set_atlas(n: int) -> void:
	_atlas = n
	RenderingServer.directional_shadow_atlas_set_size(n, true)
	_update_info()


func _set_quality(q: int) -> void:
	_quality = q as RenderingServer.ShadowQuality
	RenderingServer.directional_soft_shadow_filter_set_quality(_quality)
	_update_info()


func _zoom(f: float) -> void:
	for cam in _cams:
		cam.size = clampf(cam.size / f, 3.0, 25.0)


func _reset_view() -> void:
	for cam in _cams:
		cam.size = REF_SIZE
		cam.look_at_from_position(TARGET + Vector3(30, 30, 30), TARGET, Vector3.UP)


# ============================================================
# ساخت یک پنل (SubViewport با دنیای سه‌بعدی جدا)
# ============================================================

func _make_panel(title: String, best: bool) -> void:
	var holder := Control.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.clip_contents = true
	_split.add_child(holder)  # اول داخل درخت، چون look_at_from_position به درخت نیاز دارد
	_panels.append(holder)

	var cont := SubViewportContainer.new()
	cont.stretch = true
	cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(cont)

	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	cont.add_child(vp)

	var world := Node3D.new()
	vp.add_child(world)

	var shop := ShopFront3D.new()
	shop.world = world
	add_child(shop)
	_build_partial(shop)
	shop._flush_batches()

	_cams.append(_setup_light(world, best))

	var lab := Label.new()
	lab.text = title
	lab.add_theme_font_size_override("font_size", 26)
	lab.add_theme_color_override("font_color", Color.WHITE)
	lab.add_theme_color_override("font_outline_color", Color.BLACK)
	lab.add_theme_constant_override("outline_size", 8)
	lab.position = Vector2(12, 8)
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(lab)


# ============================================================
# نور و دوربین
# ============================================================

func _setup_light(world: Node3D, best: bool) -> Camera3D:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("e8d9b5")
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0

	if best:
		# نور محیط از آسمان: بالا روشن و سرد، پایین (زمین) تیره و گرم.
		# سطح‌های رو به پایین و کنار اجسام نزدیک زمین کمی تیره‌تر می‌شوند؛ بدون هیچ ترفند تقلبی.
		var sky_mat := ProceduralSkyMaterial.new()
		sky_mat.sky_top_color = Color(0.80, 0.86, 1.0)
		sky_mat.sky_horizon_color = Color(0.86, 0.85, 0.82)
		sky_mat.ground_horizon_color = Color(0.55, 0.52, 0.48)
		sky_mat.ground_bottom_color = Color(0.22, 0.20, 0.18)
		var sky := Sky.new()
		sky.sky_material = sky_mat
		env.sky = sky
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_energy = 0.5
	else:
		# دقیقاً همان تنظیمات اصلی (SSAO در Compatibility نادیده گرفته می‌شود)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color("f5f7ff")
		env.ambient_light_energy = 0.4
		env.ssao_enabled = true
		env.ssao_radius = 1.2
		env.ssao_intensity = 1.5

	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, 25, 0)
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	if best:
		sun.light_color = Color("fff3e0")  # خورشید گرم
		sun.light_energy = 0.85
		sun.directional_shadow_max_distance = 72.0
		sun.shadow_bias = 0.02
		sun.shadow_normal_bias = 0.6
		sun.shadow_blur = 1.5
		sun.shadow_opacity = 0.85
	else:
		sun.light_color = Color("fffaf2")
		sun.light_energy = 0.8
		sun.light_angular_distance = 2.0
		sun.directional_shadow_max_distance = 80.0
		sun.shadow_bias = 0.03
		sun.shadow_normal_bias = 0.3
		sun.shadow_blur = 8.0
		sun.shadow_opacity = 0.6
	world.add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-35, 200, 0)
	fill.light_color = Color("e6ecff")  # سرد، مخالف خورشید گرم
	fill.light_energy = 0.25 if best else 0.15
	fill.shadow_enabled = false
	world.add_child(fill)

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.size = REF_SIZE
	if best:
		# مغازه فقط حدود ۴۱ تا ۶۲ واحد از دوربین فاصله دارد؛ بازه‌ی سایه را همان‌جا نگه می‌داریم
		# تا اتلس سایه روی ۰ تا ۴۰ خالی هدر نرود.
		cam.near = 32.0
		cam.far = 80.0
	else:
		cam.far = 120.0
	world.add_child(cam)
	cam.look_at_from_position(TARGET + Vector3(30, 30, 30), TARGET, Vector3.UP)
	cam.current = true
	return cam


# ============================================================
# بخشی از مغازه: کف، دیوارها، خط تنور، میز توری (همان کد اصلی)
# ============================================================

func _build_partial(s: ShopFront3D) -> void:
	s.fancy = true
	s.off = Vector3.ZERO
	var rng := RandomNumberGenerator.new()
	rng.seed = 7

	# کف موزاییک ترازو
	s.box(Vector3(0, -0.25, 0), Vector3(12, 0.5, 12), Color("c5c5c5ff"))
	for i in range(12):
		for j in range(12):
			s.terrazzo_tile(-5.5 + i, -5.5 + j, rng)

	# دیوارها + سرامیک
	s.box(Vector3(-6.15, 1.35, -0.15), Vector3(0.3, 3.7, 12.3), WALL)
	s.ceramic_x(-6.0, -5.85, 5.85, 0.05, 3.05)
	s.box(Vector3(-1.65, 0.35, -6.15), Vector3(9.3, 1.7, 0.3), WALL)
	s.box(Vector3(5.9, 0.35, -6.15), Vector3(0.8, 1.7, 0.3), WALL)
	s.ceramic_z(-6.0, -5.95, 2.85, 0.05, 1.05)
	s.ceramic_z(-6.0, 5.65, 5.85, 0.05, 1.05)

	# ---- بخش دستگاه‌ها ----
	s.off = Vector3(-2.45, 0, -1.5)

	# مخزن خمیر
	for lx in [-3.0, -2.0]:
		for lz in [-3.8, -2.8]:
			s.box(Vector3(lx, 1.0, lz), Vector3(0.12, 2.0, 0.12), DSTEEL)
	s.cyl(Vector3(-2.5, 1.35, -3.3), 0.75, 0.2, 0.7, Color("aab4bd"))
	s.cyl(Vector3(-2.5, 2.35, -3.3), 0.75, 0.75, 1.3, Color("b9c3cc"))
	s.cyl(Vector3(-2.5, 3.05, -3.3), 0.82, 0.82, 0.12, Color("d3dae0"))
	s.cyl(Vector3(-2.5, 3.08, -3.3), 0.7, 0.7, 0.1, BREAD)
	s.cyl(Vector3(-2.5, 3.2, -3.3), 0.35, 0.6, 0.2, BREAD)
	s.cyl(Vector3(-2.5, 0.95, -3.3), 0.2, 0.2, 0.3, Color("8a97a3"))
	s.box(Vector3(-2.5, 0.95, -2.0), Vector3(0.45, 0.3, 3.0), Color("8a97a3"))
	for lz in [-2.6, -1.4]:
		s.box(Vector3(-2.5, 0.4, lz), Vector3(0.12, 0.8, 0.12), DSTEEL)

	# واحد غلتک
	s.box(Vector3(-2.5, 1.2, -0.8), Vector3(0.9, 0.7, 0.6), Color("4a5560"))
	s.cyl(Vector3(-2.5, 1.62, -0.8), 0.12, 0.12, 0.8, Color("8a97a3"), Vector3(0, 0, 90))
	s.glow(Vector3(-2.04, 1.3, -0.8), Vector3(0.04, 0.12, 0.12), Color("4cd964"))

	# تنور صنعتی
	s.box(Vector3(-1.5, 0.15, 0.5), Vector3(4.1, 0.3, 2.1), Color("4a5560"))
	s.box(Vector3(-1.5, 1.15, 0.5), Vector3(4.0, 1.7, 2.0), STEEL)
	s.box(Vector3(-1.5, 2.05, 0.5), Vector3(4.1, 0.1, 2.1), Color("c9d2da"))
	s.box(Vector3(0.49, 0.62, 0.5), Vector3(0.06, 0.34, 1.3), Color("1f2326"))
	var fc := Color("d3dae0")
	s.box(Vector3(0.52, 0.82, 0.5), Vector3(0.06, 0.06, 1.42), fc)
	s.box(Vector3(0.52, 0.42, 0.5), Vector3(0.06, 0.06, 1.42), fc)
	s.box(Vector3(0.52, 0.62, -0.19), Vector3(0.06, 0.46, 0.06), fc)
	s.box(Vector3(0.52, 0.62, 1.19), Vector3(0.06, 0.46, 0.06), fc)

	# دکمه‌ی اضطراری و چراغ‌ها
	s.box(Vector3(0.0, 0.68, 1.53), Vector3(0.34, 0.34, 0.04), Color("e0b43c"))
	s.cyl(Vector3(0.0, 0.68, 1.57), 0.13, 0.13, 0.03, Color("1f2326"), Vector3(90, 0, 0))
	s.cyl(Vector3(0.0, 0.68, 1.62), 0.09, 0.09, 0.08, Color("d62d20"), Vector3(90, 0, 0))
	s.glow(Vector3(-0.52, 0.68, 1.54), Vector3(0.12, 0.12, 0.04), Color("4cd964"))
	s.glow(Vector3(-0.34, 0.68, 1.54), Vector3(0.12, 0.12, 0.04), Color("ff3b30"))

	# دودکش و لوله‌ها
	s.cyl(Vector3(-2.4, 2.35, -0.1), 0.28, 0.28, 0.04, DSTEEL)
	s.cyl(Vector3(-2.4, 2.85, -0.1), 0.28, 0.28, 0.04, DSTEEL)
	s.cyl(Vector3(-2.4, 3.33, -0.1), 0.04, 0.32, 0.16, Color("5f6b76"))
	s.cyl(Vector3(-2.4, 2.65, -0.1), 0.25, 0.25, 1.0, DSTEEL)
	s.cyl(Vector3(-2.4, 3.2, -0.1), 0.35, 0.35, 0.1, Color("5f6b76"))
	s.cyl(Vector3(-0.7, 2.13, 0.0), 0.19, 0.19, 0.04, DSTEEL)
	s.cyl(Vector3(-0.7, 2.5, 0.0), 0.19, 0.19, 0.04, DSTEEL)
	s.cyl(Vector3(-0.7, 2.57, 0.0), 0.17, 0.17, 0.04, Color("5f6b76"))
	s.cyl(Vector3(-0.7, 2.3, 0.0), 0.15, 0.15, 0.5, DSTEEL)

	# تابلو کنترل
	s.box(Vector3(-0.3, 1.4, 1.51), Vector3(1.1, 1.0, 0.06), Color("778a9cff"))
	s.glow(Vector3(-0.3, 1.7, 1.56), Vector3(0.6, 0.16, 0.04), Color("7dffb0"))
	s.box(Vector3(-0.3, 1.05, 1.56), Vector3(0.7, 0.1, 0.04), Color("5f6b76"))
	for i in range(4):
		s.box(Vector3(-1.2, 0.55 + i * 0.12, 1.51), Vector3(0.9, 0.05, 0.05), Color("5f6b76"))

	# برش‌زن و تسمه‌ی توری
	s.box(Vector3(1.8, 0.75, -0.35), Vector3(0.14, 1.5, 0.14), DSTEEL)
	s.box(Vector3(2.0, 0.6, 0.5), Vector3(4.0, 0.08, 1.2), Color("46515b"))
	s.box(Vector3(2.3, 0.62, -0.2), Vector3(3.6, 0.1, 0.08), STEEL)
	s.box(Vector3(2.3, 0.62, 1.2), Vector3(3.6, 0.1, 0.08), STEEL)
	for lx in [0.9, 3.7]:
		for lz in [-0.15, 1.15]:
			s.box(Vector3(lx, 0.25, lz), Vector3(0.1, 0.5, 0.1), DSTEEL)
	s.cyl(Vector3(4.0, 0.57, 0.5), 0.12, 0.12, 1.5, DSTEEL, Vector3(90, 0, 0))

	s.off = Vector3.ZERO

	# میز توری کوتاه
	s.mesh_table(2.9, -1.0, 2.4, 1.5, 0.45)


# ============================================================
# ورودی: یک انگشت = جابه‌جایی، دو انگشت = زوم (هر دو دوربین با هم)
# ============================================================

func _input(event: InputEvent) -> void:
	if _cams.is_empty():
		return
	if event is InputEventScreenTouch:
		var te := event as InputEventScreenTouch
		if te.pressed and _split.get_global_rect().has_point(te.position):
			_touches[te.index] = te.position
		else:
			_touches.erase(te.index)
	elif event is InputEventScreenDrag:
		var de := event as InputEventScreenDrag
		if not _touches.has(de.index):
			return
		var old_d := 0.0
		if _touches.size() == 2:
			var ks: Array = _touches.keys()
			old_d = (_touches[ks[0]] as Vector2).distance_to(_touches[ks[1]] as Vector2)
		_touches[de.index] = de.position
		if _touches.size() == 2:
			var ks2: Array = _touches.keys()
			var new_d := (_touches[ks2[0]] as Vector2).distance_to(_touches[ks2[1]] as Vector2)
			if old_d > 1.0:
				_zoom(new_d / old_d)
		elif _touches.size() == 1:
			_pan(de.relative)
	elif event is InputEventMouseButton:
		var me := event as InputEventMouseButton
		if me.pressed and _split.get_global_rect().has_point(me.position):
			if me.button_index == MOUSE_BUTTON_WHEEL_UP:
				_zoom(1.1)
			elif me.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_zoom(1.0 / 1.1)


func _pan(rel: Vector2) -> void:
	var w: float = maxf(1.0, _panels[0].size.x)
	var k: float = _cams[0].size / w
	for cam in _cams:
		var b: Basis = cam.global_transform.basis
		cam.global_position += (-b.x * rel.x + b.y * rel.y) * k
