# تقرير الجرد والتحليل الشامل لمطابقة الميزات: Android مقابل iOS
**تاريخ التقرير:** 3 أكتوبر 2026  
**حالة الاختبار على iOS:** `لم يُختبر فعلياً على جهاز حقيقي أو محاكي macOS (بيئة التطوير الحالية Windows)`  
**منهجية الفحص:** فحص كود المشروع الفعلي سطراً بسطر في مجلدات `lib/` و `android/` و `ios/`.

---

## 1. الفهرس والجرد العام للميزات من الكود الفعلي

| # | الميزة / القسم | الوصف والمسؤولية في الكود |
|---|---|---|
| **1** | **المصحف الشريف (الصفحات والتلاوة)** | عرض 604 صفحات بالرسم العثماني وخطوط QPC v2، تقليب الصفحات، حفظ موضع القراءة، والوضع الليلي. |
| **2** | **الفهرس والعلامات المرجعية** | فهرس السور والأجزاء والأحزاب، البحث، حفظ العلامات المرجعية المتعددة والملاحظات. |
| **3** | **الورد القرآني ومتابعة القراءة** | تحديد الهدف اليومي (صفحات/أجزاء)، تتبع الأيام المستمرة (Streak)، وتسجيل الإنجاز اليومي. |
| **4** | **الأذان: الحساب والمواقيت** | حساب مواقيت الصلاة فلكياً (طريقة الحساب، المذهب، فروق الدقائق، الموقع الجغرافي). |
| **5** | **الأذان: الجدولة والتنبيه الخلفي** | إطلاق التنبيهات في الموعد المحدد حتى لو كان التطبيق مغلقاً بالكامل أو الهاتف في وضع السكون. |
| **6** | **الأذان: شاشة التنبيه التفاعلية** | شاشة كاملة فوق شاشة القفل، تفاعلية، أزرار (صلّيت / إيقاف الصوت)، دعاء بعد الأذان. |
| **7** | **الأذان: كتم الصوت بالأزرار المادية** | كتم صوت الأذان فوراً عند الضغط على أزرار رفع/خفض الصوت أو زر البور/القفل. |
| **8** | **شريط الإشعارات وشاشة القفل الدائم** | بانر مستمر (Foreground Notification) يعرض الصلاة القادمة والعد التنازلي والورد والذكر. |
| **9** | **التذكيرات: الورد ومواصلات والصدقة** | محرك جدولة محلي للتذكير بورد القرآن، ورد المواصلات، الصدقة الشهرية، والأذكار المجدولة. |
| **10** | **الأذكار وحصن المسلم** | مكتبة أذكار كاملة مصنفة من قاعدة بيانات SQLite، مع عدادات تفاعلية واهتزاز. |
| **11** | **الأذكار الذكية (Smart Zikr Card)** | بطاقة تفاعلية متجددة بالصفحة الرئيسية تتغير بحسب وقت اليوم (صباح/مساء/ليل). |
| **12** | **الويدجت (Home Screen Widgets)** | ويدجت الشاشة الرئيسية (الأذكار الدورية، مواقيت الصلاة، الورد والختمة). |
| **13** | **اتجاه القِبلة والبوصلة** | بوصلة تفاعلية بحساسات الجهاز والواقع المعزز (AR) والمسافة إلى الكعبة المشرفة. |
| **14** | **التقويم الهجري والمناسبات** | حساب الشهور الهجرية والمناسبات الإسلامية وتحويل التاريخ بين الهجري والميلادي. |
| **15** | **واحة رمضان المبارك** | الإمساكية (30 يوماً)، مدفع الإفطار، منبه السحور، مخطط الختمة، عداد التراويح، وحاسبة الزكاة. |
| **16** | **تتبع الصلوات وسجل الفروض** | تسجيل أداء الصلوات (في وقتها / جماعة / قضاء) وإحصائيات الالتزام الأسبوعية واليومية. |
| **17** | **أذكار ما بعد الصلاة المفروضة** | التسبيح والاستغفار بعد السلام من الفريضة بعداد تفاعلي. |
| **18** | **التفاسير ومعاني الكلمات** | التفسير الميسر وسور وآيات القرآن الكريم من قاعدة بيانات SQLite محلية. |
| **19** | **الأحاديث النبوية (رياض الصالحين)** | 61 قسماً و 1840 حديثاً نبوياً من قاعدة بيانات SQLite محلية. |
| **20** | **أسماء الله الحسنى والسبحة** | استعراض الأسماء الـ 99، وسبحة إلكترونية تفاعلية متعددة الأذكار. |
| **21** | **النسخ الاحتياطي واستعادة البيانات** | تصدير واستيراد بيانات المستخدم (الورد، العلامات، الصلوات) كملف JSON مشفر. |
| **22** | **مشاركة الآيات كصورة وبطاقات** | مشاركة نصوص الآيات أو بطاقات مصممة عبر تطبيقات التواصل. |
| **23** | **نظام الصلاحيات والتنبيهات** | فحص وطلب أذونات الموقع، الإشعارات، المنبهات الدقيقة، وتجاهل تحسين البطارية. |
| **24** | **الثيمات والمظهر (Dark / Light)** | الوضع النهاري والليلي مع ألوان الزمرد والذهب وتنسيق الطباعة. |
| **25** | **لوحة الإنجازات والأوسمة** | شارات تحفيزية لختم القرآن، والالتزام بالصلوات، والمواظبة على الأذكار. |

