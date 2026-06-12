@file:OptIn(ExperimentalTime::class, ExperimentalAtomicApi::class)

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
import androidx.health.connect.client.records.HydrationRecord
import androidx.health.connect.client.records.metadata.Metadata
import com.squareup.wire.AnyMessage
import hu.alb1.bottle.proto.CapBleRequest
import hu.alb1.bottle.proto.CapBleResponse
import hu.alb1.bottle.proto.CapEnumLogQuerySearchAlgo
import hu.alb1.bottle.proto.CapLogQuery
import hu.alb1.bottle.proto.CapTofLog
import hu.alb1.bottle.proto.RequestGetCapTofLog
import hu.alb1.bottle.proto.ResponseGetCapTofLog
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.asExecutor
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.mapNotNull
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch
import kotlin.concurrent.atomics.ExperimentalAtomicApi
import kotlin.concurrent.atomics.fetchAndIncrement
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
        val connectionStateChangeChannel = Channel<ConnectionStateChangeMessage>(Channel.UNLIMITED)
        val servicesDiscoveredChannel = Channel<ServicesDiscoveredMessage>(Channel.UNLIMITED)
        val descriptorWriteChannel = Channel<DescriptorWriteMessage>(Channel.UNLIMITED)
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
                    CharacteristicChangedMessage(gatt, characteristic, value)
                )
            }

            override fun onCharacteristicRead(
                gatt: BluetoothGatt,
                characteristic: BluetoothGattCharacteristic,
                value: ByteArray,
                status: Int
            ) {
                super.onCharacteristicRead(gatt, characteristic, value, status)
                val gattStatus = GattStatus.fromRawValue(status)
                val msg = if (gattStatus == GattStatus.SUCCESS) {
                    CharacteristicReadMessage.Success(gatt, characteristic, value)
                } else {
                    CharacteristicReadMessage.Error(gatt, characteristic, gattStatus)
                }
                characteristicReadChannel.trySend(msg)
            }

            override fun onCharacteristicWrite(
                gatt: BluetoothGatt?,
                characteristic: BluetoothGattCharacteristic?,
                status: Int
            ) = super.onCharacteristicWrite(gatt, characteristic, status)

            @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
            override fun onConnectionStateChange(gatt: BluetoothGatt?, status: Int, newState: Int) {
                super.onConnectionStateChange(gatt, status, newState)
                val gattStatus = GattStatus.fromRawValue(status)
                val msg = if (gattStatus == GattStatus.SUCCESS && gatt != null) {
                    when (newState) {
                        BluetoothGatt.STATE_CONNECTED -> ConnectionStateChangeMessage.Connected(gatt)
                        BluetoothGatt.STATE_DISCONNECTED -> ConnectionStateChangeMessage.Disconnected(
                            gatt
                        )

                        else -> throw Exception()
                    }
                } else {
                    ConnectionStateChangeMessage.Error(gatt, gattStatus)
                }
                msg.let { connectionStateChangeChannel.trySend(it) }
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
            ) {
                super.onDescriptorWrite(gatt, descriptor, status)
                val gattStatus = GattStatus.fromRawValue(status)
                val msg =
                    if (gattStatus == GattStatus.SUCCESS && gatt != null && descriptor != null) {
                        DescriptorWriteMessage.Success(gatt, descriptor)
                    } else {
                        DescriptorWriteMessage.Error(gatt, descriptor, gattStatus)
                    }
                descriptorWriteChannel.trySend(msg)
            }

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
                val gattStatus = GattStatus.fromRawValue(status)
                val msg = if (gattStatus == GattStatus.SUCCESS && gatt != null) {
                    ServicesDiscoveredMessage.Success(gatt)
                } else {
                    ServicesDiscoveredMessage.Error(gatt, gattStatus)
                }
                servicesDiscoveredChannel.trySend(msg)
            }

            override fun onSubrateChange(gatt: BluetoothGatt, subrateMode: Int, status: Int) =
                super.onSubrateChange(gatt, subrateMode, status)
        }

        launch {
            val gatt = connectionStateChangeChannel
                .receiveAsFlow()
                .mapNotNull { msg ->
                    when (msg) {
                        is ConnectionStateChangeMessage.Connected -> {
                            bluetoothConnectionState.value = BluetoothProfileState.CONNECTED
                            msg.gatt
                        }

                        is ConnectionStateChangeMessage.Disconnected -> {
                            bluetoothConnectionState.value = BluetoothProfileState.DISCONNECTED
                            null
                        }

                        is ConnectionStateChangeMessage.Error -> {
                            bluetoothConnectionState.value = BluetoothProfileState.DISCONNECTED
                            throw Exception()
                        }
                    }
                }
                .first()

            gatt.discoverServices()

            servicesDiscoveredChannel.receive()
                .let { if (it is ServicesDiscoveredMessage.Error) throw Exception() }

            val gattWrapper = BottleGattWrapper(gatt)

            gatt.setCharacteristicNotification(
                gattWrapper.nordicUartService.txCharacteristic.characteristic,
                true
            )
            val txChar = gattWrapper.nordicUartService.txCharacteristic.characteristic
            val clientCharacteristicConfigDescriptor =
                txChar.getDescriptor(BleIdentifiers.CLIENT_CHARACTERISTIC_CONFIG_DESCRIPTOR)
            gatt.writeDescriptor(
                clientCharacteristicConfigDescriptor,
                BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
            )

            descriptorWriteChannel.receiveAsFlow()
                .filter { it is DescriptorWriteMessage.Success && it.descriptor == clientCharacteristicConfigDescriptor }
                .first()

//            gatt.writeCharacteristic(
//                gattWrapper.nordicUartService.rxCharacteristic.characteristic,
//                CapBleRequest(
//                    requestId = 0,
//                    body = AnyMessage.pack(RequestGetCapTofState())
//                ).encode(),
//                BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
//            )
//
//            characteristicChangedChannel.receive()
//                .let {
//                    val response = CapBleResponse.ADAPTER.decode(it.value)
//                    val tofState = response.body?.unpackOrNull(ResponseGetCapTofState.ADAPTER)
//                    println(response)
//                    println(tofState)
//                }

            val limit = 6
            gatt.writeCharacteristic(
                gattWrapper.nordicUartService.rxCharacteristic.characteristic,
                CapBleRequest(
                    requestId = requestIdCounter.fetchAndIncrement(),
                    body = AnyMessage.pack(
                        RequestGetCapTofLog(
                            CapLogQuery(
                                fromTimestamp = 0,
                                limit = limit,
                                algo = CapEnumLogQuerySearchAlgo.SEARCH_ALGO_TIMESTAMP
                            )
                        )
                    )
                ).encode(),
                BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
            )

            var timestamp: Long = 0
            characteristicChangedChannel.receiveAsFlow()
                .collect { characteristicChangedMessage ->
                    gatt.writeCharacteristic(
                        gattWrapper.nordicUartService.rxCharacteristic.characteristic,
                        CapBleRequest(
                            requestId = requestIdCounter.fetchAndIncrement(),
                            body = AnyMessage.pack(
                                RequestGetCapTofLog(
                                    CapLogQuery(
                                        fromTimestamp = timestamp,
                                        limit = limit,
                                        algo = CapEnumLogQuerySearchAlgo.SEARCH_ALGO_TIMESTAMP
                                    )
                                )
                            )
                        ).encode(),
                        BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
                    )

                    val response = CapBleResponse.ADAPTER.decode(characteristicChangedMessage.value)
                    val tofState = response.body!!.unpack(ResponseGetCapTofLog.ADAPTER)
                    data class WithTime(val time: Instant, val capTofLog: CapTofLog)
                    tofState.items.map { capTofLog -> WithTime(Instant.fromEpochSeconds(capTofLog.timestamp), capTofLog) }
                        .forEach { x -> println(x) }

                    val app = context.applicationContext as BottleApplication
                    HydrationRecord(
                        startTime = null,
                        endTime = null,
                        volume = null,
                        metadata = Metadata(
                            kind =
                        )
                    )

                    if (tofState.items.size < limit) cancel()
                    timestamp = tofState.items.maxOf { it.timestamp }
                }
        }

