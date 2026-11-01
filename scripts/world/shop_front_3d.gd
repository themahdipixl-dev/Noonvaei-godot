class_name ShopFront3D
extends Node
## مغازه‌ی سه‌بعدی (Front) برای داخل بازی.
##
## محیط با کد ساخته می‌شود (Node3D + مش‌ها)، از زاویه‌ی ایزومتریک در یک SubViewport
## یک‌بار رندر می‌شود و نتیجه به صورت تکسچر به Bakery داده می‌شود (جای bakery_front.webp).
## دوربین / اندازه دقیقاً همان قبلی است؛ پس جایگاه مغازه روی نقشه، نقطه‌های توقف شاطر و ... بدون تغییر می‌ماند.
##
## چرا یک‌بار رندر؟ مغازه ثابت است و حدود ۱۰ هزار مش دارد؛ رندر زنده‌ی همه‌ی این‌ها در هر فریم روی گوشی
## سنگین است. نتیجه در user:// کش می‌شود؛ اجرای بعدی خیلی سریع است.
## اگر کد محیط را عوض کردی، BAKE_VERSION را یکی بالا ببر تا کش قدیمی کنار برود.
##
## نکته: SSAO فقط در Forward+ کار می‌کند؛ در gl_compatibility (رندرر فعلی پروژه) نادیده گرفته می‌شود.

## با false کردن، Bakery دوباره مثل قبل فقط از bakery_front.webp (یا placeholder) استفاده می‌کند.
const ENABLED := true

## بالا ببرید وقتی کد محیط عوض شد تا تصویر کش‌شده‌ی قبلی استفاده نشود.
const BAKE_VERSION := 1

## اندازه‌ی تصویر (مربع). همان محدوده‌ی ۲۰۴۸×۲۰۴۸ مرجع Bakery را پوشش می‌دهد.
const IMAGE_SIZE := 2048

## عرض دید دوربین ارتوگرافیک (واحد دنیای سه‌بعدی). همان مقدار قبلی.
const CAM_SIZE := 20.5

const STEEL := Color("aab4bd")
const DSTEEL := Color("7d8a96")
const WOOD := Color("a0724a")
const WALL := Color("f4f7f9")
const BREAD := Color("efe2b8")
const GROUT := Color("8f969b")
const TILE := Color("eef1f3")

## وقتی رندر تمام شد، تکسچر نهایی را می‌دهد (همان لحظه هم نود خودش را پاک می‌کند).
signal baked(texture: Texture2D)

var world: Node3D
var off := Vector3.ZERO
var fancy := false
var rbox_cache: Dictionary = {}
var rcyl_cache: Dictionary = {}

var _vp: SubViewport


static func cache_path() -> String:
	return "user://shop_front_v%d_%d.png" % [BAKE_VERSION, IMAGE_SIZE]


## شروع: اگر کش باشد مستقیم می‌دهد، وگرنه محیط را می‌سازد و رندر می‌گیرد.
## باید بعد از add_child صدا زده شود (نیاز به get_tree دارد).
func start() -> void:
	var cached := _load_cache()
	if cached != null:
		baked.emit(cached)
		queue_free()
		return
	_bake()


func _load_cache() -> Texture2D:
	var p := cache_path()
	if not FileAccess.file_exists(p):
		return null
	var img := Image.load_from_file(p)
	if img == null or img.is_empty():
		return null
	return _to_texture(img)


func _to_texture(img: Image) -> Texture2D:
	img.convert(Image.FORMAT_RGBA8)
	img.generate_mipmaps()  # برای زوم کم بدون دنده‌دنده شدن
	return ImageTexture.create_from_image(img)


func _bake() -> void:
	# یک فریم صبر می‌کنیم تا بازی نشان داده شود، بعد ساخت سنگین محیط
	await get_tree().process_frame

	# اتلس سایه (۴۰۹۶ به جای ۸۱۹۲ تا روی گوشی حافظه کم نیاید)
	RenderingServer.directional_shadow_atlas_set_size(4096, true)
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)

	_vp = SubViewport.new()
	_vp.size = Vector2i(IMAGE_SIZE, IMAGE_SIZE)
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_vp)

	world = Node3D.new()
	_vp.add_child(world)
	_build_front()

	# رندر در انتهای همین فریم انجام می‌شود؛ دو فریم صبر برای اطمینان
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw

	var img := _vp.get_texture().get_image()
	if img == null or img.is_empty():
		push_warning("ShopFront3D: render failed, keeping placeholder")
		queue_free()
		return
	img.convert(Image.FORMAT_RGBA8)

	var err := img.save_png(cache_path())
	if err != OK:
		push_warning("ShopFront3D: could not save cache (err %d)" % err)

	baked.emit(_to_texture(img))
	queue_free()


