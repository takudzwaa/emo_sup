import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.emosup.emo_sup"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.emosup.emo_sup"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Real per-environment flavors (was previously a manual
    // `cp google-services-prod.json google-services.json` step before every
    // prod build — easy to forget, and nothing caught it if you did). Same
    // applicationId across flavors (all three Firebase Android apps are
    // registered under "com.emosup.emo_sup", no per-flavor suffix) — only
    // the bundled google-services.json differs, picked up automatically by
    // the google-services Gradle plugin from src/<flavor>/google-services.json.
    flavorDimensions += "env"
    productFlavors {
        create("prototype") {
            dimension = "env"
            // In-memory repos; Firebase is never initialized for this
            // flavor in Dart, but the google-services plugin still needs a
            // valid file present to build the variant — reuses staging's.
        }
        create("staging") {
            dimension = "env"
        }
        create("prod") {
            dimension = "env"
        }
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Prefer the upload keystore when present; fall back to debug so
            // `flutter run --release` still works on a fresh checkout. Loud,
            // not silent — a debug-signed AAB uploaded to Play Console by
            // mistake is a real, hard-to-notice failure mode.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "WARNING: android/key.properties not found — this release " +
                        "build is DEBUG-SIGNED. Fine for local `flutter run " +
                        "--release`, but a debug-signed build bundle will be " +
                        "rejected by Play Console. Run keytool + fill in " +
                        "android/key.properties before a real release build " +
                        "(see README 'Production deploy runbook').",
                )
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
