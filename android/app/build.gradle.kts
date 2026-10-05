import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Push needs android/app/google-services.json from this app's own Firebase
// registration. Until it is there the app builds and runs without push —
// FirebasePushMessaging already treats a missing Firebase as "no push".
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

// The upload key lives outside the repo, described by android/key.properties.
// Absent on machines that only ever build debug, and that is fine: the release
// build then falls back to the debug key and Play will refuse the artefact,
// which is a louder failure than silently shipping an unsigned bundle.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

android {
    namespace = "id.co.lds.bandargames"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "id.co.lds.bandargames"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystoreProperties.containsKey("storeFile")) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")

            // R8 code shrinking + resource shrinking are already switched on by
            // the Flutter Gradle plugin for release builds; do not re-declare
            // them here or the proguard file list gets applied twice.
        }
    }

    packaging {
        jniLibs {
            // Required for 16 KB memory page devices (Android 15+): native
            // libraries must ship uncompressed so the loader can mmap them
            // directly, which also lets AGP align them to 16 KB in the archive.
            // This is the AGP default at minSdk 24 - pinned so it cannot regress.
            useLegacyPackaging = false
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
