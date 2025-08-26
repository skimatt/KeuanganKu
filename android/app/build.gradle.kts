plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle plugin harus diterapkan setelah Android dan Kotlin plugins
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.project_3"
    compileSdk = flutter.compileSdkVersion

    // Perbarui NDK sesuai permintaan plugin
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.rahmat.keuanganku"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Aktifkan core library desugaring agar plugin yang membutuhkan Java 8+ bisa berjalan
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Core library desugaring diperlukan oleh beberapa plugin seperti flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}

flutter {
    source = "../.."
}
