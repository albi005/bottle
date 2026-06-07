@file:OptIn(ExperimentalTime::class)

package hu.alb1.bottle

import android.app.Application
import dagger.hilt.android.HiltAndroidApp
import kotlin.time.ExperimentalTime

@HiltAndroidApp
class BottleApplication : Application() {
    val appViewModel = AppViewModel()
}
