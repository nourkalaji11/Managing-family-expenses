# بنية تطبيق الموبايل — شرح مبسّط

> تطبيق **Flutter** لإدارة مصاريف العائلة. المجلد الأساسي: `mobile/`
> اسم الباكج داخل الكود: `lootah_main_structure` (اسم القالب الجاهز اللي انبنى عليه المشروع).

---

## 1. نظرة عامة سريعة

المشروع حاليًا عبارة عن **قالب أساسي (Base Template) جاهز** — يعني البنية التحتية كلها موجودة (شبكة، تخزين، مصادقة، إشعارات، لغات، ثيم)، بس **شاشات المصاريف نفسها لسه ما اتبنت**. الموجود منها لهلق: التصاميم فقط داخل مجلد `stitch_family_finance_tracker/`.

المعمارية المستخدمة هي **Clean Architecture مبسّطة + BLoC**، بثلاث طبقات:

| الطبقة | الوظيفة | وين موجودة |
|---|---|---|
| **Presentation** | الشاشات والويدجت (اللي بيشوفه المستخدم) | `lib/presentation/` |
| **Business Logic** | Bloc / Cubit (العقل المدبّر) | `lib/blocs/` + `bloc/` جوّا كل صفحة |
| **Data** | الموديلات، الـ Repos، التخزين المحلي | `lib/data/` |
| **Network** | كلاينت الـ API والأخطاء والروابط | `lib/network/` |

---

## 2. شجرة المجلدات

```
mobile/
├── lib/                          ← كل كود التطبيق (Dart)
│   ├── main.dart                 ← نقطة البداية: تهيئة كل شي ثم تشغيل التطبيق
│   ├── firebase_options.dart     ← إعدادات Firebase المولّدة تلقائيًا
│   │
│   ├── core/                     ← الأساسيات المشتركة بكل التطبيق
│   │   ├── default_settings.dart      ← ثوابت عامة (رقم النسخة، مفاتيح Navigator، اللغات المدعومة)
│   │   ├── locals_app.dart            ← متغيّرات عامة بالذاكرة (المستخدم الحالي، اللغة، نوع الجهاز)
│   │   └── notification_manager.dart  ← إدارة إشعارات OneSignal
│   │
│   ├── blocs/                    ← كيوبتات عامة تُستخدم بأكثر من شاشة
│   │   ├── locale_cubit.dart          ← تبديل اللغة (عربي/إنجليزي)
│   │   ├── local_user_cubit.dart      ← بيانات المستخدم المسجّل
│   │   ├── toggle_cubit.dart          ← تبديل بسيط (true/false) لأي عنصر
│   │   ├── password_cubit.dart        ← إظهار/إخفاء كلمة المرور
│   │   └── date_cubit.dart            ← اختيار التاريخ
│   │
│   ├── data/                     ← طبقة البيانات
│   │   ├── local_storage.dart         ← التخزين المحلي عبر Hive (توكن، لغة، FCM)
│   │   ├── constant/enums.dart        ← ثوابت مُعدّدة (نوع تسجيل الدخول، الأدوار، التبويبات)
│   │   ├── models/                    ← تحويل JSON ↔ كائنات Dart
│   │   │   ├── user.dart
│   │   │   └── custom_notification.dart
│   │   └── repos/                     ← تنفيذ نداءات الـ API
│   │       ├── auth_repo.dart
│   │       └── notifications_repo.dart
│   │
│   ├── network/                  ← طبقة الاتصال بالسيرفر
│   │   ├── network_client.dart        ← DioClient: كل الطلبات بتمرق من هون
│   │   ├── global_api_endpoint.dart   ← قائمة روابط الـ API بمكان واحد
│   │   ├── failure.dart               ← أنواع الأخطاء (سيرفر، اتصال، عام...)
│   │   └── network_connection.dart    ← فحص وجود إنترنت
│   │
│   ├── presentation/             ← الواجهات
│   │   ├── pages/                     ← الشاشات، كل شاشة بمجلد مستقل
│   │   │   ├── auth/                       ← تسجيل الدخول والحساب
│   │   │   ├── dashboard/                  ← الشاشة الرئيسية + شريط التنقّل السفلي
│   │   │   └── notifications/              ← الإشعارات
│   │   └── widgets/                   ← ويدجت جاهزة قابلة لإعادة الاستخدام
│   │       ├── main_button.dart, text_field.dart, password_field.dart
│   │       ├── custom_app_bar.dart, dialog_template.dart, error_message.dart
│   │       ├── image_picker_widget.dart, file_picker_widget.dart
│   │       └── country_picker.dart, no_items.dart, refresh.dart, default_loader.dart
│   │
│   ├── style/                    ← نظام التصميم
│   │   ├── colors.dart, text_style.dart, theme.dart
│   │   └── padding.dart, radius.dart, spaces.dart, decorations.dart
│   │
│   └── utils/                    ← أدوات مساعدة
│       ├── service_locator.dart       ← تسجيل الـ Blocs بـ GetIt (حقن التبعيات)
│       ├── validator.dart             ← تحقّق من صحة المدخلات
│       ├── date_formatter.dart, string_formatter.dart
│       ├── google_sign_controller.dart, apple_sign_controller.dart
│       ├── analytics_controller.dart, device_controller.dart
│       └── app_links.dart, url_handler.dart, system_func.dart, countries.dart
│
├── android/ ios/ web/ windows/ macos/ linux/   ← ملفات كل منصّة (مولّدة تلقائيًا)
├── test/                                        ← الاختبارات
├── pubspec.yaml                                 ← الحزم والإعدادات
└── stitch_family_finance_tracker/               ← تصاميم الشاشات (HTML + صور) — مو كود التطبيق
```

