package hu.alb1.bottle

import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattService
import java.util.UUID

class BottleGattWrapper(bluetoothGatt: BluetoothGatt) {
    val batteryService = BatteryService()
    val nordicUartService = NordicUartService()

    init {
        val servicesById = bluetoothGatt.services.associateBy { it.uuid }
        val serviceList = listOf(batteryService, nordicUartService)
        for (service in serviceList) {
            service.init(
                servicesById.getValue(service.uuid)
            )
        }
    }
}

class BatteryService : ServiceWrapper() {
    val batteryLevelCharacteristic = CharacteristicWrapper(BleIdentifiers.BATTERY_LEVEL_CHAR)
    override val uuid = BleIdentifiers.BATTERY_SERVICE
    override val characteristics = listOf(batteryLevelCharacteristic)
}

class NordicUartService : ServiceWrapper() {
    val rxCharacteristic = CharacteristicWrapper(BleIdentifiers.UART_RX_CHAR)
    val txCharacteristic = CharacteristicWrapper(BleIdentifiers.UART_TX_CHAR)
    override val uuid: UUID = BleIdentifiers.NORDIC_UART_SERVICE
    override val characteristics = listOf(rxCharacteristic, txCharacteristic)
}

abstract class ServiceWrapper {
    lateinit var bluetoothGattService: BluetoothGattService

    fun init(bluetoothGattService: BluetoothGattService) {
        this.bluetoothGattService = bluetoothGattService
        val characteristicsByUuid = bluetoothGattService.characteristics.associateBy { it.uuid }
        for (wrapper in characteristics) {
            wrapper.init(characteristicsByUuid.getValue(wrapper.uuid))
        }
    }

    abstract val uuid: UUID
    protected abstract val characteristics: List<CharacteristicWrapper>
}

class CharacteristicWrapper(val uuid: UUID) {
    lateinit var characteristic: BluetoothGattCharacteristic

    fun init(bluetoothGattCharacteristic: BluetoothGattCharacteristic) {
        this.characteristic = bluetoothGattCharacteristic
    }
}

