# تقرير التحليل الشامل لمشروع تطبيق القرآن الكريم (تقرب)

---

## فهرس المحتويات
1. [هيكل المشروع والمعمارية وإدارة الحالة والحزم](#1-هيكل-المشروع-والمعمارية-وإدارة-الحالة-والحزم)
2. [مصادر البيانات وإدارتها (القرآن، الأحاديث، الأذكار، الأسماء)](#2-مصادر-البيانات-وإدارتها)
3. [نظام الأذان ومواقيت الصلاة (Kotlin & Android Platform)](#3-نظام-الأذان-ومواقيت-الصلاة-kotlin--android)
4. [الـ Widgets المصغرة (Android AppWidget & iOS WidgetKit)](#4-الـ-widgets-المصغرة-android--ios)
5. [القبلة والموقع وحساسات البوصلة](#5-القبلة-والموقع-وحساسات-البوصلة)
6. [واجهة المستخدم (UI/UX) والتجاوب (Responsiveness) والثيمات](#6-واجهة-المستخدم-uiux-والتجاوب-والثيمات)
7. [صفحات المصحف الشريف وتجربة القراءة الواقعية](#7-صفحات-المصحف-الشريف-وتجربة-القراءة-الواقعية)
8. [الأداء والاستقرار وتسريب الذاكرة (Memory & Performance)](#8-الأداء-والاستقرار-وتسريب-الذاكرة)
9. [الأمان، جودة الكود، والاختبارات](#9-الأمان-وجودة-الكود-والاختبارات)
10. [مصفوفة المشاكل مرتبة حسب الأولوية مع أرقام الأسطر](#10-مصفوفة-المشاكل-مرتبة-حسب-الأولوية)
11. [خطة الإصلاح والتحسين المقترحة (على مراحل)](#11-خطة-الإصلاح-والتحسين-المقترحة-على-مراحل)
12. [أسئلة جوهرية وقرارات تقنية مطلوبة منكم قبل البدء](#12-أسئلة-جوهرية-وقرارات-تقنية-مطلوبة-منكم-قبل-البدء)

---

## 1. هيكل المشروع والمعمارية وإدارة الحالة والحزم

### 1.1 المعمارية العامة (Architecture)
- **النمط المتبع**: يعتمد المشروع على تنظيم شبيه بـ **Feature-First Architecture**، حيث ينقسم كود `lib/` إلى مجلدين رئيسيين: `core/` و `features/`.
- **مشاكل البنية والتنظيم الهيكلي**:
  - **أخطاء إملائية في مسارات المجلدات الأساسية**: تم تسمية مجلدات طبقة العرض بأسماء خاطئة مثل `presentition/` و `presenition/` بدلاً من `presentation/` في معظم الميزات (`adhan`, `azkar`, `hadith`, `home`, `quran`, `settings`).
  - **تداخل الطبقات وانعدام الفصل (Tight Coupling)**: كائنات `GetxController` (الـ ViewModel) تخلط بين المنطق، والتعامل المباشر مع ملفات الـ Assets، واستدعاء قنوات الـ Platform Channels، والتحكم في التنقل بين الشاشات (`Get.toNamed`) وعرض الـ Snackbars.
  - **غياب طبقة المستودعات الحقيقية (Repository Pattern)**: لا توجد طبقة `Domain` أو `Repositories` تعزل مصادر البيانات عن واجهة المستخدم؛ بل يتم استدعاء `rootBundle.loadString` وتفكيك الـ JSON داخل الـ Controllers مباشرة.
  - **وجود كود مهجور وميت (Dead Code)**:
    - ملف `lib/features/adhan/presentition/views/dead_code.dart` بحجم يتجاوز 17 كيلوبايت متروك بالكامل داخل الكود المصدر.
    - ملفات كوتلن في الأندرويد تحتوي على مئات الأسطر المنسوخة والمعلقة (أكثر من 65% من حجم ملفات الأذان والأذكار في Kotlin هي تعليقات لكود قديم).

### 1.2 إدارة الحالة (State Management)
- يعتمد المشروع حصرياً على **GetX** (`get: ^4.6.5`).
- يتم استخدام خليط غير متجانس من أدوات GetX:
  - استخدام `GetBuilder` مع الاستدعاء اليدوي لـ `update()`.
  - استخدام متغيرات الملاحظة `Rx` (`.obs`) مع `Obx`.
  - إنشاء الـ Controllers بطرق غير منضبطة داخل شاشات الـ View مباشرة عبر `Get.put()` داخل دالة `build()` (مثل `AdhanViewModel adhanViewModel = Get.put(AdhanViewModel());` في [home_view.dart:21](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/home/presentition/views/home_view.dart#L21))، مما يؤدي إلى إعادة التهيئة غير المرغوبة وإهدار الموارد.

### 1.3 حزم pubspec.yaml والحزم المتروكة أو المكررة
فحص ملف [pubspec.yaml](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/pubspec.yaml) يكشف عن وجود تكرار فادح واعتماد على حزم قديمة أو متروكة:

| الحزمة في pubspec.yaml | الإصدار المستخدم | الحالة والمشكلة | البديل المقترح |
| :--- | :--- | :--- | :--- |
| `staggered_grid_view_flutter` | `^0.0.4` | **مهجورة ومتروكة** منذ سنوات (Fork قديم يسبب مشاكل توافق مع إصدارات Flutter الحديثة). | استبدالها بـ `flutter_staggered_grid_view: ^0.7.0` أو شبكات Flutter الرسمية. |
| `adhan` و `adhan_dart` | `adhan: ^2.0.0+1`<br>`adhan_dart: ^1.1.2` | **تكرار غير مبرر**: المشروع يستورد مكتبتين مختلفتين تماماً لحساب الأذان؛ الأولى تُستخدم في مواقيت الصلاة والأخرى في القبلة! | توحيد المشروع على مكتبة واحدة رسمية موثوقة (`adhan: ^2.1.0`). |
| `geolocator` و `location` | `geolocator: ^13.0.1`<br>`location: ^6.0.2` | **تكرار**: تم استيراد مكتبتي تحديد موقع مختلفتين في نفس المشروع! | الاكتفاء بـ `geolocator` وحذف `location`. |
| `widgetkit`, `flutter_widgetkit`, `home_widget` | `1.0.2`, `1.0.3`, `^0.7.0+1` | **تكرار ثلاثي**: استيراد 3 حزم مختلفة للـ Home Widgets في نفس الوقت! | توحيد العمل على `home_widget` وحذف البقية. |
| `flutter_native_timezone_latest` | `^1.0.0` | **حزمة متروكة وغير مستقرة**؛ تسبب أعطالاً مع Android 13/14 و iOS الحديث. | الانتقال إلى الحزمة الرسمية المدعومة `flutter_timezone`. |
| `win32` | `^5.5.4` | حزمة خاصة بنظام Windows، مدرجة في التبعيات لتطبيق موجه للموبايل (Android/iOS)! | حذفها فوراً لتخفيف وزن المشروع. |
| `connectivity_plus` | `^4.0.1` | إصدار قديم جداً (الإصدار الحالي في المجتمع هو 6.x). | الترقية للإصدار الأخير. |
| `audio_video_progress_bar` | `^1.0.1` | الحزمة موجودة بينما مشغل الصوتيات نفسه (`audioplayers`) معلق ومحذوف! | إزالة الحزمة أو إعادة بناء مشغل الصوتيات المتكامل. |

---

## 2. مصادر البيانات وإدارتها

### 2.1 بنية تخزين البيانات
- **القرآن الكريم، التفسير، الأحاديث، الأذكار، وأسماء الله الحسنى**:
  - **لا يوجد أي استخدام لقواعد بيانات SQLite نهائياً**: بالرغم من وجود ملف باسم [database_helper.dart](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/core/service/database/database_helper.dart)، إلا أنه ليس سوى غلاف بسيط حول `SharedPreferences`، كما أن حزمة `sqflite` معلقة في `pubspec.yaml`.
  - جميع البيانات مخزنة في ملفات **JSON نصية ضخمة داخل مجلد `assets/`**:
    - [assets/ar_muyassar.json](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/assets/ar_muyassar.json): حجمه **3.36 ميجابايت** (تفسير ميسر كامل).
    - [assets/quran_en.json](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/assets/quran_en.json): حجمه **2.93 ميجابايت** (نص القرآن وترجمته).
    - [assets/sections/hadith.json](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/assets/sections/hadith.json): حجمه **2.36 ميجابايت** (موسوعة أحاديث).
    - [assets/azkar.json](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/assets/azkar.json): حجمه **148 كيلوبايت**.
    - [assets/Names_Of_Allah.json](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/assets/Names_Of_Allah.json): حجمه **22.8 كيلوبايت**.
    - [assets/name_quran.json](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/assets/name_quran.json): حجمه **19 كيلوبايت**.
  - **الإجمالي**: أكثر من **8.8 ميجابايت** من البيانات النصية الخام بدون أي فهرسة (Indexing).

### 2.2 آلية التحميل وتأثيرها على الأداء (Bottlenecks)
- **التحميل على الـ Main Isolate (UI Thread)**:
  - في [hadith_view_model.dart:70-76](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/hadith/presentition/view_model/hadith_view_model.dart#L70-L76): يتم تحميل وقراءة `hadith.json` (2.36 MB) عبر `rootBundle.loadString` ثم فك تشفيره بـ `json.decode()` المتزامن مباشرة على خيط واجهة المستخدم الرئيسي، يليه تكرار `for loop` على آلاف العناصر لإضافتها إلى قائمة.
  - في [tafseer_details_view_model.dart:31-36](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/tafsser/presentition/view_model.dart/tafseer_details_view_model.dart#L31-L36): يتم استدعاء وتحليل `ar_muyassar.json` (3.36 MB) بالكامل على الـ UI Thread في كل مرة يتم فيها فتح شاشة التفسير!
- **النتيجة الحتمية**:
  - تجميد فوري في واجهة المستخدم (UI Freezes / Dropped Frames) لمدة تتراوح بين 500 إلى 1500 مللي ثانية على الأجهزة المتوسطة عند الدخول لهذه الصفحات.
  - استهلاك ضخم للذاكرة (RAM Spike): تحويل 9 ميجابايت من نصوص JSON إلى عشرات الآلاف من كائنات Dart المنفصلة يستهلك أكثر من 50-80 ميجابايت إضافية في الذاكرة العشوائية.
  - استحالة عمل بحث فوري وسريع (Instant Full-Text Search) عبر آيات القرآن والتفاسير والأحاديث لغياب محرك بحث مفهرس مثل SQLite FTS5.

---

## 3. نظام الأذان ومواقيت الصلاة (Kotlin & Android)

تمت مراجعة مجلد [android/app/src/main/kotlin/com/example/quran_app_android/adhan/](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/adhan/) بالكامل، وإليك التحليل الفني المفصل:

### 3.1 طريقة الجدولة (Scheduling Mechanism)
- يتم استخدام `AlarmManager` في [PrayerScheduler.kt:210-218](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/adhan/PrayerScheduler.kt#L210-L218) مع استدعاء:
  `alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, millis, pendingIntent)`.
- لا يُستخدم `WorkManager` (معلق في pubspec).
- عند إطلاق المنبه في [AlarmReceiver.kt:66-74](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/adhan/AlarmReceiver.kt#L66-L74)، يتم استدعاء `context.startForegroundService(serviceIntent)` لتشغيل [AdhanService.kt](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/adhan/AdhanService.kt) التي تقوم بتشغيل صوت الأذان عبر `MediaPlayer` وعرض إشعار في الستارة.

### 3.2 خلل جوهري قاتل في إعادة الجدولة (Boot & Time Changes Flaw)
- **كيف يتم الحصول على المواقيت؟**
  - كود Kotlin **لا يحتوي على أي معادلة أو مكتبة لحساب مواقيت الصلاة**!
  - مواقيت الصلاة تُحسب فقط في Flutter داخل [adhan_view_model.dart:289-301](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/adhan/presentition/view_model/adhan_view_model.dart#L289-L301) ثم تُرسل إلى Kotlin كأرقام وقت ملي ثانية (Timestamps) لليوم الحالي عبر `NativeAdhanBridge.schedulePrayerTimes` ويتم حفظها في `SharedPreferences` باسم `last_prayer_times`.
- **ماذا يحدث عند إعادة تشغيل الهاتف (`BOOT_COMPLETED`)؟**
  - في [BootReceiver.kt:205-220](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/adhan/BootReceiver.kt#L205-L220): يستقبل النظام أحداث الإقلاع وتغيير الوقت، ويقرأ خطوط الطول والعرض ثم يمررها إلى `NativeAdhanBridge.reschedule(context, lat, lng)`.
  - في [NativeAdhanBridge.kt:90-105](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/adhan/NativeAdhanBridge.kt#L90-L105): الدالة **لا تستخدم الإحداثيات إطلاقاً**! بل تفتح `last_prayer_times` المخزنة سابقاً وتمررها لـ `PrayerScheduler.scheduleAll`.
  - وبما أن تلك الأوقات تخص اليوم الذي فُتح فيه التطبيق سابقاً، فإنها تصبح قديمة (`millis <= now`)، فيقوم `PrayerScheduler` بتخطيها جميعاً!
  - **النتيجة**: عند إعادة تشغيل الهاتف في أي يوم تالٍ دون فتح التطبيق يدوياً، **لن يُرفع الأذان نهائياً**!
- **الكارثة في الجدولة اليومية المتكررة (`AdhanResetReceiver.kt`)**:
  - في [AdhanResetReceiver.kt:20-24](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/adhan/AdhanResetReceiver.kt#L20-L24):
    ```kotlin
    val oldTime = json.getLong(key)
    // لو الوقت فات من اليوم السابق، زوده 24 ساعة بالضبط (86400000 ملي ثانية)
    val adjustedTime = if (oldTime <= System.currentTimeMillis())
        oldTime + 86_400_000L else oldTime
    ```
  - **أخطاء شرعية وحسابية كارثية**:
    1. مواقيت الصلاة تتغير يومياً بمقدار دقيقة إلى دقيقتين؛ إضافة 24 ساعة بالضبط يجعل الأوقات تنحرف يوماً بعد يوم بفارق دقائق واضحة عن التوقيت الحقيقي.
    2. إذا ظل الجهاز مغلقاً أو لم يفتح المستخدم التطبيق لعدة أيام، فإن إضافة 24 ساعة فقط لوقت من 5 أيام ماضية ستجعله لا يزال في الماضي، وبالتالي يتخطاه المنبه ويتوقف الأذان تماماً.
    3. عند دخول أو خروج التوقيت الصيفي، سيكون وقت الأذان خاطئاً بساعة كاملة!

### 3.3 توافقية أندرويد الحديث (Android 12/13/14) وتحسين البطارية
- **Android 12+ (`SCHEDULE_EXACT_ALARM`)**:
  - في [PrayerScheduler.kt:210](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/adhan/PrayerScheduler.kt#L210)، يتم استدعاء `setExactAndAllowWhileIdle` مباشرة دون التحقق من شرط `alarmManager.canScheduleExactAlarms()`.
  - على Android 13 و 14، قد ترفض المنظومة هذا الإذن أو تسحبه من التطبيق، مما ينتج عنه رمي `SecurityException` وفشل الجدولة دون إبلاغ المستخدم.
- **Android 13+ (`POST_NOTIFICATIONS`)**:
  - معلن في Manifest ويتم طلبه عبر `PermissionsBridge`، لكن في [MainActivity.kt:24-28](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/MainActivity.kt#L24-L28) يتم تشغيل خدمة `AdhanBackgroundService` فوراً في `onCreate` قبل حتى منح المستخدم إذن الإشعارات، مما قد يسبب استثناءات في الإصدارات الأحدث.
- **Android 14+ (`FOREGROUND_SERVICE_DATA_SYNC` و سياسات Google Play)**:
  - خدمة [AdhanBackgroundService.kt](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/adhan/AdhanBackgroundService.kt) مسجلة بنوع `dataSync` وتعمل 24 ساعة في الخلفية بإشعار دائم فقط لمراقبة تغيرات الوقت!
  - **تحذير عالي الخطورة**: سياسات Google Play لنظام Android 14 (Target SDK 34/36) تحظر تشغيل `dataSync` كخدمة مستمرة دون نقل بيانات initiated من المستخدم، وتعرض التطبيق للرفض الفوري من متجر Google Play أو إيقافه وإلغاء تثبيته بواسطة Google Play Protect.
- **WakeLock و Doze Mode**:
  - في [AlarmReceiver.kt:57-60](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/adhan/AlarmReceiver.kt#L57-L60):
    يتم استخدام `PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP`. دمج `ACQUIRE_CAUSES_WAKEUP` مع `PARTIAL_WAKE_LOCK` مهجور وغير قياسي في أندرويد ولا يضمن إيقاظ الشاشة.

### 3.4 شاشة الأذان عند قفل التطبيق (AdhanAlertActivity) ومشاكل ظهورها
- **محاولة فتح الشاشة من الـ Background**:
  - في [AlarmReceiver.kt:87](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/adhan/AlarmReceiver.kt#L87): يقوم المستقبِل باستدعاء `context.startActivity(alertIntent)` مباشرة من الخلفية.
  - **الحقيقة البرمجية**: منذ نظام **Android 10 (API 29)**، يحظر نظام أندرويد منعاً باتاً فتح أي Activity من الخلفية (Background Activity Launch Restrictions). هذه المكالمة تفشل بصمت على معظم الأجهزة الحديثة إذا كان التطبيق مغلقاً أو الجهاز مقفلاً.
- **عطل في الـ Full Screen Intent داخل `AdhanService.kt`**:
  - لحل المشكلة أعلاه، حاول المطور استخدام `NotificationCompat.Builder.setFullScreenIntent(...)` في [AdhanService.kt:56](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/adhan/AdhanService.kt#L56).
  - ولكن عند إنشاء قناة الإشعار في [AdhanService.kt:108](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/adhan/AdhanService.kt#L108):
    `NotificationManager.IMPORTANCE_LOW`!
  - **قاعدة أندرويد الصارمة**: إذا كانت أهمية القناة `IMPORTANCE_LOW`، فإن نظام أندرويد **يتجاهل تماماً** الـ Full Screen Intent والإشعارات المنبثقة (Heads-up Notifications)! وبذلك تصبح الشاشة عقيمة ولا تظهر إطلاقاً عند قفل الهاتف.
- **مشكلة الثيم والوراثة**:
  - `AdhanAlertActivity` ترث من `android.app.Activity` العادية، في حين أنها معرّفة في Manifest بثيم `Theme.AppCompat.Light.NoActionBar`، مما قد يسبب `IllegalStateException` على بعض الأجهزة لعدم وراثتها من `AppCompatActivity`.

### 3.5 طريقة حساب مواعيد الصلاة ومشاكل الدقة
- الحساب يتم حصراً في Dart داخل [adhan_view_model.dart:282-286](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/adhan/presentition/view_model/adhan_view_model.dart#L282-L286):
  ```dart
  final param = CalculationMethod.egyptian.getParameters();
  param.madhab = Madhab.shafi;
  prayerTimes = PrayerTimes.today(myCoordinates, param);
  ```
- **أسباب عدم الدقة الشديدة**:
  1. **تثبيت طريقة الحساب (CalculationMethod.egyptian)**: المستخدم في مكة المكرمة أو الرياض أو الخليج يحتاج تقويم "أم القرى" (UmmAlQura)، وفي أمريكا الشمالية (ISNA)، وفي أوروبا (Muslim World League). تثبيت الهيئة المصرية للمساحة يجعل مواعيد الفجر والعشاء خاطئة بفوارق تصل لـ 15-25 دقيقة خارج مصر!
  2. **تثبيت مذهب الشافعي (Madhab.shafi)**: يحدد وقت العصر عندما يصبح ظل الشيء مثله. أتباع المذهب الحنفي (حيث العصر عندما يصبح الظل مثليه) لا يملكون أي خيار، وسيرفع الأذان قبل وقته عندهم بساعة تقريباً.
  3. **غياب قاعدة خطوط العرض العليا (High Latitude Rule)**: في الدول الاسكندنافية أو شمال أوروبا وكندا في الصيف/الشتاء، تغيب علامات الفجر أو العشاء أو تتداخل. عدم تحديد `HighLatitudeRule` يؤدي إما لانهيار الحساب أو نتائج شاذة تماماً.
  4. **موقع القاهرة الافتراضي كـ Fallback صامت**: في حال تأخر الـ GPS، يتم ضبط الموقع تلقائياً على إحداثيات القاهرة (`30.0444, 31.2357`) في [adhan_view_model.dart:268](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/adhan/presentition/view_model/adhan_view_model.dart#L268) وإرساله لكوتلن، فيُرفع الأذان بتوقيت مصر حتى لو كان المستخدم في المغرب أو إندونيسيا!

---

## 4. الـ Widgets المصغرة (Android & iOS)

### 4.1 ويدجت أندرويد (Android AppWidget - `MyHomeWidget.kt`)
- **طريقة العمل**:
  - تم بناء ويدجت تقليدي يمتد من `AppWidgetProvider` ([MyHomeWidget.kt:18](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/MyHomeWidget.kt#L18))، ويعتمد على واجهة [my_home_widget.xml](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/res/layout/my_home_widget.xml).
  - يقوم باختيار ذكر عشوائي من أذكار `azkar.json`.
- **المشاكل الكارثية في ويدجت أندرويد**:
  1. **استنزاف بطارية مدمر عبر Exact Alarms**:
     - في [MyHomeWidget.kt:82-87](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/MyHomeWidget.kt#L82-L87):
       ```kotlin
       val interval = 5 * 60 * 1000L // كل 5 دقائق
       alarmManager.setExactAndAllowWhileIdle(
           AlarmManager.ELAPSED_REALTIME_WAKEUP,
           SystemClock.elapsedRealtime() + interval,
           pendingIntent
       )
       ```
     - استخدام منبهات دقيقة (`setExactAndAllowWhileIdle`) كل 5 دقائق لتحديث مجرد نص في ويدجت الشاشة الرئيسية هو **انتهاك صريح لإرشادات جوجل لتطوير أندرويد**، ويؤدي إلى استنزاف هائل للبطارية ومنع المعالج من الدخول في وضع السكون العميق (Deep Sleep)، وسيقوم نظام أندرويد بحظر التطبيق وإدراجه في قائمة التطبيقات المستنزفة للطاقة.
  2. **قراءة وقراءة الـ JSON على الـ Main Thread**: في كل 5 دقائق عند الاستيقاظ، يقوم بفتح الـ Asset وقراءة 148KB من نصوص `azkar.json` عبر `BufferedReader` و `JSONArray` متزامناً!
  3. **انعدام دعم الثيم الداكن**: في [my_home_widget.xml:4](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/res/layout/my_home_widget.xml#L4)، لون النص ثابت `android:textColor="#000000"` والظلال بيضاء، مما يجعله سيء المظهر على الخلفيات الداكنة ولا يستجيب للـ Dark Mode.
  4. **كود مكرر لمحاولة Scrolling فاشلة**: من السطر 99 حتى السطر 242 في `MyHomeWidget.kt`، يوجد كود معلق بالكامل يحاول تشغيل Auto-scroll للذكر كل 4 ثوانٍ داخل RemoteViews عبر Handler، وهي محاولة غير صالحة برمجياً لطبيعة الـ AppWidgets.

### 4.2 ويدجت آيفون (iOS WidgetKit - `MyHomeWidget.swift`)
- **طريقة العمل**:
  - تم إنشاؤه عبر SwiftUI و `WidgetKit` بمصفوفة زمنية `TimelineProvider` ([MyHomeWidget.swift:4](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/ios/MyHomeWidget/MyHomeWidget.swift#L4)).
  - يسترجع الذكر من `UserDefaults(suiteName: "group.com.homeScreenApp")`.
- **المشاكل الحالية في ويدجت iOS**:
  1. **الذكر لا يتغير إطلاقاً إذا كان التطبيق مغلقاً (بيانات قديمة دائماً)**:
     - الويدجت في iOS ليس لديه ملف الأذكار ولا يختار أذكاراً بنفسه؛ بل ينتظر من تطبيق Flutter أن يكتب له قيمة في `currentZekr`.
     - بما أن نظام iOS لا يسمح بتشغيل Dart في الخلفية لتحديث UserDefaults دورياً، فإن الويدجت يعيد قراءة نفس الكلمة المخزنة مراراً وتكراراً، ويظل ثابتاً على ذكر واحد لأسابيع ما لم يفتح المستخدم التطبيق.
  2. **معرّف AppGroup غير مهيأ للنشر**:
     - اسم المجموعة المستخدم هو `"group.com.homeScreenApp"` وهو اسم مؤقت لا يرتبط بحساب المطور الحقيقي في Apple Developer Portal.
- **توضيح هام جداً حول الأذان في خلفية نظام iOS**:
  - **الوضع الحالي**: لا يوجد سطر كود Native واحد للأذان في مجلد `ios/`.
  - **طبيعة نظام iOS الصارمة**:
    - على عكس أندرويد، **لا يتيح نظام iOS إطلاقاً تشغيل Foreground Services أو استخدام AlarmManager لإيقاظ التطبيق وتشغيل صوت أذان كامل (3-4 دقائق) بصوت مرتفع عندما يكون الهاتف مغلقاً**.
    - الحل القياسي في iOS هو استخدام **الإشعارات المحلية ذات الأولوية الحرجة (`UNNotificationSound` / Critical Alerts)**، مع العلم أن أقصى مدة لصوت إشعار مخصص في نظام iOS هي **30 ثانية فقط**، ولا يمكن تخطي هذه المدة في الإشعار المحلي.
    - تضمين `location` و `audio` في `UIBackgroundModes` داخل [ios/Runner/Info.plist:41-43](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/ios/Runner/Info.plist#L41-L43) دون وجود تشغيل صوتي مستمر (Music Player) أو ملاحة حية سيتسبب في **الرفض الفوري للتطبيق من قِبل مراجعي متجر Apple App Store**.

---

## 5. القبلة والموقع وحساسات البوصلة

### 5.1 تحديد الموقع والصلاحيات
- **تخبط وتضارب في حزم الصلاحيات**:
  - في [qiblah_view_model.dart](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/qiblah/presentition/view_model/qiblah_view_model.dart): يتم طلب الصلاحية عبر `permission_handler`.
  - في [qiblah_view.dart:92-115](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/qiblah/presentition/views/qiblah_view.dart#L92-L115): يتم طلب الصلاحية مرة أخرى بالتوازي عبر `geolocator` في دالة `_determinePosition()`.
  - هذا الازدواج يؤدي إلى تعارض ظهور مربعات حوار الصلاحيات (Permission Dialogs) على أندرويد و iOS، وحالات سباق (Race Conditions).

### 5.2 حساس البوصلة والدقة (Sensors & Compass)
- في [qiblah_stream_builder.dart:36-66](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/qiblah/presentition/views/widget/qiblah_stream_builder.dart#L36-L66):
  1. **خطر الانهيار المباشر (Null-Pointer Exception)**:
     - يتم استدعاء `compassEvent.heading!` بالقوة الإجبارية `!` في السطور 54 و 71.
     - إذا انقطع الحساس مؤقتاً أو أرجع الحساس حدثاً بقيمة `null` (وهو أمر شائع في هواتف أندرويد عند التحريك السريع)، ينهار التطبيق فوراً.
  2. **غياب فحص وجود الحساس (Magnetometer Sensor)**:
     - العديد من الهواتف الاقتصادية لا تحتوي على حساس بوصلة مغناطيسي (Magnetometer). التطبيق لا يتحقق من توفر الحساس، مما يترك المستخدم عالقاً في شاشة خطأ أو واجهة متجمدة دون إرشاده لعدم توفر الحساس في جهازه.
  3. **غياب المعايرة (Sensor Accuracy & Calibration)**:
     - كائن `CompassEvent` يحتوي على خاصية `accuracy`. التطبيق لا يقرأ دقة الحساس ولا ينبه المستخدم إذا كانت البوصلة غير دقيقة وتحتاج إلى حركة المعايرة الشهيرة (رسم رقم 8 في الهواء).
  4. **تدمير الأداء ورعشة المؤشر (Animation Jitter & High CPU)**:
     - تدفق `FlutterCompass.events` يُطلق أحداثاً بمعدل 30 إلى 60 مرة في الثانية (Hz).
     - في كل حدث فردي (كل 16-30 مللي ثانية)، يقوم الكود بإنشاء كائن `Tween` جديد وإعادة تشغيل المتحكم من نقطة الصفر:
       ```dart
       animation = Tween(begin: begin, end: qiblaAngle - heading).animate(widget.animationController);
       widget.animationController.forward(from: 0);
       ```
     - هذا النمط يسبب استهلاكاً مكثفاً للمعالج (High CPU Load)، ورعشة مستمرة غير مستقرة (Jitter) في صورة القبلة بدلاً من الحركة السلسة التخميدية (Smooth Damping / Low-Pass Filter).

---

## 6. واجهة المستخدم (UI/UX) والتجاوب والثيمات

### 6.1 التجاوب على الشاشات المختلفة (Responsiveness & Foldables & Tablets)
- **أبعاد ثابتة ونسب كسرية مكسورة**:
  - في [home_view.dart:52](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/home/presentition/views/home_view.dart#L52):
    `height: MediaQuery.sizeOf(context).height * 1.06`!
    إعطاء حاوية داخل `SingleChildScrollView` ارتفاعاً مضاعفاً بنسبة 1.06 يتسبب في قطع المحتوى السفلي، أو حدوث أخطاء تجاوز المساحة (RenderFlex Overflow) على الشاشات ذات الكثافات المختلفة أو عند تفعيل تكبير الخطوط من إعدادات النظام (Accessibility Font Scaling).
  - في [home_grid_view.dart:33-35](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/home/presentition/views/widget/home_grid_view.dart#L33-L35):
    `MediaQuery.sizeOf(context).height * 0.00156`!
    استخدام هذا المعامل الكسري مع الارتفاع يجعل العناصر مضغوطة بشكل مشوه في الوضع الأفقي (Landscape) أو على الأجهزة القابلة للطي (Foldables)، وتصبح متناهية في الكبر على أجهزة التابلت.
  - في [container_last_read.dart:118-119](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/home/presentition/views/widget/container_last_read.dart#L118-L119):
    تحديد أبعاد شريط التاريخ الهجري بـ `width * .45` و `height * .035` يؤدي بانتظام إلى خطأ تجاوز البكسلات المشهور (`A RenderFlex overflowed by xx pixels`) عندما تكون أسماء الأشهر الهجرية طويلة (مثل "جمادى الآخرة").

### 6.2 ألوان وثيمات مشوهة وغياب الدارك مود (Dark Mode Failure)
1. **الوضع الداكن معطل إجبارياً**: في [main.dart:122](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/main.dart#L122)، تم تثبيت `themeMode: ThemeMode.light`، مما يمنع التطبيق من الاستجابة لإعدادات النظام الداكنة، ولا يوجد خيار في الإعدادات للتبديل بين الفاتح والداكن.
2. **كارثة اللون في الثيم الداكن**:
   في [dark_theme.dart:28](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/core/service/themes/dark_theme.dart#L28):
   ```dart
   bodyMedium: TextStyle(
       fontFamily: 'Rubik',
       color: Colors.black, // نص أسود داخل الثيم الداكن!
       fontWeight: FontWeight.bold,
       fontSize: 22,
   )
   ```
   النصوص الأساسية معرّفة بلون أسود داخل ملف الثيم الداكن؛ أي نص يستخدم هذا النمط سيختفي تماماً وتصبح الشاشة سوداء على أسود.
3. **ألوان متنافرة وغير موحدة**:
   - في [container_last_read.dart:122-133](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/home/presentition/views/widget/container_last_read.dart#L122-L133): شريط التاريخ الهجري مصمم بلون أصفر فاقع جداً (`#E1CB02`) والنص داخله مكتوب باللون **الأحمر الصريح** (`Colors.red`)! هذا التباين مؤذٍ بصرياً ولا يمت للهوية الإسلامية أو التصميم الاحترافي بأي صلة.
   - في شاشة قراءة القرآن [quran_details_list_view_item.dart:45](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/quran/presentition/views/widget/quran_details_list_view_item.dart#L45)، التدرجات اللونية الساطعة والنصوص السوداء (`Colors.black87`) ثابتة (Hardcoded) ولا تدعم القراءة الليلية إطلاقاً.

### 6.3 مشاكل الخطوط واتجاه النصوص (Fonts & RTL)
- **خطوط مفقودة ومربكة في `pubspec.yaml`**:
  - خط `'SourceSansPro'` مستخدم في عدة أماكن داخل ملفات الثيم، لكنه **غير موجود إطلاقاً** في `pubspec.yaml`، مما يضطر النظام لاستخدام خط احتياطي غير متناسق.
  - عائلة الخط المسماة `Rubik` في [pubspec.yaml:74-76](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/pubspec.yaml#L74-L76) تم ربطها بملف خط مختلف تماماً: `BalooBhaijaan2-VariableFont_wght.ttf`!
- **مشاكل اتجاه الواجهة (RTL)**:
  - استخدام أيقونات اتجاهية ثابتة مثل `IconBroken.Arrow___Right_2` في [container_last_read.dart:100](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/home/presentition/views/widget/container_last_read.dart#L100)؛ السهم يشير لليمين في واجهة عربية تبدأ من اليمين لليسار، مما يربك المستخدم.
  - خلط لغات عشوائي في الواجهة: نصوص مثل `'Last Read  آخر قراءة'` و `'Go to'`.

---

## 7. صفحات المصحف الشريف وتجربة القراءة الواقعية

### 7.1 طريقة العرض الحالية
- يتم عرض القرآن بنص خام عادي (Plain Text) مأخوذ من ملف `quran_en.json` بخط `Kitab`.
- في [quran_screen_model_details.dart:167-188](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/quran/presentition/view_model/quran_screen_model_details.dart#L167-L188):
  - يتم "تقسيم" السورة الواحدة إلى صفحات بناءً على **معادلة عشوائية تعتمد على عدد الحروف والآيات**:
    - الحد الأقصى للحروف: 620 حرفاً لكل صفحة.
    - الحد الأقصى للآيات: 5 إلى 9 آيات لكل صفحة.
- **العيوب الفادحة في هذا الأسلوب**:
  1. **لا علاقة له إطلاقاً بمصحف المدينة المنورة ذي الـ 604 صفحات**: التقسيم يتم داخل كل سورة بشكل منفصل؛ سورة البقرة تصبح صفحات تبدأ من 1 وتنتهي عند 25 مثلاً، ولا يوجد مفهوم لرقم الصفحة الحقيقي للمصحف (من 1 إلى 604)، ولا مفهوم للجزء والحزب والربع.
  2. **تناقض شاشات التمرير (Nested Scrolling Disasters)**:
     في [quran_details_list_view_item.dart:159-168](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/quran/presentition/views/widget/quran_details_list_view_item.dart#L159-L168)، تحتوي كل صفحة داخل الـ `PageView` الأفقي على `SingleChildScrollView` عمودي خاص بها! هذا يعني أن المستخدم إذا غيّر حجم الخط، لا يرى الصفحة كاملة، بل يضطر للتمرير رأسياً ثم السحب أفقياً للانتقال للصفحة التالية، مما يدمر تجربة قراءة القرآن بالكامل.
  3. **رسم الآيات ورموز نهاياتها**: يتم إقحام عنصر `WidgetSpan` يحتوي على `Container` لكل رقم آية داخل `Text.rich`، مما يثقل محرك معالجة النصوص في Flutter ويسبب تقطيعاً ملحوظاً أثناء القراءة السريعة.

### 7.2 متطلبات التحول لتجربة مصحف حقيقي (Real Mushaf Experience)
للوصول لتجربة مصحف متطابق مع مصحف المدينة المنورة (604 صفحات) مع تقليب صفحات واقعي، يلزم ما يلي:
1. **قاعدة بيانات صفحات المصحف الـ 604**:
   - الاعتماد على قاعدة بيانات جاهزة ومضغوطة (SQLite) تربط كل صفحة (من 1 إلى 604) ببياناتها المعتمدة: رقم الجزء، رقم الحزب، اسم السورة، الربع، مواضع السجدات، والآيات الدقيقة التي تبدأ وتنتهي بها الصفحة.
2. **محرك العرض (Rendering Engine)** - يتوفر أحد خيارين احترافيين:
   - **الخيار الأول (الموصى به للأداء والجماليات)**: صفحات فيكتور عالية الجودة بتنسيق SVG أو صور محسنة WebP بدقة عالية (Retina) مع طبقة لمس ذكية (Interactive Glyphs Layer) لتحديد الآيات وتظليلها عند القراءة والتفسير والاستماع.
   - **الخيار الثاني (Font-based QCF)**: استخدام خطوط مجمع الملك فهد لطباعة المصحف الشريف (Quran Complex Fonts - QCF v2)، حيث تخصص عائلة خط مستقلة لكل صفحة من الـ 604 صفحات لضمان ضبط بداية ونهاية كل سطر بدقة 15 سطراً لكل صفحة.
3. **محرك تقليب الصفحات ثلاثي الأبعاد (Real 3D Page Flip / Curl Engine)**:
   - استبدال الـ `PageView` التقليدي بمحرك تقليب يحاكي انحناء الورق الفيزيائي وظلاله (Page Curl Shader) يتيح التقليب السلس من اليسار لليمين (حسب قراءة المصحف الشريف)، مع إمكانية القراءة بالصفحة المزدوجة (Dual Page) تلقائياً على الشاشات الكبيرة والتابلت.

---

## 8. الأداء والاستقرار وتسريب الذاكرة

### 8.1 تسريب الذاكرة (Memory Leaks)
1. **عدم إغلاق متحكمات التمرير (Unclosed Controllers)**:
   - في [tafseer_details_view_model.dart:138-142](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/tafsser/presentition/view_model.dart/tafseer_details_view_model.dart#L138-L142)، قام المطور بتعريف دالة باسم `dispose()` بدلاً من استخدام دورة حياة GetX الرسمية `onClose()`. ونتيجة لذلك، لا يقوم GetX باستدعاء دالة التخلص، ويبقى كائن `ScrollController` عالقاً في الذاكرة ومسبباً لتسريب مستمر.
2. **تسريب الـ Context في الإشعارات**:
   - أشار تحليل `flutter analyze` إلى وجود تسريب للـ `BuildContext` عبر العمليات غير المتزامنة دون فحص `mounted` في [section_azkar_notification.dart:98](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/settings/presentition/views/widget/section_azkar_notification.dart#L98).
3. **تراكم الـ Listeners في Android Native**:
   - في كود كوتلن [AzkarBubbleService.kt:701](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/azkar/AzkarBubbleService.kt#L701)، استخدام `Handler(Looper.getMainLooper())` مع إرسال Runnables دون إزالتها عبر `removeCallbacksAndMessages(null)` في كل مسارات الخروج يسبب تسريب خدمة الـ Service داخل الـ WindowManager.

### 8.2 عمليات إعادة البناء غير الضرورية (Excessive Rebuilds)
- استدعاء `update()` بدون معرّفات (IDs) في كائنات `GetxController`، مما يؤدي إلى إعادة بناء كامل الشجرة لكل الـ Widgets المربوطة بالـ Controller، حتى لو تغير متغير ثانوي واحد.
- استدعاء دالة `HijriCalendar.setLocal('ar')` في دالة `build()` لشاشة [container_last_read.dart:17](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/home/presentition/views/widget/container_last_read.dart#L17) في كل إطار (Frame) يؤدي إلى إهدار دورات المعالجة وتعديل متغيرات ثابتة على نطاق التطبيق بدون مبرر.

### 8.3 حجم التطبيق والـ Assets
- أصول مكررة وغير مضغوطة: ملفات الصوت (`adhan.wav`, `azkar_1.wav`, `azkar_2.wav`) مخزنة بصيغة WAV غير المضغوطة في مجلد الأندرويد، بالإضافة لملفات MP3 و JSON ضخمة، مما يزيد من حجم حزمة التطبيق (APK) بدون داعٍ مقارنة بالصيغ الحديثة مثل OGG أو Opus.

---

## 9. الأمان، جودة الكود، والاختبارات

### 9.1 سلامة المتغيرات والقيم الفارغة (Null Safety)
- استخدام مفرط وغير منضبط لمعامل الفرض `!` (Force Unwrapping Operator)، مثل:
  - `settingsServices.sharedPref!.getString('lastRead')` في [container_last_read.dart:66](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/home/presentition/views/widget/container_last_read.dart#L66).
  - `compassEvent.heading!` في [qiblah_stream_builder.dart:54](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/qiblah/presentition/views/widget/qiblah_stream_builder.dart#L54).
  - `latitude!` و `longitude!` في [adhan_view_model.dart](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/adhan/presentition/view_model/adhan_view_model.dart).
  أي قيمة غير متوقعة أو تأخر في التهيئة سيتسبب فورياً في Crash أحمر يظهر للمستخدم.

### 9.2 معالجة الأخطاء (Error Handling)
- في العديد من الأماكن في كود Dart و Kotlin، يتم ابتلاع الأخطاء بكتل `catch` فارغة أو طباعتها فقط:
  - `catch (_) {}` في [AlarmReceiver.kt](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/adhan/AlarmReceiver.kt) و [BatteryDialogChannel.kt](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/permissions/BatteryDialogChannel.kt).
  - استخدام `print()` المباشر في بيئة الإنتاج كما في [native_azkar_bridge.dart:40, 42, 50, 52](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/core/native/native_azkar_bridge.dart#L40).

### 9.3 حالة الاختبارات (Tests Status)
- **نسبة التغطية (Code Coverage): 0%**.
- ملف الاختبار الوحيد في المشروع [test/widget_test.dart](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/test/widget_test.dart) هو كود افتراضي لعداد (Counter) لا وجود له في التطبيق، وتشغيل أمر `flutter test` يفشل مباشرة.
- لا توجد اختبارات وحدة (Unit Tests) للعمليات الحسابية للأذان أو معالجة التواريخ، ولا اختبارات واجهة (Widget Tests).

---

## 10. مصفوفة المشاكل مرتبة حسب الأولوية

### 🔴 أولاً: مشاكل حرجة (Critical - يجب حلها فوراً لمنع الأعطال وفشل الوظائف الأساسية)

| # | المشكلة التقنية | موقع المشكلة والملف | رقم السطر | الأثر والخطورة |
| :---: | :--- | :--- | :--- | :--- |
| **C1** | **توقف الأذان التام بعد إغلاق الهاتف أو مرور يوم** (إعادة جدولة تعتمد على أوقات ماضية دون حساب مواقيت الصلاة في Native). | `android/app/src/main/kotlin/.../adhan/` [BootReceiver.kt](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/adhan/BootReceiver.kt#L205) و [NativeAdhanBridge.kt](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/adhan/NativeAdhanBridge.kt#L90) | `BootReceiver.kt:205-220`<br>`NativeAdhanBridge.kt:90-105` | يتوقف الأذان عن العمل كلياً بعد إعادة تشغيل الهاتف في أي يوم تالٍ. |
| **C2** | **خطأ شرعي وزمني في الجدولة اليومية** عبر إضافة 24 ساعة بالضبط (`+ 86400000L`) لوقت قديم دون حساب فلكي. | `android/app/src/main/kotlin/.../adhan/` [AdhanResetReceiver.kt](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/adhan/AdhanResetReceiver.kt#L21) | `AdhanResetReceiver.kt:21-23` | انحراف مواقيت الصلاة يومياً بفوارق دقائق، وانهيارها بساعة كاملة مع التوقيت الصيفي. |
| **C3** | **فشل شاشة الأذان في الظهور عند القفل** بسبب منع إطلاق الأنشطة من الخلفية وقناة الإشعار ذات الأهمية المنخفضة `IMPORTANCE_LOW`. | `android/app/src/main/kotlin/.../adhan/` [AdhanService.kt](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/adhan/AdhanService.kt#L108) و [AlarmReceiver.kt](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/adhan/AlarmReceiver.kt#L87) | `AdhanService.kt:108`<br>`AlarmReceiver.kt:87` | لا تظهر شاشة تنبيه الأذان على شاشة القفل، ويعمل الصوت فقط في الخلفية دون واجهة استجابة. |
| **C4** | **استنزاف بطارية محظور ومخالفة سياسات متجر Google Play** عبر تشغيل Foreground Service متواصلة ومحاولة إنعاش الويدجت بـ Exact Alarm كل 5 دقائق. | `android/app/src/main/kotlin/.../` [MyHomeWidget.kt](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/MyHomeWidget.kt#L82) و [MainActivity.kt](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/android/app/src/main/kotlin/com/example/quran_app_android/MainActivity.kt#L24) | `MyHomeWidget.kt:82-87`<br>`MainActivity.kt:24-28` | استنزاف بطارية عنيف وحظر التطبيق أو رفضه في مراجعة متجر Google Play (سياسات Android 14 FGS). |
| **C5** | **خطر الانهيار الفوري في شاشة القبلة** عبر استخدام Force Unwrap `!` لحدث البوصلة دون فحص التوفر. | `lib/features/qiblah/presentition/views/widget/` [qiblah_stream_builder.dart](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/qiblah/presentition/views/widget/qiblah_stream_builder.dart#L54) | `qiblah_stream_builder.dart:54, 71` | انهيار التطبيق (Crash) عند فقدان قراءة البوصلة أو في الهواتف التي تفتقر للمستشعر. |
| **C6** | **تجميد واجهة المستخدم (UI Jank & Freezes)** عند فتح القرآن والتفسير والأحاديث بسبب تفكيك ملفات JSON بحجم 9 ميجابايت على الـ Main Thread. | `lib/features/hadith/presentition/view_model/` [hadith_view_model.dart](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/hadith/presentition/view_model/hadith_view_model.dart#L71) و [tafseer_details_view_model.dart](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/tafsser/presentition/view_model.dart/tafseer_details_view_model.dart#L32) | `hadith_view_model.dart:71`<br>`tafseer_details_view_model.dart:32` | تجمد الشاشة بالكامل وسقوط الإطارات، واستهلاك زائد للذاكرة قد يسبب إغلاق التطبيق قسراً (OOM Crash). |
| **C7** | **خطر رفض App Store الحتمي** بسبب تضمين `location` و `audio` في `UIBackgroundModes` بدون مشغل صوتيات نشط أو تتبع ملاحة فعلي. | `ios/Runner/` [Info.plist](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/ios/Runner/Info.plist#L41) | `Info.plist:41-43` | رفض فوري للتطبيق أثناء مراجعة متجر Apple App Store (Guideline 2.5.4). |

---

### 🟡 ثانياً: مشاكل مهمة (High / Major - تؤثر على تجربة المستخدم وصحة الحسابات والواجهات)

| # | المشكلة التقنية | موقع المشكلة والملف | رقم السطر | الأثر |
| :---: | :--- | :--- | :--- | :--- |
| **M1** | **تثبيت طريقة الحساب على الهيئة المصرية والمذهب الشافعي كوداً** وعدم إمكانية تغييرها أو ضبط خطوط العرض العليا. | `lib/features/adhan/presentition/view_model/` [adhan_view_model.dart](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/adhan/presentition/view_model/adhan_view_model.dart#L283) | `adhan_view_model.dart:283-285` | عدم دقة مواقيت الصلاة في السعودية والخليج وأوروبا وأمريكا ولأتباع المذهب الحنفي. |
| **M2** | **ويدجت iOS يعرض نفس الذكر دائماً** لعدم قدرته على التحديث الذاتي في الخلفية واعتماده على معرّف AppGroup مؤقت. | `ios/MyHomeWidget/` [MyHomeWidget.swift](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/ios/MyHomeWidget/MyHomeWidget.swift#L16) | `MyHomeWidget.swift:16-21` | الويدجت يفقد قيمته تماماً في نظام iOS ولا يقدم أي محتوى متجدد للمستخدم. |
| **M3** | **المصحف يفتقر للترقيم الحقيقي (604 صفحات)** ويعتمد على تقسيم عشوائي بالحروف مع تضارب تمرير أفقي ورأسي معاً. | `lib/features/quran/presentition/view_model/` [quran_screen_model_details.dart](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/quran/presentition/view_model/quran_screen_model_details.dart#L169) | `quran_screen_model_details.dart:169-188` | تجربة قراءة بدائية وغير مطابقة للمصحف الشريف ولا تتيح التصفح الطبيعي. |
| **M4** | **أخطاء التجاوب و RenderFlex Overflows المتكررة** بسبب المعاملات النسبية العشوائية في الصفحة الرئيسية. | `lib/features/home/presentition/views/` [home_view.dart](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/home/presentition/views/home_view.dart#L52) و [container_last_read.dart](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/home/presentition/views/widget/container_last_read.dart#L118) | `home_view.dart:52`<br>`container_last_read.dart:118` | تشوه كامل للشاشات الكبيرة والتابلت وظهور أخطاء البكسلات الصفراء/السوداء. |
| **M5** | **الثيم الداكن معطل ومكسور برمجياً** (نصوص سوداء في الوضع الليلي وإلغاء الثيم الداكن في main). | `lib/` [main.dart](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/main.dart#L122) و [dark_theme.dart](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/core/service/themes/dark_theme.dart#L28) | `main.dart:122`<br>`dark_theme.dart:28` | استحالة استخدام التطبيق في الوضع الليلي دون اختفاء النصوص أو تشوهها. |
| **M6** | **رعشة البوصلة الحادة واستهلاك المعالج** نتيجة إعادة إنشاء الـ Tween مع كل إطار للـ Stream. | `lib/features/qiblah/presentition/views/widget/` [qiblah_stream_builder.dart](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/qiblah/presentition/views/widget/qiblah_stream_builder.dart#L58) | `qiblah_stream_builder.dart:58-64` | حركة اهتزازية عنيفة لإبرة القبلة، وبطء في الاستجابة واستهلاك حراري للجهاز. |
| **M7** | **ازدواجية الحزم والمكتبات في pubspec.yaml** (adhan مع adhan_dart، geolocator مع location، 3 مكتبات للويدجت). | `pubspec.yaml` | `pubspec.yaml:23, 34, 37, 38, 40-42` | زيادة حجم التطبيق، وتضارب قنوات الاتصال، ومشاكل الصيانة والتوافق. |

---

### 🟢 ثالثاً: تحسينات وجودة كود (Medium / Low / Clean Code)

| # | التحسين المقترح | الموقع والملف | ملاحظات |
| :---: | :--- | :--- | :--- |
| **L1** | تصحيح الأخطاء الإملائية في أسماء المجلدات (`presentition/` -> `presentation/`). | جميع مجلدات `lib/features/*/` | تحسين مقروئية وهيكل المشروع. |
| **L2** | إزالة مئات الأسطر المنسوخة والمعلقة في ملفات Kotlin وملف `dead_code.dart`. | `PrayerScheduler.kt`, `BootReceiver.kt`, `BatteryDialogChannel.kt`, `AzkarBubbleService.kt`, `dead_code.dart` | تنظيف الكود وتقليص مساحة المشروع وسرعة البناء (Build time). |
| **L3** | إعادة صياغة تباين ألوان شريط التاريخ الهجري (إزالة الأصفر الفاقع مع النص الأحمر). | `lib/features/home/presentition/views/widget/container_last_read.dart:122` | جعل الألوان متسقة مع هوية التطبيق الهادئة والمريحة للعين. |
| **L4** | تصحيح عائلة الخط `Rubik` في `pubspec.yaml` وإزالة الخطوط المفقودة مثل `SourceSansPro`. | `pubspec.yaml:74-76` و `lib/core/service/themes/*.dart` | إعطاء النصوص مظهرها الطباعي الصحيح. |
| **L5** | كتابة اختبارات وحدة (Unit Tests) للعمليات الحسابية للأذان وإصلاح ملف الـ Tests المكسور. | `test/widget_test.dart` | ضمان استقرار التطبيق قبل النشر على المتاجر. |
| **L6** | تطبيق نمط الفرز والمستودعات (Repository Pattern) لفصل GetX عن استدعاءات البيانات المباشرة. | `lib/features/*/view_model/` | رفع جودة المعمارية وتسهيل الصيانة المستقبلية. |

---

## 11. خطة الإصلاح والتحسين المقترحة (على مراحل)

للوصول بالتطبيق إلى أعلى معايير الجودة والاستقرار، نقترح خطة تنفيذية مقسمة إلى **5 مراحل متتالية**:

### المرحلة 1: تنظيف المشروع وهيكلة الحزم والبيانات (Data & Architecture Cleanup)
1. **تنظيف `pubspec.yaml`**:
   - إزالة الحزم المكررة والمهجورة (`win32`, `staggered_grid_view_flutter`, `adhan_dart`, `location`, `widgetkit`, `flutter_widgetkit`).
   - اعتماد النسخ المحدثة والمستقرة (`flutter_timezone`, `home_widget`, `adhan`, `geolocator`).
2. **التحول إلى قاعدة بيانات محلية SQLite مفهرسة (Offline SQLite DB)**:
   - تحويل ملفات الـ JSON الضخمة (`ar_muyassar.json`, `quran_en.json`, `hadith.json`) إلى قاعدة بيانات SQLite محلية مهيأة ومفهرسة مسبقاً (Pre-populated SQLite Database) مع تقنية البحث فائق السرعة `FTS5`.
   - الاستعلام المباشر عن السور والآيات والتفاسير حسب الطلب (On-Demand Pagination) لتوفير الذاكرة والقضاء التام على تجمد الشاشات (UI Freezes).
3. **تنظيف كود Kotlin وحذف مئات الأسطر الميتة والتعليقات** من جميع ملفات `android/` و `dead_code.dart`.

### المرحلة 2: إعادة هندسة نظام الأذان بالكامل في أندرويد (Robust Native Adhan Engine)
1. **نقل محرك حساب الأذان ليعمل ذاتياً داخل Kotlin (Native Adhan Calculation)**:
   - تضمين مكتبة الحسابات الفلكية للأذان داخل كوتلن (أو استخدام خوارزمية فلكية مدمجة).
   - عند استقبال حدث `BOOT_COMPLETED` أو `TIMEZONE_CHANGED`، يقوم كود كوتلن بقراءة آخر إحداثيات موقع للمستخدم وحساب مواقيت اليوم الجديد والأيام القادمة برمجياً ودقة متناهية دون الحاجة لفتح Flutter نهائياً.
2. **إصلاح شاشة الأذان عند القفل (Adhan Lock Screen UI)**:
   - ضبط قناة إشعار الأذان على `NotificationManager.IMPORTANCE_MAX` / `HIGH`.
   - استخدام `PendingIntent` مخصص للـ `FullScreenIntent` متوافق مع Android 10/11/12/13/14.
   - التحقق من صلاحية `USE_FULL_SCREEN_INTENT` وطلبها برمجياً على Android 14.
3. **ضبط صلاحيات الطاقة وأندرويد الحديث**:
   - التخلص التام من خدمة `AdhanBackgroundService` ذات الـ 24 ساعة لتفادي رفض Google Play.
   - التحقق دائماً من `alarmManager.canScheduleExactAlarms()` قبل استدعاء `setExactAndAllowWhileIdle`، وتوجيه المستخدم لإعدادات النظام في حال سحب الإذن.
   - طلب تجاهل تحسينات البطارية (`ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`) بشفافية واحترافية.

### المرحلة 3: إصلاح الـ Widgets وحل معضلة iOS
1. **إعادة بناء ويدجت أندرويد (AppWidget)**:
   - التوقف الفوري عن استخدام المنبهات الدقيقة (`setExactAndAllowWhileIdle`) لتحديث الويدجت كل 5 دقائق.
   - الاعتماد على `PeriodicWorkRequest` عبر `WorkManager` كل 15-30 دقيقة، مع التحديث الفوري عند دخول وقت صلاة جديد أو عند فتح التطبيق.
   - تصميم واجهة عصرية تدعم الوضعين الفاتح والداكن (Light & Dark Mode) وألوان النظام الديناميكية (Material You).
2. **تطوير ويدجت iOS (WidgetKit Timeline)**:
   - تزويد الـ WidgetKit بمصفوفة زمنية ممتدة (Timeline entries) للأذكار ومواقيت الصلاة تكفي لـ 24-48 ساعة قادمة دفعة واحدة بدلاً من طلب قيمة واحدة ثابتة.
   - تصحيح معرّف الـ App Group ليكون رسمياً ومتوافقاً مع حساب المطور.
3. **تطبيق الحل المعتمد لإشعارات الأذان على iOS**:
   - حذف وسوم الـ background modes غير القانونية في iOS لمنع رفض التطبيق.
   - جدولة 64 إشعاراً محلياً مجدولاً مسبقاً (Local Scheduled Notifications) مع صوت أذان مخصص بصيغة `caf`/`wav` (بحد أقصى 30 ثانية لكل إشعار حسب قيود Apple)، وتحديثها تلقائياً في كل مرة يفتح فيها المستخدم التطبيق.

### المرحلة 4: تطوير مصحف حقيقي متطابق مع مصحف المدينة (604 صفحات)
1. **تضمين صفحات مصحف المدينة المنورة (604 صفحات)**:
   - ربط الصفحات بقاعدة بيانات دقيقة تضمن ترقيم صفحات مصحف المدينة (من 1 إلى 604) مع بيانات الأجزاء والأحزاب والأرباع بدقة.
   - اعتماد خطوط الرسم العثماني لكل صفحة أو صفحات SVG/WebP متجهة فائقة الوضوح.
2. **دمج محرك تقليب الصفحات ثلاثي الأبعاد (Real 3D Page Flip)**:
   - إتاحة تقليب الصفحات كأنك تمسك بمصحف ورقي حقيقي، مع القراءة بدون أي تمرير رأسي مزعج داخل الصفحة.
   - دعم حفظ علامات القراءة (Bookmarks) بالصفحة والآية.
3. **توفير تظليل الآيات والتفسير اللحظي**:
   - إمكانية الضغط المطول على أي آية لعرض تفسيرها الميسر، أو الاستماع إليها، أو نسخها ومشاركتها.

### المرحلة 5: تحسين واجهة المستخدم، القبلة، والتجاوب وضمان الجودة
1. **إصلاح شاشة القبلة والبوصلة**:
   - التحقق من وجود حساس الـ Magnetometer وعرض رسالة توضيحية بديلة إن لم يكن متوفراً.
   - تطبيق خوارزمية تنعيم الحركة (Low-Pass Filter) لمؤشر القبلة لمنع الرعشة واستهلاك المعالج.
   - إظهار مؤشر دقة البوصلة وإرشاد للمعايرة عند الحاجة.
2. **توحيد الثيم ودعم الوضع الداكن الحقيقي (True Dark Mode)**:
   - تفعيل خيار تبديل الثيم في الإعدادات (فاتح / داكن / حسب النظام).
   - إصلاح كافة الألوان المتنافرة، وجعل التباين مريحاً ومطابقاً لمعايير التصميم الحديثة.
   - إصلاح مشاكل الـ Responsiveness والتجاوب على الشاشات الكبيرة والتابلت.
3. **كتابة الاختبارات الأساسية (Unit & Integration Tests)**:
   - كتابة اختبارات شاملة لحسابات الأذان، تحويل التاريخ الهجري، ومنطق قواعد البيانات.

---

## 12. أسئلة جوهرية وقرارات تقنية مطلوبة منكم قبل البدء

قبل أن نبدأ في كتابة أي كود أو تنفيذ خطة الإصلاح، هناك بعض القرارات الأساسية التي نحتاج معرفة اختياركم بخصوصها:

1. **طريقة عرض صفحات المصحف المفضلة لديكم**:
   - **الخيار (أ)**: استخدام صور فيكتور/WebP عالية الجودة متطابقة 100% مع صفحات مصحف مجمع الملك فهد (تضمن تطابقاً بصرياً تاماً مع المصحف المطبوع، وهي الأسهل في دمج محرك التقليب ثلاثي الأبعاد).
   - **الخيار (ب)**: استخدام خطوط الرسم العثماني الرقمية لكل صفحة (Font-based QCF v2) (تسمح بتغيير أحجام الخطوط وألوان الخلفيات، لكنها تحتاج لمعالجة معقدة لضبط 604 خطوط مختلفة في الـ Assets).
   *ما هو الخيار الأنسب لرؤيتكم للمشروع؟*

2. **قواعد بيانات القرآن والأحاديث**:
   - هل تفضلون الاعتماد على قاعدة بيانات **SQLite محلية مضمنة بالكامل داخل التطبيق (Offline)** بحجم تقريبي (~15-20 ميجابايت للقرآن والتفسير وكتب الحديث)، بحيث يعمل التطبيق فوراً بدون إنترنت ودون أي شاشات انتظار؟

3. **سلوك شاشة الأذان على الهواتف المقفلة**:
   - على أندرويد، هل تفضلون أن تظهر شاشة تنبيه كاملة تضيء الشاشة فوق القفل (Full-Screen Alarm Activity الشبيهة بمنبه الهاتف)، أم الاكتفاء بإشعار منبثق فائق الأهمية (High Priority Heads-up Notification) مع تشغيل الصوت؟
   - هل تستهدفون مستخدمين في دول ومذاهب مختلفة لنقوم بتفعيل شاشة اختيار (طريقة الحساب: أم القرى، الهيئة المصرية، كراتشي، أمريكا الشمالية... ومذهب العصر: شافعي / حنفي)؟

4. **سياسة دعم نظام iOS للأذان**:
   - كما وضحنا، يفرض نظام iOS قيوداً صارمة على الصوت في الخلفية (أقصى مدة لصوت الإشعار هي 30 ثانية ولا يمكن فتح الشاشة بالقوة). هل نعتمد نظام الإشعارات المحلية المجدولة المسبقة (Scheduled Local Notifications مع صوت الأذان 30 ثانية) وهو المعيار المعتمد لدى جميع التطبيقات الإسلامية في App Store (مثل Muslim Pro و المصلي)؟

5. **أذكار الشاشة العائمة (Floating Bubble - `SYSTEM_ALERT_WINDOW`)**:
   - ميزة الفقاعة العائمة الموجودة حالياً في كود كوتلن تتطلب إذن "الظهور فوق التطبيقات الأخرى"، وهذا الإذن أصبح يخضع لقيود شديدة على متجر Google Play. هل ترغبون في الإبقاء على هذه الميزة وتطويرها بشكل آمن، أم الاكتفاء بالإشعارات المجدولة والويدجت لضمان سرعة قبول التطبيق على المتجر؟
