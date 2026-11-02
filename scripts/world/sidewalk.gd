class_name Sidewalk
extends Node2D
## پیاده‌رو جلوی مغازه + جدولِ سبک تهران + خیابانِ جلوی آن.
##
## اندازه‌ها بر حسب «واحد» هستند. یک واحد = عرض یک کاشی زرد (UNIT خانه‌ی گرید).
## عرض پیاده‌رو (قسمت آجرفرش) = WIDTH_UNITS واحد = 5 تا کاشی زرد کنار هم:
##   2 ردیف خاکستری | 1 ردیف زرد (وسط) | 2 ردیف خاکستری
## خطوط برجسته‌ی کاشی زرد موازی طول نوار هستند.
##
## از مغازه به سمت خیابان (gy بزرگ‌تر):
##   [آجرفرش روی دال] -> [جدول رنگ‌شده، بلندتر از آجرفرش] -> [خیابان: دو لاین]
## - جدول یک بلوک جداست که CURB_UP پیکسل از سطح آجرفرش بلندتر است (هم‌سطح نیست).
## - جدول بلوک‌بلوک سبز تیره و سفید است و رنگ‌ها یکی‌درمیان عوض می‌شوند.
## - بین بلوک‌های جدول هیچ درز یا خط تیره‌ای نیست.
## - جدول و دال دقیقاً هم‌طول‌اند و دو سرشان یک خط عمودی صاف دارد (بدون بیرون‌زدگی).
##   فقط گوشه‌های عقبیِ دال و گوشه‌های جلویی جدول گردند.
## - خیابان هم‌طول پیاده‌رو است و عرضش ROAD_LANES لاین (هر لاین ROAD_LANE_W خانه) = رفت‌وآمد دو ماشین،
##   یک لاین برای هر جهت، با خط‌چین وسط.
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
const RIM := 0.045
## عرض (ضخامت) جدول سمت خیابان (خانه‌ی گرید).
const CURB_W := 0.107
## اندازه‌ی تقریبی هر بلوک جدول (خانه‌ی گرید). اندازه‌ی واقعی طوری تنظیم می‌شود که
## تعداد بلوک‌ها فرد و هر دو سر جدول سبز باشد و بلوک نیمه‌کاره نداشته باشیم.
const CURB_BLOCK := 0.3
## شعاع گوشه‌های جلویی جدول (خانه‌ی گرید).
const CURB_R := 0.045
## شعاع گوشه‌های عقبیِ دال (خانه‌ی گرید).
const CORNER_R := 0.12
## ارتفاع دال از زمین (px).
const CURB_H := 6.0
## ارتفاع جدول بالاتر از سطح آجرفرش (px).
const CURB_UP := 4.0
## گردیِ لبه‌ی بالایی: چقدر به داخل (خانه‌ی گرید) و چقدر از ارتفاع (px) را می‌گیرد.
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

## خیابان: تعداد لاین‌ها (۲ = یکی برای هر جهت) و عرض هر لاین (خانه‌ی گرید؛ کمی بیشتر از عرض یک ماشین).
const ROAD_LANES := 2
const ROAD_LANE_W := 1.2
## گوشه‌های گردِ دور (سمت مقابل جدول) خیابان.
const ROAD_R := 0.1
## خط‌چین وسط: طول، فاصله، ضخامت (خانه‌ی گرید).
const DASH_LEN := 0.4
const DASH_GAP := 0.3
const DASH_W := 0.05
## خط ممتد لبه‌های خیابان (هم لبه‌ی دور، هم لبه‌ی کنار جدول): فاصله از لبه و ضخامت.
const EDGE_LINE_INSET := 0.1
const EDGE_LINE_W := 0.035

const BRICK_COLOR := Color("#a9acaf")
const JOINT_COLOR := Color("#7d8185")
const YELLOW_COLOR := Color("#e6bf5f")
const YELLOW_RIB_COLOR := Color("#f6df9a")
## بتن ساده (حاشیه‌ی دور دال).
const CURB_COLOR := Color("#cfc9bd")
## رنگ جدول: سبز تیره + سفید.
const CURB_GREEN := Color("#1f5b3b")
const CURB_WHITE := Color("#d8dbd7")
const ROAD_COLOR := Color("#4b4e54")
const ROAD_LINE_COLOR := Color("#e9e6dc")
const SHADOW_COLOR := Color(0.25, 0.18, 0.08, 0.12)

