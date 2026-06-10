@file:OptIn(ExperimentalTime::class)

package hu.alb1.bottle

import android.app.Application
import android.bluetooth.BluetoothManager
import androidx.core.content.getSystemService
import dagger.hilt.android.HiltAndroidApp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlin.time.ExperimentalTime

@HiltAndroidApp
class BottleApplication : Application() {
    val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    val appViewModel = AppViewModel(applicationScope, this)
    lateinit var bleScanner: BleScanner
    lateinit var syncService: SyncService

    override fun onCreate() {
        super.onCreate()
        bleScanner = BleScanner(getSystemService<BluetoothManager>()!!)
        syncService = SyncService(appViewModel, bleScanner)
        applicationScope.launch { syncService.loop() }
    }
}
