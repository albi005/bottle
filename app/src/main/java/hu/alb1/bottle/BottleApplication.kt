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
    val appViewModel = AppViewModel()
    
    lateinit var syncManager: SyncManager
    lateinit var bleScanner: BleScanner

    override fun onCreate() {
        super.onCreate()
        syncManager = SyncManager(this, applicationScope)
        bleScanner = BleScanner(this)
    }
}
