# سياسة الخصوصية لتطبيق "تَقَرَّبْ" (Privacy Policy for Taqarrab)

**تاريخ آخر تحديث (Last Updated):** 10 أكتوبر 2026  
**اسم التطبيق (App Name):** تَقَرَّبْ (Taqarrab)  
**معرّف الحزمة (Bundle ID / Package Name):** `com.yousefmohamed.quranApp`  
**البريد الإلكتروني للدعم (Contact Email):** `support@taqarrab.app`  

---

## 🌿 1. مقدمة ورؤية الخصوصية (Introduction & Core Philosophy)

تطبيق **"تَقَرَّبْ"** هو تطبيق إسلامي مجاني بالكامل وخالٍ تماماً من أي إعلانات، صُمم ليكون رفيقاً شاملاً للمسلم في قراءة القرآن الكريم، الاستماع للأذان، معرفة اتجاه القبلة العادي والمعزز (AR)، متابعة الأذكار، مناسك الحج والعمرة، وحساب الزكاة والختمات القرآنية.

نحن نؤمن إيماناً راسخاً بأن العبادة تتطلب أعلى درجات الأمان والطمأنينة والخصوصية؛ ولذلك تم بناء التطبيق هندسياً على مبدأ **"العمل دون اتصال بالإنترنت وحفظ البيانات محلياً (100% Offline-First & On-Device Processing)"**.

> 🛡️ **تعهد قاطع:**  
> **نحن لا نجمع، ولا نخزن على خوادم خارجية، ولا نتتبع، ولا نبيع، ولا نشارك أي بيانات شخصية أو معلومات استخدام أو موقع مع أي طرف ثالث على الإطلاق.**

---

## 🔒 2. البيانات والتخزين المحلي على جهازك (Local On-Device Data)

* **ما يتم تخزينه:**  
  جميع بيانات تفاعلك مع التطبيق تظل **حصرياً داخل هاتفك الشخصي**، وتشمل:
  - آخر صفحة وموضع توقف في المصحف الشريف وعلاماتك المرجعية (Bookmarks).
  - سجل التلاوة، الورد اليومي، وإحصائيات القراءة والتحليلات البيانية (Reading Analytics).
  - سجل الأذكار، تسبيحات العداد الإلكتروني، وتفضيلات تنبيهات الصلوات.
  - يوميات وملاحظات الحج والعمرة، وأشواط الطواف والسعي.
  - بيانات الختمات القرآنية الفردية والعائلية.
* **مكان التخزين:**  
  تُخزن هذه البيانات في قاعدة بيانات محلية مشفرة ومحمية تابعة للتطبيق فقط (`SQLite / SharedPreferences`).
* **عدم الرفع السحابي:**  
  لا يتم إرسال أي جزء من هذه البيانات إلى أي خادم أو قاعدة بيانات سحابية (Cloud). وحذف التطبيق من جهازك يؤدي لحذف هذه البيانات المحلية تلقائياً.

---

## 📱 3. الأذونات واستخدامات الحساسات (Permissions & Sensors Usage)

يطلب التطبيق فقط الحد الأدنى من الصلاحيات لتشغيل وظائفه الدينية، وتتم معالجتها **آنياً ومحلياً على الهاتف فقط (In-Memory Processing)**:

### أ) إذن الموقع الجغرافي (`Location`):
* **الاستخدام:**  
  - حساب مواقيت الصلاة الخمسة بدقة فلكية وفق إحداثيات خطوط الطول والعرض لموقعك الحالي.
  - حساب زاوية انحراف القِبلة الدقيقة نحو الكعبة المشرفة بمكة المكرمة.
* **الضمان:**  
  - المعالجة تتم داخل جهازك لحظياً، ولا يتم تسجيل سجل تحركاتك (No Location Tracking/History)، ولا يتم إرسال إحداثياتك لأي جهة.

### ب) إذن الكاميرا (`Camera`):
* **الاستخدام:**  
  - ميزة **القبلة بالواقع المعزز (AR Qiblah Camera)**: لعرض مجسم الكعبة ثلاثي الأبعاد ومسار التوجيه فوق المنظر الحقيقي المحيط بك لتسهيل تحديد اتجاه الصلاة.
  - ميزة **مسح رموز الختمات القرآنية (QR Code Scanner)**: لقراءة رموز الختمات المشتركة ومزامنة إنجاز القراءة بين أجهزة العائلة دون الحاجة للإنترنت.
