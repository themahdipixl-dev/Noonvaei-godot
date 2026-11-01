# دارایی‌های تصویری (assets)

در نسخهٔ React Native تصویرها از اینترنت (ریپوی `themahdipixl-dev/Assets`) دانلود می‌شدند. در Godot باید داخل خود پروژه باشند.
فایل‌های `.webp` باینری هستند و از طریق ابزار خودکار قابل کامیت نبودند، پس خودتان کپی کنید.

مسیر مبدأ در ریپوی Assets ← مسیر مقصد در این پروژه (همان ساختار پوشه‌ها را حفظ کنید):

```
Assets/assets/environment/            ←  assets/environment/
    bakery_front.webp
    bakery_belt.webp
    bakery_cutter.webp
    bakery_bread_1.webp ... bakery_bread_5.webp
    baker_view1.webp ... baker_view4.webp

Assets/assets/characters/baker/       ←  assets/characters/baker/
    baker_walk_sw.webp, baker_walk_se.webp, baker_walk_ne.webp, baker_walk_nw.webp

Assets/assets/vehicles/peugeot_pars/  ←  assets/vehicles/peugeot_pars/
    peugeot_pars_sw.webp, _se.webp, _ne.webp, _nw.webp
    peugeot_pars_rim.webp
    peugeot_pars_spritesheet.webp
```

- بخش ۲ فقط از `environment/bakery_front`، `bakery_belt`، `bakery_cutter` و `bakery_bread_1` استفاده می‌کند.
- `characters/` و `vehicles/` مربوط به بخش ۴ هستند.
- بعد از کپی، ادیتور Godot را باز کنید تا تصویرها import شوند.
- اگر تصویری نباشد کد کرش نمی‌کند: برای `bakery_front` یک جعبهٔ زرد موقت نشان داده می‌شود.