# ============================================================
# ابزارهای ساخت مش
# ============================================================

# جعبه با گوشه‌ی گرد (کش می‌شود تا مش تکراری ساخته نشود)
func rounded_mesh(size: Vector3, r: float) -> ArrayMesh:
	var key: String = str(size) + "_" + str(r)
	if rbox_cache.has(key):
		return rbox_cache[key]
	var h: Vector3 = size / 2.0
	var inner: Vector3 = h - Vector3(r, r, r)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for a in range(3):
		var u: int = (a + 1) % 3
		var v: int = (a + 2) % 3
		for s in [-1.0, 1.0]:
			var cu: Array = [-h[u], -h[u] + r * 0.3, -h[u] + r * 0.7, -h[u] + r, h[u] - r, h[u] - r * 0.7, h[u] - r * 0.3, h[u]]
			var cv: Array = [-h[v], -h[v] + r * 0.3, -h[v] + r * 0.7, -h[v] + r, h[v] - r, h[v] - r * 0.7, h[v] - r * 0.3, h[v]]
			var pts: Array = []
			var nrm: Array = []
			for i in range(8):
				for j in range(8):
					var p := Vector3.ZERO
					p[a] = s * h[a]
					p[u] = cu[i]
					p[v] = cv[j]
					var q: Vector3 = p.clamp(-inner, inner)
					var n: Vector3 = (p - q).normalized()
					pts.append(q + n * r)
					nrm.append(n)
			for i in range(7):
				for j in range(7):
					var ia: int = i * 8 + j
					var ib: int = (i + 1) * 8 + j
					var ic: int = i * 8 + j + 1
					var id: int = (i + 1) * 8 + j + 1
					var order: Array
					if s > 0.0:
						order = [ia, id, ib, ia, ic, id]
					else:
						order = [ia, ib, id, ia, id, ic]
					for k in order:
						st.set_normal(nrm[k])
						st.add_vertex(pts[k])
	var mesh: ArrayMesh = st.commit()
	rbox_cache[key] = mesh
	return mesh


