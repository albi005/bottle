package hu.alb1.bottle

import android.Manifest
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.Build
import android.os.ParcelUuid
import androidx.annotation.RequiresPermission
import androidx.core.content.getSystemService

class BleScanner(val context: Context) {
    private var scanCount = 0
    private val bluetoothManager: BluetoothManager = context.getSystemService<BluetoothManager>()!!
    private val bluetoothAdapter = bluetoothManager.adapter
    private val bleScanner = bluetoothAdapter.bluetoothLeScanner

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

    private val scanSettings =
        ScanSettings.Builder()
            .setScanMode(
                if (Build.VERSION.SDK_INT_FULL >= Build.VERSION_CODES_FULL.BAKLAVA_1) {
                    ScanSettings.SCAN_TYPE_PASSIVE
                } else {
                    throw Exception()
                }
            )
            .build()

    private val scanCallback = object : ScanCallback() {
        @RequiresPermission(allOf = [Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT])
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            super.onScanResult(callbackType, result)

            val app = (context.applicationContext as BottleApplication)
            val vm = app.appViewModel
            vm.update(result)

            // Stop scanning once found to save battery
//            stopScanning()
        }

        override fun onScanFailed(errorCode: Int) {
            super.onScanFailed(errorCode)
            println("Scan failed with error: $errorCode")
        }

        override fun onBatchScanResults(results: List<ScanResult?>?) {
            super.onBatchScanResults(results)
        }
    }

    @Synchronized
    @RequiresPermission(Manifest.permission.BLUETOOTH_SCAN)
    fun startScanning() {
        if (bleScanner == null) {
            println("Bluetooth is disabled or not supported")
            return
        }

        if (scanCount == 0) {
            val filters = listOf(scanFilter)
            bleScanner.startScan(filters, scanSettings, scanCallback)
        }
        scanCount++
    }

    @Synchronized
    @RequiresPermission(Manifest.permission.BLUETOOTH_SCAN)
    fun stopScanning() {
        if (scanCount > 0) {
            scanCount--
            if (scanCount == 0) {
                bleScanner?.stopScan(scanCallback)
            }
        }
    }
}