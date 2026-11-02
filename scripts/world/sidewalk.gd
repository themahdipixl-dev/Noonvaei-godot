class_name Sidewalk
extends Node2D
## پیاده‌رو جلوی مغازه + جدول و جوبِ سبک تهران.
## همه‌ی لبه‌ها و گوشه‌ها گرد و نرم‌اند (مثل بقیه‌ی محیط بازی):
##   - گوشه‌های دال گردند و لبه‌ی بالایی دال هم گرد است (bullnose، نه لبه‌ی تیز)
##   - آجرها و کاشی‌های زرد و شیارهاشان گوشه‌گردند
##   - جوب با دو سر گرد
##
## اندازه‌ها بر حسب «واحد» هستند. یک واحد = عرض یک کاشی زرد (UNIT خانه‌ی گرید).
## عرض پیاده‌رو (قسمت آجرفرش) = WIDTH_UNITS واحد = 5 تا کاشی زرد کنار هم:
##   2 ردیف خاکستری | 1 ردیف زرد (وسط) | 2 ردیف خاکستری
## خطوط برجسته‌ی کاشی زرد موازی طول نوار هستند.
##
## از مغازه به سمت خیابان (gy بزرگ‌تر):
##   [آجرفرش] -> [جدول بتنی، تکه‌تکه با درز] -> [جوب: کانال کم‌عمق با آب] -> خیابان
## جدول لبه‌ی بیرونی خود دال است (رویه‌ی بتنی + دیواره‌ی رو به خیابان)؛ جوب درست جلوی آن و پایین‌تر از زمین است
## و دیواره‌ی جدول تا ته جوب ادامه پیدا می‌کند. طول جوب = طول پیاده‌رو.
##
## جای پیاده‌رو: جلوی ورودی مغازه (لبه‌ی gy بزرگ‌تر)، به‌اندازه‌ی عرض مغازه + SIDE_MARGIN از هر طرف.
## ترتیب کشیدن: بعد از Bakery (روی آن)، تا لبه‌ی بیرونی کف مغازه دیده نشود.
## دال به‌اندازه‌ی CURB_H پیکسل بالا آمده و به‌اندازه‌ی همان ارتفاع جلوتر گذاشته شده؛ پس لبه‌ی بالایی‌اش دقیقاً روی
## لبه‌ی کف مغازه می‌افتد و لبه‌ی بیرونی کف زیر دال پنهان می‌شود.
##
## همه‌چیز با _draw() کشیده می‌شود (یک‌بار کشیده و کش می‌شود). رنگ آجرها با seed ثابت کمی متفاوت است.

## عرض یک کاشی زرد، بر حسب خانه‌ی گرید.
const UNIT := 0.2
## عرض آجرفرش بر حسب واحد (تعداد کاشی‌های زرد).
const WIDTH_UNITS := 5
## ردیف زرد کدام واحد است (از 0): 0 1 [2] 3 4 = وسط.
const YELLOW_UNIT_INDEX := 2
## پیاده‌رو از هر طرف مغازه این‌قدر (خانه‌ی گرید) بلندتر است.
const SIDE_MARGIN := 1.0

## حاشیه‌ی سنگی کنار و پشت آجرفرش (خانه‌ی گرید).
const RIM := 0.07
## عرض جدول بتنی سمت خیابان (خانه‌ی گرید).
const CURB_W := 0.16
## طول هر تکه‌ی جدول (خانه‌ی گرید)؛ بین تکه‌ها درز است.
const CURB_SEG := 0.6
## شعاع گوشه‌های بیرونی دال (خانه‌ی گرید).
const CORNER_R := 0.22
## ارتفاع دال از زمین (px).
const CURB_H := 6.0
## گردیِ لبه‌ی بالایی دال: چقدر به داخل (خانه‌ی گرید) و چقدر از ارتفاع (px) را می‌گیرد.
const BEVEL_I := 0.03
const BEVEL_H := 2.6
## زاویه‌های پله‌های گردی لبه (درجه، آخری 90 است).
const BEVEL_ANGLES := [35.0, 65.0, 90.0]
## فاصله‌ی درز بین آجرها (خانه‌ی گرید).
const JOINT := 0.014
## شعاع گوشه‌ی آجرها و کاشی‌ها (خانه‌ی گرید).
const BRICK_R := 0.012
const YELLOW_R := 0.022
## تعداد تکه‌ی هر کمان گوشه (بیشتر = گردتر).
const ARC_SEGS := 8

## جوب: عرض و شعاع دو سر (خانه‌ی گرید) و عمق (px).
const GUTTER_W := 0.34
const GUTTER_R := 0.12
const GUTTER_D := 4.0

