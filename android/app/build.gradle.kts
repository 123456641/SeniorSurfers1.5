plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.senior_surfers"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Keep Java 8 for flutter_local_notifications compatibility
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        
        // Enable core library desugaring
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        applicationId = "com.example.senior_surfers"
        
        // Set the minSdkVersion and targetSdkVersion correctly
        minSdkVersion(21) // Use function invocation
        targetSdkVersion(flutter.targetSdkVersion) // Use function invocation with flutter version
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Enable multidex if needed
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Add core library desugaring dependency
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // Add multidex support if your app has many dependencies
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}