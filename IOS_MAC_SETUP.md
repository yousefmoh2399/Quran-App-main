# دليل إعداد وبناء وتجهيز نظام iOS (iOS Mac Setup Guide)

تم إعداد هذا التوثيق بناءً على بيئة العمل الفعلية لفرع `ios/mac-setup` في مشروع Flutter لتطبيق **تقرب**.

---

## 1. القيم المعتمدة (Configured Identity)

| المتغير | القيمة المعتمدة | الملاحظات |
| :--- | :--- | :--- |
| **`APP_BUNDLE_ID`** | `com.yousefmohamed.quranApp` | المعرّف الأساسي لتطبيق Runner |
| **`WIDGET_BUNDLE_ID`** | `com.yousefmohamed.quranApp.MyHomeWidget` | معرّف ملحق الويدجت (Extension) |
| **`RUNNER_TESTS_ID`** | `com.yousefmohamed.quranApp.RunnerTests` | تم توحيده بدلاً من com.example |
| **`APP_GROUP`** | `group.com.yousefmohamed.quranApp` | موحد في Entitlements، Swift، وDart |
| **`TEAM_ID`** | `BFJD25Q53G` | مضبوط في جميع أهداف البناء (Targets) |
| **`APP_DISPLAY_NAME`** | `تقرب` | الاسم الظاهر على الشاشة الرئيسية وشاشات الأذونات |
| **`MIN_IOS`** | `16.0` | موحد في Runner، Extension، وPodfile لدعم ويدجت شاشة القفل |

---

## 2. سجل الملفات المعدلة والمنشأة

1. `ios/Podfile`:
   * رفع المنصة إلى `platform :ios, '16.0'`.
   * إضافة ضبط `IPHONEOS_DEPLOYMENT_TARGET = '16.0'` في حلقة `post_install` لجميع مكتبات البودز.
2. `ios/Flutter/Release.xcconfig`:
   * إضافة تضمين fallback لـ `Pods-Runner.profile.xcconfig` لمنع تحذير CocoaPods الخاص بتكوين Profile.
3. `ios/Flutter/AppFrameworkInfo.plist`:
   * تنظيف وتحديث أدوات Flutter.
4. `ios/Runner.xcodeproj/project.pbxproj`:
   * توحيد `IPHONEOS_DEPLOYMENT_TARGET = 16.0` لجميع الـ Configurations (Debug, Release, Profile) لكل الأهداف (Project, Runner, Extension).
   * إزالة تجاوز `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES` وضبطه على `$(inherited)`.
   * تحديث `PRODUCT_BUNDLE_IDENTIFIER` لاختبارات `RunnerTests`.
   * ربط `baseConfigurationReference` لـ `MyHomeWidgetExtension` مع `Debug.xcconfig` و `Release.xcconfig` لوراثة `FLUTTER_BUILD_NAME` و `FLUTTER_BUILD_NUMBER`.
   * ضبط `CURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)"` و `MARKETING_VERSION = "$(FLUTTER_BUILD_NAME)"` للـ Extension.
   * تضمين ملفات `PrivacyInfo.xcprivacy` في مصادر ومراحل بناء Runner و Extension.
5. `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`:
   * تحديث مرحلة الإعداد المسبق لـ Flutter Framework.
6. `ios/Runner/Runner.entitlements`:
   * تحديث App Group إلى `group.com.yousefmohamed.quranApp`.
   * تفعيل `com.apple.developer.usernotifications.time-sensitive = true` لإشعارات الأذان الحساسة للوقت.
7. `ios/MyHomeWidgetExtension.entitlements`:
   * تحديث App Group إلى `group.com.yousefmohamed.quranApp`.
