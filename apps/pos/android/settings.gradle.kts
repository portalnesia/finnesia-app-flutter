pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    // START: FlutterFire Configuration
    // 4.3.15 is not enough for Crashlytics Gradle plugin 3, which hard-fails with
    // "requires Google-Services 4.4.1 and above". 4.5.0 is the current release.
    id("com.google.gms.google-services") version("4.5.0") apply false
    // NOT the version in firebase_crashlytics's own example/android/settings.gradle in the pub
    // cache: that example still pins 2.8.1, which is Groovy-based and calls
    // `groovy.util.XmlSlurper` in GoogleAppIdUtils. Groovy 4 — the one bundled with Gradle 9 —
    // removed `groovy.util`, so 2.8.1 dies on `:app:uploadCrashlyticsMappingFileRelease` with
    // "groovy/util/XmlSlurper". 3.0.0 rewrote the plugin in Kotlin and dropped the Groovy
    // dependency (verified by unzipping the jars: 2.8.1 has the symbol, 3.0.8 does not).
    id("com.google.firebase.crashlytics") version("3.0.8") apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")
