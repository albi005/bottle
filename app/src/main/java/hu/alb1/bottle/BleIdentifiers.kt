package hu.alb1.bottle

import java.util.UUID

object BleIdentifiers {
    /**
     * Helper to create a full 128-bit UUID from a 16-bit standard Bluetooth alias.
     * Bluetooth Base UUID: 0000xxxx-0000-1000-8000-00805F9B34FB
     */
    private fun standardUuid(shortId: String): UUID {
        return UUID.fromString("0000$shortId-0000-1000-8000-00805f9b34fb")
    }

    // Generic Access Service
    val GENERIC_ACCESS_SERVICE = standardUuid("1800")
    val DEVICE_NAME_CHAR = standardUuid("2A00")
    val APPEARANCE_CHAR = standardUuid("2A01")
    val PERIPHERAL_PREFERRED_PARAMS_CHAR = standardUuid("2A04")
    val CENTRAL_ADDRESS_RESOLUTION_CHAR = standardUuid("2AA6")

    // Generic Attribute Service
    val GENERIC_ATTRIBUTE_SERVICE = standardUuid("1801")

    // Device Information Service
    val DEVICE_INFORMATION_SERVICE = standardUuid("180A")
    val MANUFACTURER_NAME_CHAR = standardUuid("2A29")
    val MODEL_NUMBER_CHAR = standardUuid("2A24")
    val SERIAL_NUMBER_CHAR = standardUuid("2A25")
    val HARDWARE_REVISION_CHAR = standardUuid("2A27")
    val FIRMWARE_REVISION_CHAR = standardUuid("2A26")
    val SOFTWARE_REVISION_CHAR = standardUuid("2A28")

    // Battery Service
    val BATTERY_SERVICE = standardUuid("180F")
    val BATTERY_LEVEL_CHAR = standardUuid("2A19")

    // Nordic UART Service (Custom Vendor UUIDs)
    val NORDIC_UART_SERVICE = UUID.fromString("6e400001-b5a3-f393-e0a9-e50e24dcca9e")
    val UART_RX_CHAR = UUID.fromString("6e400002-b5a3-f393-e0a9-e50e24dcca9e")
    val UART_TX_CHAR = UUID.fromString("6e400003-b5a3-f393-e0a9-e50e24dcca9e")

    // Secure DFU (Nordic)
    val SECURE_DFU_SERVICE = standardUuid("FE59")
    val BUTTONLESS_DFU_WITHOUT_BONDS_CHAR = UUID.fromString("8ec90003-f315-4f60-9fb8-838830daea50")

    // Common Descriptors
    val CLIENT_CHARACTERISTIC_CONFIG_DESCRIPTOR = standardUuid("2902")
}