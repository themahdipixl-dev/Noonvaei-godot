# ماشین‌ها (assets/vehicles)

## مدل سه‌بعدی (glb)

فایل مدل را با نام **`<id>.glb`** در یکی از این مسیرها بگذار (برای پژو پارس: `peugeot_pars.glb`):

```
assets/vehicles/peugeot_pars/peugeot_pars.glb   <- پیشنهادی
assets/vehicles/peugeot_pars.glb
assets/models/peugeot_pars.glb
models/peugeot_pars.glb
peugeot_pars.glb                                  (ریشه پروژه)
```

- تا وقتی فایل در پروژه نباشد، یک **ماشین سه‌بعدی ساده (جعبه‌ای)** نشان داده می‌شود. چراغ‌های زرد جلوی ماشین را نشان می‌دهند.
- به‌محض اینکه فایل را بگذاری و ادیتور Godot آن را import کند، مدل واقعی جای ماشین ساده می‌نشیند (بدون تغییر در کد).
- در Output موقع اجرا نوشته می‌شود کدام مدل استفاده شده: `CarModel3D[peugeot_pars]: using model ...`.
- اندازه، مرکز و ارتفاع مدل خودکار تنظیم می‌شود؛ طول ماشین روی صفحه از `shadow.length` در `world_config.gd` می‌آید.
- جلوی ماشین باید رو به محور **+Z** باشد (پیش‌فرض glTF). اگر ماشین بغل یا برعکس می‌رود، در `world_config.gd` داخل `cars()` این را اضافه کن:

```gdscript
car["model"] = {"yaw_offset": 90.0}   # یا 180 / -90
```

- گزینه‌های دیگر `model`: `"scale"` (ضریب اندازه)، `"spin_wheels": true` (چرخاندن نودهایی که اسمشان `wheel` دارد؛ فقط اگر pivot هر چرخ در مرکز خودش باشد).

## اسپریت‌ها (روش قدیمی)

اگر مدل glb نباشد ولی هر ۴ تصویر جهت (`<id>_sw/se/ne/nw.webp`) باشند، از اسپریت‌ها استفاده می‌شود (همراه `_rim` و `_spritesheet`). اولویت: **glb ← اسپریت ← ماشین ساده**.
