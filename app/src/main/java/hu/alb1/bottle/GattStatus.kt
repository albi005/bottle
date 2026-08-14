package hu.alb1.bottle

import android.bluetooth.BluetoothGatt

enum class GattStatus(val rawValue: Int) {
    SUCCESS(BluetoothGatt.GATT_SUCCESS),
    READ_NOT_PERMITTED(BluetoothGatt.GATT_READ_NOT_PERMITTED),
    WRITE_NOT_PERMITTED(BluetoothGatt.GATT_WRITE_NOT_PERMITTED),
    INSUFFICIENT_AUTHENTICATION(BluetoothGatt.GATT_INSUFFICIENT_AUTHENTICATION),
    REQUEST_NOT_SUPPORTED(BluetoothGatt.GATT_REQUEST_NOT_SUPPORTED),
    INVALID_OFFSET(BluetoothGatt.GATT_INVALID_OFFSET),
    INSUFFICIENT_AUTHORIZATION(BluetoothGatt.GATT_INSUFFICIENT_AUTHORIZATION),
    INVALID_ATTRIBUTE_LENGTH(BluetoothGatt.GATT_INVALID_ATTRIBUTE_LENGTH),
    INSUFFICIENT_ENCRYPTION(BluetoothGatt.GATT_INSUFFICIENT_ENCRYPTION),
    CONNECTION_CONGESTED(BluetoothGatt.GATT_CONNECTION_CONGESTED),
    FAILURE(BluetoothGatt.GATT_FAILURE);

    companion object {
        fun fromRawValue(rawValue: Int): GattStatus {
            return entries.find { it.rawValue == rawValue } ?: FAILURE
        }
    }
}
