# دليل النشر على متجر Google Play وإقرار صلاحيات الأذان المجدول (USE_EXACT_ALARM)

يوثق هذا الدليل الخطوات والإقرارات الرسمية المطلوبة لنشر تطبيق **"تقرّب" (Taqarrab)** على متجر Google Play مع الالتزام الكامل بسياسات Android 14/15/16 ومعايير الخصوصية.

---

## 1. هوية التطبيق الرسمية (App Identity)
- **Application ID (Package Name):** `com.taqarrab.quran`
- **اسم التطبيق (App Name):** تقرّب | القرآن الكريم والأذان
- **الفئة على المتجر (Category):** Books & Reference / Lifestyle
- **الجمهور المستهدف (Target Audience):** جميع الفئات العمرية (عام)

---

## 2. إقرار صلاحية USE_EXACT_ALARM في Google Play Console

### متطلبات سياسة Google Play
تتطلب سياسة Google Play للتطبيقات المستهدفة لـ Android 14 (API 34) وما فوق تبريراً تفصيلياً لاستخدام الصلاحيات:
- `android.permission.USE_EXACT_ALARM`
- `android.permission.SCHEDULE_EXACT_ALARM`

تطبيقات الأذان ومواقيت الصلاة **مصرّح لها رسمياً** باستخدام هذا الإذن تحت بند **"Religious & Prayer Time Alarms"** لأن تأخير التنبيه بدقيقة واحدة يفوت على المسلم وقت الصلاة المفروضة شرعاً.

### النموذج الجاهز للصق في Google Play Console:

#### الحقل الأول: Core Use Case (الاستخدام الأساسي)
> اختر من القائمة: **Alarms or timers** (أو **Prayer time notifications**)

#### الحقل الثاني: Detailed description of core functionality (نص التبرير بالإنجليزي - جاهز للصق)
```text
The app "Taqarrab" is an Islamic worship companion whose primary core functionality is delivering strictly time-accurate Adhan (Islamic call to prayer) and prayer alerts five times a day.

In Islamic tradition, prayer times are bound to precise astronomical sun positions calculated down to the second. A delay of even a few minutes caused by OS battery optimization/Doze mode renders the religious prayer call invalid and causes users to miss their obligatory prayers.

The app uses USE_EXACT_ALARM exclusively for:
1. Triggering the full-screen Adhan alert and notification at the exact calculated prayer time (Fajr, Dhuhr, Asr, Maghrib, Isha).
2. Scheduling user-configured voluntary worship alarms (e.g. Qiyam / Suhoor / Morning and Evening Reminders).

Without exact alarm scheduling, the app cannot fulfill its essential service to millions of Muslims who rely on it for their daily prayer rituals.
```

#### الحقل الثالث: Video Demonstration Link (فيديو توضيحي)
تطلب Google رابط فيديو (YouTube Unlisted) يوضح:
1. فتح المستخدم للتطبيق والدخول لإعدادات الأذان.
2. تفعيل التنبيه أو تجربة أذان (زر "اختبار الأذان").
3. ظهور شاشة تنبيه الأذان في الوقت المحدد بالضبط.

---

## 3. إنشاء مفتاح التوقيع الرسمي (Release Keystore)

لبناء نسخة الإنتاج الموقعة لمتجر Google Play، اتبع الخطوات التالية في Windows PowerShell:

### الخطوة 1: توليد ملف Keystore
قم بتشغيل الأمر التالي في سطر الأوامر (تأكد من استبدال `YOUR_PASSWORD` بكلمة مرور قوية):

```powershell
keytool -genkey -v -keystore C:\Users\Yousef\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
*(ستطلب منك الأداة إدخال الاسم، والمدينة، والمنظمة، وكلمة المرور).*

### الخطوة 2: إنشاء ملف الإعدادات `android/key.properties`
أنشئ ملفاً باسم `android/key.properties` بجانب `android/key.properties.example`:

```properties
keyAlias=upload
keyPassword=كلمة_مرور_المفتاح_هنا
storePassword=كلمة_مرور_المخزن_هنا
storeFile=C:/Users/Yousef/upload-keystore.jks
```

> **تنبيه أمني:** ملف `key.properties` وملف `.jks` مضافان تلقائياً إلى `.gitignore` لمنع رفعهما إلى مستودعات Git العامة.

---

## 4. بناء حزمة النشر لمتجر Google Play (AAB)

بعد ضبط `key.properties`، قم بتشغيل الأمر التالي لإنتاج حزمة `App Bundle`:

```powershell
flutter build appbundle --release
```

الملف الناتج سيكون جاهزاً للرفع المباشر على Google Play Console في المسار:
`build/app/outputs/bundle/release/app-release.aab`
