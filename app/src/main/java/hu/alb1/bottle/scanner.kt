package hu.alb1.bottle

import android.Manifest
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.os.ParcelUuid
import androidx.annotation.RequiresPermission
import androidx.core.app.ActivityCompat

class BleScanner(context: Context) {

    private val bluetoothManager: BluetoothManager = context.getSystemService(BluetoothManager::class.java)
    private val bluetoothAdapter = bluetoothManager.adapter
    private val bleScanner = bluetoothAdapter.bluetoothLeScanner

    // Define what we are looking for based on your device's payload
    private val scanFilter = ScanFilter.Builder()
        // Manufacturer Data (Company 0x0059, Data 0x434150)
        // 0x43, 0x41, 0x50 equates to ASCII "C", "A", "P"
        .setManufacturerData(
            0x0059,
            byteArrayOf(0x43, 0x41, 0x50)
        )

        // Service UUID (180A needs to be expanded to the 128-bit base UUID)
        .setServiceUuid(ParcelUuid.fromString("0000180a-0000-1000-8000-00805f9b34fb"))

        .build()

    // Use low latency for foreground scanning to find it quickly
    private val scanSettings = ScanSettings.Builder()
//        .setScanMode(ScanSettings.SCAN_MODE_LOW_POWER)
        .build()

    // The callback that gets triggered when the device is found
    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            super.onScanResult(callbackType, result)

            val device = result.device
            val deviceName = device.name ?: "Unknown"
            val macAddress = device.address
            val rssi = result.rssi

            println("Found the bad boy! Name: $deviceName, MAC: $macAddress, Signal: $rssi dBm")

            // device.connectGatt(context, false, yourGattCallback)

            // Stop scanning once found to save battery
            if (ActivityCompat.checkSelfPermission(
                    this,
                    Manifest.permission.BLUETOOTH_SCAN
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                return
            }
            stopScanning()
        }

        override fun onScanFailed(errorCode: Int) {
            super.onScanFailed(errorCode)
            println("Scan failed with error: $errorCode")
        }
    }

    // Call this after you have checked runtime permissions
    @RequiresPermission(Manifest.permission.BLUETOOTH_SCAN)
    fun startScanning() {
        if (bleScanner == null) {
            println("Bluetooth is disabled or not supported")
            return
        }

        val filters = listOf(scanFilter)

        bleScanner.startScan(filters, scanSettings, scanCallback)
        println("Scanning started...")
    }

    @RequiresPermission(Manifest.permission.BLUETOOTH_SCAN)
    fun stopScanning() {
        bleScanner?.stopScan(scanCallback)
        println("Scanning stopped.")
    }
}