8. `ios/Runner/Info.plist`:
   * الاحتفاظ بـ `NSLocationWhenInUseUsageDescription` بثنائية اللغة (عربي/إنجليزي).
   * حذف أذونات الصور والكاميرا غير المستخدمة (`NSPhotoLibraryAddUsageDescription` و `NSPhotoLibraryUsageDescription`).
   * إزالة وضع الخلفية للصوت `UIBackgroundModes -> audio` لتجنب رفض App Store (Guideline 2.5.4) لعدم وجود تشغيل صوت مستمر في الخلفية عبر AVAudioSession.
   * إضافة `ITSAppUsesNonExemptEncryption = false`.
   * إضافة `CFBundleLocalizations` للغتين العربية والإنجليزية (`ar`, `en`).
9. `ios/MyHomeWidget/Info.plist`:
   * تضمين كافة الحقول القياسية مع `CFBundleShortVersionString` و `CFBundleVersion` لمنع خطأ `IXErrorDomain` أثناء التثبيت.
10. `ios/MyHomeWidget/MyHomeWidget.swift`:
    * استبدال `group.com.homeScreenApp` بـ `group.com.yousefmohamed.quranApp` في وظائف قراءة ومزامنة البيانات.
11. `lib/core/services/widget_sync_service.dart`:
    * تحديث `appGroupId = 'group.com.yousefmohamed.quranApp'`.
12. `lib/features/home/presentation/view_model/home_view_model.dart`:
    * تحديث `appGroupId = 'group.com.yousefmohamed.quranApp'`.
13. `ios/Runner/Assets.xcassets/AppIcon.appiconset/1024.png`:
    * تفريغ قناة الشفافية (Alpha Channel) بدون مساس بدقة أو ألوان الأيقونة الأصلية عبر CoreGraphics.
14. `ios/Runner/PrivacyInfo.xcprivacy` (جديد):
    * إعلان عدم وجود تتبع `NSPrivacyTracking = false`.
    * إعلان Required Reason APIs:
      * `UserDefaults`: الأكواد `CA92.1` و `1C8F.1` للـ App Group.
      * `FileTimestamp`: الكود `C617.1`.
      * `SystemBootTime`: الكود `35F9.1`.
      * `DiskSpace`: الكود `E174.1`.
15. `ios/MyHomeWidget/PrivacyInfo.xcprivacy` (جديد):
    * إعلان `NSPrivacyTracking = false` وكود `1C8F.1` للوصول لـ UserDefaults عبر الـ App Group.
16. `ios/exportOptions.plist` (جديد):
    * ملف خيارات التصدير والأرشفة الجاهز للتوزيع على App Store و TestFlight بالـ Team ID والـ Automatic Signing.

---

## 3. نتائج الخطوات التنفيذية (الأوامر الفعلية)

| الخطوة | الحالة | الناتج والأدلة الفعلية |
| :--- | :--- | :--- |
| **الخطوة 0: فحص البيئة** | **نجح** | `Xcode 26.3`، `CocoaPods 1.17.0`، `Flutter 3.47.5`. تنفيذ `pod install` بنجاح بعد ضبط UTF-8. |
| **الخطوة 1: تغيير الهوية** | **نجح** | مطابقة كاملة لـ Bundle IDs والـ App Groups والـ Deployment Target 16.0، وربط إصدارات الـ Extension بالـ App. |
| **الخطوة 2: Entitlements** | **نجح** | تم إضافة App Group و Time-Sensitive Notifications في Runner و Extension. |
| **الخطوة 3: Info.plist والخصوصية** | **نجح** | تم حذف وضع الصوت غير المبرر وأذونات الصور، وإضافة Privacy Manifests ومطابقتها لمواصفات Apple الرسمية. |
| **الخطوة 4: ملفات الصوت** | **نجح** | تم التحقق عبر `afinfo` من `adhan_ios.wav`: المدة 28.50 ثانية، ومضمن في Copy Bundle Resources ومطابق لكود Dart. |
| **الخطوة 5: الأيقونة** | **نجح** | تم التحقق عبر `sips -g all`: المقاس 1024x1024، `hasAlpha: no`. |
| **الخطوة 6: بناء المحاكي (Debug)** | **نجح** | `flutter build ios --simulator --debug` اكتمل بنجاح (Exit code 0). |
| **الخطوة 6: تثبيت وتشغيل المحاكي** | **نجح** | تم التثبيت على `iPhone 16e` عبر `xcrun simctl install/launch`، والتطبيق يعمل والشاشات ظاهرة والـ App Group مُنشأ. |
| **الخطوة 6: بناء Release (No-Codesign)** | **نجح** | `flutter build ios --release --no-codesign` اكتمل بنجاح (276.1MB). حجم Runner.app النهائي 265MB وحجم Extension 684KB مع دعم arm64. |
| **الخطوة 6: التشغيل على iPhone 12 حقيقي** | **لم يُختبر** | الجهاز متصل لاسلكياً (`00008101-001E39C026D8001E`)، بانتظار تأكيدك لإجراءات بوابة Apple Developer للبدء بالتثبيت الفعلي. |

