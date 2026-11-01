# نانوایی سنگک (Noonvaei) — نسخهٔ Godot

مهاجرت بازی idle/tycoon «Iran Bakery Tycoon» از **Expo / React Native** به **Godot 4**.

- ریپوی مبدأ (React Native): [`themahdipixl-dev/Noonvaei`](https://github.com/themahdipixl-dev/Noonvaei)
- ریپوی مقصد (همین ریپو): `themahdipixl-dev/Noonvaei-godot`

> ⚠️ **وضعیت تست:** کدها در این مرحله «ترجمهٔ ایستا» هستند و داخل ادیتور Godot اجرا/تست **نشده‌اند**. اولین بار که پروژه را باز می‌کنید ممکن است چند خطا/هشدار کوچک ببینید؛ لطفاً خروجی Output/Debugger را بفرستید تا در بخش بعد اصلاح شود.

---

## برنامهٔ مهاجرت (۴ بخش)

پروژهٔ مبدأ حدود ۳۱ فایل دارد. برای اینکه هر مرحله قابل اجرا و بررسی باشد، به ۴ بخش تقسیم شد:

| بخش | محتوا | فایل‌های RN | وضعیت |
|---|---|---|---|
| **۱** | بنیاد پروژه، تنظیمات، منطق بازی (اقتصاد/ذخیره)، ابزارهای کمکی UI | `app.json`، `package.json`، `config/*`، `game/*`، `ui/format.js`، `ui/theme.js`، `ui/Fonts.js` | ✅ **انجام شد** |
| **۲** | دنیای بازی: نقشه، دوربین (pan/zoom)، ایزومتریک، نانوایی | `scene/*`، `world/WorldMap.js`، `WorldScene.js`، `Bakery.js`، `worldConfig.js`، `useWorldCamera.js` | ⏳ بعدی |
| **۳** | رابط کاربری: HUD، نوار پایین، پنل ارتقا، کارت آفلاین و سرهم‌کردن صحنهٔ اصلی (معادل `App.js`) | `ui/*` (Hud، BottomBar، UpgradePanel، OfflineCard، ComingSoon، Background، TopGradient، Icons) + `App.js` | ⏳ |
| **۴** | شخصیت‌های متحرک: شاطر و ماشین + فیزیک ماشین، خروجی اندروید، مرتب‌سازی نهایی | `world/BakerWalker.js`، `CarDriver.js`، `carPhysics.js` | ⏳ |

---

## بخش ۱ — چه کارهایی انجام شد

### ۱. ساخت اسکلت پروژهٔ Godot
- `project.godot` ساخته شد؛ معادل `app.json`:
  - حالت **portrait** (`window/handheld/orientation=1`)
  - رزولوشن مرجع `1080×1920` با `stretch mode = canvas_items` و `aspect = expand` (برای گوشی‌های با نسبت‌های مختلف)
  - رندرر `gl_compatibility` (سازگار با اکثر گوشی‌های اندروید)
  - شبیه‌سازی لمس با ماوس (`emulate_touch_from_mouse`) برای تست روی کامپیوتر
  - رنگ پس‌زمینهٔ پیش‌فرض همان سبز `#b9d98f` در `App.js`
- `.gitignore`، `icon.svg` (آیکن موقت)

### ۲. ترجمهٔ config
| React Native | Godot |
|---|---|
| `src/config/balance.js` | `scripts/config/balance.gd` (`class_name Balance`) |
| `src/config/strings.js` | `scripts/config/strings.gd` (`class_name Strings`) |

تمام اعداد balance و متن‌های فارسی دقیقاً مثل نسخهٔ اصلی منتقل شد. کلیدها از camelCase به `UPPER_SNAKE_CASE` تبدیل شدند (مثلاً `STRINGS.perSec` ← `Strings.PER_SEC`).

### ۳. ترجمهٔ منطق بازی
| React Native | Godot | توضیح |
|---|---|---|
| `game/economy.js` | `scripts/game/economy.gd` (`class_name Economy`) | توابع خالص `static`، بدون نود و ذخیره |
| `game/storage.js` (AsyncStorage) | `scripts/game/storage.gd` (`class_name Storage`) | با `FileAccess` + JSON در `user://bakery_save.json` |
| `game/state.js` (reducer) + `game/useGame.js` (hook) | `scripts/game/game_state.gd` (**Autoload با نام `Game`**) | یک singleton که state، tick، ذخیره‌سازی و lifecycle را نگه می‌دارد |

معادل‌سازی مفاهیم React در Godot:

| React | Godot |
|---|---|
| `useReducer` + `dispatch` | متغیرهای عضو + متدهای ساده (`Game.upgrade()`، `Game.dismiss_offline()`) |
| re-render | سیگنال‌ها: `Game.changed` و `Game.offline_report_changed` |
| `setInterval` (tick هر ۲۵۰ms / save هر ۵s) | دو نود `Timer` |
| `AppState.addEventListener` | `_notification()` با `NOTIFICATION_APPLICATION_PAUSED/RESUMED`، `FOCUS_IN/OUT`، `WM_CLOSE_REQUEST` |
| `useMemo` (`info`, `costs`) | `_recompute()` که فقط هنگام تغییر سطح‌ها صدا زده می‌شود |

رفتارهای حفظ‌شده: درآمد = `min(مشتری، فروش، نان) × قیمت`، گلوگاه (bottleneck)، درآمد آفلاین (آستانه ۱۰ثانیه، سقف ۸ساعت، بازده ۵۰٪)، sanitize ذخیره، مهاجرت ذخیرهٔ v1 به v2، ذخیره بلافاصله بعد از ارتقا.

### ۴. ابزارهای کمکی UI
| React Native | Godot |
|---|---|
| `ui/theme.js` | `scripts/ui/palette.gd` (`class_name Palette`) |
| `ui/format.js` | `scripts/ui/fa_format.gd` (`class_name FaFormat`): `to_fa`، `format_number`، `format_grouped`، `format_rate` |
| `ui/Fonts.js` | `scripts/ui/app_fonts.gd` (`class_name AppFonts`) |

### ۵. صحنهٔ تست (موقت)
`scenes/main.tscn` + `scripts/main.gd` فقط برای اطمینان از درستی منطق ساخته شده: موجودی خودکار زیاد می‌شود، ۴ دکمهٔ ارتقا هزینه و سطح را نشان می‌دهند، گلوگاه مشخص است و پیام آفلاین نمایش داده می‌شود. این صحنه در بخش ۳ با صحنهٔ اصلی (معادل `App.js`) جایگزین می‌شود.

---

## تفاوت‌های عمدهٔ طراحی نسبت به نسخهٔ RN

- **زمان بر حسب ثانیه است**، نه میلی‌ثانیه (`Time.get_unix_time_from_system()`). ذخیرهٔ قدیمی RN قابل انتقال مستقیم نیست (موتور و محل ذخیره فرق دارد)، ولی فرمت JSON همان کلیدها را دارد.
- **فونت‌ها** دیگر از اینترنت دانلود نمی‌شوند؛ داخل پروژه قرار می‌گیرند (بخش بعد را ببینید).
- **ایموجی آیکن‌ها** (🪟 🧾 🔥 🏮) فعلاً فقط در `Strings.SECTIONS` نگه داشته شده‌اند؛ فونت پیش‌فرض Godot ایموجی را مطمئن نشان نمی‌دهد، پس در بخش ۳ با تکسچر/آیکن جایگزین می‌شوند.
- **متن فارسی:** برای هر `Label` مقدار `language = "fa"` گذاشته شده است. موتور متن پیشرفتهٔ Godot (TextServer Advanced) شکل‌دهی حروف عربی/فارسی را انجام می‌دهد.
- پکیج‌های npm (`expo`, `react-native-svg`, `reanimated`, `gesture-handler`, …) در Godot معادل مستقیم لازم ندارند: SVG ← `_draw()`/Polygon2D، reanimated ← Tween/`_process`، gesture-handler ← `InputEventScreenTouch/Drag`.

---

## کارهای دستی لازم از طرف شما

1. **Godot 4.3 یا جدیدتر** را نصب کنید و پوشهٔ پروژه را باز کنید (بار اول، ادیتور `class_name`ها را اسکن می‌کند — حتماً یک بار در ادیتور باز شود، نه فقط خط فرمان).
2. **فونت‌ها را اضافه کنید:** فایل‌های `.ttf` را از ریپوی `themahdipixl-dev/Assets` در `assets/fonts/` بگذارید (فهرست نام‌ها در `assets/fonts/README.md`). فایل باینری بود و از این ابزار قابل کامیت نبود.
3. صحنهٔ اصلی (`scenes/main.tscn`) را اجرا کنید (F5).

### چک‌لیست تست بخش ۱
- [ ] موجودی هر ثانیه ~۱ سکه زیاد می‌شود (سطح ۱: `min(1.0, 1.5, 1.2) × 1`)
- [ ] با ۱۵ سکه دکمهٔ ویترین فعال می‌شود و بعد از خرید، سطح و هزینه عوض می‌شود
- [ ] گلوگاه روی ضعیف‌ترین بخش (ویترین) نشان داده می‌شود
- [ ] بازی را ببندید و بعد از بیش از ۱۰ ثانیه باز کنید → پیام «خوش آمدی، شاطر!» با درآمد آفلاین
- [ ] اعداد و حروف فارسی درست و راست‌به‌چپ نمایش داده می‌شوند

---

## ساختار فعلی پروژه

```
Noonvaei-godot/
├── project.godot
├── icon.svg
├── assets/fonts/            # فونت‌ها را اینجا بگذارید
├── scenes/
│   └── main.tscn            # صحنهٔ تست موقت (بخش ۱)
└── scripts/
    ├── main.gd
    ├── config/  balance.gd, strings.gd
    ├── game/    economy.gd, storage.gd, game_state.gd (Autoload: Game)
    └── ui/      palette.gd, fa_format.gd, app_fonts.gd
```

## بخش بعدی (۲)
دنیای بازی: `worldConfig`، `iso` و `environmentAssets` (تبدیل مختصات ایزومتریک و دارایی‌های محیط)، `WorldMap` / `WorldScene` / `Bakery` و دوربین با pan/zoom لمسی (`useWorldCamera`).