---

## 3. بنية الشاشة الواحدة (النمط المتكرر)

كل شاشة رئيسية بتتقسم لـ 3 مجلدات — مثال `auth`:

```
presentation/pages/auth/
├── domain/
│   └── auth_domain.dart      ← عقد مجرّد (abstract): شو العمليات المتاحة؟ (تسجيل، دخول، OTP...)
├── bloc/
│   ├── auth_event.dart       ← الأحداث: شو المستخدم عمل؟ (OnLogin, OnRegister, OnSendOTP)
│   ├── auth_state.dart       ← الحالات: شو وضع الشاشة؟ (Loading, Success, Failure)
│   └── auth_bloc.dart        ← المنطق: بستقبل حدث → بينادي الـ Repo → بيطلّع حالة
└── presentation/
    ├── welcome_screen.dart
    ├── login_with_password.dart
    └── signup.dart
```

> الـ `domain` بيعرّف **شو** بدنا نعمل، والـ `repo` بـ `data/repos/` بينفّذ **كيف** بينعمل. هيك بتقدر تبدّل مصدر البيانات بدون ما تلمس الواجهة.

---

## 4. رحلة البيانات (مثال: تسجيل الدخول)

```
[1] المستخدم بيضغط "دخول"
        ↓
[2] الشاشة بتبعت حدث:  context.read<AuthBloc>().add(OnLogin(...))
        ↓
[3] AuthBloc  →  emit(AuthLoading())  ← الشاشة بتعرض لودر
        ↓
[4] AuthRepo().login(...)
        ↓
[5] DioClient.request()  ← بيضيف الهيدرز تلقائيًا (اللغة، التوكن، نوع الجهاز)
        ↓
[6] السيرفر بيرجّع JSON
        ↓
[7] الـ Repo بيرجّع Either<Failure, User>
        ├─ Left  = خطأ   → emit(AuthFailure)  → رسالة خطأ
        └─ Right = نجاح  → حفظ التوكن بـ Hive + emit(LoginSuccess) → انتقال للرئيسية
```

**نقطة مهمة:** المشروع بيستخدم `Either` من حزمة `dartz` بدل ما يرمي Exceptions. يعني كل دالة بترجع **إمّا خطأ إمّا نتيجة**، وأنت مجبور تتعامل مع الحالتين — هاد بيمنع الكراشات المفاجئة.

---

## 5. أهم الحزم المستخدمة