---

## 2. جدول المقارنة التفصيلي (Android مقابل iOS)

| الميزة | تنفيذ Android (ملفات) | تنفيذ iOS الحالي (ملفات) | هل Dart مشترك يشتغل على iOS؟ | الحالة على iOS | القيد من Apple | المكافئ المقترح على iOS | الجهد المقدر |
|---|---|---|:---:|:---:|---|---|:---:|
| **1. المصحف وتصفح الآيات** | `lib/features/mushaf/` (صفحات QPC، خطوط ttf، وقاعدة بيانات SQLite) | نفس ملفات Dart المشتركة | **نعم 100%** | **كاملة** (لم يُختبر عتادياً) | لا توجد قيود. | نفس الكود المشترك. | معدوم (0) |
| **2. الفهرس والعلامات** | `lib/features/bookmarks/`, `lib/core/data/` | نفس ملفات Dart المشتركة | **نعم 100%** | **كاملة** (لم يُختبر عتادياً) | لا توجد قيود. | نفس الكود المشترك. | معدوم (0) |
| **3. الورد القرآني والختمة** | `lib/features/home/`, `UserRepository.dart` | نفس ملفات Dart المشتركة | **نعم 100%** | **كاملة** (لم يُختبر عتادياً) | لا توجد قيود على المنطق الداخلي. | نفس الكود المشترك. | معدوم (0) |
| **4. حساب مواقيت الصلاة في الواجهة** | `lib/features/adhan/`, مكتبة `adhan` في Dart | نفس ملفات Dart المشتركة | **نعم 100%** | **كاملة** (لم يُختبر عتادياً) | لا قيود على الحسابات الرياضية في الواجهة. | نفس الكود المشترك. | معدوم (0) |
| **5. جدولة الأذان الخلفي** | `PrayerScheduler.kt`, `AlarmManager`, `AdhanService.kt` | **غير موجود** (لا يوجد كود Swift لجدولة الأذان) | **جزئي** (`notifications_services.dart` فيه دالة لكنها غير مستدعاة) | **ناقصة كلياً** | لا يوجد `AlarmManager` على iOS؛ تمنع Apple إيقاظ التطبيق بحرية في الخلفية؛ الحد الأقصى للإشعارات المحلية المجدولة هو 64 إشعاراً فقط. | جدولة 64 إشعاراً محلياً مسبقاً (UNNotificationRequest) تغطي مواقيت الصلوات الخمس لـ 12 يوماً متتالية بصوت أذان مدته 29 ثانية، وتجديدها تلقائياً عند كل فتح للتطبيق أو عبر Background App Refresh. | **كبير** |
| **6. صوت الأذان في التنبيه** | `android/app/src/main/res/raw/adhan.ogg` (تشغيل كامل حتى 3.5 دقيقة) | يوجد ملف `ios/adhan.wav` لكنه غير مستخدم، وبحجم 5.7MB (>30 ثانية) | **لا** (صوت التنبيه مسؤولية النظام) | **ناقصة / غير متوافقة** | تشترط Apple ألا يتجاوز صوت الإشعار المحلي (`UNNotificationSound`) **30 ثانية** قطعاً، وتدعم فقط صيغ `.caf` أو `.wav` أو `.aiff`. الملفات الأطول تُهمل تلقائياً ويصدر صوت الرنين الافتراضي. | تجهيز ملف صوتي بصيغة `.caf` أو `.wav` مدته **29 ثانية** بالضبط ("الله أكبر الله أكبر.. أشهد أن لا إله إلا الله") وتضمينه في bundle المشروع تحت اسم مطابق في `UNNotificationSound`. | **صغير** |
| **7. شاشة الأذان فوق القفل** | `AdhanAlertActivity.kt` (`USE_FULL_SCREEN_INTENT`, `setShowWhenLocked`) | **غير موجود** | **لا** | **مستحيلة بنظام أندرويد** | تمنع سياسات iOS الأمنية منعاً باتاً قيام أي تطبيق بفتح واجهة مستخدم أو نشاط مرئي تلقائياً فوق شاشة القفل عند وصول إشعار. | إشعار محلي من نوع Time-Sensitive أو Critical Alert مع واجهة إشعار مخصصة (`UNNotificationContentExtension`) تفتح بطاقة الأذان ودعاء ما بعد الصلاة مباشرة من شاشة القفل عند التفاعل مع الإشعار. | **متوسط** |
| **8. كتم الأذان بالأزرار المادية** | `AdhanAlertActivity.kt` (`dispatchKeyEvent`, `VOLUME_CHANGED_ACTION`) | **غير موجود** | **لا** | **مستحيلة** | نظام iOS يمنع التطبيقات في الخلفية أو عند قفل الشاشة من رصد أزرار رفع/خفض الصوت أو زر البور (`Power Button`) لخصوصية النظام والأمان. | توفير زر تفاعلي سريع داخل إشعار الأذان (`UNNotificationAction` بعنوان "إيقاف الصوت 🔕") مع إيقاف الصوت فور لمس أي تفاعل مع الهاتف. | **صغير** |
| **9. بانر شاشة القفل الدائم** | `NotificationCompat.Builder.setOngoing(true)` على Android | **غير موجود** | **لا** | **مستحيلة بالطريقة الحالية** | يمنع نظام iOS الإشعارات المستمرة غير القابلة للإلغاء (`Ongoing Notifications`) في شريط الإشعارات. | استخدام ميزة Apple الرسمية **Live Activities (ActivityKit)** المتوفرة من iOS 16.1+ لعرض كبسولة ومربع حي بالصلاة القادمة والعد التنازلي على شاشة القفل والجزيرة التفاعلية (Dynamic Island). | **كبير** |
| **10. محرك التذكيرات الموحد** | `NativeRemindersBridge.kt`, `AlarmManager` (ورد، مواصلات، صدقة، أذكار) | **غير موجود** (لا يوجد كود Swift للقناة) | **جزئي** (الاستدعاء محمي بـ try-catch لكنه يفشل بصمت) | **ناقصة كلياً** | غياب قناة Swift المقابلة لـ `com.taqarrab.quran/native_reminders`. | كتابة كلاس Swift موازٍ أو الاعتماد الكامل في iOS على `flutter_local_notifications` وتخزين الإعدادات في SharedPreferences في دارت دون الحاجة لقناة أندرويد. | **متوسط** |
| **11. ويدجت الشاشة الرئيسية** | `PrayerTimesWidgetProvider.kt`, `WirdKhatmaWidgetProvider.kt` | كود Swift موجود في `ios/MyHomeWidget/` | **نعم** عبر مكتبة `home_widget` | **جزئية (تحتاج مراجعة وبناء)** (لم تُختبر عتادياً) | تتطلب إعداد App Group مفعل في حساب Apple Developer وتوقيع Extension بـ Provisioning Profile مطابق. | الكود مكتوب بالفعل لـ 3 ويدجت (أذكار، مواقيت الصلاة، الورد) ولكن يحتاج تجميع على Mac وربط App Group الرسمي. | **متوسط** |
| **12. الأذكار وحصن المسلم** | `lib/features/azkar/`, قاعدة SQLite | نفس ملفات Dart المشتركة | **نعم 100%** | **كاملة** (لم يُختبر عتادياً) | لا توجد قيود. | نفس الكود المشترك. | معدوم (0) |
| **13. القبلة والبوصلة** | `lib/features/qiblah/`, `flutter_compass`, `geolocator` | `flutter_compass` و `geolocator` يدعمان iOS | **نعم 100%** | **كاملة** (لم يُختبر عتادياً) | يتطلب هاتف آيفون حقيقي يحتوي على حساس مغناطيسي (Magnetometer) مع إذن الموقع. | نفس الكود المشترك. | معدوم (0) |
| **14. التقويم الهجري** | `lib/features/calendar/`, مكتبة `hijri` | نفس ملفات Dart المشتركة | **نعم 100%** | **كاملة** (لم يُختبر عتادياً) | لا توجد قيود. | نفس الكود المشترك. | معدوم (0) |
| **15. واحة رمضان المبارك** | `lib/features/ramadan/` (إمساكية، ختمة، مدفع، تراويح، زكاة) | نفس ملفات Dart المشتركة | **نعم 100%** | **كاملة** (لم يُختبر عتادياً) | لا توجد قيود على الحسابات أو الواجهات. | نفس الكود المشترك. | معدوم (0) |
| **16. تتبع الصلوات وسجل الفروض** | `lib/features/prayers_tracker/`, SQLite | نفس ملفات Dart المشتركة | **نعم 100%** | **كاملة في الواجهة / ناقصة من الإشعار** | كود Dart يعمل داخل التطبيق؛ أما تسجيل الصلاة مباشرة من الإشعار بنقرة واحدة فيحتاج Action تفاعلي في إشعار iOS. | إضافة `UNNotificationAction` بعنوان "صلّيت في وقتها" يرسل Payload إلى التطبيق. | **صغير** |
| **17. أذكار بعد الصلاة** | `lib/features/prayers_tracker/` | نفس ملفات Dart المشتركة | **نعم 100%** | **كاملة** (لم يُختبر عتادياً) | لا توجد قيود. | نفس الكود المشترك. | معدوم (0) |
| **18. التفاسير والأحاديث** | `lib/features/tafsser/`, `lib/features/hadith/` | نفس ملفات Dart المشتركة | **نعم 100%** | **كاملة** (لم يُختبر عتادياً) | لا توجد قيود. | نفس الكود المشترك. | معدوم (0) |
| **19. أسماء الله والسبحة** | `lib/features/nameOfAllah/`, `pngTree/` | نفس ملفات Dart المشتركة | **نعم 100%** | **كاملة** (لم يُختبر عتادياً) | لا توجد قيود. | نفس الكود المشترك. | معدوم (0) |
| **20. النسخ الاحتياطي** | `lib/features/settings/` (تصدير واستيراد JSON) | نفس ملفات Dart المشتركة | **نعم** (مع خطر iPad) | **جزئية (خطر كراش على iPad)** | تتطلب مكتبة `share_plus` على أجهزة iPad تحديد `sharePositionOrigin` لمنع كراش الـ Popover. | إضافة إحداثيات الزر `sharePositionOrigin` في شاشة النسخ الاحتياطي وشاشة "عن التطبيق". | **صغير** |
| **21. مشاركة الآيات** | `lib/features/tafsser/` عبر `share_plus` | نفس ملفات Dart المشتركة | **نعم 100%** | **كاملة** (معظمها يحدد Rect) | قيود الـ Popover على iPad. | نفس الكود المشترك. | معدوم (0) |
| **22. إدارة الصلاحيات** | `PermissionService.dart`, `permissions_bridge` | `permission_handler` على iOS | **نعم** (مفصول بذكاء في Dart) | **كاملة نظرياً** (لم يُختبر عتادياً) | تتطلب ذكر نصوص التوضيح في `Info.plist` (موجودة للموقع والكاميرا والصور). | الكود في `PermissionPlatformAdapter` يفصل iOS عن أندرويد بشكل سليم. | معدوم (0) |
| **23. الثيمات والمظهر** | `ThemeController.dart`, `AppTheme.dart` | نفس ملفات Dart المشتركة | **نعم 100%** | **كاملة** (لم يُختبر عتادياً) | لا توجد قيود. | نفس الكود المشترك. | معدوم (0) |
| **24. لوحة الإنجازات** | `lib/features/stats/` | نفس ملفات Dart المشتركة | **نعم 100%** | **كاملة** (لم يُختبر عتادياً) | لا توجد قيود. | نفس الكود المشترك. | معدوم (0) |