//        launch {
//            for (msg in characteristicReadChannel) {
//                if (msg is CharacteristicReadMessage.Success &&
//                    msg.characteristic == gattWrapper!!.batteryService.batteryLevelCharacteristic
//                ) {
//                    batteryLevelLoading.value = false
//                    batteryLevel.intValue = msg.value[0].toInt()
//                }
//            }
//        }

//        launch {
//            for (msg in characteristicChangedChannel) {
//                if (msg.characteristic == gattWrapper!!.nordicUartService.txCharacteristic.characteristic) {
//                    val response = CapBleResponse.ADAPTER.decode(msg.value)
//                    val tofState = response.body?.unpackOrNull(ResponseGetCapTofState.ADAPTER)
//                    println(response)
//                    println(tofState)
//                }
//            }
//        }

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

    private val requestIdCounter = kotlin.concurrent.atomics.AtomicInt(0)
}

sealed interface DescriptorWriteMessage {
    data class Success(val gatt: BluetoothGatt, val descriptor: BluetoothGattDescriptor) :
        DescriptorWriteMessage

    data class Error(
        val gatt: BluetoothGatt?,
        val descriptor: BluetoothGattDescriptor?,
        val status: GattStatus
    ) : DescriptorWriteMessage
}

sealed interface ConnectionStateChangeMessage {
    data class Connected(val gatt: BluetoothGatt) : ConnectionStateChangeMessage
    data class Disconnected(val gatt: BluetoothGatt?) : ConnectionStateChangeMessage
    data class Error(val gatt: BluetoothGatt?, val status: GattStatus) :
        ConnectionStateChangeMessage
}

sealed interface ServicesDiscoveredMessage {
    data class Success(val gatt: BluetoothGatt) : ServicesDiscoveredMessage
    data class Error(val gatt: BluetoothGatt?, val status: GattStatus) : ServicesDiscoveredMessage
}

sealed interface CharacteristicReadMessage {
    @Suppress("ArrayInDataClass")
    data class Success(
        val gatt: BluetoothGatt,
        val characteristic: BluetoothGattCharacteristic,
        val value: ByteArray
    ) : CharacteristicReadMessage

    data class Error(
        val gatt: BluetoothGatt,
        val characteristic: BluetoothGattCharacteristic,
        val status: GattStatus
    ) : CharacteristicReadMessage
}

@Suppress("ArrayInDataClass")
data class CharacteristicChangedMessage(
    val gatt: BluetoothGatt,
    val characteristic: BluetoothGattCharacteristic,
    val value: ByteArray
)