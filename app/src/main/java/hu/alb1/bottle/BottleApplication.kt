@file:OptIn(ExperimentalTime::class)

package hu.alb1.bottle

import android.app.Application
import android.bluetooth.BluetoothManager
import androidx.core.content.getSystemService
import androidx.health.connect.client.HealthConnectClient
import androidx.room.Room
import dagger.hilt.android.HiltAndroidApp
import hu.alb1.bottle.data.AppDatabase
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
    lateinit var db: AppDatabase
    lateinit var healthConnectClient: HealthConnectClient

    override fun onCreate() {
        super.onCreate()
        bleScanner = BleScanner(getSystemService<BluetoothManager>()!!)
        syncService = SyncService(appViewModel, bleScanner)
        applicationScope.launch { syncService.loop() }
        db = Room.databaseBuilder(
            applicationContext,
            AppDatabase::class.java, "bottle"
        ).build()
        healthConnectClient = HealthConnectClient.getOrCreate(this)
    }
}
