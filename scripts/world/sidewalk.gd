class_name Sidewalk
extends Node2D
## پیاده‌رو جلوی مغازه: کاشی/آجر خاکستری (چیدمان حصیری) + نوار زردِ وسط (کاشی راهنمای نابینایان).
##
## اندازه‌ها بر حسب «واحد» هستند. یک واحد = عرض یک کاشی زرد (UNIT خانه‌ی گرید).
## عرض پیاده‌رو = WIDTH_UNITS واحد = 5 تا کاشی زرد کنار هم:
##   2 ردیف خاکستری | 1 ردیف زرد (وسط) | 2 ردیف خاکستری
##
## جای پیاده‌رو: چسبیده به لبه‌ی ورودی مغازه (لبه‌ی gy بزرگ‌تر = سمت شیشه‌های ورودی، پایین-چپ صفحه)،
## به‌اندازه‌ی عرض مغازه + SIDE_MARGIN خانه از هر طرف. طول کوتاه است؛ فقط یک تکه جلوی مغازه.
##
## همه چیز با _draw() کشیده می‌شود (مثل زمین در WorldScene): یک‌بار کشیده و کش می‌شود، هزینه‌ی هر فریم ندارد.
## رنگ آجرها با seed ثابت کمی متفاوت است تا یکنواخت نباشد (هر بار همان ظاهر).

## عرض یک کاشی زرد، بر حسب خانه‌ی گرید.
const UNIT := 0.2
## عرض کل پیاده‌رو بر حسب واحد (تعداد کاشی‌های زرد).
const WIDTH_UNITS := 5
## ردیف زرد کدام واحد است (از 0 شروع می‌شود): 0 1 [2] 3 4 = وسط.
const YELLOW_UNIT_INDEX := 2
## پیاده‌رو از هر طرف مغازه این‌قدر (خانه‌ی گرید) بلندتر است.
const SIDE_MARGIN := 1.0

## جدول (سنگ لبه‌ی خیابان): عرض بر حسب خانه‌ی گرید، ارتفاع بر حسب px.
const CURB_W := 0.08
const CURB_H := 5.0
## فاصله‌ی درز بین آجرها (خانه‌ی گرید).
const JOINT := 0.014

const BRICK_COLOR := Color("#a9acaf")
const JOINT_COLOR := Color("#7d8185")
const YELLOW_COLOR := Color("#e6bf5f")
const YELLOW_RIB_COLOR := Color("#f6df9a")
const CURB_COLOR := Color("#c9c3b8")

var _iso: Iso
## گوشه‌های پیاده‌رو (گرید): x0..x1 = طول، y0..y1 = عرض (y0 کنار مغازه، y1 سمت خیابان).
var _x0 := 0.0
var _x1 := 0.0
var _y0 := 0.0
var _y1 := 0.0
var _n_len := 0


## lot_gx, lot_gy = گوشه‌ی بالا-چپِ زمین مغازه (گرید)، lot_size = ضلع زمین (خانه).
func setup(projector: Iso, lot_gx: float, lot_gy: float, lot_size: float) -> void:
	_iso = projector
	_x0 = lot_gx - SIDE_MARGIN
	_x1 = lot_gx + lot_size + SIDE_MARGIN
	_y0 = lot_gy + lot_size
	_y1 = _y0 + float(WIDTH_UNITS) * UNIT
	_n_len = maxi(1, roundi((_x1 - _x0) / UNIT))
	_x1 = _x0 + float(_n_len) * UNIT  # طول دقیقاً مضرب صحیحی از UNIT
	queue_redraw()


## عرض پیاده‌رو بر حسب خانه‌ی گرید (بدون جدول).
func width_tiles() -> float:
	return float(WIDTH_UNITS) * UNIT


func _draw() -> void:
	if _iso == null:
		return
	var z := CURB_H
	var y_curb := _y1 + CURB_W

	# --- کناره‌های سه‌بعدی (فقط دو وجهی که دیده می‌شوند) ---
	var cols := Iso.box_colors(CURB_COLOR)
	# وجه سمت خیابان (+gy): پایین-چپ
	_side(Vector3(_x0, y_curb, z), Vector3(_x1, y_curb, z), Vector3(_x1, y_curb, 0.0), Vector3(_x0, y_curb, 0.0), cols["left"])
	# وجه انتهای راست (+gx): پایین-راست
	_side(Vector3(_x1, _y0, z), Vector3(_x1, y_curb, z), Vector3(_x1, y_curb, 0.0), Vector3(_x1, _y0, 0.0), cols["right"])

	# --- رویه: اول رنگ درز، بعد آجرها روی آن ---
	_quad(_x0, _y0, _x1, _y1, z, JOINT_COLOR)

	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in range(_n_len):
		var gx := _x0 + float(i) * UNIT
		for j in range(WIDTH_UNITS):
			var gy := _y0 + float(j) * UNIT
			if j == YELLOW_UNIT_INDEX:
				_draw_yellow_tile(gx, gy, z)
			else:
				_draw_weave_cell(gx, gy, z, (i + j) % 2 == 0, rng)

	# --- سنگ لبه‌ی خیابان (روی رویه) ---
	_quad(_x0, _y1, _x1, y_curb, z, cols["top"])


## یک خانه‌ی UNIT×UNIT از چیدمان حصیری: دو آجر کنار هم؛ جهت آجرها خانه‌به‌خانه عوض می‌شود.
func _draw_weave_cell(gx: float, gy: float, z: float, stacked_along_y: bool, rng: RandomNumberGenerator) -> void:
	var h := JOINT / 2.0
	var half := UNIT / 2.0
	for k in range(2):
		var color := Iso.shade(BRICK_COLOR, rng.randf_range(0.93, 1.07))
		if stacked_along_y:
			var yy := gy + float(k) * half
			_quad(gx + h, yy + h, gx + UNIT - h, yy + half - h, z, color)
		else:
			var xx := gx + float(k) * half
			_quad(xx + h, gy + h, xx + half - h, gy + UNIT - h, z, color)


## یک کاشی زرد راهنما: بدنه + ۴ شیار برجسته‌ی عرضی (عمود بر راستای نوار).
func _draw_yellow_tile(gx: float, gy: float, z: float) -> void:
	var h := JOINT / 2.0
	_quad(gx + h, gy + h, gx + UNIT - h, gy + UNIT - h, z, YELLOW_COLOR)
	var rib_w := 0.028
	var pad := 0.03
	for k in range(4):
		var cx := gx + UNIT * (float(k) + 0.5) / 4.0
		_quad(cx - rib_w / 2.0, gy + pad, cx + rib_w / 2.0, gy + UNIT - pad, z, YELLOW_RIB_COLOR)


## مستطیل روی زمین (گرید) در ارتفاع z px.
func _quad(ax: float, ay: float, bx: float, by: float, z: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		_iso.project(ax, ay, z), _iso.project(bx, ay, z),
		_iso.project(bx, by, z), _iso.project(ax, by, z),
	]), color)


## وجه عمودی؛ هر نقطه = Vector3(gx, gy, z px).
func _side(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		_iso.project(p0.x, p0.y, p0.z), _iso.project(p1.x, p1.y, p1.z),
		_iso.project(p2.x, p2.y, p2.z), _iso.project(p3.x, p3.y, p3.z),
	]), color)