var _iso: Iso
## آجرفرش (گرید)
var _px0 := 0.0
var _px1 := 0.0
var _py0 := 0.0
var _py1 := 0.0
## دال (گرید): x از _sx0 تا _sx1، y از _sy0 تا _cy0
var _sx0 := 0.0
var _sx1 := 0.0
var _sy0 := 0.0
## جدول (گرید): y از _cy0 تا _sy1 ، x همان _sx0.._sx1
var _cy0 := 0.0
var _sy1 := 0.0
## خیابان (گرید): x همان _sx0.._sx1، y از _sy1 تا _ry1
var _ry1 := 0.0
var _n_len := 0
## تعداد و اندازه‌ی بلوک‌های جدول
var _n_blk := 1
var _blk := CURB_BLOCK


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
	_cy0 = _py1
	_sy1 = _cy0 + CURB_W
	_ry1 = _sy1 + float(ROAD_LANES) * ROAD_LANE_W
	# بلوک‌های جدول: تعداد فرد => هر دو سر سبز و هم‌شکل
	var span := _sx1 - _sx0
	_n_blk = maxi(1, roundi(span / CURB_BLOCK))
	if _n_blk % 2 == 0:
		_n_blk += 1
	_blk = span / float(_n_blk)
	queue_redraw()


## عرض آجرفرش بر حسب خانه‌ی گرید.
func width_tiles() -> float:
	return float(WIDTH_UNITS) * UNIT


## مرکز هر لاین (gy، گرید): lane = 0 نزدیک جدول، lane = 1 دورتر. برای تنظیم مسیر ماشین‌ها.
func lane_center_y(lane: int) -> float:
	return _sy1 + (float(lane) + 0.5) * ROAD_LANE_W


func _draw() -> void:
	if _iso == null:
		return
	var z := CURB_H
	var zc := CURB_H + CURB_UP
	var slab := _slab_outline(0.0)
	var top := _slab_outline(BEVEL_I)
	var pr := maxf(CORNER_R - RIM, 0.02)
	var paved := _rrect_c(_px0, _py0, _px1, _py1, pr, pr, 0.0, 0.0)

	# خیابان (روی زمین، زیر جدول)
	_draw_road()

	# سایه‌ی ملایم روی زمین (کمی به سمت جلو/راست)
	draw_colored_polygon(_proj(_rrect(_sx0 + 0.03, _sy0 + 0.06, _sx1 + 0.05, _sy1 + 0.09, CORNER_R), 0.0), SHADOW_COLOR)

	# ---- دال (بتن + آجرفرش)
	_ring(slab, z - BEVEL_H, slab, 0.0, 0.0, false)
	var prev := slab
	var prev_z := z - BEVEL_H
	var prev_a := 0.0
	for a in BEVEL_ANGLES:
		var th := deg_to_rad(a)
		var cur := _slab_outline(BEVEL_I * (1.0 - cos(th)))
		var cz := z - BEVEL_H * (1.0 - sin(th))
		_ring(prev, prev_z, cur, cz, sin(deg_to_rad((prev_a + a) * 0.5)), false)
		prev = cur
		prev_z = cz
		prev_a = a

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

	# ---- جدول (بلوک جدا و بلندتر از آجرفرش؛ روی آجرفرش کشیده می‌شود تا پشتش را بپوشاند)
	var cslab := _curb_outline(0.0)
	var ctop := _curb_outline(BEVEL_I)
	_ring(cslab, zc - BEVEL_H, cslab, 0.0, 0.0, true)
	var cprev := cslab
	var cprev_z := zc - BEVEL_H
	var cprev_a := 0.0
	for a in BEVEL_ANGLES:
		var th2 := deg_to_rad(a)
		var ccur := _curb_outline(BEVEL_I * (1.0 - cos(th2)))
		var ccz := zc - BEVEL_H * (1.0 - sin(th2))
		_ring(cprev, cprev_z, ccur, ccz, sin(deg_to_rad((cprev_a + a) * 0.5)), true)
		cprev = ccur
		cprev_z = ccz
		cprev_a = a
	_draw_curb_top(ctop, zc)


## خط دور دال (گرید) با «فاصله‌ی inset» از لبه‌ی بیرونی. گوشه‌های عقب گرد، گوشه‌های جلو (کنار جدول) تیز.
## لبه‌ی جلویی دال (چسبیده به جدول) inset نمی‌گیرد.
func _slab_outline(inset: float) -> PackedVector2Array:
	var r := maxf(CORNER_R - inset, 0.02)
	return _rrect_c(_sx0 + inset, _sy0 + inset, _sx1 - inset, _cy0, r, r, 0.0, 0.0)


