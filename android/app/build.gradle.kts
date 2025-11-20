plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.evacutaion"
   compileSdk = 36

    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

 kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        // ✅ App details
        applicationId = "com.example.mswdo"

        // ✅ Minimum SDK required by camera libraries
        minSdk = flutter.minSdkVersion
        targetSdk = 36

        // ✅ Versioning (use Flutter defaults if available)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // ✅ Temporary: use debug signing until you create a release key
            signingConfig = signingConfigs.getByName("debug")

            // ✅ Optimize later when releasing
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
