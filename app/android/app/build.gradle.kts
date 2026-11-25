import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The upload key's file and passwords, from android/key.properties: written
// by android-test.yml from the repository's secrets, and never committed.
// Without it a release build is signed with the debug key, so
// `flutter run --release` still works on a laptop.
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "com.tfaqud.tfaqud"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications uses java.time on every Android
        // version, which needs desugaring below API 26.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Fixed for good once the app is on Google Play.
        applicationId = "com.tfaqud.tfaqud"
        // Android 7.0: the lowest every plugin supports (notifications,
        // calendar, recording, speech, secure storage all need 24).
        minSdk = 24
        // Google Play takes new apps and updates only at Android 16 (API
        // 36) or higher since 31 August 2026.
        targetSdk = 36
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("upload") {
            keyAlias = keyProperties.getProperty("keyAlias")
            keyPassword = keyProperties.getProperty("keyPassword")
            storeFile = keyProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keyProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (keyProperties.isEmpty) "debug" else "upload",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // A plugin brings an older WorkManager whose database the release
    // build's code shrinking breaks, so the app crashed on start. This
    // newer one works with it.
    implementation("androidx.work:work-runtime:2.10.0")
}
