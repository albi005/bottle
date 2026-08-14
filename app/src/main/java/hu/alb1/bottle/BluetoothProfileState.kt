package hu.alb1.bottle

import android.bluetooth.BluetoothProfile

enum class BluetoothProfileState(val rawValue: Int) {
    DISCONNECTED(BluetoothProfile.STATE_DISCONNECTED),
    CONNECTING(BluetoothProfile.STATE_CONNECTING),
    CONNECTED(BluetoothProfile.STATE_CONNECTED),
    DISCONNECTING(BluetoothProfile.STATE_DISCONNECTING);

    companion object {
        private val map = entries.associateBy { it.rawValue }
        fun fromRawValue(value: Int) = map[value] ?: DISCONNECTED
    }
}