## خط دور جدول (گرید). گوشه‌های جلو گرد، گوشه‌های عقب (چسبیده به دال) تیز.
## لبه‌ی عقبی جدول inset نمی‌گیرد (از دوربین دیده نمی‌شود).
func _curb_outline(inset: float) -> PackedVector2Array:
	var r := maxf(CURB_R - inset, 0.02)
	return _rrect_c(_sx0 + inset, _cy0, _sx1 - inset, _sy1 - inset, 0.0, 0.0, r, r)


# ---------------------------------------------------------------- خیابان

## خیابان: آسفالت هم‌طول پیاده‌رو، ROAD_LANES لاین، خط‌چین سفید وسط و دو خط ممتد باریک کنار لبه‌ی دور و لبه‌ی نزدیک (کنار جدول).
## از زیر جدول شروع می‌شود (جدول رویش کشیده می‌شود)؛ فقط دو گوشه‌ی دور گرد است.
func _draw_road() -> void:
	var y0 := _sy1 - 0.03
	var asphalt := _rrect_c(_sx0, y0, _sx1, _ry1, 0.0, 0.0, ROAD_R, ROAD_R)
	draw_colored_polygon(_proj(asphalt, 0.0), ROAD_COLOR)

	# خط‌چین وسط (بین لاین‌ها)، وسط‌چین شده در طول خیابان
	var mid_y := _sy1 + ROAD_LANE_W * float(ROAD_LANES) / 2.0
	var pitch := DASH_LEN + DASH_GAP
	var length := _sx1 - _sx0
	var n := maxi(1, floori((length - 0.4 + DASH_GAP) / pitch))
	var used := float(n) * pitch - DASH_GAP
	var x := _sx0 + (length - used) / 2.0
	for i in range(n):
		_rect(x, mid_y - DASH_W / 2.0, x + DASH_LEN, mid_y + DASH_W / 2.0, 0.0, ROAD_LINE_COLOR)
		x += pitch

	# خط ممتد کنار لبه‌ی دور خیابان
	var ey := _ry1 - EDGE_LINE_INSET
	_rect(_sx0 + ROAD_R, ey - EDGE_LINE_W, _sx1 - ROAD_R, ey, 0.0, ROAD_LINE_COLOR)

	# خط ممتد کنار لبه‌ی نزدیک خیابان (سمت جدول؛ سمت راست روی صفحه)
	var ny := _sy1 + EDGE_LINE_INSET
	_rect(_sx0 + ROAD_R, ny, _sx1 - ROAD_R, ny + EDGE_LINE_W, 0.0, ROAD_LINE_COLOR)


# ---------------------------------------------------------------- جدول

## رنگ بلوکی که در مختصات gx (گرید) قرار دارد: سبز، سفید، سبز، سفید ... (یکی‌درمیان).
func _curb_color_at(gx: float) -> Color:
	var k := clampi(floori((gx - _sx0) / _blk), 0, _n_blk - 1)
	return CURB_GREEN if k % 2 == 0 else CURB_WHITE


## رویه‌ی جدول: بلوک‌های سبز/سفید بدون هیچ درز؛ بلوک‌ها کمی روی هم می‌افتند تا شکافی نماند.
func _draw_curb_top(top: PackedVector2Array, zc: float) -> void:
	var ov := 0.004
	for k in range(_n_blk):
		var bx0 := _sx0 + float(k) * _blk
		var bx1 := bx0 + _blk
		var blk := PackedVector2Array([
			Vector2(bx0 - ov, _cy0 - 0.01), Vector2(bx1 + ov, _cy0 - 0.01),
			Vector2(bx1 + ov, _sy1 + 0.01), Vector2(bx0 - ov, _sy1 + 0.01),
		])
		_fill_grid_clipped(blk, top, zc, Iso.shade(_curb_color_at((bx0 + bx1) / 2.0), 1.08))


## چندضلعی گرید را با clip (هر دو در مختصات گرید) برش می‌دهد و در ارتفاع z می‌کشد.
func _fill_grid_clipped(poly: PackedVector2Array, clip: PackedVector2Array, z: float, color: Color) -> void:
	var parts: Array = Geometry2D.intersect_polygons(poly, clip)
	for part in parts:
		var pts: PackedVector2Array = part
		if pts.size() >= 3:
			draw_colored_polygon(_proj(pts, z), color)


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


