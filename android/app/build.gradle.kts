import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val isKeystoreConfigured = keystorePropertiesFile.exists() && run {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
    val storeFilePath = keystoreProperties.getProperty("storeFile")
    val storePassword = keystoreProperties.getProperty("storePassword")
    if (storeFilePath.isNullOrBlank() || storePassword.isNullOrBlank()) {
        false
    } else {
        val f = file(storeFilePath)
        val resolved = if (f.isAbsolute) f else rootProject.file(storeFilePath)
        resolved.exists()
    }
}

android {
    namespace = "io.github.humayanx.resinc" 
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.humayanx.resinc"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (isKeystoreConfigured) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                val storeFilePath = keystoreProperties.getProperty("storeFile")
                val f = file(storeFilePath)
                storeFile = if (f.isAbsolute) f else rootProject.file(storeFilePath)
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    buildTypes {
        release {
            signingConfig = if (isKeystoreConfigured) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
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
