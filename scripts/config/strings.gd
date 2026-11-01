class_name Strings
extends RefCounted
## All UI strings (Persian). Port of src/config/strings.js
## Keys were converted from camelCase to UPPER_SNAKE_CASE.

const LOADING := "در حال بارگذاری..."
const MONEY := "موجودی"
const PER_SEC := "درآمد در ثانیه"
const PER_SEC_SHORT := "در ثانیه"
const LEVEL := "سطح نانوایی"
const UPGRADE := "ارتقا"
const COST := "هزینه"
const WELCOME_BACK := "خوش آمدی، شاطر!"
const OFFLINE_EARNED := "در نبودت نانوایی این مقدار درآمد داشت:"
const AWAY := "مدت غیبت"
const OK := "باشه"
const HOURS := "ساعت"
const MINUTES := "دقیقه"
const TITLE := "نانوایی سنگک"
const NEXT := "سطح بعدی"
const BOTTLENECK := "گلوگاه"
const SECTION_LEVEL := "سطح"
const COMING_SOON := "به‌زودی..."
const DAILY_MISSION := "ماموریت روزانه"
const SEASON_PASS := "پس فصل"
const CITIES := "شهرها"

## Bottom tab bar labels.
const TABS := {
	"shop": "فروشگاه",
	"cards": "کارت‌ها",
	"home": "خانه",
	"upgrade": "ارتقا",
	"minigames": "مینی‌گیم‌ها",
}

## The 4 sections of the bakery.
## NOTE: 'icon' keeps the original emoji for reference; Part 3 (UI) replaces them with textures.
const SECTIONS := {
	"vitrin":   {"name": "ویترین",     "sub": "مشتری", "icon": "🪟"},
	"pishkhan": {"name": "پیشخوان",    "sub": "فروش",  "icon": "🧾"},
	"tanoor":   {"name": "تنور و حمل", "sub": "تولید", "icon": "🔥"},
	"decor":    {"name": "دکور",       "sub": "پول اضافه برای هر مشتری", "icon": "🏮"},
}
