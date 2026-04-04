plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.noor_rewards"
    // Use fixed versions for stability in Release builds if flutter.sdk is fluctuating
    compileSdk = 34
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
        applicationId = "com.example.noor_rewards"
        // Ensure minSdk is at least 21 for modern plugins
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appAuthRedirectScheme"] = "noorrewards"
    }

    buildTypes {
        release {
            // Optimizations to help prevent "Daemon Disappeared" crashes
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("debug")

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
