# سياسة الخصوصية لتطبيق "تَقَرَّبْ" (Privacy Policy for Taqarrab)

**تاريخ السريان (Effective Date):** 5 أكتوبر 2026  
**اسم التطبيق (App Name):** تَقَرَّبْ (Taqarrab)  
**معرّف التطبيق (Application ID):** `com.taqarrab.quran`  
**البريد الإلكتروني للتواصل (Contact Email):** `support@taqarrab.app` (أو بريدك الخاص)

---

## 🌿 مقدمة ورؤية الخصوصية (Introduction)

تطبيق **"تَقَرَّبْ"** هو تطبيق إسلامي مجاني بالكامل خُصص لمساعدة المسلمين على قراءة القرآن الكريم، معرفة مواقيت الصلاة، اتجاه القبلة، وقراءة الأذكار.

نحن نؤمن بأن العبادة تتطلب أعلى درجات الخصوصية والطمأنينة؛ لذا صُمم التطبيق ليعمل بمبدأ **"الخصوصية أولاً وحفظ البيانات محلياً (Offline-First Privacy)"**.  
**نحن لا نجمع، ولا نبيع، ولا نشارك أي بيانات شخصية تخصك مع أي طرف ثالث على الإطلاق.**

---

## 🔒 1. البيانات والتخزين المحلي (Local Data Storage)
* **ما يتم تخزينه:** جميع بيانات تفاعلك مع التطبيق (مثل: آخر صفحة قرأتها في المصحف، العلامات المرجعية، سجل الآيات المحفوظة، ملاحظات التدبر، إعدادات التنبيهات، ومتابعة الختمة).
* **مكان التخزين:** تُخزن هذه البيانات **فقط وحصرياً داخل قاعدة بيانات محلية ومحمية على هاتفك الشخصي**.
* **عدم الرفع:** لا يتم نقل هذه البيانات أو رفعها إلى أي خوادم خارجية (Servers) أو سحابية، وتظل تحت تحكمك الكامل. حذف التطبيق من هاتفك يؤدي إلى حذف هذه البيانات المحلية.

---

## 📍 2. أذونات التطبيق وكيفية استخدامها (Permissions Usage)

يطلب التطبيق الحد الأدنى من الأذونات اللازمة لتقديم وظائفه الأساسية، ويتم التعامل معها كالتالي:

### أ) إذن الموقع الجغرافي (Location Permission):
* **النوع:** `ACCESS_FINE_LOCATION` و `ACCESS_COARSE_LOCATION`.
* **الهدف:** حساب مواقيت الصلاة الخمسة بدقة فلكية وتحديد زاوية بوصلة القبلة نحو الكعبة المشرفة وفق موقعك الحالي.
* **الخصوصية:** تتم معالجة بيانات الموقع **لحظياً داخل جهازك فقط (Ephemeral on-device processing)**؛ لا نقوم بتتبع موقعك الجغرافي، ولا يتم حفظ سجل تنقلاتك، ولا يتم إرسال موقعك لأي خادم.

### ب) إذن المنبهات الدقيقة والإشعارات (Exact Alarms & Notifications):
* **النوع:** `SCHEDULE_EXACT_ALARM` و `USE_EXACT_ALARM` و `POST_NOTIFICATIONS`.
* **الهدف:** إطلاق صوت الأذان وعرض تنبيهات الصلاة بدقة بالثانية في مواعيدها المحددة، والتذكير بأذكار الصباح والمساء والورد القرآني.
* **التحكم:** يمكنك تفعيل أو تعطيل أو تخصيص أصوات أي صلاة أو ذكر بالكامل من داخل إعدادات التطبيق.

### ج) إذن خدمة الواجهة الأمامية (Foreground Service):
* **النوع:** `FOREGROUND_SERVICE_MEDIA_PLAYBACK`.
* **الهدف:** ضمان استمرار تشغيل صوت نداء الأذان كاملاً عند دخول وقت الصلاة حتى في حال كانت شاشة الهاتف مغلقة أو كان التطبيق في الخلفية.

### د) إذن حفظ الصور والوسائط (Media / Storage Access):
* **النوع:** `WRITE_EXTERNAL_STORAGE` (للإصدارات القديمة فقط).
* **الهدف:** يُستخدم **فقط** عندما تختار بنفسك حفظ بطاقة تصميم لآية قرآنية أو ذكر في ألبوم الصور بهاتفك.
* **الخصوصية:** التطبيق **لا يقرأ ولا يستعرض ولا يصل إلى أي صورة شخصية أو فيديو في معرض الصور الخاص بك**.