* **الضمان:**  
  - البث المباشر للكاميرا يُعالج لحظياً في الذاكرة العشوائية لتحديد الزاوية وقراءة الرمز فقط؛ **لا يتم التقاط أو تسجيل أو حفظ أو رفع أي صور أو فيديوهات على الإطلاق**.

### ج) حساسات الحركة والبوصلة والجيروسكوب (`Motion & Compass Sensors / Gyroscope`):
* **الاستخدام:**  
  - قراءة حساس المجال المغناطيسي (Magnetometer) والجيروسكوب لتوجيه إبرة البوصلة نحو القبلة بسلاسة ودقة.
  - تتبع حركة الدوران في ميزة **مساعد الطواف (Tawaf Heading Accumulator)** لتقدير إتمام الدورة حول الكعبة (360 درجة).
* **الضمان:**  
  - بيانات الحساسات تُقرأ وتُعالج داخلياً عبر واجهات النظام الرسمية دون حفظ سجلات حركة أو مشاركة أي بيانات حركية.

### د) ألبوم الصور والوسائط (`Photo Library & Storage`):
* **الاستخدام:**  
  - يُطلب الإذن فقط عندما تختار بنفسك حفظ بطاقة تصميمية لآية أو ذكر من **"استوديو البطاقات"** أو حفظ تقرير إنجازك من **"تحليلات القراءة"** في ألبوم الصور.
* **الضمان:**  
  - التطبيق يستخدم صلاحية الإضافة فقط (`Add-Only`) عند توفرها، **ولا يقرأ أو يستعرض أو يصل لأي صور أو فيديوهات شخصية في هاتفك**.

### هـ) الإشعارات والمنبهات الدقيقة (`Notifications & Exact Alarms`):
* **الاستخدام:**  
  - إطلاق صوت الأذان في موعد كل صلاة بالدقيقة والثانية حتى مع قفل الشاشة أو وضع السكون.
  - إرسال تذكيرات الأذكار الصباحية والمسائية والورد اليومي.
* **التحكم:**  
  - يتم جدولة جميع التنبيهات محلياً على نظام التشغيل مباشرة دون خوادم وسيطة (No Push Notification Servers)، ويمكنك إيقافها أو تخصيص أصواتها بالكامل.

---

## 🚫 4. الإعلانات والتتبع الخارجي (No Ads & Zero Third-Party Tracking)

* **خالٍ 100% من الإعلانات:**  
  لا يتضمن التطبيق أي شبكات إعلانية تجارية (لا وجود لـ Google AdMob أو Unity Ads أو غيرها).
* **خالٍ من أدوات التتبع (Zero Analytics SDKs):**  
  لا يحتوي كود التطبيق على أي مكتبات تتبع سلوكي أو تحليلي (لا وجود لـ Firebase Analytics أو Facebook SDK أو AppsFlyer).
* **توافق وثيقة خصوصية أبل (Apple Privacy Manifest):**  
  التطبيق مزود بملف `PrivacyInfo.xcprivacy` معتمد يعلن رسمياً بأن `NSPrivacyTracking = false`، مع توثيق الأسباب المشروعة لاستخدام واجهات النظام المحلية القياسية.

---

## 👶 5. خصوصية الأطفال والأسرة (Children & Family Safety)

التطبيق مخصص ومناسب لكافة الفئات العمرية (تصنيف 4+ على App Store و 3+ على Google Play). التطبيق آمن تماماً، ولا يجمع أي معلومات تعريفية شخصية، ومتوافق مع المعايير الدولية لحماية خصوصية الأطفال على الإنترنت (COPPA).

---

## 🔄 6. التحديثات والتعديلات (Updates to Policy)

قد نقوم بتحديث سياسة الخصوصية هذه من حين لآخر لتعكس أي ميزات دينية جديدة نضيفها مستقبلاً. سيتم توثيق أي تحديث في هذا الملف مع تحديث تاريخ السريان داخل التطبيق وعلى المستودع البرمجي.

