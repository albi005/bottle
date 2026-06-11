@file:OptIn(ExperimentalTime::class)

package hu.alb1.bottle

import android.Manifest
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattConnectionSettings
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.le.ScanResult
import android.content.Context
import android.os.Build
import androidx.annotation.RequiresPermission
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.room.concurrent.AtomicInt
import com.squareup.wire.AnyMessage
import hu.alb1.bottle.proto.CapBleRequest
import hu.alb1.bottle.proto.CapBleResponse
import hu.alb1.bottle.proto.RequestGetCapTofState
import hu.alb1.bottle.proto.ResponseGetCapTofState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.asExecutor
import kotlinx.coroutines.async
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.mapNotNull
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch
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
    private suspend fun runSyncLoop(bluetoothDevice: BluetoothDevice) = coroutineScope {
        var gattWrapper: BottleGattWrapper? = null
        val connectionStateChangeChannel = Channel<ConnectionStateChangeMessage>(Channel.UNLIMITED)
        val servicesDiscoveredChannel = Channel<ServicesDiscoveredMessage>(Channel.UNLIMITED)
        val characteristicReadChannel = Channel<CharacteristicReadMessage>(Channel.UNLIMITED)
        val characteristicChangedChannel = Channel<CharacteristicChangedMessage>(Channel.UNLIMITED)

        val bluetoothGattCallback = object : BluetoothGattCallback() {
            override fun onCharacteristicChanged(
                gatt: BluetoothGatt,
                characteristic: BluetoothGattCharacteristic,
                value: ByteArray
            ) {
                super.onCharacteristicChanged(gatt, characteristic, value)
                characteristicChangedChannel.trySend(
                    CharacteristicChangedMessage(
                        gatt,
                        characteristic,
                        value
                    )
                )
            }

            override fun onCharacteristicRead(
                gatt: BluetoothGatt,
                characteristic: BluetoothGattCharacteristic,
                value: ByteArray,
                status: Int
            ) {
                super.onCharacteristicRead(gatt, characteristic, value, status)
                characteristicReadChannel.trySend(
                    CharacteristicReadMessage(
                        gatt,
                        characteristic,
                        value,
                        status
                    )
                )
            }

            override fun onCharacteristicWrite(
                gatt: BluetoothGatt?,
                characteristic: BluetoothGattCharacteristic?,
                status: Int
            ) = super.onCharacteristicWrite(gatt, characteristic, status)

            @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
            override fun onConnectionStateChange(gatt: BluetoothGatt?, status: Int, newState: Int) {
                super.onConnectionStateChange(gatt, status, newState)
                connectionStateChangeChannel.trySend(
                    ConnectionStateChangeMessage(
                        gatt,
                        status,
                        BluetoothProfileState.fromRawValue(newState)
                    )
                )
            }

            override fun onDescriptorRead(
                gatt: BluetoothGatt,
                descriptor: BluetoothGattDescriptor,
                status: Int,
                value: ByteArray
            ) = super.onDescriptorRead(gatt, descriptor, status, value)

            override fun onDescriptorWrite(
                gatt: BluetoothGatt?,
                descriptor: BluetoothGattDescriptor?,
                status: Int
            ) = super.onDescriptorWrite(gatt, descriptor, status)

            override fun onMtuChanged(gatt: BluetoothGatt?, mtu: Int, status: Int) =
                super.onMtuChanged(gatt, mtu, status)

            override fun onPhyRead(gatt: BluetoothGatt?, txPhy: Int, rxPhy: Int, status: Int) =
                super.onPhyRead(gatt, txPhy, rxPhy, status)

            override fun onPhyUpdate(gatt: BluetoothGatt?, txPhy: Int, rxPhy: Int, status: Int) =
                super.onPhyUpdate(gatt, txPhy, rxPhy, status)

            override fun onReadRemoteRssi(gatt: BluetoothGatt?, rssi: Int, status: Int) =
                super.onReadRemoteRssi(gatt, rssi, status)

            override fun onReliableWriteCompleted(gatt: BluetoothGatt?, status: Int) =
                super.onReliableWriteCompleted(gatt, status)

            override fun onServiceChanged(gatt: BluetoothGatt) = super.onServiceChanged(gatt)

            @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
            override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
                super.onServicesDiscovered(gatt, status)
                servicesDiscoveredChannel.trySend(ServicesDiscoveredMessage(gatt, status))
            }

            override fun onSubrateChange(gatt: BluetoothGatt, subrateMode: Int, status: Int) =
                super.onSubrateChange(gatt, subrateMode, status)
        }

        launch {
            val gatt = connectionStateChangeChannel
                .receiveAsFlow()
                .mapNotNull {
                    bluetoothConnectionState.value = it.newState
                    it.gatt
                }
                .first()

            gatt.discoverServices()
        }

        launch {
            for (msg in servicesDiscoveredChannel) {
                val gatt = msg.gatt ?: continue

                gattWrapper = BottleGattWrapper(gatt)

                gatt.setCharacteristicNotification(
                    gattWrapper.nordicUartService.txCharacteristic.characteristic,
                    true
                )

                val txChar = gattWrapper.nordicUartService.txCharacteristic.characteristic
                val cccd =
                    txChar.getDescriptor(BleIdentifiers.CLIENT_CHARACTERISTIC_CONFIG_DESCRIPTOR)

                (context.applicationContext as BottleApplication).applicationScope.launch {
                    delay(1000)
                    gatt.writeCharacteristic(
                        gattWrapper.nordicUartService.rxCharacteristic.characteristic,
                        CapBleRequest(
                            requestId = 0,
                            body = AnyMessage.pack(RequestGetCapTofState())
                        ).encode(),
                        BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
                    )
                }
                gatt.writeDescriptor(cccd, BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)

                batteryLevelLoading.value = true
            }
        }

        launch {
            for (msg in characteristicReadChannel) {
                if (msg.characteristic == gattWrapper!!.batteryService.batteryLevelCharacteristic) {
                    batteryLevelLoading.value = false
                    batteryLevel.intValue = msg.value[0].toInt()
                }
            }
        }

        launch {
            for (msg in characteristicChangedChannel) {
                if (msg.characteristic == gattWrapper!!.nordicUartService.txCharacteristic.characteristic) {
                    val response = CapBleResponse.ADAPTER.decode(msg.value)
                    val tofState = response.body?.unpackOrNull(ResponseGetCapTofState.ADAPTER)
                    println(response)
                    println(tofState)
                }
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.CINNAMON_BUN) {
            bluetoothDevice.connectGatt(
                BluetoothGattConnectionSettings.Builder().build(),
                Dispatchers.IO.limitedParallelism(1).asExecutor(),
                bluetoothGattCallback,
            )
        } else {
            bluetoothDevice.connectGatt(
                context,
                false,
                bluetoothGattCallback,
                BluetoothDevice.TRANSPORT_LE
            )
        }
        bluetoothConnectionState.value = BluetoothProfileState.CONNECTING
    }

    private val requestIdCounter = AtomicInt(0)
}

data class ConnectionStateChangeMessage(
    val gatt: BluetoothGatt?,
    val status: Int,
    val newState: BluetoothProfileState
)

data class ServicesDiscoveredMessage(
    val gatt: BluetoothGatt?,
    val status: Int
)

@Suppress("ArrayInDataClass") // don't care
data class CharacteristicReadMessage(
    val gatt: BluetoothGatt,
    val characteristic: BluetoothGattCharacteristic,
    val value: ByteArray,
    val status: Int
)

@Suppress("ArrayInDataClass")
data class CharacteristicChangedMessage(
    val gatt: BluetoothGatt,
    val characteristic: BluetoothGattCharacteristic,
    val value: ByteArray
)