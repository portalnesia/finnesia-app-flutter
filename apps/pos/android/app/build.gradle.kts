import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.finnesia.pos"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.finnesia.pos"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Android 12 (API 31): the tablets this app targets. It is the first release with the
        // BLUETOOTH_SCAN / BLUETOOTH_CONNECT runtime permissions, so the printer needs no
        // location permission and no legacy BLUETOOTH* entries (plan/printer/README.md §9).
        minSdk = 31
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Release signing reads keystore.properties from this Gradle project root, which is
    // never committed: absent on a fresh clone, and on CI until the workflow writes it
    // from GitHub Secrets. Reading it unconditionally would throw during configuration
    // and take debug builds down with it, so values are only set when the file exists.
    // Without it, release fails with "Keystore file not set" — deliberate, so no
    // unsigned APK ships by accident. Debug builds use Gradle's own debug keystore.
    // The secrets are ANDROID_KEY_BASE64 / ANDROID_KEY_ALIAS / ANDROID_KEY_PASSWORD.
    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("keystore.properties")
            if (keystorePropertiesFile.exists()) {
                val keystoreProperties = Properties().apply {
                    keystorePropertiesFile.inputStream().use { load(it) }
                }
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("password")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("password")
            }
        }
    }

    buildTypes {
        debug {
            // A separate app from the release one, so a tablet can hold both and neither shares
            // the other's data (session, device fingerprint). Debug builds are the ones that can
            // talk to staging or a local backend (README §13); release talks to production only.
            // The suffix is on the application id, not the `namespace`, so the code package is
            // unchanged. The backend's App Links document names this id for the staging host
            // and `com.finnesia.pos` for production.
            applicationIdSuffix = ".debug"
        }
        release {
            // Was the `flutter create` default, which signed releases with the DEBUG
            // keystore. That is fine for `flutter run --release` locally but wrong for a
            // distributed APK: it is a different signing identity from the one already in
            // use, so it cannot be installed as an upgrade. Signing config values come
            // from keystore.properties; when that file is absent this fails loudly.
            signingConfig = signingConfigs.getByName("release")
        }
        // `profile` is Flutter's own build type, created by the Flutter Gradle plugin from the
        // debug one — and it is the staging build (`plan/staging/README.md`). It already
        // carries the two properties staging needs: no `applicationIdSuffix` (so the app id is
        // the release one) and `dart.vm.product=false` (so `isDebugApp` is true, which is what
        // turns on the staging host, the endpoint picker and the request inspector).
        //
        // The one thing it inherits wrong is the signing config: from debug, it gets the debug
        // keystore. Left alone, a locally built staging bundle and a CI one would be signed
        // with different keys — and neither with the identity the app is registered under.
        //
        // `named(...)`, not `create(...)`: the Flutter plugin applies during the `plugins {}`
        // block, which runs BEFORE this script's body, so the build type already exists here.
        // Creating it again would throw.
        named("profile") {
            signingConfig = signingConfigs.getByName("release")
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
