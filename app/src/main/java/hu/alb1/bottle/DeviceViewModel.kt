@file:OptIn(ExperimentalTime::class)

package hu.alb1.bottle

import android.Manifest
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.le.ScanResult
import android.content.Context
import androidx.annotation.RequiresPermission
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

class DeviceViewModel(val coroutineScope: CoroutineScope, val context: Context) {
    var name by mutableStateOf("null")
    var address by mutableStateOf("null")
    var rssi by mutableIntStateOf(-1)
    var latestPing = mutableStateOf<Instant?>(null)
    var syncLoop = mutableStateOf<Job?>(null)
    var batteryLevel = mutableIntStateOf(-1)
    var batteryLevelLoading = mutableStateOf(false)
    var bluetoothConnectionState = mutableStateOf(BluetoothProfileState.DISCONNECTED)

    @Synchronized
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    fun update(scanResult: ScanResult) {
        name = scanResult.device.name
        address = scanResult.device.address
        rssi = scanResult.rssi
        latestPing.value = Clock.System.now()
        syncLoop.value ?: coroutineScope.async { runSyncLoop(scanResult.device) }
    }

    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    private suspend fun runSyncLoop(bluetoothDevice: BluetoothDevice) {
        bluetoothDevice.connectGatt(
            context,
            false,
            bluetoothGattCallback,
            BluetoothDevice.TRANSPORT_LE
        )
        bluetoothConnectionState.value = BluetoothProfileState.CONNECTING
    }

    private val bluetoothGattCallback = object : BluetoothGattCallback() {
        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray
        ) {
            super.onCharacteristicChanged(gatt, characteristic, value)
        }

        override fun onCharacteristicRead(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray,
            status: Int
        ) {
            super.onCharacteristicRead(gatt, characteristic, value, status)

            if (characteristic.uuid == BleIdentifiers.BATTERY_LEVEL_CHAR) {
                batteryLevelLoading.value = false
                batteryLevel.intValue = value[0].toInt()
            }
        }

        override fun onCharacteristicWrite(
            gatt: BluetoothGatt?,
            characteristic: BluetoothGattCharacteristic?,
            status: Int
        ) {
            super.onCharacteristicWrite(gatt, characteristic, status)
        }

        @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
        override fun onConnectionStateChange(
            gatt: BluetoothGatt?,
            status: Int,
            newState: Int
        ) {
            super.onConnectionStateChange(gatt, status, newState)
            bluetoothConnectionState.value = BluetoothProfileState.fromRawValue(newState)
            if (gatt == null) return
            gatt.discoverServices()
        }

        override fun onDescriptorRead(
            gatt: BluetoothGatt,
            descriptor: BluetoothGattDescriptor,
            status: Int,
            value: ByteArray
        ) {
            super.onDescriptorRead(gatt, descriptor, status, value)
        }

        override fun onDescriptorWrite(
            gatt: BluetoothGatt?,
            descriptor: BluetoothGattDescriptor?,
            status: Int
        ) {
            super.onDescriptorWrite(gatt, descriptor, status)
        }

        override fun onMtuChanged(gatt: BluetoothGatt?, mtu: Int, status: Int) {
            super.onMtuChanged(gatt, mtu, status)
        }

        override fun onPhyRead(gatt: BluetoothGatt?, txPhy: Int, rxPhy: Int, status: Int) {
            super.onPhyRead(gatt, txPhy, rxPhy, status)
        }

        override fun onPhyUpdate(
            gatt: BluetoothGatt?,
            txPhy: Int,
            rxPhy: Int,
            status: Int
        ) {
            super.onPhyUpdate(gatt, txPhy, rxPhy, status)
        }

        override fun onReadRemoteRssi(gatt: BluetoothGatt?, rssi: Int, status: Int) {
            super.onReadRemoteRssi(gatt, rssi, status)
        }

        override fun onReliableWriteCompleted(gatt: BluetoothGatt?, status: Int) {
            super.onReliableWriteCompleted(gatt, status)
        }

        override fun onServiceChanged(gatt: BluetoothGatt) {
            super.onServiceChanged(gatt)
        }

        @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
        override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
            super.onServicesDiscovered(gatt, status)
            if (gatt == null) return

            val batteryService = gatt.services.first {it.uuid == BleIdentifiers.BATTERY_SERVICE}
            val batteryLevelCharacteristic = batteryService.characteristics.first {it.uuid == BleIdentifiers.BATTERY_LEVEL_CHAR}
            gatt.setCharacteristicNotification(batteryLevelCharacteristic, true)
            gatt.setCharacteristicNotification()
            gatt.readCharacteristic(batteryLevelCharacteristic)
            batteryLevelLoading.value = true
        }

        override fun onSubrateChange(gatt: BluetoothGatt, subrateMode: Int, status: Int) {
            super.onSubrateChange(gatt, subrateMode, status)
        }
    }
}
