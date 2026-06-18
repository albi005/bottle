plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.google.devtools.ksp)
    alias(libs.plugins.google.dagger.hilt.android)
    alias(libs.plugins.wire)
}

android {
    namespace = "hu.alb1.bottle"
    compileSdk {
        version = release(37) {
        }
    }

    defaultConfig {
        applicationId = "hu.alb1.bottle"
        minSdk = 36
        targetSdk = 37
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    buildFeatures {
        compose = true
    }
}

dependencies {
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.material3.adaptive.navigation.suite)
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.protobuf.javalite)
    implementation(libs.protobuf.kotlin.lite)
    testImplementation(libs.junit)
    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.compose.ui.test.junit4)
    androidTestImplementation(libs.androidx.espresso.core)
    androidTestImplementation(libs.androidx.junit)
    debugImplementation(libs.androidx.compose.ui.test.manifest)
    debugImplementation(libs.androidx.compose.ui.tooling)

    // CoroutineWorker https://developer.android.com/develop/background-work/background-tasks/persistent/getting-started
    implementation(libs.androidx.work.runtime)
    implementation(libs.androidx.work.runtime.ktx)

    // Dependency injection https://developer.android.com/training/dependency-injection/hilt-android
    implementation(libs.hilt.android)
    ksp(libs.hilt.android.compiler)

    // Protobuf https://square.github.io/wire/
    api(libs.wire.runtime)

    // SQLite ORM and stuff https://developer.android.com/training/data-storage/room
    implementation(libs.androidx.room.runtime)
    ksp(libs.androidx.room.compiler)
    implementation(libs.androidx.room.ktx)
    testImplementation(libs.androidx.room.testing)
    implementation(libs.androidx.room.paging)
    implementation(libs.androidx.paging.compose)

    // https://developer.android.com/health-and-fitness/health-connect/get-started
    implementation(libs.androidx.health.connect.client)

    // https://github.com/Kotlin/kotlinx-datetime#gradle
    implementation(libs.kotlinx.datetime)
}

wire {
    kotlin {}
}
