# نانوایی سنگک (Noonvaei) — نسخهٔ Godot

مهاجرت بازی idle/tycoon «Iran Bakery Tycoon» از **Expo / React Native** به **Godot 4**.

- ریپوی مبدأ (React Native): [`themahdipixl-dev/Noonvaei`](https://github.com/themahdipixl-dev/Noonvaei)
- ریپوی مقصد (همین ریپو): `themahdipixl-dev/Noonvaei-godot`

> ⚠️ **وضعیت تست:** کدها «ترجمهٔ ایستا» هستند و داخل ادیتور Godot اجرا/تست **نشده‌اند**. اولین بار که پروژه را باز می‌کنید ممکن است چند خطا/هشدار کوچک ببینید؛ لطفاً خروجی Output/Debugger را برای ما بفرستید تا اصلاح شود.

---

## برنامهٔ مهاجرت (۴ بخش)

پروژهٔ مبدأ حدود ۳۱ فایل دارد. برای اینکه هر مرحله قابل اجرا و بررسی باشد، به ۴ بخش تقسیم شد:

| بخش | محتوا | فایل‌های RN | وضعیت |
|---|---|---|---|
| **۱** | بنیاد پروژه، تنظیمات، منطق بازی (اقتصاد/ذخیره)، ابزارهای کمکی UI | `app.json`، `package.json`، `config/*`، `game/*`، `ui/format.js`، `ui/theme.js`، `ui/Fonts.js` | ✅ **انجام شد** |
| **۲** | دنیای بازی: نقشه، دوربین (pan/zoom)، ایزومتریک، نانوایی | `scene/*`، `world/WorldMap.js`، `WorldScene.js`، `Bakery.js`، `worldConfig.js`، `useWorldCamera.js` | ✅ **انجام شد** |
| **۳** | رابط کاربری: HUD، نوار پایین، پنل ارتقا، کارت آفلاین و سرهم‌کردن صحنهٔ اصلی (معادل `App.js`) | `ui/*` (Hud، BottomBar، UpgradePanel، OfflineCard، ComingSoon، Background، TopGradient، Icons) + `App.js` | ✅ **انجام شد** (آیکن‌ها فعلاً ایموجی) |
| **۴** | شخصیت‌های متحرک: شاطر و ماشین + فیزیک ماشین، خروجی اندروید، مرتب‌سازی نهایی | `world/BakerWalker.js`، `CarDriver.js`، `carPhysics.js` | ✅ **انجام شد** (شاطر و ماشین تا آماده شدن تصاویر، placeholder هستند) |

---

## کارهای دستی لازم از طرف شما

1. **Godot 4.3 یا جدیدتر** را نصب کنید و پوشهٔ پروژه را **داخل خود ادیتور** باز کنید (بار اول ادیتور `class_name`ها را اسکن می‌کند).
2. **فونت‌ها** → `assets/fonts/` (نام‌ها در `assets/fonts/README.md`).
3. **تصویرهای محیط، شاطر و ماشین** → `assets/environment/`، `assets/characters/baker/` و `assets/vehicles/peugeot_pars/` (نام‌ها و مسیرها در `assets/README.md`). بدون تصویر هم بازی اجرا می‌شود و به‌جای آن‌ها placeholder نشان داده می‌شود.
4. *(اختیاری)* اگر ایموجی‌ها روی دستگاه شما نمایش داده نشد، فایل `NotoColorEmoji.ttf` را در `assets/fonts/` بگذارید (به‌صورت خودکار fallback همهٔ فونت‌ها می‌شود).
5. برای خروجی اندروید به بخش «خروجی اندروید» در بخش ۴ (پایین‌تر) نگاه کنید. Export Preset آماده است و Immersive Mode در آن روشن است.
6. صحنهٔ اصلی را اجرا کنید (F5).

---

## بخش ۴ — شاطر، ماشین و خروجی اندروید (انجام شد)

### نگاشت فایل‌ها
| React Native | Godot | توضیح |
|---|---|---|
| `world/carPhysics.js` | `scripts/world/car_physics.gd` (`class_name CarPhysics`) | مسیر با پیچ‌های گرد، نمونه‌گیری و مدل راننده (شتاب / ترمز / پیچ / چراغ). تابع‌های `static` ساده، بدون worklet |
| `world/BakerWalker.js` | `scripts/world/baker_walker.gd` (`class_name BakerWalker`) | گشت شاطر بین نقطه‌های توقف؛ همان جدول زمانی، ۸ فریم راه‌رفتن و تصویر ایستاده هنگام توقف |
| `world/CarDriver.js` | `scripts/world/car_driver.gd` (`class_name CarDriver`) | ماشین در حال رانندگی: ۴ جهت، اسپریت‌شیت پیچ ۹۰ درجه، چرخ‌های چرخان، سایه روی زمین |
| — (جدید) | `scripts/world/draw_proxy.gd` (`class_name DrawProxy`) | نود کوچکی که اجازه می‌دهد شاطر / ماشین سایه و placeholder را با `draw_*` بکشند |
| `world/WorldScene.js` (بخش actors) | `scripts/world/world_scene.gd` | نود `Actors` حالا `BakerWalker` و همهٔ ماشین‌های `WorldConfig.cars()` را می‌سازد (همان ترتیب RN: زمین → نانوایی → شاطر → ماشین) |
| `app.json` (اندروید) | `export_presets.cfg` + `project.godot` | Export Preset اندروید (arm64، Immersive Mode) + فشرده‌سازی ETC2/ASTC |

### معادل‌سازی مفاهیم
| React Native | Godot |
|---|---|
| `useSharedValue` + `useFrameCallback` | متغیرهای ساده + `_process(delta)` (ماشین: `delta` حداکثر ۰٫۰۵ ثانیه، مثل JS) |
| `withRepeat(withTiming(total))` | `_time = fmod(_time + delta, total)` |
| `useAnimatedStyle` (opacity) | `visible` روی نودهای هر جهت |
| نوار راه‌رفتن با `translateX` در یک View بریده‌شده | `Sprite2D` با `hframes = 8` و تغییر `frame` |
| اسپریت‌شیت پیچ ماشین (`translateX/Y`) | `Sprite2D` با `hframes = 5`، `vframes = 4` و `frame` |
| Rim: `rotate` + `scaleX` روی View | `Node2D` (`rotation_degrees` + `scale.x`) که یک `Sprite2D` چرخان داخلش است |
| `react-native-svg` (سایهٔ شاطر: RadialGradient، سایهٔ ماشین: Polygon) | `GradientTexture2D` رادیال / `draw_colored_polygon()` |
| `Image.getSize` (خواندن ابعاد baker_view) | اندازهٔ تکسچر (همان لحظه موجود است) |
| `toGrid` در BakerWalker (کسر تصویر → گرید) | `Iso.unproject(canvas_origin + کسر × canvas_size)` — همان نتیجه، محاسبهٔ کوتاه‌تر |

### رفتار (دقیقاً مثل RN)
- **شاطر:** بین نقطه‌های `WALKER.stops` راه می‌رود؛ هرجا `wait` دارد می‌ایستد و به سمت `face` نگاه می‌کند؛ بعد از آخرین نقطه به اولی برمی‌گردد. راه‌رفتن در هر مسیر دقیقاً عدد صحیحی از چرخه‌های ۸ فریمی است تا روی حالت «پاها جفت» تمام شود.
- **ماشین:** مسیر بسته با گوشه‌های گرد (`corner_radius`)؛ از سکون شتاب می‌گیرد (`start_delay` = ۱٫۵ ثانیه)، در پیچ‌ها آهسته می‌شود و پشت چراغ‌های قرمز خیالی (`lights`) کاملاً می‌ایستد و `stop_for` ثانیه می‌ماند.
- **چرخ‌ها:** با مسافت طی‌شده می‌چرخند (`wheel_circ`) و به شکل بیضی کج دیده می‌شوند (`rim_k` و `rim_rot`).
- **پیچ:** وقتی ماشین بین دو جهت اصلی است (فریم‌های بین ۴ جهت)، لایه‌های جهت مخفی می‌شوند و اسپریت‌شیت پیچ نشان داده می‌شود.
- یک لرزش کوچک جاده (`bob`) هم وجود دارد، فقط وقتی ماشین در حال حرکت است.

### Placeholder (تا وقتی تصاویر اضافه نشده)
اگر تصاویر داخل پروژه نباشند، کد کرش نمی‌کند و به‌جای آن‌ها چیزی کشیده می‌شود که بتوان رفتار را تست کرد:
- **شاطر:** یک آدمک ساده (تنه کرم، کله و کلاه، پاهای در حال راه‌رفتن) همراه با سایه. وقتی رو به دوربین است (sw / se) چشم دارد.
- **ماشین:** یک جعبهٔ ایزومتریک (بدنه + کابین) که در جهت مسیر می‌چرخد، با سایهٔ واقعی روی زمین.
- سایه‌ها همیشه کشیده می‌شوند.
- با اضافه شدن تصاویر واقعی (بدون هیچ تغییر در کد) خودکار جای placeholder می‌نشینند. شاطر وقتی هر ۴ شیت راه‌رفتن موجود باشند از تصویر واقعی استفاده می‌کند (و اگر `baker_view` نباشد، حالت ایستاده همان فریم «پاها جفت» است). ماشین وقتی هر ۴ تصویر جهت موجود باشند از تصویر واقعی استفاده می‌کند (چرخ‌ها و پیچ هم اگر فایل‌شان باشد).

### تفاوت‌ها / نکات
- کلیدهای `WALKER` و `CARS` در `world_config.gd` به‌صورت `snake_case` هستند (مثلاً `corner_radius`، `brake_max`، `stop_for`).
- زمان بر حسب ثانیه است (نه میلی‌ثانیه).
- تابع `lightState` و تنظیم `reaction` که در نسخهٔ JS هیچ‌جا استفاده نمی‌شدند منتقل نشدند (`reaction` همچنان در `world_config.gd` مانده).
- `debug` در `WALKER` نقطه‌های توقف را با دایره‌های قرمز نشان می‌دهد. `debug` ماشین (کادر قرمز روی چرخ‌ها) منتقل نشد.
- برای تنظیم متفاوت شاطر یا ماشین فقط `world_config.gd` را عوض کنید. ماشین جدید = یک اندیس جدید در `WorldConfig.cars()` و یک id جدید در `EnvironmentAssets.VEHICLE_IDS`.

### خروجی اندروید
1. در ادیتور: *Editor > Manage Export Templates* → تمپلیت‌های همان نسخهٔ Godot را نصب کنید.
2. *Editor Settings > Export > Android*: مسیر Android SDK و JDK را بدهید (و یک debug keystore اگر ندارید).
3. *Project > Export* → پریست **Android** از قبل آماده است (`export_presets.cfg`): `arm64-v8a`، نام پکیج `com.noonvaei.game`، **Immersive Mode روشن**؛ حالت portrait هم در `project.godot` تنظیم است. ادیتور ممکن است بار اول گزینه‌های جاافتادهٔ پریست را خودش اضافه کند.
4. تنظیم `Rendering > Textures > VRAM Compression > Import ETC2 ASTC` روشن شده است (برای خروجی اندروید لازم است، وگرنه خطا می‌دهد). بعد از باز شدن پروژه ممکن است ادیتور بخواهد تصاویر را دوباره import کند.
5. *Export Project* یا دکمهٔ «Remote Debug» (گوشی متصل با USB debugging) برای تست روی گوشی واقعی.
6. برای انتشار روی فروشگاه‌ها: پریست را روی AAB و امضای release بگذارید (نیاز به keystore شخصی، که در ریپو نیست و نباید کامیت شود).

### چک‌لیست تست بخش ۴
- [ ] (بدون تصویر) شاطر placeholder بین دو نقطهٔ نانوایی راه می‌رود، هرجا می‌رسد حدود ۴ ثانیه می‌ایستد و بعد ادامه می‌دهد (حلقهٔ بی‌نهایت)
- [ ] (بدون تصویر) ماشین placeholder یک مسیر مستطیلی را دور نانوایی می‌رود: اول ۱.۵ ثانیه می‌ایستد، در گوشه‌ها آهسته می‌شود، در هر دو چراغ ۵ ثانیه کاملاً می‌ایستد
- [ ] سایه‌های شاطر و ماشین روی زمین دیده می‌شوند و با جهت ماشین می‌چرخند
- [ ] با pan / zoom نقشه، شاطر و ماشین همان‌جایی که هستند روی زمین می‌مانند (نلغزند)
- [ ] کشیدن نقشه و دکمه‌های بخش ۳ همچنان درست کار می‌کنند
- [ ] (با تصاویر) شاطر با جهت حرکت، ۴ جهتش را عوض می‌کند و هنگام توقف تصویر ایستاده (`baker_view`) به همان جهت `face` نشان داده می‌شود
- [ ] (با تصاویر) ماشین جهت را صاف عوض می‌کند، در پیچ‌ها اسپریت‌شیت پیچ بدون پرش در اندازه نشان داده می‌شود، و چرخ‌ها متناسب با سرعت می‌چرخند (وقتی ماشین می‌ایستد نمی‌چرخند)
- [ ] خروجی APK اندروید گرفته می‌شود، روی گوشی تمام‌صفحه (بدون نوار سیستم) اجرا می‌شود، HUD زیر ناچ و نوار پایین بالای خط ژست می‌ماند

---

## بخش ۳ — رابط کاربری و صحنهٔ اصلی (انجام شد)

### نگاشت فایل‌ها
| React Native | Godot | توضیح |
|---|---|---|
| `ui/Hud.js` | `scripts/ui/hud.gd` (`class_name Hud`) | همان مختصات طراحی (۷۸۰ پیکسل) و همان مقیاس‌دهی؛ ریشه mouse را نادیده می‌گیرد (`box-none`)، فقط دکمه‌ها لمس می‌گیرند |
| `Btn` / `PlusBtn` در `Hud.js` | `scripts/ui/cartoon_button.gd` (`CartoonButton`) | دکمهٔ کارتونی: خط دور + لبهٔ سه‌بعدی + نور بالا + فرو رفتن هنگام لمس |
| `Bar` در `Hud.js` | `scripts/ui/hud_bar.gd` (`HudBar`) | نوار پیشرفت (با `_draw()`) |
| `ui/BottomBar.js` | `scripts/ui/bottom_bar.gd` (`class_name BottomBar`) | ۵ بخش با خط جداکننده؛ تب فعال بزرگ‌تر می‌شود (انیمیشن Tween جای `LayoutAnimation`) |
| `ui/UpgradePanel.js` | `scripts/ui/upgrade_panel.gd` (`class_name UpgradePanel`) | ۴ کارت ارتقا، علامت ⚠️ روی گلوگاه، کارت غیرفعال وقتی پول کافی نیست |
| `ui/OfflineCard.js` | `scripts/ui/offline_card.gd` (`class_name OfflineCard`) | overlay تیره + کارت درآمد آفلاین؛ لمس را از نقشه می‌گیرد |
| `ui/ComingSoon.js` | `scripts/ui/coming_soon.gd` (`class_name ComingSoon`) | برای تب‌های فروشگاه / کارت‌ها / مینی‌گیم‌ها |
| `ui/Background.js` | `scripts/ui/background.gd` (`class_name Background`) | آسمان + خورشید + نوار کاشی (مثل RN در صحنهٔ اصلی استفاده نمی‌شود) |
| `ui/TopGradient.js` | `scripts/ui/top_gradient.gd` (`class_name TopGradient`) | گرادیان مشکی→شفاف بالای صفحه (همان ۱۷ مقدار alpha) |
| `ui/Icons.js` | `scripts/ui/icons.gd` (`class_name Icons`) | **فعلاً ایموجی** (جدول زیر) |
| `App.js` | `scripts/main.gd` | لایه‌ها: نقشه → گرادیان → HUD → پنل ارتقا / به‌زودی → نوار پایین → کارت آفلاین |
| — (جدید) | `scripts/ui/ui_kit.gd` (`class_name UiKit`) | ابزارهای مشترک: Label فارسی، StyleBox، تناسب متن با عرض، Safe Area و تبدیل dp |

`app_fonts.gd` هم یک تغییر کوچک گرفت (فونت اختیاری ایموجی به‌عنوان fallback).

### آیکن‌ها = ایموجی (موقت)
همهٔ آیکن‌ها فقط در `icons.gd` تعریف شده‌اند. وقتی تکسچرهای واقعی را اضافه کردید، فقط همین فایل (تابع `Icons.place`) عوض می‌شود و بقیهٔ UI دست نمی‌خورد.

| کلید | ایموجی | کلید | ایموجی |
|---|---|---|---|
| `money` | 💵 | `diamond` | 💎 |
| `crown` | 👑 | `clipboard` | 📋 |
| `gear` | ⚙️ | `buildings` | 🏙️ |
| `star` | ⭐ | `plus` | ➕ |
| تب `shop` | 🛒 | تب `cards` | 🃏 |
| تب `home` | 🏠 | تب `upgrade` | ⬆️ |
| تب `minigames` | 🕹️ | سکه / هشدار | 🪙 / ⚠️ |

آیکن بخش‌های نانوایی (🪟 🧾 🔥 🏮) همان ایموجی‌های `Strings.SECTIONS` هستند.

### معادل‌سازی مفاهیم
| React Native | Godot |
|---|---|
| `useWindowDimensions` + `s = min(width/780, 0.7)` | `Hud.configure()`؛ واحد dp ← `عرض صفحه / ۴۰۰` (`UiKit.dp_scale`) چون رزولوشن مرجع ۱۰۸۰ است |
| `Pressable` + `pressed && translateY` | `BaseButton` + سیگنال‌های `button_down` / `button_up` |
| `useSafeAreaInsets` | `UiKit.safe_insets()` (با `DisplayServer.get_display_safe_area()`؛ روی دسکتاپ صفر) |
| `LayoutAnimation.spring` | `Tween` با `TRANS_BACK` روی وزن هر بخش |
| `adjustsFontSizeToFit` | `UiKit.fit_text()` (برای موجودی و الماس) |
| `StatusBar hidden` + `NavigationBar` | `DisplayServer.window_set_mode(FULLSCREEN)` در اندروید + Immersive Mode در Export Preset |
| `useGame()` | سیگنال‌های `Game.changed` و `Game.offline_report_changed` |
| `useBottomBarHeight()` | `BottomBar.bar_height(inset, dp)` |
| `react-native-svg` | `_draw()` و `GradientTexture2D` |

### تفاوت‌ها / نکات
- **صفحهٔ «در حال بارگذاری»** حذف شد؛ ذخیره همزمان توسط `Game` لود می‌شود و فونت‌ها فایل محلی‌اند.
- دکمه‌های HUD (تنظیمات، ماموریت، پس فصل، شهرها، «+») فقط **سیگنال** دارند (`settings_pressed` و …) و هنوز به چیزی وصل نیستند؛ در RN هم هندلری نداشتند. مقدار الماس / ماموریت / پس فصل همان placeholderهای RN هستند (۳۵۰ / ۴۰٪ / ۲۵٪).
- با تغییر اندازهٔ پنجره، UI دوباره چیده می‌شود.
- کارت‌های ارتقا ارتفاعشان خودکار از محتوا حساب می‌شود.
- اگر ایموجی روی دستگاه شما دیده نشد یا سیاه‌وسفید بود، `NotoColorEmoji.ttf` را در `assets/fonts/` بگذارید.

### چک‌لیست تست بخش ۳
- [ ] بالای صفحه HUD کارتونی دیده می‌شود: سطح (ستاره + نوار)، موجودی، الماس و زیر موجودی «درآمد در ثانیه» (سبز نعنایی)
- [ ] موجودی هر ثانیه بالا می‌رود و اعداد فارسی‌اند؛ عدد بزرگ در موجودی کوچک می‌شود تا جا شود
- [ ] دکمه‌های HUD هنگام لمس پایین می‌روند؛ کشیدن نقشه از روی دکمه‌ها شروع نمی‌شود و از جاهای خالی نقشه را می‌کشد
- [ ] نوار پایین ۵ بخش دارد؛ لمس یک تب آن را بزرگ می‌کند (انیمیشن) و برچسبش bold می‌شود
- [ ] تب «ارتقا» ← ۴ کارت بالای نوار؛ با پول کم خاکستری، با پول کافی نارنجی؛ ⚠️ روی گلوگاه؛ لمس کارت سطح را بالا می‌برد و سکه کم می‌شود
- [ ] تب‌های «فروشگاه / کارت‌ها / مینی‌گیم‌ها» ← کارت «به‌زودی...» بالای نوار
- [ ] بازی را ببندید و بعد از ۱۰+ ثانیه باز کنید ← کارت «خوش آمدی، شاطر!» با درآمد و مدت غیبت؛ دکمهٔ «باشه» آن را می‌بندد و پشتش نقشه کشیده نمی‌شود
- [ ] (گوشی با ناچ) HUD زیر ناچ و نوار پایین بالای خط ژست می‌ماند
- [ ] ایموجی‌ها نمایش داده می‌شوند

---

## بخش ۲ — دنیای بازی (انجام شد)

### نگاشت فایل‌ها
| React Native | Godot | توضیح |
|---|---|---|
| `scene/iso.js` | `scripts/scene/iso.gd` (`class_name Iso`) | نگاشت گرید → مختصات صفحه (`project`)، `shade` و `box_colors`. از تابع به کلاس تغییر کرد (همان closure مورد استفادهٔ `makeProjector`) |
| `scene/environmentAssets.js` | `scripts/scene/environment_assets.gd` (`class_name EnvironmentAssets`) | مسیر تصویرها، تابع `get_texture`، `preload_all` (با `ResourceLoader.load_threaded_request`) |
| `world/worldConfig.js` | `scripts/world/world_config.gd` (`class_name WorldConfig`) | همهٔ اعداد منتقل شدند، از جمله `WALKER` و `CARS` که در بخش ۴ استفاده می‌شوند |
| `world/useWorldCamera.js` | `scripts/world/world_camera.gd` (`class_name WorldCamera`) | منطق pan / pinch-zoom (بدون نود؛ فقط محاسبه) |
| `world/WorldMap.js` | `scripts/world/world_map.gd` (`class_name WorldMap`) | کنترل تمام‌صفحه + دریافت لمس + نود `Content` |
| `world/WorldScene.js` | `scripts/world/world_scene.gd` (`class_name WorldScene`) | زمین با `_draw()` + نانوایی + نود `Actors` (جای شاطر و ماشین، ساخته‌شده در بخش ۴) |
| `world/Bakery.js` | `scripts/world/bakery.gd` (`class_name Bakery`) | لایه‌های `Sprite2D` (front → belt → lavash → cutter) |
| `App.js` (بخشی) | `scripts/main.gd` | در بخش ۳ به صحنهٔ اصلی کامل تبدیل شد |

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
- `Iso.unproject()` برای تبدیل مختصات صفحه به گرید (بخش ۴ از آن استفاده می‌کند).
- `Bakery.set_lavash_stage(0..4)`: دادهٔ ۵ مرحلهٔ نان لواش در فایل JS بود ولی فقط مرحله ۱ نمایش داده می‌شد؛ حالا قابل تغییر است.
- **placeholder:** اگر `bakery_front.webp` داخل پروژه نباشد، یک جعبهٔ ایزومتریک زرد نشان داده می‌شود تا بتوانید دوربین را بدون آرت تست کنید.

### تفاوت‌ها
- تصویرها از اینترنت دانلود نمی‌شوند؛ باید داخل پروژه باشند. پارامترهای cache-busting (`?v=3`) حذف شدند.
- نقشه با کد ساخته می‌شود (نه با فایل `.tscn` مستقل)؛ اگر خواستید بعداً به صحنه تبدیل می‌کنیم.

### چک‌لیست تست بخش ۲
- [ ] زمین کرمی لوزی با نانوایی در مرکز دیده می‌شود و دوربین روی نانوایی است
- [ ] کشیدن (ماوس یا انگشت) نقشه را جابه‌جا می‌کند و از کناره‌ها بیرون نمی‌رود
- [ ] چرخ ماوس / pinch دو انگشتی زوم می‌کند و نقطهٔ زیر انگشت/ماوس تقریباً ثابت می‌ماند
- [ ] کشیدن نقشه وقتی انگشت روی دکمه‌های HUD شروع شده نقشه را حرکت نمی‌دهد
- [ ] (با تصاویر) لایه‌های front / belt / lavash / cutter دقیقاً روی هم می‌نشینند
- [ ] (با تصاویر) اگر با زوم کم (۰.۲۵) تصویر لرزش/دنده‌ای شد، در Import تصاویر گزینهٔ `Mipmaps > Generate` را روشن کنید

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
- **ایموجی آیکن‌های بخش‌ها** (🪟 🧾 🔥 🏮) در `Strings.SECTIONS` هستند و در بخش ۳ مستقیماً در کارت‌های ارتقا استفاده می‌شوند.
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
├── export_presets.cfg       # پریست خروجی اندروید
├── icon.svg
├── assets/
│   ├── README.md            # لیست تصاویر لازم
│   └── fonts/               # فونت‌ها را اینجا بگذارید (+ NotoColorEmoji.ttf اختیاری)
├── scenes/
│   └── main.tscn            # صحنهٔ اصلی (اسکریپت main.gd همه‌چیز را می‌سازد)
└── scripts/
    ├── main.gd              # معادل App.js
    ├── config/  balance.gd, strings.gd
    ├── game/    economy.gd, storage.gd, game_state.gd (Autoload: Game)
    ├── scene/   iso.gd, environment_assets.gd
    ├── world/   world_config.gd, world_camera.gd, world_map.gd, world_scene.gd, bakery.gd,
    │            car_physics.gd, baker_walker.gd, car_driver.gd, draw_proxy.gd
    └── ui/      palette.gd, fa_format.gd, app_fonts.gd,
                 ui_kit.gd, icons.gd, cartoon_button.gd, hud_bar.gd, hud.gd,
                 bottom_bar.gd, upgrade_panel.gd, offline_card.gd, coming_soon.gd,
                 top_gradient.gd, background.gd
```

## کارهای باقی‌مانده (بعد از بخش ۴)
- گذاشتن تصاویر واقعی محیط، شاطر و ماشین داخل `assets/` و چک کردن هماهنگی اندازه‌های `WALKER` / `CARS` با آن‌ها.
- جایگزینی ایموجی‌های `icons.gd` با تکسچر آیکن‌های واقعی.
- وصل کردن سیگنال‌های دکمه‌های HUD به منو/صفحه‌های آینده (تنظیمات، ماموریت، شهرها، فروشگاه ...).
- اجرای واقعی در Godot و رفع خطاهای احتمالی.
