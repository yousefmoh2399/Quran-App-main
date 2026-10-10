# الدليل الشامل لرفع ونشر تطبيق "تَقَرَّبْ" على متجر أبل (Apple App Store) 🍏🚀

هذا الدليل يوضح لك خطوة بخطوة وبالتفصيل الكامل كل ما تحتاجه لرفع تطبيق **"تَقَرَّبْ" (Taqarrab)** بنجاح على متجر **Apple App Store** وقبوله من أول مرة طبقاً لأحدث معايير وسياسات شركة أبل (2026/2027).

---

## 📑 فهرس المحتويات:
1. [المتطلبات الأساسية قبل البدء](#1-المتطلبات-الأساسية-قبل-البدء)
2. [الشهادات والملفات التعريفية (Certificates & Profiles)](#2-الشهادات-والملفات-التعريفية-certificates--profiles)
3. [مراجعة إعدادات المشروع في Xcode](#3-مراجعة-إعدادات-المشروع-في-xcode)
4. [إنشاء التطبيق على App Store Connect](#4-إنشاء-التطبيق-على-app-store-connect)
5. [تجهيز أصول المتجر ولقطات الشاشة (Screenshots & Assets)](#5-تجهيز-أصول-المتجر-ولقطات-الشاشة-screenshots--assets)
6. [بناء حزمة الإنتاج ورفع التطبيق (Build & Upload)](#6-بناء-حزمة-الإنتاج-ورفع-التطبيق-build--upload)
7. [تعبئة استبيان الخصوصية في المتجر (App Privacy Questions)](#7-تعبئة-استبيان-الخصوصية-في-المتجر-app-privacy-questions)
8. [بيانات المراجعة وملاحظات لفاحص أبل (App Review Notes)](#8-بيانات-المراجعة-وملاحظات-لفاحص-أبل-app-review-notes)
9. [إرسال التطبيق للمراجعة والموافقة (Submit for Review)](#9-إرسال-التطبيق-للمراجعة-والموافقة-submit-for-review)

---

## 1. المتطلبات الأساسية قبل البدء

1. **حساب Apple Developer مفعّل:**
   - اشتراك في برنامج مطوري أبل ($99 سنوياً) عبر [developer.apple.com](https://developer.apple.com).
2. **جهاز Mac مثبت عليه:**
   - برنامج **Xcode** (الإصدار الأخير من Mac App Store).
   - حزمة **Flutter** وأدوات **CocoaPods** (`sudo gem install cocoapods`).
   - تطبيق **Transporter** (مجاني من متجر برامج الماك - أسرع وأسهل أداة لرفع ملفات IPA).
3. **معرف الحزمة (Bundle Identifier):**
   - المعرف المضبوط في المشروع هو: `com.yousefmohamed.quranApp` (أو المعرف الذي تختاره في حسابك).

---

## 2. الشهادات والملفات التعريفية (Certificates & Profiles)

أسهل وأضمن طريقة تعتمدها أبل حالياً هي **التوقيع التلقائي (Automatic Signing)** عبر Xcode:

1. افتح مشروع iOS في Xcode عبر فتح ملف الـ Workspace:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. من الشريط الجانبي الأيسر اضغط على **Runner** (المشروع الرئيسي في الأعلى).
3. انتقل إلى تبويب **Signing & Capabilities**.
4. حدد خيار **Automatically manage signing**.
5. في خانة **Team**: اختر حساب المطور الخاص بك (Apple Developer Account).
   - *إذا لم يكن حسابك مضافاً: اضغط على `Add an Account...` وسجل دخولك بـ Apple ID الخاص بحساب المطور.*
6. تأكد من أن خانة **Bundle Identifier** مطابقة لـ `com.yousefmohamed.quranApp`.
7. كرر نفس الخطوة لـ Target التابع للـ Widgets (`MyHomeWidgetExtension` إن وجد).

---

## 3. مراجعة إعدادات المشروع في Xcode

لقد قمنا بالفعل بتهيئة وضبط كافة الإعدادات والملفات داخل المشروع لتكون متوافقة 100% مع أبل:

1. **إصدار التطبيق ورقم البناء (Version & Build Number):**
   - موجود في تبويب **General**:
     - **Version:** `1.0.1` (هو الرقم الذي يراه المستخدمون على المتجر).
     - **Build:** `4010` (أو أي رقم بناء صحيح يزداد مع كل رفعة جديدة مثل `4011`).
2. **ملف الخصوصية (Privacy Manifest):**
   - تم إنشاء ملف `PrivacyInfo.xcprivacy` وضبطه بدقة لتأكيد أن التطبيق لا يجمع أي بيانات ولا يتتبع المستخدمين (`NSPrivacyTracking = false`).
3. **إلغاء فحص التشفير التجاري:**
   - تم ضبط `<key>ITSAppUsesNonExemptEncryption</key><false/>` في `Info.plist` حتى لا يسألك المتجر عن تراخيص التشفير العسكري الأمريكية في كل رفعة.
4. **نصوص الصلاحيات ثنائية اللغة (عربي / إنجليزي):**
   - تم تجهيزها بالكامل في `Info.plist`:
     - `NSLocationWhenInUseUsageDescription` (الموقع لحساب مواقيت الصلاة والقبلة).
     - `NSCameraUsageDescription` (الكاميرا للواقع المعزز ومسح رموز QR).
     - `NSPhotoLibraryUsageDescription` و `NSPhotoLibraryAddUsageDescription` (لحفظ بطاقات الآيات والأذكار في ألبوم الصور).
     - `NSMotionUsageDescription` (حساسات البوصلة والجيروسكوب لمتابعة الطواف والقبلة).

---

## 4. إنشاء التطبيق على App Store Connect

1. توجه إلى موقع [App Store Connect](https://appstoreconnect.apple.com) وسجل الدخول بحساب المطور.
2. انتقل إلى **Apps** ثم اضغط على زر الزائد **`+`** واشترِ **New App**.
3. قم بتعبئة النافذة المنبثقة:
   - **Platforms:** اختر `iOS`.
   - **Name:** اسم التطبيق (مثلاً: `تقرّب - القرآن والأذان` أو `Taqarrab - تقرّب`).
   - **Primary Language:** `Arabic` (العربية).
   - **Bundle ID:** اختر المعرف الخاص بك `com.yousefmohamed.quranApp`.
   - **SKU:** اسم تعريفي داخلي لك (مثلاً: `taqarrab-ios-01`).
   - **User Access:** اختر `Full Access`.
4. اضغط على **Create**.

---

## 5. تجهيز أصول المتجر ولقطات الشاشة (Screenshots & Assets)

### أ) أيقونة التطبيق للتسويق (App Store Icon):
- الحجم: **1024 × 1024 بكسل**.
- التنسيق: PNG عالي الدقة، 72 DPI، بنظام ألوان RGB، **بدون أي قنوات شفافة (No Alpha / Transparency)** وبدون زوايا دائرية (أبل تقوم بتدوير الزوايا تلقائياً).

### ب) لقطات الشاشة (Screenshots):
أبل تلزمك بتوفير لقطات شاشة واضحة للتطبيق بالأحجام الآتية (يمكن التقاطها مباشرة من محاكي iOS عبر الضغط على `Cmd + S`):
1. **شاشات iPhone مقاس 6.9" / 6.7" (إلزامية):**
   - الدقة المطلوبة: **1290 × 2796 بكسل** أو **1320 × 2868 بكسل**.
   - من محاكي: `iPhone 16 Pro Max` أو `iPhone 15 Pro Max`.
   - عدد الصور الموصى به: من 4 إلى 8 صور لأهم الشاشات (المصحف الشريف، مواقيت الصلاة، القبلة بالواقع المعزز، أذكار المسلم، رفيق الحج والعمرة، استوديو البطاقات).
2. **شاشات iPhone مقاس 6.5" (إلزامية):**
   - الدقة المطلوبة: **1242 × 2688 بكسل**.
   - من محاكي: `iPhone 11 Pro Max`.
3. **شاشات iPad مقاس 13" (إلزامية فقط في حال اختيار دعم الآيباد):**
   - الدقة المطلوبة: **2064 × 2752 بكسل** أو **2048 × 2732 بكسل**.
   - من محاكي: `iPad Pro 13-inch (M4)`.

---

## 6. بناء حزمة الإنتاج ورفع التطبيق (Build & Upload)

### الطريقة الموصى بها والأسرع (عبر سطر الأوامر وتطبيق Transporter):

1. **تنظيف وتحديث التبعيات:**
   افتح مجلد المشروع في الـ Terminal ونفذ:
   ```bash
   flutter clean
   flutter pub get
   cd ios
   pod install
   cd ..
   ```

2. **بناء حزمة الإنتاج (Production IPA):**
   نفذ الأمر التالي:
   ```bash
   flutter build ipa --release
   ```
   *سيعمل الأمر على عمل أرشيف كامل للمشروع وإنتاج ملف `Runner.ipa` داخل المسار:*
   `build/ios/ipa/quran_app_android.ipa` (أو `Runner.ipa`).

3. **الرفع عبر تطبيق Transporter:**
   - افتح تطبيق **Transporter** على الماك وسجل دخولك بـ Apple ID الخاص بحساب المطور.
   - اضغط على زر **`+`** واختر ملف `.ipa` المُنشأ.
   - اضغط على زر **Deliver (تسليم)**.
   - سيقوم التطبيق بالتحقق من الحزمة ورفعها مباشرة إلى خوادم أبل خلال دقائق معدودة.

---

## 7. تعبئة استبيان الخصوصية في المتجر (App Privacy Questions)

في صفحة تطبيقك على App Store Connect، ادخل إلى قسم **App Privacy**:

1. اضغط على **Get Started**.
2. **هل يقوم التطبيق بجمع بيانات؟ (Do you or your third-party partners collect data from this app?):**
   - اختر: **`No, we do not collect data from this app`** (لا، نحن لا نجمع بيانات من هذا التطبيق).
   - *السبب الشرعي والتقني:* لأن جميع معالجات الموقع والكاميرا والحساسات تتم آنياً في ذاكرة الهاتف فقط (Ephemeral in-memory processing) دون حفظ أو نقل أو خوادم وسيطة.
3. **رابط سياسة الخصوصية (Privacy Policy URL):**
   - ضع رابط صفحة سياسة الخصوصية (يمكنك استخدام رابط المستودع المباشر أو موقعك):
     `https://github.com/yousefmoh2399/Quran-App-main/blob/main/PRIVACY_POLICY.md`

---

## 8. بيانات المراجعة وملاحظات لفاحص أبل (App Review Notes)

عند الدخول إلى قسم **App Review Information** داخل صفحة الإصدار، قم بتعبئة التالي:

### أ) معلومات تسجيل الدخول (Sign-In Information):
- حدد: **Sign-in not required** (التطبيق لا يتطلب أي تسجيل دخول أو حسابات).

### ب) معلومات التواصل للمراجعة (Review Contact Information):
- اسمك الكامل، رقم هاتفك الدولي (مثل `+201xxxxxxxxx`)، وبريدك الإلكتروني المعتمد.

### ج) ملاحظات موجهة لفاحص أبل (Notes for App Reviewer):
> 💡 **نصيحة ذهبية:** انسخ هذا النص باللغة الإنجليزية وضعه في خانة الملاحظات لتسريع الفحص وتجنب أي أسئلة:

```text
Dear Apple Review Team,

Thank you for reviewing Taqarrab (تقرّب). 
Taqarrab is a 100% free, ad-free Islamic utility app built on an offline-first architecture with strict on-device processing:

1. Permissions Usage:
- Location (NSLocationWhenInUseUsageDescription): Used solely on-device to calculate astronomical prayer times and determine the Qiblah direction toward Mecca. No location tracking or logging is performed.
- Camera (NSCameraUsageDescription): Used exclusively for the Augmented Reality (AR) Qiblah compass view and for scanning Family Khatma Quran completion QR codes. Camera frames are processed strictly in volatile memory and never captured or stored.
- Photo Library (NSPhotoLibraryAddUsageDescription): Used only when the user explicitly taps "Save Card to Photos" in the Card Studio or Reading Analytics to save their generated verse card image to their Photo Library.
- Motion Sensors (NSMotionUsageDescription): Used for orientation tracking in the Qiblah compass and Tawaf rotation tracking.

2. Account Access:
- The application does not require any account creation, login, or subscriptions. All features are fully functional immediately upon launch.

Thank you for your time and assistance.
```

---

## 9. إرسال التطبيق للمراجعة والموافقة (Submit for Review)

1. عد إلى صفحة إصدار التطبيق (مثلاً `1.0.1 Prepare for Submission`).
2. في قسم **Build**:
   - اضغط على **Select a build before you submit your app**.
   - اختر النسخة التي رفعتها للتو عبر Transporter (ستظهر بعد دقائق من معالجتها من قبل أبل).
3. في قسم **Version Information**:
   - **Description (الوصف):** وصف مميز ومفصل للتطبيق وميزاته (المصحف الشريف، الأذان ومواقيت الصلاة، اتجاه القبلة العادي والمعزز، الأذكار اليومية، مناسك الحج والعمرة، حاسبة الزكاة، تحليلات القراءة).
   - **Keywords (الكلمات المفتاحية):** كلمات مفصولة بفواصل مثل: `قرآن,مصحف,أذان,مواقيت الصلاة,قبلة,أذكار,حج,عمرة,تلاوة,quran,adhan,athan,qibla,azkar,taqarrab`
   - **Support URL:** رابط الدعم (مثلاً رابط مستودع GitHub أو صفحة الدعم).
4. اضغط على **Save** في أعلى الصفحة.
5. اضغط على زر **Add for Review** الأخضر، ثم **Submit to App Review**.

---

### ⏱️ ماذا بعد الإرسال؟
- ستتحول حالة التطبيق إلى **Waiting for Review**.
- تستغرق مراجعة التطبيق عادة ما بين **12 إلى 24 ساعة**.
- بمجرد قبول التطبيق، ستتغير الحالة إلى **Ready for Sale** وسيصبح متاحاً للتحميل لملايين المسلمين حول العالم على أجهزة iPhone و iPad! 🎉