# ---------------------------------------------------------------- دیواره‌ها

## نوار بین دو خط هم‌تعداد: a در ارتفاع za و b در ارتفاع zb. برای هر ضلعِ رو به دوربین یک چهارضلعی؛
## رنگ نرم بین وجه چپِ روشن و وجه راستِ تیره. w (۰..۱) = چقدر رو به بالا است (۰ = دیواره‌ی عمودی، ۱ = رویه).
## curb = false: بتن ساده (دال). curb = true: رنگ بلوک‌های جدول؛ ضلع صاف جلو به تکه‌های بلوک شکسته می‌شود
## تا هر بلوک رنگ خودش را بگیرد (بدون درز).
func _ring(a: PackedVector2Array, za: float, b: PackedVector2Array, zb: float, w: float, curb: bool) -> void:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in a:
		lo = lo.min(p)
		hi = hi.max(p)
	var c := (lo + hi) / 2.0
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
		var shade_f := lerpf(base, 1.12, w)
		var mid := (a[i] + a[j]) / 2.0
		if not curb:
			_ring_piece(a[i], a[j], za, b[i], b[j], zb, Iso.shade(CURB_COLOR, shade_f))
		elif absf(d.y) < 0.0001 and absf(d.x) > _blk:
			# ضلع صاف جلو: تکه‌تکه با رنگ هر بلوک
			var x_lo := minf(a[i].x, a[j].x)
			var x_hi := maxf(a[i].x, a[j].x)
			var e := x_lo
			while e < x_hi - 0.00001:
				var nb := minf(_sx0 + (floorf((e - _sx0) / _blk + 0.00001) + 1.0) * _blk, x_hi)
				var t0 := (e - a[i].x) / d.x
				var t1 := (nb - a[i].x) / d.x
				_ring_piece(
					a[i].lerp(a[j], t0), a[i].lerp(a[j], t1), za,
					b[i].lerp(b[j], t0), b[i].lerp(b[j], t1), zb,
					Iso.shade(_curb_color_at((e + nb) / 2.0), shade_f)
				)
				e = nb
		else:
			# دو سر و کمان‌های گوشه‌ی جلو: رنگ بلوکِ همان نقطه
			_ring_piece(a[i], a[j], za, b[i], b[j], zb, Iso.shade(_curb_color_at(mid.x), shade_f))


## یک چهارضلعی از نوار _ring: a0-a1 در ارتفاع za، b0-b1 در ارتفاع zb.
func _ring_piece(a0: Vector2, a1: Vector2, za: float, b0: Vector2, b1: Vector2, zb: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		_iso.project(a0.x, a0.y, za), _iso.project(a1.x, a1.y, za),
		_iso.project(b1.x, b1.y, zb), _iso.project(b0.x, b0.y, zb),
	]), color)


## مستطیل گرد در فضای گرید (نقطه‌ها پشت‌سرهم دور مستطیل). segs = تعداد تکه‌ی هر کمان.
static func _rrect(x0: float, y0: float, x1: float, y1: float, r: float, segs: int = ARC_SEGS) -> PackedVector2Array:
	return _rrect_c(x0, y0, x1, y1, r, r, r, r, segs)


## مستطیل با شعاع جداگانه برای هر گوشه: بالا-چپ، بالا-راست، پایین-راست، پایین-چپ (در فضای گرید).
## شعاع صفر = گوشه‌ی تیز (فقط یک نقطه). تعداد نقطه‌ها فقط به این بستگی دارد که کدام گوشه‌ها صفرند.
static func _rrect_c(x0: float, y0: float, x1: float, y1: float, r_tl: float, r_tr: float, r_br: float, r_bl: float, segs: int = ARC_SEGS) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var lim := minf(x1 - x0, y1 - y0) / 2.0
	var corners := [
		[Vector2(x0, y0), Vector2(1.0, 1.0), PI, r_tl],
		[Vector2(x1, y0), Vector2(-1.0, 1.0), PI * 1.5, r_tr],
		[Vector2(x1, y1), Vector2(-1.0, -1.0), 0.0, r_br],
		[Vector2(x0, y1), Vector2(1.0, -1.0), PI * 0.5, r_bl],
	]
	for corner in corners:
		var p: Vector2 = corner[0]
		var dir: Vector2 = corner[1]
		var a0: float = corner[2]
		var rr: float = minf(float(corner[3]), lim)
		if rr <= 0.0001:
			pts.append(p)
			continue
		var c := p + dir * rr
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