func box(pos: Vector3, size: Vector3, col: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mind: float = minf(size.x, minf(size.y, size.z))
	if fancy and mind >= 0.03:
		m.mesh = rounded_mesh(size, minf(0.12, mind * 0.45))
	else:
		var b := BoxMesh.new()
		b.size = size
		m.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 1.0 if fancy else 0.8
	if fancy:
		mat.metallic_specular = 0.0
	m.material_override = mat
	m.position = pos + off
	world.add_child(m)
	return m


func _lv(st: SurfaceTool, p: Vector2, n: Vector2, f: float) -> void:
	st.set_normal(Vector3(n.x * cos(f), n.y, n.x * sin(f)))
	st.add_vertex(Vector3(p.x * cos(f), p.y, p.x * sin(f)))


func rounded_cyl_mesh(rt: float, rb: float, h: float, r: float) -> ArrayMesh:
	var key: String = "%.3f_%.3f_%.3f_%.3f" % [rt, rb, h, r]
	if rcyl_cache.has(key):
		return rcyl_cache[key]
	var prof: Array = [Vector2(0.0, h / 2.0)]
	var ct := Vector2(rt - r, h / 2.0 - r)
	for k in range(5):
		var a: float = deg_to_rad(90.0 - 22.5 * k)
		prof.append(ct + Vector2(cos(a), sin(a)) * r)
	var cb := Vector2(rb - r, -h / 2.0 + r)
	for k in range(5):
		var a2: float = deg_to_rad(-22.5 * k)
		prof.append(cb + Vector2(cos(a2), sin(a2)) * r)
	prof.append(Vector2(0.0, -h / 2.0))
	var np: int = prof.size()
	var nrm: Array = []
	for i in range(np):
		var t: Vector2 = (prof[mini(i + 1, np - 1)] as Vector2) - (prof[maxi(i - 1, 0)] as Vector2)
		nrm.append(Vector2(-t.y, t.x).normalized())
	var seg := 24
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(np - 1):
		for j in range(seg):
			var f0: float = TAU * j / seg
			var f1: float = TAU * (j + 1) / seg
			var pa: Vector2 = prof[i]
			var pb: Vector2 = prof[i + 1]
			_lv(st, pa, nrm[i], f0)
			_lv(st, pb, nrm[i + 1], f0)
			_lv(st, pb, nrm[i + 1], f1)
			_lv(st, pa, nrm[i], f0)
			_lv(st, pb, nrm[i + 1], f1)
			_lv(st, pa, nrm[i], f1)
	var mesh: ArrayMesh = st.commit()
	rcyl_cache[key] = mesh
	return mesh


func cyl(pos: Vector3, r_top: float, r_bot: float, h: float, col: Color, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var rmin: float = minf(r_top, r_bot)
	if fancy and h >= 0.04 and rmin >= 0.03:
		m.mesh = rounded_cyl_mesh(r_top, r_bot, h, minf(minf(h * 0.45, rmin * 0.9), 0.12))
	else:
		var c := CylinderMesh.new()
		c.top_radius = r_top
		c.bottom_radius = r_bot
		c.height = h
		c.radial_segments = 24
		m.mesh = c
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 1.0 if fancy else 0.7
	if fancy:
		mat.metallic_specular = 0.0
	m.material_override = mat
	m.position = pos + off
	m.rotation_degrees = rot
	world.add_child(m)
	return m


func glow(pos: Vector3, size: Vector3, col: Color) -> MeshInstance3D:
	var m := box(pos, size, col)
	var mat := m.material_override as StandardMaterial3D
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.0
	return m


# کره‌ی کوچک (برای گره‌ی کیسه و ...)
func ball(pos: Vector3, r: float, col: Color, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 24
	s.rings = 12
	m.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 1.0 if fancy else 0.4
	if fancy:
		mat.metallic_specular = 0.0
	m.material_override = mat
	m.position = pos + off
	m.scale = scl
	world.add_child(m)
	return m


# شفاف کردن یک مش (رنگ آن باید آلفا داشته باشد)
func clear_mat(m: MeshInstance3D) -> void:
	var mat := m.material_override as StandardMaterial3D
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 1.0
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func glass(pos: Vector3, size: Vector3) -> MeshInstance3D:
	var m := box(pos, size, Color(0.75, 0.9, 0.95, 0.25))
	var mat := m.material_override as StandardMaterial3D
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 1.0
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m


# ============================================================
# نور و دوربین (ارتوگرافیک، زاویه‌ی ایزومتریک (30,30,30))
# ============================================================

func _base_soft(cam_size: float, target: Vector3, bg: Color) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.background_color = bg
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("f5f7ff")
	env.ambient_light_energy = 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.5
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, 25, 0)
	sun.light_color = Color("fffaf2")
	sun.light_energy = 0.8
	sun.light_angular_distance = 2.0
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 80.0
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 0.3
	sun.shadow_blur = 8.0
	sun.shadow_opacity = 0.6
	world.add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-35, 200, 0)
	fill.light_color = Color("e6ecff")
	fill.light_energy = 0.15
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


# ============================================================
# ابزارهای مخصوص Front
# ============================================================

# خطوط درز سرامیک روی دیوار عمود بر محور x (دیوار چپ)
func ceramic_x(x: float, z0: float, z1: float, y0: float, y1: float, tw: float = 0.45, th: float = 0.6) -> void:
	var nz: int = maxi(1, int(round((z1 - z0) / tw)))
	var ny: int = maxi(1, int(round((y1 - y0) / th)))
	var sz: float = (z1 - z0) / nz
	var sy: float = (y1 - y0) / ny
	var gap: float = 0.016
	box(Vector3(x + 0.004, (y0 + y1) / 2.0, (z0 + z1) / 2.0), Vector3(0.008, y1 - y0, z1 - z0), GROUT)
	for i in range(nz):
		for j in range(ny):
			box(Vector3(x + 0.012, y0 + sy * (j + 0.5), z0 + sz * (i + 0.5)), Vector3(0.016, sy - gap, sz - gap), TILE)


# خطوط درز سرامیک روی دیوار عمود بر محور z (دیوار پشتی)
func ceramic_z(z: float, x0: float, x1: float, y0: float, y1: float, tw: float = 0.45, th: float = 0.6) -> void:
	var nx: int = maxi(1, int(round((x1 - x0) / tw)))
	var ny: int = maxi(1, int(round((y1 - y0) / th)))
	var sx: float = (x1 - x0) / nx
	var sy: float = (y1 - y0) / ny
	var gap: float = 0.016
	box(Vector3((x0 + x1) / 2.0, (y0 + y1) / 2.0, z + 0.004), Vector3(x1 - x0, y1 - y0, 0.008), GROUT)
	for i in range(nx):
		for j in range(ny):
			box(Vector3(x0 + sx * (i + 0.5), y0 + sy * (j + 0.5), z + 0.012), Vector3(sx - gap, sy - gap, 0.016), TILE)


# موزاییک ترازو: زمینه‌ی کرم + تراشه‌های بسیار ریز رنگی
func terrazzo_tile(cx: float, cz: float, rng: RandomNumberGenerator) -> void:
	var base := Color("c5c5c5ff")
	base = base.lightened(rng.randf_range(-0.03, 0.03))
	box(Vector3(cx, 0.01, cz), Vector3(0.98, 0.02, 0.98), base)
	var chips := [
		Color("1f1f1f"), Color("2b2b2b"),
		Color("b9703f"), Color("c98557"),
		Color("d9a58a"), Color("c48a74"),
		Color("9a8f86"), Color("b7ada3"),
		Color("f4ece0")
	]
	for k in range(24):
		var px: float = cx + rng.randf_range(-0.46, 0.46)
		var pz: float = cz + rng.randf_range(-0.46, 0.46)
		var s: float = rng.randf_range(0.02, 0.05)
		var m := box(Vector3(px, 0.022, pz), Vector3(s, 0.006, s * rng.randf_range(0.6, 1.4)), chips[rng.randi() % chips.size()])
		m.rotation_degrees.y = rng.randf_range(0, 180)


# توری شطرنجی (خطوط در هر دو جهت) روی سطح میز
func mesh_top(cx: float, cy: float, cz: float, sx: float, sz: float) -> void:
	var wire := Color("6f7b86")
	var n: int = int(sx / 0.18)
	for i in range(n + 1):
		box(Vector3(cx - sx / 2.0 + i * (sx / n), cy, cz), Vector3(0.03, 0.03, sz), wire)
	var m: int = int(sz / 0.18)
	for j in range(m + 1):
		box(Vector3(cx, cy + 0.015, cz - sz / 2.0 + j * (sz / m)), Vector3(sx, 0.03, 0.03), wire)


# میز توری: قاب استیل با لبه‌ی بالاآمده + توری شطرنجی + پایه
func mesh_table(cx: float, cz: float, sx: float, sz: float, h: float) -> void:
	var frame := Color("c2cbd3")
	box(Vector3(cx, h, cz - sz / 2.0), Vector3(sx, 0.14, 0.08), frame)
	box(Vector3(cx, h, cz + sz / 2.0), Vector3(sx, 0.14, 0.08), frame)
	box(Vector3(cx - sx / 2.0, h, cz), Vector3(0.08, 0.14, sz), frame)
	box(Vector3(cx + sx / 2.0, h, cz), Vector3(0.08, 0.14, sz), frame)
	for gx in [cx - sx / 2.0, cx + sx / 2.0]:
		for gz in [cz - sz / 2.0, cz + sz / 2.0]:
			box(Vector3(gx, h, gz), Vector3(0.085, 0.14, 0.085), frame)
	mesh_top(cx, h + 0.04, cz, sx - 0.1, sz - 0.1)
	for px in [cx - sx / 2.0 + 0.06, cx + sx / 2.0 - 0.06]:
		for pz in [cz - sz / 2.0 + 0.06, cz + sz / 2.0 - 0.06]:
			box(Vector3(px, (h - 0.05) / 2.0, pz), Vector3(0.1, h + 0.05, 0.1), STEEL)


# یک ورق نان لواش. pattern: 0 = بدون دایره | 1 = فقط حاشیه | 2 = دایره‌ی کامل
func bread_sheet(cx: float, cy: float, cz: float, sx: float, sz: float, thick: float, deg: float, rng: RandomNumberGenerator, pattern: int = 2) -> void:
	var base := Color("e8d3a0").lightened(rng.randf_range(-0.03, 0.03))
	var m := box(Vector3(cx, cy, cz), Vector3(sx, thick, sz), base)
	m.rotation_degrees.y = deg
	if pattern == 0:
		return
	var a: float = deg_to_rad(deg)
	var ca: float = cos(a)
	var sa: float = sin(a)
	var r: float = 0.012
	var edge: float = r + 0.01
	var step: float = 0.04
	var nx: int = int(round((sx - 2.0 * edge) / step))
	var nz: int = int(round((sz - 2.0 * edge) / step))
	var step_x: float = (sx - 2.0 * edge) / nx
	var step_z: float = (sz - 2.0 * edge) / nz
	var bw: int = 2   # تعداد ردیف دایره‌ی حاشیه
	var light := Color("d9a45a")
	var dark := Color("a9672e")
	for i in range(nx + 1):
		for j in range(nz + 1):
			if pattern == 1 and i >= bw and i <= nx - bw and j >= bw and j <= nz - bw:
				continue
			var lx: float = -sx / 2.0 + edge + i * step_x
			var lz: float = -sz / 2.0 + edge + j * step_z
			var t: float = float(i) / float(nx)
			var col: Color = dark.lerp(light, t)
			if rng.randf() < 0.30:
				col = base
			var px: float = cx + lx * ca + lz * sa
			var pz: float = cz - lx * sa + lz * ca
			cyl(Vector3(px, cy + thick / 2.0 + 0.003, pz), r, r, 0.006, col)


# دسته‌ی نان: ورق رویی دایره‌ی کامل، ورق‌های زیرین طبق lower (0 بدون دایره، 1 فقط حاشیه)
func bread_stack(cx: float, cy: float, cz: float, sx: float, sz: float, h: float, rng: RandomNumberGenerator, layers: int = 6, lower: int = 1, jitter: float = 1.0) -> void:
	var th: float = h / layers
	for i in range(layers):
		var y: float = cy - h / 2.0 + th * (i + 0.5)
		var ox: float = rng.randf_range(-0.04, 0.04) * jitter
		var oz: float = rng.randf_range(-0.04, 0.04) * jitter
		var deg: float = rng.randf_range(-2.5, 2.5) * jitter
		var pat: int = 2 if i == layers - 1 else lower
		bread_sheet(cx + ox, y, cz + oz, sx, sz, th, deg, rng, pat)


# دسته‌ی نان داخل کیسه‌ی شفاف با گره‌ی نیمه‌شفاف در یک سر (dir = 1 یا -1)
func bagged_bread(cx: float, cy: float, cz: float, sx: float, sz: float, h: float, rng: RandomNumberGenerator, dir: float, layers: int = 10) -> void:
	bread_stack(cx, cy, cz, sx, sz, h, rng, layers, 0, 0.25)
	var bag := box(Vector3(cx, cy, cz), Vector3(sx + 0.06, h + 0.04, sz + 0.06), Color(0.96, 0.97, 1.0, 0.3))
	var bmat := bag.material_override as StandardMaterial3D
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.roughness = 1.0
	bag.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# گره و گردن: شفافیت کمتر از خود کیسه (آلفا 0.6 در برابر 0.3)
	var plastic := Color(0.93, 0.95, 0.98, 0.6)
	var shade := Color(0.84, 0.87, 0.92, 0.65)
	var end: float = cz + dir * (sz / 2.0 + 0.03)
	var rot := Vector3(90.0 * dir, 0.0, 0.0)

	# گردن جمع‌شده‌ی کیسه
	clear_mat(cyl(Vector3(cx, cy, end + dir * 0.09), 0.03, 0.1, 0.18, plastic, rot))
	# چین‌های گردن
	clear_mat(cyl(Vector3(cx, cy, end + dir * 0.06), 0.05, 0.075, 0.03, shade, rot))
	clear_mat(cyl(Vector3(cx, cy, end + dir * 0.13), 0.035, 0.05, 0.03, shade, rot))
	# گره: دو گلوله
	clear_mat(ball(Vector3(cx, cy, end + dir * 0.21), 0.058, plastic, Vector3(1.0, 0.9, 0.85)))
	clear_mat(ball(Vector3(cx + 0.03, cy + 0.02, end + dir * 0.25), 0.04, shade, Vector3(1.0, 0.9, 0.9)))
	# دو دم باز شده‌ی کیسه
	var th: float = 24.0
	var t1 := box(Vector3(cx + 0.035, cy + 0.01, end + dir * 0.33), Vector3(0.055, 0.012, 0.16), Color(0.93, 0.95, 0.98, 0.55))
	t1.rotation_degrees = Vector3(0.0, th * dir, 0.0)
	clear_mat(t1)
	var t2 := box(Vector3(cx - 0.035, cy - 0.01, end + dir * 0.32), Vector3(0.05, 0.012, 0.14), Color(0.84, 0.87, 0.92, 0.55))
	t2.rotation_degrees = Vector3(0.0, -th * dir, 0.0)
	clear_mat(t2)


# دسته‌ی کیسه‌ی خالی نان: ورق‌های شفاف روی هم (همان شفافیت کیسه‌ها: آلفا 0.3)
func bag_stack(cx: float, cy: float, cz: float, sx: float, sz: float, h: float, rng: RandomNumberGenerator, layers: int = 20) -> void:
	var th: float = h / layers
	for i in range(layers):
		var y: float = cy - h / 2.0 + th * (i + 0.5)
		var ox: float = rng.randf_range(-0.03, 0.03)
		var oz: float = rng.randf_range(-0.03, 0.03)
		var m := box(Vector3(cx + ox, y, cz + oz), Vector3(sx, th * 0.85, sz), Color(0.96, 0.97, 1.0, 0.3))
		m.rotation_degrees.y = rng.randf_range(-2.5, 2.5)
		clear_mat(m)


# تبدیل مختصات محلیِ شیب‌دار به مختصات دنیا (شیب حول محور x)
func tpos(bc: Vector3, lx: float, ly: float, lz: float, c: float, s: float) -> Vector3:
	return bc + Vector3(lx, ly * c - lz * s, ly * s + lz * c)


# کارتخوان: بدنه‌ی شیب‌دار رو به مشتری (جهت z+)، صفحه، شیار کارت، کلیدها
func card_reader(cx: float, cy: float, cz: float) -> void:
	var t: float = 18.0
	var c: float = cos(deg_to_rad(t))
	var s: float = sin(deg_to_rad(t))
	var bc := Vector3(cx, cy + 0.09, cz)
	# پایه‌ی پشتی
	box(Vector3(cx, cy + 0.06, cz - 0.17), Vector3(0.2, 0.12, 0.07), Color("1f2326"))
	# بدنه
	var body := box(bc, Vector3(0.26, 0.05, 0.4), Color("2f3a44"))
	body.rotation_degrees.x = t
	# صفحه
	var scr := glow(tpos(bc, 0.0, 0.028, -0.11, c, s), Vector3(0.2, 0.008, 0.11), Color("6aa7ff"))
	scr.rotation_degrees.x = t
	# شیار کارت
	var slot := box(tpos(bc, 0.0, 0.027, -0.035, c, s), Vector3(0.19, 0.006, 0.014), Color("0d0f10"))
	slot.rotation_degrees.x = t
	# کلیدها: 4 ردیف 3 تایی (ردیف آخر قرمز، زرد، سبز)
	var last_row := [Color("ff3b30"), Color("ffcc00"), Color("4cd964")]
	for r in range(4):
		for k in range(3):
			var col := Color("d3dae0")
			if r == 3:
				col = last_row[k]
			var kb := box(tpos(bc, -0.07 + k * 0.07, 0.029, 0.015 + r * 0.05, c, s), Vector3(0.055, 0.012, 0.036), col)
			kb.rotation_degrees.x = t


# ============================================================
# FRONT: خط تنور، میز فروش در ورودی، خیابان
# ============================================================
func _build_front() -> void:
	fancy = true
	_base_soft(CAM_SIZE, Vector3(0, 1.0, 0), Color("e8d9b5"))

	# کف موزاییک ترازو 12 در 12
	box(Vector3(0, -0.25, 0), Vector3(12, 0.5, 12), Color("c5c5c5ff"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in range(12):
		for j in range(12):
			terrazzo_tile(-5.5 + i, -5.5 + j, rng)

	# دیوار پشتی چپ (بلند) + سرامیک
	box(Vector3(-6.15, 1.35, -0.15), Vector3(0.3, 3.7, 12.3), WALL)
	ceramic_x(-6.0, -5.85, 5.85, 0.05, 3.05)

	# دیوار پشتی راست (کوتاه) با راه عبور + سرامیک
	box(Vector3(-1.65, 0.35, -6.15), Vector3(9.3, 1.7, 0.3), WALL)
	box(Vector3(5.9, 0.35, -6.15), Vector3(0.8, 1.7, 0.3), WALL)
	ceramic_z(-6.0, -5.95, 2.85, 0.05, 1.05)
	ceramic_z(-6.0, 5.65, 5.85, 0.05, 1.05)
	# دیوار کوتاه سمت راست جلو
	box(Vector3(6.15, 0.05, -0.15), Vector3(0.3, 1.1, 12.3), WALL)

	# تابلو و ساعت روی دیوار چپ
	box(Vector3(-5.95, 2.55, 4.0), Vector3(0.08, 0.7, 1.5), WOOD)
	box(Vector3(-5.91, 2.55, 4.0), Vector3(0.04, 0.55, 1.3), Color("f7efd2"))
	cyl(Vector3(-5.93, 2.1, 1.5), 0.4, 0.4, 0.06, Color("f7f7f2"), Vector3(0, 0, 90))
	box(Vector3(-5.9, 2.2, 1.5), Vector3(0.02, 0.22, 0.05), Color("222222"))
	box(Vector3(-5.9, 2.1, 1.65), Vector3(0.02, 0.05, 0.2), Color("222222"))

	# قفسه‌ی نان 4 طبقه کنار ساعت تا کنج دیوار چپ
	for sy in [0.4, 0.85, 1.3, 1.75]:
		box(Vector3(-5.5, sy, 4.0), Vector3(0.9, 0.06, 3.8), WOOD)
		bagged_bread(-5.46, sy + 0.11, 3.15, 0.77, 1.4, 0.12, rng, -1.0)
		bagged_bread(-5.46, sy + 0.11, 4.75, 0.77, 1.4, 0.12, rng, 1.0)
	# ستون‌های پشتی (کنار دیوار): هر ۴ تا
	for pz in [2.15, 3.4, 4.65, 5.85]:
		box(Vector3(-5.9, 0.925, pz), Vector3(0.06, 1.85, 0.06), WOOD)
	# ستون‌های جلو (سمت اتاق): فقط دو ستون کناری
	for pz in [2.15, 5.85]:
		box(Vector3(-5.1, 0.925, pz), Vector3(0.06, 1.85, 0.06), WOOD)

	# ورودی: تمام شیشه
	glass(Vector3(-3.675, 1.6, 6.0), Vector3(4.95, 3.2, 0.06))
	glass(Vector3(3.675, 1.6, 6.0), Vector3(4.95, 3.2, 0.06))

	# ---- شروع بخش دستگاه‌ها ----
	off = Vector3(-2.45, 0, -1.5)

	# مخزن خمیر
	for lx in [-3.0, -2.0]:
		for lz in [-3.8, -2.8]:
			box(Vector3(lx, 1.0, lz), Vector3(0.12, 2.0, 0.12), DSTEEL)
	cyl(Vector3(-2.5, 1.35, -3.3), 0.75, 0.2, 0.7, Color("aab4bd"))
	cyl(Vector3(-2.5, 2.35, -3.3), 0.75, 0.75, 1.3, Color("b9c3cc"))
	cyl(Vector3(-2.5, 3.05, -3.3), 0.82, 0.82, 0.12, Color("d3dae0"))
	cyl(Vector3(-2.5, 3.08, -3.3), 0.7, 0.7, 0.1, BREAD)
	cyl(Vector3(-2.5, 3.2, -3.3), 0.35, 0.6, 0.2, BREAD)
	cyl(Vector3(-2.5, 0.95, -3.3), 0.2, 0.2, 0.3, Color("8a97a3"))
	box(Vector3(-2.5, 0.95, -2.0), Vector3(0.45, 0.3, 3.0), Color("8a97a3"))
	for lz in [-2.6, -1.4]:
		box(Vector3(-2.5, 0.4, lz), Vector3(0.12, 0.8, 0.12), DSTEEL)
	# واحد غلتک پشت تنور
	box(Vector3(-2.5, 1.2, -0.8), Vector3(0.9, 0.7, 0.6), Color("4a5560"))
	cyl(Vector3(-2.5, 1.62, -0.8), 0.12, 0.12, 0.8, Color("8a97a3"), Vector3(0, 0, 90))
	glow(Vector3(-2.04, 1.3, -0.8), Vector3(0.04, 0.12, 0.12), Color("4cd964"))

	# تنور صنعتی
	box(Vector3(-1.5, 0.15, 0.5), Vector3(4.1, 0.3, 2.1), Color("4a5560"))
	box(Vector3(-1.5, 1.15, 0.5), Vector3(4.0, 1.7, 2.0), STEEL)
	box(Vector3(-1.5, 2.05, 0.5), Vector3(4.1, 0.1, 2.1), Color("c9d2da"))
	# دهانه‌ی تاریک شکاف روی سطح راست بدنه
	box(Vector3(0.49, 0.62, 0.5), Vector3(0.06, 0.34, 1.3), Color("1f2326"))
	# قاب استیل دور شکاف
	var fc := Color("d3dae0")
	box(Vector3(0.52, 0.82, 0.5), Vector3(0.06, 0.06, 1.42), fc)
	box(Vector3(0.52, 0.42, 0.5), Vector3(0.06, 0.06, 1.42), fc)
	box(Vector3(0.52, 0.62, -0.19), Vector3(0.06, 0.46, 0.06), fc)
	box(Vector3(0.52, 0.62, 1.19), Vector3(0.06, 0.46, 0.06), fc)
	for fz in [-0.19, 1.19]:
		for fy in [0.42, 0.82]:
			ball(Vector3(0.52, fy, fz), 0.04, fc)

	# ---- جزئیات بیشتر تنور ----

	# دو گیج بالای پنجره‌ی شعله
	for gx in [-2.8, -2.0]:
		cyl(Vector3(gx, 1.78, 1.52), 0.14, 0.14, 0.03, DSTEEL, Vector3(90, 0, 0))
		cyl(Vector3(gx, 1.78, 1.54), 0.115, 0.115, 0.03, Color("f7f7f2"), Vector3(90, 0, 0))
		for k in range(5):
			var ta: float = deg_to_rad(-60.0 + k * 30.0)
			var tk := box(Vector3(gx - sin(ta) * 0.09, 1.78 + cos(ta) * 0.09, 1.558), Vector3(0.008, 0.025, 0.006), Color("333333"))
			tk.rotation_degrees.z = rad_to_deg(ta)
		var ang: float = 35.0 if gx < -2.4 else -50.0
		var ar: float = deg_to_rad(ang)
		var nd := box(Vector3(gx - sin(ar) * 0.045, 1.78 + cos(ar) * 0.045, 1.565), Vector3(0.012, 0.09, 0.008), Color("c0392b"))
		nd.rotation_degrees.z = ang
		cyl(Vector3(gx, 1.78, 1.57), 0.018, 0.018, 0.02, Color("222222"), Vector3(90, 0, 0))

	# دکمه‌ی اضطراری و دکمه‌های استارت/استپ
	box(Vector3(0.0, 0.68, 1.53), Vector3(0.34, 0.34, 0.04), Color("e0b43c"))
	cyl(Vector3(0.0, 0.68, 1.57), 0.13, 0.13, 0.03, Color("1f2326"), Vector3(90, 0, 0))
	cyl(Vector3(0.0, 0.68, 1.62), 0.09, 0.09, 0.08, Color("d62d20"), Vector3(90, 0, 0))
	glow(Vector3(-0.52, 0.68, 1.54), Vector3(0.12, 0.12, 0.04), Color("4cd964"))
	glow(Vector3(-0.34, 0.68, 1.54), Vector3(0.12, 0.12, 0.04), Color("ff3b30"))

	# ---- جزئیات سقف تنور ----

	# دودکش: دو حلقه‌ی بند و کلاهک مخروطی
	cyl(Vector3(-2.4, 2.35, -0.1), 0.28, 0.28, 0.04, DSTEEL)
	cyl(Vector3(-2.4, 2.85, -0.1), 0.28, 0.28, 0.04, DSTEEL)
	cyl(Vector3(-2.4, 3.33, -0.1), 0.04, 0.32, 0.16, Color("5f6b76"))

	# لوله‌ی کوچک سمت راست: فلنج پایین و بالا + درپوش
	cyl(Vector3(-0.7, 2.13, 0.0), 0.19, 0.19, 0.04, DSTEEL)
	cyl(Vector3(-0.7, 2.5, 0.0), 0.19, 0.19, 0.04, DSTEEL)
	cyl(Vector3(-0.7, 2.57, 0.0), 0.17, 0.17, 0.04, Color("5f6b76"))

	# دریچه‌ی تهویه‌ی شبکه‌دار
	box(Vector3(-2.2, 2.13, 1.2), Vector3(0.9, 0.06, 0.5), DSTEEL)
	for i in range(6):
		box(Vector3(-2.2, 2.17, 1.04 + i * 0.08), Vector3(0.8, 0.02, 0.04), Color("1f2326"))

	cyl(Vector3(-2.4, 2.65, -0.1), 0.25, 0.25, 1.0, DSTEEL)
	cyl(Vector3(-2.4, 3.2, -0.1), 0.35, 0.35, 0.1, Color("5f6b76"))
	cyl(Vector3(-0.7, 2.3, 0.0), 0.15, 0.15, 0.5, DSTEEL)

	# تابلو کنترل (فقط نمایشگر، بدون دکمه‌های رنگی)
	box(Vector3(-0.3, 1.4, 1.51), Vector3(1.1, 1.0, 0.06), Color("778a9cff"))
	glow(Vector3(-0.3, 1.7, 1.56), Vector3(0.6, 0.16, 0.04), Color("7dffb0"))
	box(Vector3(-0.3, 1.05, 1.56), Vector3(0.7, 0.1, 0.04), Color("5f6b76"))
	# دریچه‌ها و لوله‌ی گاز
	for i in range(4):
		box(Vector3(-1.2, 0.55 + i * 0.12, 1.51), Vector3(0.9, 0.05, 0.05), Color("5f6b76"))

	# برش‌زن (فقط میله‌ی پشتی)
	box(Vector3(1.8, 0.75, -0.35), Vector3(0.14, 1.5, 0.14), DSTEEL)

	# تسمه‌ی توری (بدون میله‌ها، میله‌ها لایه‌ی جدا هستن)
	box(Vector3(2.0, 0.6, 0.5), Vector3(4.0, 0.08, 1.2), Color("46515b"))
	box(Vector3(2.3, 0.62, -0.2), Vector3(3.6, 0.1, 0.08), STEEL)
	box(Vector3(2.3, 0.62, 1.2), Vector3(3.6, 0.1, 0.08), STEEL)
	for lx in [0.9, 3.7]:
		for lz in [-0.15, 1.15]:
			box(Vector3(lx, 0.25, lz), Vector3(0.1, 0.5, 0.1), DSTEEL)
	cyl(Vector3(4.0, 0.57, 0.5), 0.12, 0.12, 1.5, DSTEEL, Vector3(90, 0, 0))

	# ---- پایان بخش دستگاه‌ها ----
	off = Vector3.ZERO

	# میز توری کوتاه (خالی)
	mesh_table(2.9, -1.0, 2.4, 1.5, 0.45)

	# میز توری فروش (طول 5، عرض 2.6) فقط با کیسه‌های خالی و کارتخوان
	mesh_table(0.0, 4.4, 5.0, 2.6, 1.0)
	bag_stack(1.2, 1.17, 4.4, 0.77, 1.4, 0.2, rng, 20)
	card_reader(2.0, 1.07, 4.4)