---

## 4. جدول التكافؤ الفعلي مع Android (Parity Matrix)

بناءً على الكود المصدري واختبارات البيئة وقيود نظام iOS:

| البند | الحالة الفعلية | التصنيف | الدليل والتحليل الفني |
| :--- | :--- | :--- | :--- |
| **1. إشعار الأذان والصوت (الجهاز مقفول)** | **مدعوم في iOS** (لم يُختبر على الجهاز الحقيقي بعد) | يتصلح بكود / متوافق | يستخدم الكود `DarwinNotificationDetails` مع `interruptionLevel: .timeSensitive` وصوت `adhan_ios.wav` (28.5 ثانية). على iOS الإشعار يعمل والجهاز مقفول، ولكن iOS لا يسمح بتشغيل شاشة كاملة تلقائياً (Full Screen Intent) مثل أندرويد إلا عبر إشعار عادي يضغط عليه المستخدم لفتح التطبيق، أو عبر Live Activities لاحقاً. |
| **2. التذكيرات المجدولة (ورد/صدقة/أذكار)** | **مدعوم في iOS** (لم يُختبر على الجهاز الحقيقي بعد) | متوافق | يتم الجدولة عبر `zonedSchedule` ضمن ميزانية الإشعارات (Budget System) المخصصة بحد أقصى 64 إشعاراً لـ iOS. |
| **3. الويدجت الثلاثة** | **مكتمل بالـ Extension** (تم التحقق في المحاكي) | متوافق | الـ Extension يتضمن ويدجت الأذكار (`WirdKhatmaWidget`)، مواقيت الصلاة (`PrayerTimesWidget`)، وويدجت رمضان (`RamadanWidget`) مع دعم Lock Screen Widgets (`accessoryRectangular`). مشاركة البيانات عبر `group.com.yousefmohamed.quranApp`. |
| **4. المشاركة والنسخ الاحتياطي** | **مدعوم كودياً** (لم يُختبر على الجهاز الحقيقي بعد) | متوافق | تستخدم المشاركة مكتبة `share_plus` (UIActivityViewController الأصلي لـ iOS). |
| **5. القبلة (البوصلة والحساس المغناطيسي)** | **مدعوم كودياً** (لم يُختبر على المحاكي لعدم توفر حساس) | يحتاج جهاز حقيقي | البوصلة تعتمد على `flutter_compass` الذي يستدعي `CLLocationManager.startUpdatingHeading`، ويتطلب أجهزة حقيقية تحتوي على Magnetometer. |
| **6. أذونات الموقع والإشعارات** | **نجح على المحاكي** | متوافق | تم طلب الأذونات وظهور حوار "تقرب Would Like to Send You Notifications" بنجاح، وطلب إذن الموقع يمرر الرسالة المعتمدة. |
| **7. بعد إغلاق التطبيق وإعادة التشغيل** | **مدعوم كودياً** (لم يُختبر على الجهاز الحقيقي بعد) | قيد منصة Apple | الإشعارات المجدولة تظل مسجلة في نظام iOS حتى بعد إغلاق التطبيق أو إعادة تشغيل الجهاز. لكن لا يمكن تشغيل كود Dart في الخلفية عند إعادة التشغيل بدون فتح التطبيق (على عكس Android BootReceiver). |