const BRICK_COLOR := Color("#a9acaf")
const JOINT_COLOR := Color("#7d8185")
const YELLOW_COLOR := Color("#e6bf5f")
const YELLOW_RIB_COLOR := Color("#f6df9a")
const CURB_COLOR := Color("#cfc9bd")
const CURB_JOINT_COLOR := Color("#a29c8f")
const GUTTER_WALL_COLOR := Color("#8b867b")
const GUTTER_FLOOR_COLOR := Color("#6d6a62")
const WATER_COLOR := Color(0.42, 0.56, 0.57, 0.92)
const WATER_HI_COLOR := Color(0.78, 0.88, 0.88, 0.55)
const SHADOW_COLOR := Color(0.25, 0.18, 0.08, 0.12)

var _iso: Iso
## آجرفرش (گرید)
var _px0 := 0.0
var _px1 := 0.0
var _py0 := 0.0
var _py1 := 0.0
## دال کامل = آجرفرش + حاشیه + جدول (گرید)
var _sx0 := 0.0
var _sx1 := 0.0
var _sy0 := 0.0
var _sy1 := 0.0
## جوب (گرید): درست جلوی جدول
var _gut_y0 := 0.0
var _gut_y1 := 0.0
var _n_len := 0


## lot_gx, lot_gy = گوشه‌ی بالا-چپِ زمین مغازه (گرید)، lot_size = ضلع زمین (خانه).
func setup(projector: Iso, lot_gx: float, lot_gy: float, lot_size: float) -> void:
	_iso = projector
	# جلو آمدن به‌اندازه‌ی ارتفاع دال: لبه‌ی بالایی دال روی لبه‌ی کف مغازه می‌نشیند.
	var gap := CURB_H / (projector.tile_h / 2.0)
	_sx0 = lot_gx - SIDE_MARGIN
	_sy0 = lot_gy + lot_size + gap
	var raw_len := (lot_size + 2.0 * SIDE_MARGIN) - 2.0 * RIM
	_n_len = maxi(1, roundi(raw_len / UNIT))
	_px0 = _sx0 + RIM
	_px1 = _px0 + float(_n_len) * UNIT
	_sx1 = _px1 + RIM
	_py0 = _sy0 + RIM
	_py1 = _py0 + float(WIDTH_UNITS) * UNIT
	_sy1 = _py1 + CURB_W
	_gut_y0 = _sy1
	_gut_y1 = _gut_y0 + GUTTER_W
	queue_redraw()


## عرض آجرفرش بر حسب خانه‌ی گرید.
func width_tiles() -> float:
	return float(WIDTH_UNITS) * UNIT


func _draw() -> void:
	if _iso == null:
		return
	var z := CURB_H
	var slab := _slab_outline(0.0)
	var top := _slab_outline(BEVEL_I)
	var paved := _rrect(_px0, _py0, _px1, _py1, maxf(CORNER_R - RIM, 0.02))

	# سایه‌ی ملایم روی زمین (کمی به سمت جلو/راست)
	draw_colored_polygon(_proj(_rrect(_sx0 + 0.03, _sy0 + 0.06, _sx1 + 0.05, _sy1 + 0.09, CORNER_R), 0.0), SHADOW_COLOR)

	# جوب (پایین‌تر از زمین، جلوی جدول)
	_draw_gutter()

	# دیواره‌ی گرد دال (فقط قسمت‌هایی که رو به دوربین‌اند)
	_draw_ring(slab, z - BEVEL_H, slab, 0.0, 0.0)

	# لبه‌ی بالایی گرد (چند پله‌ی کوچک روی یک ربع‌دایره)
	var prev := slab
	var prev_z := z - BEVEL_H
	var prev_a := 0.0
	for a in BEVEL_ANGLES:
		var th := deg_to_rad(a)
		var cur := _slab_outline(BEVEL_I * (1.0 - cos(th)))
		var cz := z - BEVEL_H * (1.0 - sin(th))
		_draw_ring(prev, prev_z, cur, cz, sin(deg_to_rad((prev_a + a) * 0.5)))
		prev = cur
		prev_z = cz
		prev_a = a

	# رویه‌ی سنگی/بتنی + آجرفرش
	draw_colored_polygon(_proj(top, z), Iso.shade(CURB_COLOR, 1.12))
	draw_colored_polygon(_proj(paved, z), JOINT_COLOR)

	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in range(_n_len):
		var gx := _px0 + float(i) * UNIT
		for j in range(WIDTH_UNITS):
			var gy := _py0 + float(j) * UNIT
			if j == YELLOW_UNIT_INDEX:
				_draw_yellow_tile(gx, gy, z)
			else:
				_draw_weave_cell(gx, gy, z, (i + j) % 2 == 0, rng, paved)

	_draw_curb_joints(z)


