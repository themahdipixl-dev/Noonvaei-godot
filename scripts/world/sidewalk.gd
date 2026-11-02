class_name Sidewalk
extends Node2D
## پیاده‌رو جلوی مغازه: آجر خاکستری (چیدمان حصیری) + نوار زردِ وسط (کاشی راهنمای نابینایان).
## لبه‌ها گرد و نرم‌اند (مثل بقیه‌ی محیط بازی): دال با گوشه‌ی گرد، حاشیه‌ی سنگی دور تا دور و سایه‌ی ملایم روی زمین.
##
## اندازه‌ها بر حسب «واحد» هستند. یک واحد = عرض یک کاشی زرد (UNIT خانه‌ی گرید).
## عرض پیاده‌رو (قسمت آجرفرش) = WIDTH_UNITS واحد = 5 تا کاشی زرد کنار هم:
##   2 ردیف خاکستری | 1 ردیف زرد (وسط) | 2 ردیف خاکستری
## خطوط برجسته‌ی کاشی زرد موازی طول نوار هستند.
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

## حاشیه‌ی سنگی دور آجرفرش (خانه‌ی گرید).
const RIM := 0.07
## شعاع گوشه‌های بیرونی دال (خانه‌ی گرید).
const CORNER_R := 0.22
## ارتفاع دال از زمین (px).
const CURB_H := 6.0
## فاصله‌ی درز بین آجرها (خانه‌ی گرید).
const JOINT := 0.014
## تعداد تکه‌ی هر کمان گوشه (بیشتر = گردتر).
const ARC_SEGS := 8

const BRICK_COLOR := Color("#a9acaf")
const JOINT_COLOR := Color("#7d8185")
const YELLOW_COLOR := Color("#e6bf5f")
const YELLOW_RIB_COLOR := Color("#f6df9a")
const CURB_COLOR := Color("#cfc9bd")
const SHADOW_COLOR := Color(0.25, 0.18, 0.08, 0.12)

var _iso: Iso
## آجرفرش (گرید)
var _px0 := 0.0
var _px1 := 0.0
var _py0 := 0.0
var _py1 := 0.0
## دال کامل = آجرفرش + حاشیه (گرید)
var _sx0 := 0.0
var _sx1 := 0.0
var _sy0 := 0.0
var _sy1 := 0.0
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
	_sy1 = _py1 + RIM
	queue_redraw()


## عرض آجرفرش بر حسب خانه‌ی گرید.
func width_tiles() -> float:
	return float(WIDTH_UNITS) * UNIT


func _draw() -> void:
	if _iso == null:
		return
	var z := CURB_H
	var slab := _rrect(_sx0, _sy0, _sx1, _sy1, CORNER_R)
	var paved := _rrect(_px0, _py0, _px1, _py1, maxf(CORNER_R - RIM, 0.02))

	# سایه‌ی ملایم روی زمین (کمی به سمت جلو/راست)
	draw_colored_polygon(_proj(_rrect(_sx0 + 0.03, _sy0 + 0.06, _sx1 + 0.05, _sy1 + 0.09, CORNER_R), 0.0), SHADOW_COLOR)

	# دیواره‌ی گرد دال (فقط قسمت‌هایی که رو به دوربین‌اند)
	_draw_skirt(slab, z)

	# رویه‌ی سنگی + آجرفرش
	draw_colored_polygon(_proj(slab, z), Iso.shade(CURB_COLOR, 1.12))
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


## یک کاشی زردِ راهنما: بدنه + ۴ شیار برجسته‌ی موازیِ طول نوار.
func _draw_yellow_tile(gx: float, gy: float, z: float) -> void:
	var h := JOINT / 2.0
	_rect(gx + h, gy + h, gx + UNIT - h, gy + UNIT - h, z, YELLOW_COLOR)
	var rib_w := 0.028
	for k in range(4):
		var cy := gy + UNIT * (float(k) + 0.5) / 4.0
		_rect(gx + h + 0.015, cy - rib_w / 2.0, gx + UNIT - h - 0.015, cy + rib_w / 2.0, z, YELLOW_RIB_COLOR)


## آجر: اگر نزدیک گوشه‌ی گرد باشد با شکل آجرفرش بریده می‌شود تا بیرون نزند.
func _brick(x0: float, y0: float, x1: float, y1: float, z: float, color: Color, paved: PackedVector2Array) -> void:
	var rin := maxf(CORNER_R - RIM, 0.02)
	var near_x := x0 < _px0 + rin or x1 > _px1 - rin
	var near_y := y0 < _py0 + rin or y1 > _py1 - rin
	if not (near_x and near_y):
		_rect(x0, y0, x1, y1, z, color)
		return
	var r := PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)])
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


## دیواره‌ی دال: برای هر ضلعِ رو به دوربین یک چهارضلعی؛ رنگ نرم بین وجه چپِ روشن و وجه راستِ تیره.
func _draw_skirt(poly: PackedVector2Array, z: float) -> void:
	var c := Vector2((_sx0 + _sx1) / 2.0, (_sy0 + _sy1) / 2.0)
	var n := poly.size()
	for i in range(n):
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var d := b - a
		if d.length() < 0.0001:
			continue
		var nrm := Vector2(d.y, -d.x).normalized()
		if nrm.dot((a + b) / 2.0 - c) < 0.0:
			nrm = -nrm
		if nrm.x + nrm.y <= 0.001:
			continue  # پشت دال، دیده نمی‌شود
		var t := clampf((nrm.y - nrm.x) * 0.5 + 0.5, 0.0, 1.0)
		var color := Iso.shade(CURB_COLOR, lerpf(0.68, 0.9, t))
		draw_colored_polygon(PackedVector2Array([
			_iso.project(a.x, a.y, z), _iso.project(b.x, b.y, z),
			_iso.project(b.x, b.y, 0.0), _iso.project(a.x, a.y, 0.0),
		]), color)


## مستطیل گرد در فضای گرید (نقطه‌ها پشت‌سرهم دور مستطیل).
static func _rrect(x0: float, y0: float, x1: float, y1: float, r: float) -> PackedVector2Array:
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
		for s in range(ARC_SEGS + 1):
			var a := a0 + (PI * 0.5) * float(s) / float(ARC_SEGS)
			pts.append(c + Vector2(cos(a), sin(a)) * rr)
	return pts


## چندضلعی گرید -> مختصات دنیا در ارتفاع z px.
func _proj(poly: PackedVector2Array, z: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		out.append(_iso.project(p.x, p.y, z))
	return out
