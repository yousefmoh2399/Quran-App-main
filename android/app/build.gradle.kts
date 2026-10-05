import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val isKeystoreFileValid = keystorePropertiesFile.exists() && keystorePropertiesFile.length() > 0

if (isKeystoreFileValid) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

val storeFilePath = keystoreProperties.getProperty("storeFile")
val resolvedStoreFile = if (!storeFilePath.isNullOrBlank()) {
    val f = file(storeFilePath)
    if (f.exists()) f else rootProject.file(storeFilePath)
} else null

val isReleaseSigningConfigured = isKeystoreFileValid &&
    !keystoreProperties.getProperty("keyAlias").isNullOrBlank() &&
    !keystoreProperties.getProperty("keyPassword").isNullOrBlank() &&
    !keystoreProperties.getProperty("storePassword").isNullOrBlank() &&
    (resolvedStoreFile != null && resolvedStoreFile.exists())

android {
    namespace = "com.example.quran_app_android"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.taqarrab.quran"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 4010
        versionName = "1.0.1"
        compileOptions {
            isCoreLibraryDesugaringEnabled = true
        }
    }

    signingConfigs {
        create("release") {
            if (isReleaseSigningConfigured) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = resolvedStoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            if (isReleaseSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Do NOT silently fall back to debug signing for production release.
                // An unsigned AAB prevents accidental upload of debug-signed artifacts to Google Play.
                println("\n==========================================================================")
                println("⚠️ [CRITICAL PRODUCTION NOTICE] android/key.properties is not configured!")
                println("⚠️ AAB will NOT be signed with debug key to protect Google Play release.")
                println("⚠️ To sign for Google Play, create upload keystore and fill android/key.properties.")
                println("==========================================================================\n")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.2.2")
    implementation("com.google.code.gson:gson:2.10.1")
    implementation("com.batoulapps.adhan:adhan:1.2.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
}

flutter {
    source = "../.."
}