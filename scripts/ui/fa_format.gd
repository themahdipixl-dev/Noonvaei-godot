class_name FaFormat
extends RefCounted
## Persian number formatting. Port of src/ui/format.js

const FA_DIGITS: Array[String] = ["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"]

## [threshold, unit name]
const UNITS := [
	[1e12, "تریلیون"],
	[1e9, "میلیارد"],
	[1e6, "میلیون"],
	[1e3, "هزار"],
]


## Replaces Latin digits with Persian digits.
static func to_fa(value: Variant) -> String:
	var out := ""
	for ch in str(value):
		if ch >= "0" and ch <= "9":
			out += FA_DIGITS[int(ch)]
		else:
			out += ch
	return out


static func format_number(n: float) -> String:
	if n < 10000.0:
		return to_fa(int(floor(n)))
	for unit in UNITS:
		var v: float = unit[0]
		if n >= v:
			var short := ("%.1f" % (n / v)).replace(".", "٫")
			return to_fa(short) + " " + String(unit[1])
	return to_fa(int(floor(n)))


## Full number with thousands separators (۱۲۴,۵۰۰). Falls back to the short form for huge values.
static func format_grouped(n: float) -> String:
	if n >= 1e9:
		return format_number(n)
	var digits := str(int(floor(n)))
	var out := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return to_fa(out)


static func format_rate(n: float) -> String:
	if n < 100.0:
		return to_fa(("%.1f" % n).replace(".", "٫"))
	return format_number(n)
