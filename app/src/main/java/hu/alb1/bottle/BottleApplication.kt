@file:OptIn(ExperimentalTime::class)

package hu.alb1.bottle

import android.app.Application
import dagger.hilt.android.HiltAndroidApp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlin.time.ExperimentalTime

@HiltAndroidApp
class BottleApplication : Application() {
    val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    val appViewModel = AppViewModel(applicationScope, this)
    
    lateinit var bleScanner: BleScanner

    override fun onCreate() {
        super.onCreate()
        bleScanner = BleScanner(this)
    }
}
