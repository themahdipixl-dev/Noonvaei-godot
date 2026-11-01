# نانوایی سنگک (Noonvaei) — نسخهٔ Godot

مهاجرت بازی idle/tycoon «Iran Bakery Tycoon» از **Expo / React Native** به **Godot 4**.

- ریپوی مبدأ (React Native): [`themahdipixl-dev/Noonvaei`](https://github.com/themahdipixl-dev/Noonvaei)
- ریپوی مقصد (همین ریپو): `themahdipixl-dev/Noonvaei-godot`

> ⚠️ **وضعیت تست:** کدها «ترجمهٔ ایستا» هستند و داخل ادیتور Godot اجرا/تست **نشده‌اند**. اولین بار که پروژه را باز می‌کنید ممکن است چند خطا/هشدار کوچک ببینید؛ لطفاً خروجی Output/Debugger را برای ما بفرستید تا در بخش بعد اصلاح شود.

---

## برنامهٔ مهاجرت (۴ بخش)

پروژهٔ مبدأ حدود ۳۱ فایل دارد. برای اینکه هر مرحله قابل اجرا و بررسی باشد، به ۴ بخش تقسیم شد:

| بخش | محتوا | فایل‌های RN | وضعیت |
|---|---|---|---|
| **۱** | بنیاد پروژه، تنظیمات، منطق بازی (اقتصاد/ذخیره)، ابزارهای کمکی UI | `app.json`، `package.json`، `config/*`، `game/*`، `ui/format.js`، `ui/theme.js`، `ui/Fonts.js` | ✅ **انجام شد** |
| **۲** | دنیای بازی: نقشه، دوربین (pan/zoom)، ایزومتریک، نانوایی | `scene/*`، `world/WorldMap.js`، `WorldScene.js`، `Bakery.js`، `worldConfig.js`، `useWorldCamera.js` | ✅ **انجام شد** |
| **۳** | رابط کاربری: HUD، نوار پایین، پنل ارتقا، کارت آفلاین و سرهم‌کردن صحنهٔ اصلی (معادل `App.js`) | `ui/*` (Hud، BottomBar، UpgradePanel، OfflineCard، ComingSoon، Background، TopGradient، Icons) + `App.js` | ⏳ بعدی |
| **۴** | شخصیت‌های متحرک: شاطر و ماشین + فیزیک ماشین، خروجی اندروید، مرتب‌سازی نهایی | `world/BakerWalker.js`، `CarDriver.js`، `carPhysics.js` | ⏳ |

---

## کارهای دستی لازم از طرف شما

1. **Godot 4.3 یا جدیدتر** را نصب کنید و پوشهٔ پروژه را **داخل خود ادیتور** باز کنید (بار اول ادیتور `class_name`ها را اسکن می‌کند).
2. **فونت‌ها** → `assets/fonts/` (نام‌ها در `assets/fonts/README.md`).
3. **تصویرهای محیط** → `assets/environment/` و بقیه (نام‌ها و مسیرها در `assets/README.md`). برای بخش ۲ فقط ۴ فایل `bakery_front`، `bakery_belt`، `bakery_cutter`، `bakery_bread_1` لازم است.
4. صحنهٔ اصلی را اجرا کنید (F5).

---

## بخش ۲ — دنیای بازی (انجام شد)

### نگاشت فایل‌ها
| React Native | Godot | توضیح |
|---|---|---|
| `scene/iso.js` | `scripts/scene/iso.gd` (`class_name Iso`) | نگاشت گرید → مختصات صفحه (`project`)، `shade` و `box_colors`. از تابع به کلاس تغییر کرد (همان closure مورد استفادهٔ `makeProjector`) |
| `scene/environmentAssets.js` | `scripts/scene/environment_assets.gd` (`class_name EnvironmentAssets`) | مسیر تصویرها، تابع `get_texture`، `preload_all` (با `ResourceLoader.load_threaded_request`) |
| `world/worldConfig.js` | `scripts/world/world_config.gd` (`class_name WorldConfig`) | همهٔ اعداد منتقل شدند، از جمله `WALKER` و `CARS` که فقط در بخش ۴ استفاده می‌شوند |
| `world/useWorldCamera.js` | `scripts/world/world_camera.gd` (`class_name WorldCamera`) | منطق pan / pinch-zoom (بدون نود؛ فقط محاسبه) |
| `world/WorldMap.js` | `scripts/world/world_map.gd` (`class_name WorldMap`) | کنترل تمام‌صفحه + دریافت لمس + نود `Content` |
| `world/WorldScene.js` | `scripts/world/world_scene.gd` (`class_name WorldScene`) | زمین با `_draw()` + نانوایی + نود `Actors` (جای شاطر و ماشین در بخش ۴) |
| `world/Bakery.js` | `scripts/world/bakery.gd` (`class_name Bakery`) | لایه‌های `Sprite2D` (front → belt → lavash → cutter) |
| `App.js` (بخشی) | `scripts/main.gd` | نمایش نقشه زیر overlay موقت بخش ۱ |

### معادل‌سازی مفاهیم
| React Native | Godot |
|---|---|
| `Animated.View` + `transform` (translate/scale) | یک `Node2D` (`Content`) که `position` و `scale` آن مقداردهی می‌شود |
| `GestureDetector` (Pan + Pinch) | `_gui_input()` روی `WorldMap` با `InputEventScreenTouch` و `InputEventScreenDrag` |
| `useSharedValue` / worklet | متغیرهای سادهٔ `WorldCamera` (نیاز به thread جدا نیست) |
| `react-native-svg` `<Polygon>` | `draw_colored_polygon()` در `_draw()` |
| `<Image>` با `left/top/width/height` | `Sprite2D` با `centered = false`، `position` و `scale` (مثل `resizeMode="stretch"`) |
| `onLayout` | سیگنال `resized` |
| `useMemo` برای projector / ground | یکبار در `WorldScene.setup()` محاسبه می‌شود |

### رفتار دوربین (دقیقاً همان RN)
- محدودهٔ زوم: `0.25` تا `3.5`، توان pinch = `1.4`.
- محدودیت pan: نقشه همیشه داخل صفحه می‌ماند (نیمهٔ قسمتی از محتوا که جا نمی‌شود).
- باز شدن اولیه: دوربین روی مرکز نانوایی (ارتفاع ۴۰px) تنظیم می‌شود.
- وقتی انگشت اول در pinch بلند شود، دوربین تا بالا آمدن همهٔ انگشت‌ها قفل می‌شود (مثل `locked` در JS) تا نپرد.

### چیزهایی که اضافه شد (در نسخهٔ RN نبود)
- **چرخ ماوس و trackpad** برای زوم روی کامپیوتر (برای تست راحت‌تر). کشیدن با ماوس هم کار می‌کند (`emulate_touch_from_mouse`).
- `Iso.unproject()` برای تبدیل مختصات صفحه به گرید (بخش ۴ لازم دارد).
- `Bakery.set_lavash_stage(0..4)`: دادهٔ ۵ مرحلهٔ نان لواش در فایل JS بود ولی فقط مرحله ۱ نمایش داده می‌شد؛ حالا قابل تغییر است.
- **placeholder:** اگر `bakery_front.webp` داخل پروژه نباشد، یک جعبهٔ ایزومتریک زرد نشان داده می‌شود تا بتوانید دوربین را بدون آرت تست کنید.

### تفاوت‌ها
- تصویرها از اینترنت دانلود نمی‌شوند؛ باید داخل پروژه باشند. پارامترهای cache-busting (`?v=3`) حذف شدند.
- نقشه با کد ساخته می‌شود (نه با فایل `.tscn` مستقل)؛ اگر خواستید بعداً به صحنه تبدیل می‌کنیم.
- `main.gd` هنوز موقت است: نقشه + دکمه‌های تست بخش ۱. صحنهٔ اصلی در بخش ۳.

### چک‌لیست تست بخش ۲
- [ ] زمین کرمی لوزی با نانوایی در مرکز دیده می‌شود و دوربین روی نانوایی است
- [ ] کشیدن (ماوس یا انگشت) نقشه را جابه‌جا می‌کند و از کناره‌ها بیرون نمی‌رود
- [ ] چرخ ماوس / pinch دو انگشتی زوم می‌کند و نقطهٔ زیر انگشت/ماوس تقریباً ثابت می‌ماند
- [ ] کشیدن نقشه وقتی انگشت روی دکمه‌های ارتقا شروع شده نقشه را حرکت نمی‌دهد
- [ ] (با تصاویر) لایه‌های front / belt / lavash / cutter دقیقاً روی هم می‌نشینند
- [ ] (با تصاویر) اگر با زوم کم (۰.۲۵) تصویر لرزش/دنده‌دار شد، در Import تصاویر گزینهٔ `Mipmaps > Generate` را روشن کنید

> اگر کشیدن با **انگشت روی گوشی واقعی** کار نکرد (ولی با ماوس کار کرد)، به من بگویید. یکی از نقاطی که ممکن است نیاز به اصلاح داشته باشد همین دریافت لمس در `_gui_input` است.

---

## بخش ۱ — پایه و منطق بازی (انجام شد)

### اسکلت پروژه
`project.godot` معادل `app.json`: حالت portrait، رزولوشن مرجع `1080×1920` با `stretch mode = canvas_items` و `aspect = expand`، رندرر `gl_compatibility`، شبیه‌سازی لمس با ماوس و رنگ پس‌زمینهٔ `#b9d98f`. همچنین `.gitignore` و `icon.svg` (موقت).

### نگاشت فایل‌ها
| React Native | Godot |
|---|---|
| `config/balance.js` | `scripts/config/balance.gd` (`Balance`) |
| `config/strings.js` | `scripts/config/strings.gd` (`Strings`) — کلیدها به `UPPER_SNAKE_CASE` |
| `game/economy.js` | `scripts/game/economy.gd` (`Economy`) — توابع خالص `static` |
| `game/storage.js` (AsyncStorage) | `scripts/game/storage.gd` (`Storage`) — `FileAccess` + JSON در `user://bakery_save.json` |
| `game/state.js` + `game/useGame.js` | `scripts/game/game_state.gd` (**Autoload با نام `Game`**) |
| `ui/theme.js` | `scripts/ui/palette.gd` (`Palette`) |
| `ui/format.js` | `scripts/ui/fa_format.gd` (`FaFormat`) |
| `ui/Fonts.js` | `scripts/ui/app_fonts.gd` (`AppFonts`) |

| React | Godot |
|---|---|
| `useReducer` + `dispatch` | متغیرهای عضو + متدها (`Game.upgrade()`، `Game.dismiss_offline()`) |
| re-render | سیگنال‌ها: `Game.changed` و `Game.offline_report_changed` |
| `setInterval` | نود `Timer` |
| `AppState.addEventListener` | `_notification()` (PAUSED / RESUMED / FOCUS / WM_CLOSE_REQUEST) |
| `useMemo` (`info`, `costs`) | `_recompute()` |

رفتارهای حفظ‌شده: درآمد = `min(مشتری، فروش، نان) × قیمت`، گلوگاه، درآمد آفلاین (آستانه ۱۰ ثانیه، سقف ۸ ساعت، بازده ۵۰٪)، sanitize ذخیره، مهاجرت v1→v2، ذخیره بلافاصله بعد از ارتقا.

### تفاوت‌های طراحی
- **زمان بر حسب ثانیه** است (نه میلی‌ثانیه). ذخیرهٔ قدیمی RN قابل انتقال مستقیم نیست؛ فرمت JSON همان کلیدها را دارد.
- **ایموجی آیکن‌ها** (🪟 🧾 🔥 🏮) فعلاً فقط در `Strings.SECTIONS` هستند؛ فونت پیش‌فرض Godot ایموجی را مطمئن نشان نمی‌دهد؛ در بخش ۳ با تکسچر جایگزین می‌شوند.
- **متن فارسی:** برای هر `Label` مقدار `language = "fa"` گذاشته شده؛ موتور متن Godot شکل‌دهی حروف فارسی را انجام می‌دهد.
- پکیج‌های npm (`expo`, `react-native-svg`, `reanimated`, `gesture-handler`, …) معادل مستقیم لازم ندارند: SVG ← `_draw()`، reanimated ← Tween/`_process`، gesture-handler ← `InputEventScreenTouch/Drag`.

### چک‌لیست تست بخش ۱
- [ ] موجودی هر ثانیه ~۱ سکه زیاد می‌شود (سطح ۱: `min(1.0, 1.5, 1.2) × 1`)
- [ ] با ۱۵ سکه دکمهٔ ویترین فعال می‌شود و بعد از خرید سطح و هزینه عوض می‌شود
- [ ] گلوگاه روی ضعیف‌ترین بخش (ویترین) نشان داده می‌شود
- [ ] بازی را ببندید و بعد از بیش از ۱۰ ثانیه باز کنید → پیام «خوش آمدی، شاطر!» با درآمد آفلاین
- [ ] اعداد و حروف فارسی درست و راست‌به‌چپ نمایش داده می‌شوند

---

## ساختار فعلی پروژه

```
Noonvaei-godot/
├── project.godot
├── icon.svg
├── assets/
│   ├── README.md            # لیست تصاویر لازم
│   └── fonts/               # فونت‌ها را اینجا بگذارید
├── scenes/
│   └── main.tscn            # صحنهٔ موقت (نقشه + overlay تست)
└── scripts/
    ├── main.gd
    ├── config/  balance.gd, strings.gd
    ├── game/    economy.gd, storage.gd, game_state.gd (Autoload: Game)
    ├── scene/   iso.gd, environment_assets.gd
    ├── world/   world_config.gd, world_camera.gd, world_map.gd, world_scene.gd, bakery.gd
    └── ui/      palette.gd, fa_format.gd, app_fonts.gd
```

## بخش بعدی (۳)
رابط کاربری: `Hud`، `BottomBar`، `UpgradePanel`، `OfflineCard`، `ComingSoon`، `Background`، `TopGradient`، `Icons` و سرهم‌کردن صحنهٔ اصلی معادل `App.js` (شامل مخفی کردن system bars در اندروید و safe area).
