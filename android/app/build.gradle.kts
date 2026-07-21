import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Load release signing config from android/key.properties (gitignored).
// The file is created locally per Flutter's recommended signing flow; the
// build falls back to the debug keystore only when key.properties is absent
// (e.g. on CI without secrets) so developer machines aren't blocked.
val keystoreProperties = Properties().apply {
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}

android {
    namespace = "com.sabiq.noorrewards"
    // Use fixed versions for stability in Release builds if flutter.sdk is fluctuating
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
        // Set to VERSION_17 to match your Java 21 environment and remove "Obsolete" warnings
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        // Explicitly stringify VERSION_17 for the Kotlin compiler
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.sabiq.noorrewards"
        // Ensure minSdk is at least 21 for modern plugins

        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appAuthRedirectScheme"] = "noorrewards"
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties["storeFile"] as String?
            if (storeFilePath != null) {
                storeFile = file(storeFilePath)
                storePassword = keystoreProperties["storePassword"] as String?
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // Optimizations to help prevent "Daemon Disappeared" crashes
            isMinifyEnabled = true
            isShrinkResources = true
            // Use the release keystore when key.properties supplied one;
            // otherwise fall back to debug so developer builds on machines
            // without the keystore still work (only Play-facing AABs need
            // the real signing config).
            signingConfig = if (keystoreProperties["storeFile"] != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // Add ProGuard rules if you have complex dependencies like Supabase
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Upgraded desugaring library for better Java 17 compatibility
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