---

## 3. الفحص الدقيق والعميق لنقاط iOS (بالأدلة القاطعة من الكود)

### 3.1. الأذان ومواقيت الصلاة على iOS
* **هل يجدول إشعارات محلية للأذان على iOS؟**
  * **الدليل من الكود:** **لا، لا يتم جدولة أي إشعار أذان على iOS إطلاقاً حالياً.**
  * في ملف [`adhan_view_model.dart`](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/adhan/presentation/view_model/adhan_view_model.dart#L167-L168):
    ```dart
    await NativeAdhanBridge.saveSettings(updated.toMap());
    await recalculatePrayerTimes();
    ```
    الاعتماد على نظام أندرويد يتم عبر إرسال الإعدادات إلى `NativeAdhanBridge` (المكتوب بلغة Kotlin فقط). وعلى نظام iOS، دالة `saveSettings` تفشل بصمت داخل try-catch دون وجود بديل Swift.
  * في ملف [`notifications_services.dart`](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/core/service/settings/notifications_services.dart#L278-L318): توجد دالة اسمها `schedulePrayerTimeNotification` لجدولة 5 صلوات لليوم الحالي عبر `flutter_local_notifications`، ولكن **لا يوجد استدعاء واحد لها في كل كود التطبيق (`lib/`)** (تم تأكيد ذلك عبر `git grep "schedulePrayerTimeNotification"`).
* **كم إشعار وهل يتجدد عند فتح التطبيق؟**
  * النتيجة: **صفر إشعار حالياً على iOS.**
* **هل صوت الأذان مدعوم ومدته ≤ 30 ثانية؟**
  * **الدليل من الكود:**
    1. في [`notifications_services.dart:75`](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/core/service/settings/notifications_services.dart#L75):
       ```dart
       final String soundAdhan = 'adhan.ogg';
       ```
       وفي السطر 345:
       ```dart
       final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
         sound: soundAdhan, // يمرر adhan.ogg!
         ...
       ```
       نظام iOS **لا يدعم صيغة `.ogg` نهائياً**، بل يدعم حصراً: `.caf` أو `.wav` أو `.aiff`.
    2. في مجلد `ios/`: يوجد ملف `ios/adhan.wav` بحجم **5,760,508 بايت (5.7 ميجابايت)**. مدة هذا الملف تتجاوز دقيقتين ونصف. طبقاً لتوثيق Apple الرسمي لـ `UNNotificationSound`:
       > *"The audio file must be in a supported format and its duration must be under 30 seconds. If it exceeds 30 seconds, the system plays the default sound instead."*
       وبالتالي، حتى لو تم تمرير `adhan.wav`، ستلغي Apple الصوت المخصص فوراً وتصدر الرنة العادية.

---

### 3.2. التذكيرات (الورد، المواصلات، الصدقة، الأذكار)
* **هل تُجدول التذكيرات على iOS؟**
  * **الدليل من الكود:** **لا، لا تُجدول على iOS.**
  * في ملف [`notifications_services.dart:247`](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/core/service/settings/notifications_services.dart#L247) و[`السطر 261`](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/core/service/settings/notifications_services.dart#L261):
    ```dart
    await NativeRemindersBridge.rescheduleAll();
    ```
    تم استبدال الجدولة القديمة لـ `zonedSchedule` بالاعتماد الحصري على المحرك الأصلي `NativeRemindersBridge`.
  * قناة `com.taqarrab.quran/native_reminders` مبنية بلغة Kotlin في ملف `NativeRemindersBridge.kt` وقاعدة بيانات SQLite خاصة بالأندرويد (`NativeRemindersDatabaseHelper.kt`).
  * في نظام iOS، لا يوجد أي ملف Swift مسجل لهذه القناة في `AppDelegate.swift`. لذلك يتم رمي `MissingPluginException` ويتم ابتلاعها بواسطة `catch` في Dart، مما يعني عدم جدولة أي تذكير على iOS.
* **إلغاء التذكير عند قراءة الورد:**
  * تستدعي دالة `cancelWirdNotifications()` في [`notifications_services.dart:272`](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/core/service/settings/notifications_services.dart#L272) الدالة:
    `await NativeRemindersBridge.markWirdCompleted();`
    وهي أيضاً لا تعمل على iOS لنفس السبب.

---

### 3.3. ويدجت iOS (WidgetKit)
* **أي أنواع ويدجت موجودة في Swift؟**
  * **الدليل من الكود:** في ملف [`ios/MyHomeWidget/MyHomeWidgetBundle.swift:5-11`](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/ios/MyHomeWidget/MyHomeWidgetBundle.swift#L5-L11):
    ```swift
    @main
    struct MyHomeWidgetBundle: WidgetBundle {
        var body: some Widget {
            MyHomeWidget()         // ويدجت الأذكار والتسابيح
            PrayerTimesWidget()    // ويدجت مواقيت الصلاة
            WirdKhatmaWidget()     // ويدجت الورد القرآني والختمة
        }
    }
    ```
    يوجد 3 أنواع ويدجت مبنية بلغة Swift و SwiftUI في ملف [`MyHomeWidget.swift`](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/ios/MyHomeWidget/MyHomeWidget.swift):
    1. **أذكار وتسابيح (`MyHomeWidget`):** يدعم الأحجام `.systemSmall`, `.systemMedium`, `.systemLarge`, وويدجت شاشة القفل `.accessoryRectangular`, `.accessoryInline`, `.accessoryCircular`.
    2. **مواقيت الصلاة (`PrayerTimesWidget`):** يدعم `.systemSmall`, `.systemMedium`, `.accessoryRectangular`.
    3. **الورد القرآني والختمة (`WirdKhatmaWidget`):** يدعم `.systemSmall`, `.systemMedium`, `.accessoryRectangular`.
* **مجموعة التطبيق (App Group):**
  * المعرف المستخدم في الكود هو: `group.com.homeScreenApp` (موجود في `Runner.entitlements` و `MyHomeWidgetExtension.entitlements` و `WidgetSyncService.dart`).
* **من أين تأخذ الويدجت بياناتها؟**
  * **ويدجت الأذكار:** يقرأ من ملف JSON محلي اسمه `azkar_widget_data.json` موجود داخل حزمة الويدجت في [`ios/MyHomeWidget/azkar_widget_data.json`](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/ios/MyHomeWidget/azkar_widget_data.json) (حجمه 161 كيلوبايت ويحتوي على أذكار كاملة)، وإذا لم يجده يستخدم 3 أذكار احتياطية مبرمجة في الكود.
  * **ويدجت الصلاة والورد:** يقرأ القيم من `UserDefaults(suiteName: "group.com.homeScreenApp")`، وتصله التحديثات من دارت عبر استدعاءات `WidgetSyncService.syncWirdProgress` و `WidgetSyncService.syncPrayerTimes` باستخدام مكتبة `home_widget`.
* **هل كل أحجام أندرويد موجودة؟**
  * نعم، ويدجت iOS يغطي كل أحجام شاشة القفل والشاشة الرئيسية في iOS، بل ويتميز عن أندرويد بدعمه لـ Lock Screen Inline و Circular.

---

### 3.4. الصلاحيات وإعدادات `Info.plist`
* **محتوى `ios/Runner/Info.plist` الحالي:**
  * `NSLocationWhenInUseUsageDescription`: موجود ومترجم باللغتين العربية والإنجليزية لحساب الصلاة والقبلة.
  * `NSCameraUsageDescription`: موجود لدعم كاميرا القبلة والواقع المعزز.
  * `NSPhotoLibraryUsageDescription` و `NSPhotoLibraryAddUsageDescription`: موجودان لحفظ بطاقات الآيات.
  * `UIBackgroundModes`: يحتوي فقط على `<string>audio</string>`.
* **كيف يتعامل `PermissionService` مع iOS؟**
  * **الدليل من الكود:** في [`permission_platform_adapter.dart`](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/core/permissions/permission_platform_adapter.dart#L19-L27):
    ```dart
    if (Platform.isIOS) {
      return type == AppPermissionType.location ||
          type == AppPermissionType.notification;
    }
    ```
    النظام يعلم تماماً أن صلاحيات أندرويد الخاصة (مثل `exactAlarm`, `batteryOptimization`, `fullScreenIntent`) غير منطبقة على iOS فيرجع لها `AppPermissionStatus.notApplicable` فوراً.
  * بالنسبة لـ `PermissionStatus.provisional` و `limited`: يتم ترجمتها في [`السطر 192`](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/core/permissions/permission_platform_adapter.dart#L192) إلى `AppPermissionStatus.granted` بصورة صحيحة.
  * صلاحية `restricted` (مثل الرقابة الأبوية على أجهزة أبل) يتم تحويلها إلى `AppPermissionStatus.restricted` لمنع تكرار طلبها.

---

### 3.5. قنوات MethodChannel وغياب النظير في Swift
| اسم القناة في Dart | مكانها في Kotlin (Android) | مكانها في Swift (iOS) | هل يوجد حماية من الكراش؟ | السلوك الفعلي على iOS |
|---|---|---|:---:|---|
| `native_adhan_bridge` | `adhan/NativeAdhanBridge.kt` | **غير موجود** | نعم (`try-catch`) | تفشل بصمت: لا تُحفظ الإعدادات في النيتف ولا يُجدول أي أذان. |
| `com.taqarrab.quran/native_reminders` | `reminders/NativeRemindersBridge.kt` | **غير موجود** | نعم (`try-catch`) | تفشل بصمت: ترجع قوائم فارغة ولا يُجدول أي تنبيه للورد أو الصدقة أو الأذكار. |
| `native_azkar_bridge` | `azkar/NativeAzkarBridge.kt` | **غير موجود** | نعم (`try-catch`) | تفشل بصمت ولا تؤثر على التطبيق. |
| `permissions_bridge` | `permissions/PermissionsBridge.kt` | **غير موجود** | نعم (`Platform.isAndroid`) | لا يتم استدعاؤها على iOS؛ يتم التوجيه مباشرة لـ `permission_handler`. |
| `com.taqarrab.quran/app_navigation` | `MainActivity.kt` | **غير موجود** | نعم (`try-catch`) | تفشل بصمت ولا تُعالج النوايا الباردة الخاصة بأندرويد. |

**الخلاصة:** الكود محمي من الكراش الفوري، ولكنه **يفشل بصمت تام في كل ما يتعلق بالخلفية والأذان والتنبيهات.**

---

### 3.6. فحص الإضافات (Plugins) في `pubspec.yaml`
1. `android_intent_plus: ^6.0.0`: إضافة مخصصة لأندرويد فقط؛ وبفحص الكود تبين أنها **غير مستخدمة نهائياً** في أي ملف داخل `lib/`، لذا لا تسبب أي كراش ولكن يُفضل حذفها للتنظيف.
2. `sqflite: ^2.3.3+2`: متوافقة تماماً مع iOS وتعمل فوق SQLite / FMDB الرسمية.
3. `path_provider: ^2.1.5`: متوافقة تماماً وتستخدم مسارات iOS الرسمية (`NSDocumentDirectory`, `NSTemporaryDirectory`).
4. `flutter_compass: ^0.8.1`: متوافقة وتعتمد على `CoreLocation.heading`.
5. `share_plus: ^10.1.4`: متوافقة، لكن تتطلب حذر خاص بأجهزة iPad.
6. `flutter_local_notifications: ^17.0.2`: متوافقة مع iOS عبر `UNUserNotificationCenter`.

---

### 3.7. مشاركة الصور والنسخ الاحتياطي والبوصلة
* **مشاركة الآيات والملفات (`share_plus`):**
  * في [`ayah_tafseer_card.dart:94`](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/tafsser/presentation/views/widget/ayah_tafseer_card.dart#L94): تم استخدام `sharePositionOrigin` لمنع كراش أجهزة iPad.
  * **تحذير كراش iPad:** في ملف [`about_app_view.dart:140`](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/settings/presentation/views/about_app_view.dart#L140) وفي [`backup_restore_view.dart:41`](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/lib/features/settings/presentation/views/backup_restore_view.dart#L41) يتم استدعاء `Share.share` و `Share.shareXFiles` **دون تمرير `sharePositionOrigin`**. على أجهزة iPad سيؤدي هذا فوراً إلى **Fatal Crash** بسبب فشل عرض نافذة المشاركة المنبثقة (UIPopoverPresentationController).
* **مسارات النسخ الاحتياطي:**
  * تستخدم `getTemporaryDirectory()` من `path_provider` وهو مسار قياسي ومدعوم في رمل أمان iOS (`App Sandbox/tmp`).
* **البوصلة (Compass):**
  * تعتمد على `flutter_compass` وخوارزمية رياضية في Dart لحساب زاوية القبلة الكروية العظمى (`Qibla(coords).direction`).
  * على محاكي iOS (Simulator) ستعطي البوصلة قيمة `null` دائماً لعدم وجود حساس مغناطيسي في المحاكي، لكن الكود يتعامل مع الحالة ويعرض واجهة انتظار دون كراش.

---

## 4. استدعاءات `Platform.isAndroid` والقنوات الناتجة
1. **في `WidgetSyncService.dart:40`:**
   ```dart
   if (Platform.isAndroid) {
     final prefs = await SharedPreferences.getInstance();
     ...
   }
   ```
   محمي بشكل صحيح، ويقوم بحفظ بيانات الويدجت في `HomeWidget.saveWidgetData` لـ iOS وفي SharedPreferences لـ Android.
2. **في `permission_platform_adapter.dart`:**
   جميع قنوات `_bridge.invokeMethod` محاطة بشرط صريح:
   `if (!kIsWeb && Platform.isAndroid)`
   وبالتالي لا يتم استدعاء أي كود أندرويد على iOS.

---

## 5. تصنيف الفجوات والعيوب

### (أ) فجوات قد تكسر iOS أو تسبب كراش (Bugs & Crashes)
1. **كراش أجهزة iPad عند المشاركة:**
   * استدعاء `Share.share` في `about_app_view.dart` و `Share.shareXFiles` في `backup_restore_view.dart` بدون `sharePositionOrigin` يسبب كراش فوري على أجهزة iPad.
2. **صوت الإشعار غير المدعوم (`adhan.ogg`):**
   * تمرير اسم ملف ينتهي بـ `.ogg` لـ `DarwinNotificationDetails` يسبب فشل تشغيل الصوت المخصص وسقوطه إلى الصوت الافتراضي.

### (ب) ميزات ناقصة على iOS (Missing Features)
1. **غياب جدولة الأذان الخلفي نهائياً:** عدم وجود آلية لجدولة الصلوات الخمس في خلفية iOS سواء عبر `UNNotificationRequest` أو عبر Swift.
2. **غياب محرك التذكيرات الموحد:** تذكير الورد اليومي، ورد المواصلات، الصدقة الشهرية، والأذكار المجدولة لا تعمل على iOS.
3. **غياب ملف صوت أذان متوافق مع شروط Apple:** عدم وجود ملف صوتي بصيغة `.caf` مدته 29 ثانية داخل الحزمة.
4. **تسجيل الصلوات من الإشعار:** غياب أزرار التفاعل السريع مع إشعار الصلاة على iOS.

### (ج) ميزات مستحيلة بسياسات Apple والبدائل المقترحة لها
1. **شاشة الأذان الكاملة فوق القفل (Adhan Full Screen on Lock Screen):**
   * *السبب المستحيل:* أبل تمنع أي تطبيق طرف ثالث من فتح Activity أو View فوق شاشة القفل.
   * *البديل المقترح:* استخدام إشعارات Time-Sensitive غنية مع واجهة مخصصة (`UNNotificationContentExtension`) تفتح بطاقة الأذان عند لمس الإشعار.
2. **شريط الإشعارات الدائم (Ongoing Status Notification):**
   * *السبب المستحيل:* أبل تمنع الإشعارات التي لا يمكن مسحها من مركز الإشعارات.
   * *البديل المقترح:* استخدام ميزة أبل الرسمية **Live Activities (ActivityKit)** وشاشة القفل التفاعلية (iOS 16.1+).
3. **كتم الصوت بواسطة أزرار الصوت المادية أو زر البور:**
   * *السبب المستحيل:* حماية أبل لعزل أزرار العتاد المادية عن التطبيقات.
   * *البديل المقترح:* زر "إيقاف الصوت 🔕" تفاعلي وسريع على الإشعار مباشرة.

### (د) تحسينات مطلوبة لبيئة iOS (Improvements)
1. ضبط وربط الـ App Group الحقيقي وتوقيع الـ Target الخاص بـ `MyHomeWidgetExtension` داخل Xcode.
2. إضافة صلاحية `UIBackgroundModes: fetch` لتمكين التحديث الدوري المسموح به.
3. تنظيف حزمة `android_intent_plus` غير المستخدمة من `pubspec.yaml`.

---

## 6. خطة التنفيذ المقترحة لنظام iOS (مرتبة بالأولوية والجهد)

### المرحلة الأولى: الإصلاحات الفورية والوقاية من الكراش (يمكن عملها من Windows)
* **الجهد:** صغير (1 - 2 ساعة)
1. إصلاح استدعاءات `Share` في `about_app_view.dart` و `backup_restore_view.dart` بإضافة `sharePositionOrigin` لتأمين أجهزة iPad.
2. حذف التبعية غير المستخدمة `android_intent_plus` من `pubspec.yaml`.
3. تعديل اسم امتداد ملف الصوت في `DarwinNotificationDetails` ليشير إلى صيغة مدعومة (`.caf` أو `.wav`).

### المرحلة الثانية: إطلاق منظومة الأذان والتذكيرات المعتمدة على iOS Local Notifications (من Windows في Dart)
* **الجهد:** متوسط (3 - 5 ساعات)
1. تفعيل محرك جدولة لـ 64 إشعاراً محلياً في Dart باستخدام `flutter_local_notifications` يغطي مواقيت الصلوات للأيام القادمة بالاعتماد على مكتبة `adhan` المدمجة في دارت.
2. ربط التذكيرات (الورد، المواصلات، الصدقة، الأذكار) بمحرك `flutter_local_notifications` الداخلي في حال كان النظام يعمل على iOS (`Platform.isIOS`) كبديل عن قناة Kotlin المفقودة.
3. توفير ملف صوتي مقصوص ومدته 29 ثانية بصيغة `.caf` باسم `adhan_ios.caf` في مجلد أصوات الحزمة.

### المرحلة الثالثة: إعداد وبناء وتوقيع الويدجت والمشروع (تتطلب نظام macOS وجهاز Mac مع Xcode)
* **الجهد:** متوسط إلى كبير (يوم عمل)
1. فتح `ios/Runner.xcworkspace` على جهاز Mac.
2. ضبط معرف الحساب والمطور (Apple Developer Team ID).
3. تفعيل الـ App Group الرسمي لربط تطبيق Runner مع `MyHomeWidgetExtension`.
4. التحقق من صلاحيات `Notification Service Extension` وبناء التطبيق على محاكي آيفون وجهاز آيفون حقيقي.
5. (اختياري مستقبلي): إضافة Live Activity لويدجت مواقيت الصلاة عبر ActivityKit لنظام iOS 16.1+.

---

> **ملاحظة أمان وتأكيد:** تم توثيق وحفظ هذا التقرير بالكامل داخل ملف [`IOS_PARITY.md`](file:///c:/Users/Yousef/Downloads/New%20folder/Quran-App-main/Quran-App-main/IOS_PARITY.md) في جذر المشروع، ولم يتم إجراء أي تعديل على كود التطبيق الفعلي التزاماً بتعليماتك. بانتظار توجيهك وموافقتك على الخطوات التالية!