---

## 5. الخطوات اليدوية المطلوبة منك على developer.apple.com

لتشغيل التطبيق على الـ iPhone 12 المتصل وتجهيزه للمتجر:

1. **تسجيل الـ App Group**:
   * ادخل إلى [developer.apple.com](https://developer.apple.com) > **Certificates, Identifiers & Profiles** > **Identifiers**.
   * اضغط على `+` واختر **App Groups**.
   * الـ Identifier: `group.com.yousefmohamed.quranApp`.
2. **تسجيل App ID للتطبيق الأساسي (Runner)**:
   * اختر **App IDs** > **App**.
   * الـ Bundle ID: `com.yousefmohamed.quranApp`.
   * فعّل **App Groups** واختر `group.com.yousefmohamed.quranApp`.
   * فعّل **Time-Sensitive Notifications**.
3. **تسجيل App ID للـ Extension**:
   * اختر **App IDs** > **App**.
   * الـ Bundle ID: `com.yousefmohamed.quranApp.MyHomeWidget`.
   * فعّل **App Groups** واختر نفس المجموعة.
4. **في Xcode GUI على جهازك**:
   * افتح المشروع عبر: `open ios/Runner.xcworkspace`.
   * من القائمة الجانبية، اختر الهدف **Runner** > تبويب **Signing & Capabilities**:
     * تأكد من تحديد **Automatically manage signing**.
     * تأكد من اختيار فريقك (**Team: BFJD25Q53G**).
   * اختر الهدف **MyHomeWidgetExtension** > تبويب **Signing & Capabilities**:
     * تأكد من تفعيل نفس خيار التوقيع التلقائي وفريق العمل.

---

## 6. خطوات الأرشفة والتسليم على App Store Connect

1. **إنشاء التطبيق في App Store Connect**:
   * توجّه إلى [appstoreconnect.apple.com](https://appstoreconnect.apple.com) > **My Apps** > `+` (New App).
   * اختر المنصة: **iOS**.
   * الاسم: **تقرب**.
   * اللغة الأساسية: **Arabic**.
   * اختر الـ Bundle ID: `com.yousefmohamed.quranApp`.
   * أدخل الـ SKU (مثلاً: `quran-taqarrab-ios`).
2. **بناء وتصدير الـ Archive عبر سطر الأوامر أو Xcode**:
   * عبر سطر الأوامر (باستخدام الملف المجهز):
     ```bash
     flutter build ipa --release --export-options-plist=ios/exportOptions.plist
     ```
   * أو من داخل Xcode:
     * اختر الجهاز **Any iOS Device (arm64)**.
     * من القائمة العلوية: **Product** > **Archive**.
     * بعد اكتمال الأرشفة، ستفتح نافذة **Organizer**.
     * اضغط **Validate App** للتأكد من خلو الحزمة من أي مشكلات.
     * اضغط **Distribute App** > **App Store Connect** > **Upload**.
3. **تجهيز بيانات المتجر للمراجعة**:
   * **App Privacy**: أجب عن استبيان الخصوصية باختيار "لا يتم جمع أي بيانات" (مطابق لـ PrivacyInfo.xcprivacy).
   * **Screenshots**: رفع لقطات شاشة لمقاس 6.7 بوصة (iPhone 16 Pro Max / 15 Pro Max) ومقاس 6.5/5.5 بوصة، وشاشات الآيباد.
   * **App Review Notes**: توضيح لفريق المراجعة: "التطبيق إسلامي مجاني بالكامل لا يتطلب إنشاء حساب أو تسجيل دخول. يتم طلب إذن الموقع فقط لحساب مواقيت الصلاة واتجاه القبلة، ويتم جدولة إشعارات الأذان محلياً بصوت أذان مدمج مع مستوى Time-Sensitive".