---

## 📬 7. التواصل والدعم (Contact & Inquiries)

إذا كان لديك أي استفسار أو اقتراح بخصوص خصوصية بياناتك:
* **البريد الإلكتروني:** `support@taqarrab.app`
* **المستودع المفتوح:** [GitHub Issues](https://github.com/yousefmoh2399/Quran-App-main/issues)

---
---

# Privacy Policy for Taqarrab (English Version)

**Last Updated:** October 10, 2026  
**Application Name:** Taqarrab (تَقَرَّبْ)  
**Bundle Identifier:** `com.yousefmohamed.quranApp`  
**Support Email:** `support@taqarrab.app`  

### 1. Overview & Commitment
Taqarrab is an authentic, completely free, and 100% ad-free Islamic utility application built to serve Muslims worldwide with Quran recitation, accurate Adhan prayer times, Augmented Reality (AR) and standard Qiblah direction, daily Azkar, Hajj & Umrah companions, and Zakat calculation.

Taqarrab is built upon an uncompromising **offline-first, zero-data-collection architecture**. **We do not collect, transmit, store on servers, sell, or monetize any of your personal data.**

### 2. Local On-Device Data Storage
* **Data Stored:** Reading history, Quran bookmarks, daily Wird targets, memorization badges, personal reflection notes, Azkar counter progress, and Hajj/Umrah logs.
* **Storage Location:** All data is stored strictly in your device's isolated local application sandbox (`SQLite` / `UserDefaults`).
* **No Cloud Transmission:** No personal data is ever uploaded to external cloud servers or third-party databases.

### 3. Permissions and Sensor Usage
Taqarrab requests only the permissions necessary to provide its core religious features, processed strictly on-device:
* **Location (`NSLocationWhenInUseUsageDescription` / Android Location):** Used ephemerally in-memory to compute local astronomical prayer times and calculate the exact Qiblah compass angle towards the Kaaba. Location is never tracked, logged, or transmitted.
* **Camera (`NSCameraUsageDescription` / Android Camera):**
  - **AR Qiblah View:** Projects an augmented 3D Kaaba indicator on your camera feed to guide your prayer orientation in physical space.
  - **Family Khatma QR Scanning:** Decodes QR codes to synchronize Quran completion circles between family devices completely offline.
  - *Guarantee:* Live camera frames are processed exclusively in volatile memory; **no photos or videos are ever captured, saved, or uploaded**.
* **Motion Sensors, Gyroscope & Magnetometer (`NSMotionUsageDescription`):**
  - Used for real-time heading orientation in the Qiblah compass and AR overlay.
  - Used in the experimental **Tawaf Heading Accumulator** to detect rotational movement during circumambulation around the Kaaba.
* **Photo Library (`NSPhotoLibraryAddUsageDescription`, `NSPhotoLibraryUsageDescription`):**
  - Used solely when you explicitly choose to export or save a high-resolution Quranic verse card or reading achievement image from the Card Studio to your device's Photos gallery. We never read or inspect your personal photo album.
* **Notifications & Exact Alarms:**
  - Scheduled purely on-device via native system schedulers to deliver timely Adhan audio calls to prayer and morning/evening Azkar reminders without remote push servers.

### 4. Zero Advertising & Zero Tracking
* **100% Ad-Free:** Zero third-party ad networks or commercial banners.
* **Zero Tracking:** No behavioral trackers or telemetry SDKs (No Firebase Analytics, Facebook SDK, or commercial trackers).
* **Apple Privacy Manifest Compliant:** Fully configured with `PrivacyInfo.xcprivacy` declaring `NSPrivacyTracking = false` and `NSPrivacyCollectedDataTypes = []`.

### 5. Children's Privacy
Rated 4+ / Everyone. Taqarrab does not solicit or collect information from children under 13, fully complying with COPPA and App Store safety guidelines.

### 6. Contact Us
For questions regarding this policy:  
Email: `support@taqarrab.app`  
GitHub: [https://github.com/yousefmoh2399/Quran-App-main](https://github.com/yousefmoh2399/Quran-App-main)
