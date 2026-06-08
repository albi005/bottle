package hu.alb1.bottle

enum class BluetoothProfileState(val rawValue: Int) {
    DISCONNECTED(0),
    CONNECTING(1),
    CONNECTED(2),
    DISCONNECTING(3),
    UNKNOWN(-1);

    companion object {
        private val map = entries.associateBy { it.rawValue }
        fun fromRawValue(value: Int) = map[value] ?: UNKNOWN
    }
}