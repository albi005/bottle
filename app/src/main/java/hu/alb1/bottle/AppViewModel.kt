@file:OptIn(ExperimentalTime::class, ExperimentalUuidApi::class)

package hu.alb1.bottle

import android.Manifest
import android.bluetooth.BluetoothDevice
import android.bluetooth.le.ScanResult
import android.content.Context
import androidx.annotation.RequiresPermission
import androidx.compose.runtime.mutableStateMapOf
import kotlinx.coroutines.CoroutineScope
import kotlin.time.ExperimentalTime
import kotlin.uuid.ExperimentalUuidApi

class AppViewModel(val coroutineScope: CoroutineScope, val context: Context) {
    val devices = mutableStateMapOf<BluetoothDevice, DeviceViewModel>()

    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    fun update(scanResult: ScanResult) {
        val device =
            devices.getOrPut(scanResult.device) { DeviceViewModel(coroutineScope, context) }
        device.update(scanResult)
    }
}
