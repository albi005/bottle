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
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.snapshotFlow
import androidx.core.content.getSystemService
import com.google.protobuf.enum
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.channelFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.conflate
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

class BleScanner(val context: Context) {
    private val bluetoothManager: BluetoothManager = context.getSystemService<BluetoothManager>()!!
    private val bluetoothAdapter = bluetoothManager.adapter
    private val bleScanner = bluetoothAdapter.bluetoothLeScanner

    private val scanFilters = listOf(
        ScanFilter.Builder()
            // Manufacturer Data (Company 0x0059, Data 0x434150)
            // 0x43, 0x41, 0x50 equates to ASCII "C", "A", "P"
            .setManufacturerData(
                0x0059,
                byteArrayOf(0x43, 0x41, 0x50)
            )
            // Service UUID (180A needs to be expanded to the 128-bit base UUID)
            .setServiceUuid(ParcelUuid.fromString("0000180a-0000-1000-8000-00805f9b34fb"))
            .build()
    )

    private val passiveScanSettings =
        if (Build.VERSION.SDK_INT_FULL >= Build.VERSION_CODES_FULL.BAKLAVA_1) {
            ScanSettings.Builder()
                .setScanType(ScanSettings.SCAN_TYPE_PASSIVE)
                .setScanMode(ScanSettings.SCAN_MODE_LOW_POWER)
                .build()
        } else {
            throw Exception()
        }
    private val lowLatencyScanSettings = ScanSettings.Builder()
        .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
        .build()
    private val activeBackgroundScanSettings = ScanSettings.Builder()
        .setScanMode(ScanSettings.SCAN_MODE_LOW_POWER)
        .build()

    @RequiresPermission(allOf = [Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT])
    private suspend fun scan(isBackground: Boolean) {
        if (isBackground) {
            try {
                suspendCancellableCoroutine {
                    bleScanner.startScan(
                        scanFilters,
                        passiveScanSettings,
                        object : ScanCallback() {
                            override fun onScanFailed(errorCode: Int) {
                                it.resumeWithException(Exception())
                            }

                            override fun onScanResult(callbackType: Int, result: ScanResult?) {
                                it.resumeWith(Result.success(result))
                            }
                        }
                    )
                }


                // TODO: Use a single ScanCallback and have it put its stuff in Channels
                // then await a
                MutableSharedFlow<Int>()

            } finally {
                bleScanner.stopScan(scanCallback)
            }
        }
    }

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

    val uiCount = MutableStateFlow(0)
    val workerCount = MutableStateFlow(0)
    val scanningState = mutableStateOf(ScanningState.NOT_SCANNING)

    enum class ScanningState {
        BACKGROUND_SCANNING,
        FOREGROUND_SCANNING,
        NOT_SCANNING,
        ERRORED
    }

    private suspend fun run(): Nothing {
        val desiredState = getDesiredScanningState(uiCount.value, workerCount.value)
        if (scanningState.value != desiredState) {

        }

        val desiredStateFlow = uiCount.combine(workerCount) { uiCount, workerCount ->
            getDesiredScanningState(uiCount, workerCount)
        }.distinctUntilChanged()

        desiredStateFlow.firstOrNull()
    }

    @RequiresPermission(Manifest.permission.BLUETOOTH_SCAN)
    private fun reconcile(desiredState: ScanningState) {
        if (desiredState == ScanningState.ERRORED) throw Exception()

        if (desiredState == scanningState.value) return

        when (scanningState.value) {
            ScanningState.ERRORED -> return
            ScanningState.NOT_SCANNING -> {}
            ScanningState.BACKGROUND_SCANNING, ScanningState.FOREGROUND_SCANNING ->
                bleScanner.stopScan(scanCallback)
        }

        when (scanningState.value) {
            ScanningState.BACKGROUND_SCANNING ->

        }
    }

    private fun getDesiredScanningState(uiCount: Int, workerCount: Int): ScanningState {
        if (uiCount > 0) return ScanningState.FOREGROUND_SCANNING
        if (workerCount > 0) return ScanningState.BACKGROUND_SCANNING
        return ScanningState.NOT_SCANNING
    }

    @RequiresPermission(Manifest.permission.BLUETOOTH_SCAN)
    fun startScanning(isUi: Boolean) {
        if (isUi)
            synchronized(uiCount) { uiCount.value++ }
        else
            synchronized(workerCount) { workerCount.value++ }
    }

    @RequiresPermission(Manifest.permission.BLUETOOTH_SCAN)
    fun stopScanning(isUi: Boolean) {
        if (isUi)
            synchronized(uiCount) { uiCount.value-- }
        else
            synchronized(workerCount) { workerCount.value-- }
    }
}