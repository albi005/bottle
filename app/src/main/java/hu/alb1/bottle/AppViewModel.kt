@file:OptIn(ExperimentalTime::class)

package hu.alb1.bottle

import android.Manifest
import android.R.attr.name
import android.bluetooth.BluetoothDevice
import android.bluetooth.le.ScanResult
import androidx.annotation.RequiresPermission
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

class AppViewModel {
    val devices = mutableStateMapOf<BluetoothDevice, DeviceViewModel>()

    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    fun update(scanResult: ScanResult) {
        val device = devices.getOrPut(scanResult.device) { DeviceViewModel() }
        device.update(scanResult)
    }
}

class DeviceViewModel(val coroutineScope: CoroutineScope) {
    var name by mutableStateOf("null")
    var address by mutableStateOf("null")
    var rssi by mutableIntStateOf(-1)
    var latestPing = mutableStateOf<Instant?>(null)
    var job = mutableStateOf<Job?>(null)

    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    fun update(scanResult: ScanResult) {
        name = scanResult.device.name
        address = scanResult.device.address
        rssi = scanResult.rssi
        latestPing.value = Clock.System.now()
        job ?: coroutineScope.async { run(scanResult.device) }
    }

    private suspend fun run(bluetoothDevice: BluetoothDevice) {
        bluetoothDevice.connectGatt()
    }
}