---

## 🚫 3. الإعلانات والتتبع (No Ads & Zero Tracking)
* **خالٍ تماماً من الإعلانات (100% Ad-Free):** لا يحتوي التطبيق على أي إعلانات تجارية (No Google AdMob, No Unity Ads, etc.).
* **خالٍ من أدوات التتبع والتحليلات (Zero Analytics / Tracking SDKs):** لا يحتوي التطبيق على أي كود برمجي لتتبع المستخدمين أو تحليل سلوكهم (لا يوجد Firebase Analytics، أو Facebook Pixel، أو أي مكتبة طرف ثالث تتبعية).

---

## 👶 4. خصوصية الأطفال (Children's Privacy)
تطبيق "تقرب" آمن ومناسب لجميع الأعمار (تصنيف 3+ / Everyone). التطبيق لا يجمع عن علم أي معلومات تعريف شخصية من أي مستخدم بما في ذلك الأطفال، ويتوافق تماماً مع معايير قانون حماية خصوصية الأطفال على الإنترنت (COPPA) وسياسات متجر Google Play و Apple App Store.

---

## 🔄 5. التعديلات على سياسة الخصوصية (Changes to this Policy)
قد نقوم بتحديث سياسة الخصوصية من حين لآخر إذا أضفنا ميزات جديدة تتطلب ذلك. سيتم نشر أي تحديث على هذه الصفحة مع تحديث "تاريخ السريان".

---

## 📬 6. التواصل والدعم الفني (Contact Us)
إذا كان لديك أي سؤال أو استفسار بخصوص سياسة الخصوصية هذه أو استخدامك لتطبيق "تقرب"، يسعدنا تواصلك معنا:
* **البريد الإلكتروني:** `support@taqarrab.app` (أو البريد المعتمد في حساب المطور)
* **مستودع المشروع:** [GitHub Repository Issues](https://github.com/yousefmoh2399/Quran-App-main/issues)

---
---

# English Version (For Google Play & App Store Compliance)

## Privacy Policy for "Taqarrab"

**Effective Date:** October 5, 2026  
**Application ID:** `com.taqarrab.quran`  
**Contact:** `support@taqarrab.app`

### Overview
Taqarrab ("we", "our", or "the app") is a completely free, ad-free Islamic application designed to provide users with an authentic Holy Quran reading experience, accurate prayer times, Qiblah compass, and daily Azkar (supplications).

We are deeply committed to protecting your privacy. Taqarrab is engineered on an **offline-first, zero-tracking philosophy**. **We do not collect, transmit, sell, or share any personal information whatsoever.**

### 1. Data Collection and Local Storage
* All user data—including bookmarks, reading progress, memorization status, personal notes, and prayer notification preferences—is stored strictly and exclusively on your local device storage.
* No data is transmitted to any cloud servers or external databases.

### 2. Device Permissions
Taqarrab requests only the bare minimum permissions necessary for its religious utility features:
* **Location (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`):** Used solely on-device to calculate astronomical prayer times and determine the Qiblah direction. Location data is processed ephemerally in-memory and is never logged, stored, or transmitted.
* **Exact Alarms & Notifications (`USE_EXACT_ALARM`, `SCHEDULE_EXACT_ALARM`, `POST_NOTIFICATIONS`):** Used strictly to schedule timely Adhan call-to-prayer alerts and Azkar reminders.
* **Foreground Service (`FOREGROUND_SERVICE_MEDIA_PLAYBACK`):** Used to play the audio Adhan when prayer time arrives, even when the screen is locked.
* **Photo Library / Storage:** Used only when you explicitly export/save an Ayah card image that you generated to your photo gallery. The app never reads or accesses your personal photos.

### 3. Advertising and Analytics
* **100% Ad-Free:** The app contains zero advertisements.
* **No Third-Party Analytics:** We do not embed any third-party tracking or behavioral SDKs (e.g., Google Analytics, Firebase, Facebook SDK).

### 4. Children’s Privacy
The app contains no inappropriate content and is rated for Everyone / 4+. We do not collect personal information from any user, including children under the age of 13.

### 5. Contact Us
If you have any questions or feedback regarding this Privacy Policy, please contact us at:  
Email: `support@taqarrab.app`  
GitHub: [https://github.com/yousefmoh2399/Quran-App-main](https://github.com/yousefmoh2399/Quran-App-main)
