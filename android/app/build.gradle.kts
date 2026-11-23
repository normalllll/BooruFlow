import java.net.URI
import java.security.MessageDigest
import java.util.zip.ZipInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "io.github.normalllll.booruflow"
    compileSdk = 37
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.normalllll.booruflow"
        minSdk = 26
        targetSdk = 37
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    packaging {
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

// The app ships the reduced libmpv of tool/libmpv. Libraries in the app's own
// jniLibs take precedence over media_kit's libmpv.so of the same name.
val libmpvUrl = "https://github.com/normalllll/BooruFlow/releases/download/libmpv-0.42.0-1/libmpv-android.zip"
val libmpvSha256 = "7e12f4fd1088dc191b5bbe3e51f6459e6f8abeaf8f01ae47e0c15b8a6efb8411"
val libmpvJniLibs = layout.buildDirectory.dir("libmpv/$libmpvSha256")

val fetchLibmpv by tasks.registering {
    val url = libmpvUrl
    val sha256 = libmpvSha256
    val destination = libmpvJniLibs
    inputs.property("sha256", sha256)
    outputs.dir(destination)
    doLast {
        val bytes = URI(url).toURL().openStream().use { it.readBytes() }
        val actual = MessageDigest.getInstance("SHA-256").digest(bytes)
            .joinToString("") { "%02x".format(it) }
        if (actual != sha256) {
            throw GradleException("$url has SHA-256 $actual, expected $sha256")
        }
        val root = destination.get().asFile
        root.deleteRecursively()
        ZipInputStream(bytes.inputStream()).use { zip ->
            generateSequence { zip.nextEntry }.filterNot { it.isDirectory }.forEach { entry ->
                val file = root.resolve(entry.name).canonicalFile
                check(file.startsWith(root.canonicalFile)) { "Unexpected entry ${entry.name}" }
                file.parentFile.mkdirs()
                file.outputStream().use { zip.copyTo(it) }
            }
        }
    }
}

android.sourceSets.getByName("main").jniLibs.srcDir(libmpvJniLibs.get().asFile)
tasks.named("preBuild") { dependsOn(fetchLibmpv) }

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}


flutter {
    source = "../.."
}

dependencies {
    implementation("com.squareup.okhttp3:okhttp:5.5.0")
}
