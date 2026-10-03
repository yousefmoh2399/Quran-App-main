# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Deferred Components / Play Core (optional feature, ignore missing references)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Keep native app code, broadcast receivers, alarm services, and widgets
-keep class com.example.quran_app_android.** { *; }
-keepclassmembers class com.example.quran_app_android.** { *; }

# Keep Adhan calculation library
-keep class com.batoulapps.adhan.** { *; }
-keepclassmembers class com.batoulapps.adhan.** { *; }

# Keep Gson serialization for widget data and shared prefs
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keepclassmembers class com.google.gson.** { *; }

# Keep HomeWidget plugin classes
-keep class es.antonborri.home_widget.** { *; }

# Keep Sqflite native classes
-keep class com.tekartik.sqflite.** { *; }

# Keep AndroidX & Notification components
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class androidx.work.** { *; }
