plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "io.github.normalllll.yande_gui"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "io.github.normalllll.yande_gui"
        minSdk = 26
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    packagingOptions {
        dex {
            useLegacyPackaging = true
        }
        jniLibs {
            useLegacyPackaging = true
        }
    }

    signingConfigs {
        create("release") {
            if (project.hasProperty("KEYSTORE_FILE") &&
                project.hasProperty("KEYSTORE_PASSWORD") &&
                project.hasProperty("KEY_ALIAS")
            ) {
                storeFile = file(project.property("KEYSTORE_FILE") as String)
                storePassword = project.property("KEYSTORE_PASSWORD") as String
                keyAlias = project.property("KEY_ALIAS") as String
                keyPassword = project.property("KEY_PASSWORD") as String
            } else {
                throw GradleException("Missing required signing properties. Make sure to provide MY_KEYSTORE_FILE, MY_KEYSTORE_PASSWORD, and MY_KEY_ALIAS.")
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86_64")
            isUniversalApk = true
        }
    }
}

flutter {
    source = "../.."
}