| الحزمة | الوظيفة |
|---|---|
| `flutter_bloc` | إدارة الحالة (State Management) |
| `dio` | طلبات HTTP |
| `get_it` | حقن التبعيات (Dependency Injection) |
| `hive` | تخزين محلي سريع |
| `dartz` | نمط `Either` لمعالجة الأخطاء |
| `easy_localization` | تعدد اللغات (عربي/إنجليزي) |
| `flutter_screenutil` | تجاوب الشاشات (التصميم المرجعي 412×917) |
| `firebase_core/auth/messaging/analytics` | فايربيز |
| `onesignal_flutter` | الإشعارات |
| `google_sign_in` + `sign_in_with_apple` | تسجيل دخول اجتماعي |
| `flutter_easyloading` | مؤشرات التحميل والتوستات |
| `shorebird_code_push` | تحديثات فورية بدون رفع نسخة جديدة |
| `connectivity_plus` | فحص الإنترنت |

---

## 6. ملفات مفتاحية لازم تعرفها

| الملف | ليش مهم |
|---|---|
| `lib/main.dart` | التهيئة بالترتيب: Firebase → اللغات → Hive → OneSignal → GetIt → تشغيل التطبيق |
| `lib/utils/service_locator.dart` | مكان تسجيل أي Bloc جديد — لازم تضيفه هون |
| `lib/network/global_api_endpoint.dart` | كل روابط الـ API بمكان واحد |
| `lib/core/locals_app.dart` | متغيّرات عامة: المستخدم الحالي، اللغة، نوع الجهاز |
| `lib/data/constant/enums.dart` | تبويبات الشريط السفلي مُعرّفة هون (`MainTabs`) |
| `lib/style/theme.dart` | الثيم العام للتطبيق |

---

## 7. مجلد التصاميم `stitch_family_finance_tracker/`

هاد مجلد **تصاميم فقط** (HTML + صور PNG)، مو جزء من كود التطبيق. فيه 12 شاشة مصمّمة:

- `splash_screen` — شاشة البداية
- `login_screen` / `register_screen` — الدخول والتسجيل
- `dashboard_screen` — لوحة التحكم الرئيسية
- `accounts_list` + `add_edit_account` — الحسابات
- `transactions_list` + `add_edit_transaction` — الحركات المالية
- `budgets_list` + `add_edit_budget` — الميزانيات
- `categories_list` + `add_edit_category` — التصنيفات
- `kinship_finance/DESIGN.md` — **نظام التصميم الكامل**: الألوان، الخطوط (IBM Plex Sans Arabic)، المسافات، الظلال، الأشكال. التصميم مبني أصلًا لواجهة **RTL** عربية.

---

## 8. ملاحظات ونواقص حالية (TODO)

هاي أشياء لازم تنتبه إلها لأنها لسه فاضية أو من القالب القديم:

1. **رابط الـ API فاضي** — `global_api_endpoint.dart:3` فيه `https://domain/api/v1` (قيمة وهمية).
2. **مفتاح OneSignal فاضي** — `default_settings.dart:22` → `oneSignalAppId = ""`.
3. **رابط التطبيق بالمتجر فاضي** — `default_settings.dart:19` → `linkApp`.
4. **مجلد `assets/` غير موجود** — بس `main.dart:42` بيدوّر على `assets/translations`، وقسم الـ `assets` بـ `pubspec.yaml` لسه مُعلَّق (كومنت). التطبيق رح يفشل عند الإقلاع بدون ما تنشئه.
5. **الشاشة الرئيسية فاضية** — `dashboard_cubit.dart:11` قائمة `tabs` كلها كومنتات.
6. **التبويبات من تطبيق تاني** — `MainTabs` فيها `feed / explore / chats / appointments` (تطبيق شات)، لازم تتبدّل لتبويبات المصاريف (حركات، ميزانيات، تصنيفات...).
7. **عنوان التطبيق** — `main.dart:102` لسه `"Cash For Chat"`.
8. **اسم الباكج** — `lootah_main_structure` بكل ملفات الاستيراد، إذا بدك تغيّره لازم تغيير شامل.

---

## 9. باقي مجلدات المشروع

المجلدات `backend/` و `docs/` كانت موجودة بالكوميت الأول كمجلدات فاضية (فيها `.gitkeep` بس)، وحاليًا محذوفة من الشجرة. يعني الباك-إند لسه ما بلش.