## دایره‌وار: خطوط دال (گرید) با «فاصله‌ی inset» از لبه‌ی بیرونی؛ تعداد نقطه‌ها همیشه یکی است.
func _slab_outline(inset: float) -> PackedVector2Array:
	return _rrect(_sx0 + inset, _sy0 + inset, _sx1 - inset, _sy1 - inset, maxf(CORNER_R - inset, 0.02))


# ---------------------------------------------------------------- جدول

## درز بین تکه‌های جدول بتنی: روی رویه و روی دیواره‌ی رو به خیابان تا ته جوب.
func _draw_curb_joints(z: float) -> void:
	var x_min := _sx0 + CORNER_R + 0.05
	var x_max := _sx1 - CORNER_R - 0.05
	var k := 1
	while true:
		var x := _px0 + float(k) * CURB_SEG
		if x > x_max:
			break
		if x >= x_min:
			_rect(x - 0.005, _py1, x + 0.005, _sy1 - BEVEL_I, z, CURB_JOINT_COLOR)
			draw_line(
				_iso.project(x, _sy1, z - BEVEL_H),
				_iso.project(x, _sy1, -GUTTER_D),
				CURB_JOINT_COLOR, 1.2, true
			)
		k += 1


# ---------------------------------------------------------------- جوب

## جوب تهران: کانال بتنی باز و کم‌عمق جلوی جدول، با کمی آب. کف به‌اندازه‌ی GUTTER_D پایین‌تر از زمین است؛
## لبه‌ی نزدیک به خیابان (که پشت آن پنهان است) قسمتی از کف را می‌پوشاند، پس کف با دهانه‌ی جوب برش می‌خورد.
## دیواره‌ی دورتر (همان دیواره‌ی جدول) در بالای دهانه دیده می‌شود.
func _draw_gutter() -> void:
	var opening := _rrect(_sx0, _gut_y0, _sx1, _gut_y1, GUTTER_R)
	var open_px := _proj(opening, 0.0)

	# دهانه با رنگ دیواره پر می‌شود؛ کف و آب روی آن می‌نشینند.
	draw_colored_polygon(open_px, GUTTER_WALL_COLOR)

	var floor_plan := _rrect(_sx0 + 0.04, _gut_y0, _sx1 - 0.04, _gut_y1 - 0.03, GUTTER_R * 0.8)
	_draw_clipped(_proj(floor_plan, -GUTTER_D), open_px, GUTTER_FLOOR_COLOR)

	# آب: باریک‌تر از کف، کمی بالاتر از آن
	var water_plan := _rrect(_sx0 + 0.1, _gut_y0 + 0.04, _sx1 - 0.1, _gut_y1 - 0.1, 0.06)
	_draw_clipped(_proj(water_plan, -GUTTER_D + 0.8), open_px, WATER_COLOR)
	var hi_plan := _rrect(_sx0 + 0.25, _gut_y0 + 0.08, _sx1 - 0.25, _gut_y0 + 0.12, 0.02, 3)
	_draw_clipped(_proj(hi_plan, -GUTTER_D + 0.8), open_px, WATER_HI_COLOR)

	# لبه‌ی گرد و روشن دهانه‌ی جوب (فقط سمت نزدیک به خیابان و دو سر)
	var s := ARC_SEGS + 1
	var lip := PackedVector2Array()
	for i in range(2 * s, 4 * s):
		lip.append(open_px[i])
	lip.append(open_px[2 * s])
	draw_polyline(lip, Iso.shade(CURB_COLOR, 1.02), 2.0, true)


## poly را با clip (هر دو در مختصات صفحه) برش می‌دهد و با رنگ می‌کشد.
func _draw_clipped(poly: PackedVector2Array, clip: PackedVector2Array, color: Color) -> void:
	var parts: Array = Geometry2D.intersect_polygons(poly, clip)
	for part in parts:
		var pts: PackedVector2Array = part
		if pts.size() >= 3:
			draw_colored_polygon(pts, color)


# ---------------------------------------------------------------- آجرفرش

## یک خانه‌ی UNIT×UNIT از چیدمان حصیری: دو آجر کنار هم؛ جهت آجرها خانه‌به‌خانه عوض می‌شود.
func _draw_weave_cell(gx: float, gy: float, z: float, stacked_along_y: bool, rng: RandomNumberGenerator, paved: PackedVector2Array) -> void:
	var h := JOINT / 2.0
	var half := UNIT / 2.0
	for k in range(2):
		var color := Iso.shade(BRICK_COLOR, rng.randf_range(0.93, 1.07))
		if stacked_along_y:
			var yy := gy + float(k) * half
			_brick(gx + h, yy + h, gx + UNIT - h, yy + half - h, z, color, paved)
		else:
			var xx := gx + float(k) * half
			_brick(xx + h, gy + h, xx + half - h, gy + UNIT - h, z, color, paved)


## یک کاشی زردِ راهنما: بدنه‌ی گوشه‌گرد + ۴ شیار برجسته‌ی گرد موازیِ طول نوار.
func _draw_yellow_tile(gx: float, gy: float, z: float) -> void:
	var h := JOINT / 2.0
	draw_colored_polygon(_proj(_rrect(gx + h, gy + h, gx + UNIT - h, gy + UNIT - h, YELLOW_R, 3), z), YELLOW_COLOR)
	var rib_w := 0.028
	for k in range(4):
		var cy := gy + UNIT * (float(k) + 0.5) / 4.0
		var rib := _rrect(gx + h + 0.015, cy - rib_w / 2.0, gx + UNIT - h - 0.015, cy + rib_w / 2.0, rib_w / 2.0, 3)
		draw_colored_polygon(_proj(rib, z), YELLOW_RIB_COLOR)


## آجر گوشه‌گرد: اگر نزدیک گوشه‌ی گرد باشد با شکل آجرفرش بریده می‌شود تا بیرون نزند.
func _brick(x0: float, y0: float, x1: float, y1: float, z: float, color: Color, paved: PackedVector2Array) -> void:
	var rin := maxf(CORNER_R - RIM, 0.02)
	var near_x := x0 < _px0 + rin or x1 > _px1 - rin
	var near_y := y0 < _py0 + rin or y1 > _py1 - rin
	var r := _rrect(x0, y0, x1, y1, BRICK_R, 2)
	if not (near_x and near_y):
		draw_colored_polygon(_proj(r, z), color)
		return
	var parts: Array = Geometry2D.intersect_polygons(r, paved)
	for part in parts:
		var pts: PackedVector2Array = part
		if pts.size() >= 3:
			draw_colored_polygon(_proj(pts, z), color)


func _rect(x0: float, y0: float, x1: float, y1: float, z: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		_iso.project(x0, y0, z), _iso.project(x1, y0, z),
		_iso.project(x1, y1, z), _iso.project(x0, y1, z),
	]), color)


## نوار بین دو خط هم‌تعداد: a در ارتفاع za و b در ارتفاع zb. برای هر ضلعِ رو به دوربین یک چهارضلعی؛
## رنگ نرم بین وجه چپِ روشن و وجه راستِ تیره. w (۰..۱) = چقدر رو به بالا است (۰ = دیواره‌ی عمودی، ۱ = رویه).
## دیواره‌ی دال = حالتی که a و b یکی‌اند و zb = 0.
func _draw_ring(a: PackedVector2Array, za: float, b: PackedVector2Array, zb: float, w: float) -> void:
	var c := Vector2((_sx0 + _sx1) / 2.0, (_sy0 + _sy1) / 2.0)
	var n := a.size()
	for i in range(n):
		var j := (i + 1) % n
		var d := a[j] - a[i]
		if d.length() < 0.0001:
			continue
		var nrm := Vector2(d.y, -d.x).normalized()
		if nrm.dot((a[i] + a[j]) / 2.0 - c) < 0.0:
			nrm = -nrm
		if nrm.x + nrm.y <= 0.001:
			continue  # پشت دال، دیده نمی‌شود
		var t := clampf((nrm.y - nrm.x) * 0.5 + 0.5, 0.0, 1.0)
		var base := lerpf(0.68, 0.9, t)
		var color := Iso.shade(CURB_COLOR, lerpf(base, 1.12, w))
		draw_colored_polygon(PackedVector2Array([
			_iso.project(a[i].x, a[i].y, za), _iso.project(a[j].x, a[j].y, za),
			_iso.project(b[j].x, b[j].y, zb), _iso.project(b[i].x, b[i].y, zb),
		]), color)


## مستطیل گرد در فضای گرید (نقطه‌ها پشت‌سرهم دور مستطیل). segs = تعداد تکه‌ی هر کمان.
static func _rrect(x0: float, y0: float, x1: float, y1: float, r: float, segs: int = ARC_SEGS) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var rr := minf(r, minf(x1 - x0, y1 - y0) / 2.0)
	var corners := [
		[Vector2(x0 + rr, y0 + rr), PI],
		[Vector2(x1 - rr, y0 + rr), PI * 1.5],
		[Vector2(x1 - rr, y1 - rr), 0.0],
		[Vector2(x0 + rr, y1 - rr), PI * 0.5],
	]
	for corner in corners:
		var c: Vector2 = corner[0]
		var a0: float = corner[1]
		for s in range(segs + 1):
			var a := a0 + (PI * 0.5) * float(s) / float(segs)
			pts.append(c + Vector2(cos(a), sin(a)) * rr)
	return pts


## چندضلعی گرید -> مختصات دنیا در ارتفاع z px.
func _proj(poly: PackedVector2Array, z: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		out.append(_iso.project(p.x, p.y, z))
	return out
