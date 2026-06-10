@file:OptIn(ExperimentalAtomicApi::class)

package hu.alb1.bottle

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.Build
import android.os.ParcelUuid
import androidx.annotation.RequiresPermission
import androidx.compose.runtime.mutableStateOf
import androidx.core.content.getSystemService
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import kotlin.concurrent.atomics.AtomicInt
import kotlin.concurrent.atomics.ExperimentalAtomicApi
import kotlin.concurrent.atomics.decrementAndFetch
import kotlin.concurrent.atomics.incrementAndFetch
import kotlin.time.Duration.Companion.seconds

class BleScanner(val context: Context) {
    private val bluetoothManager: BluetoothManager = context.getSystemService<BluetoothManager>()!!
    private val bluetoothAdapter = bluetoothManager.adapter
    private val bleScanner = bluetoothAdapter.bluetoothLeScanner
    private val app = context.applicationContext as BottleApplication

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

    private val foregroundScanRequestCounter = AtomicInt(0)
    private val backgroundScanRequestCounter = AtomicInt(0)
    val scanningState = mutableStateOf<ScanningState>(ScanningState.NotScanning)

    private val reconciliationRequestChannel = Channel<Unit>(capacity = 1)

    suspend fun ensureScanning(scanningVersion: ScanningVersion) {
        val counter = when (scanningVersion) {
            ScanningVersion.Foreground -> foregroundScanRequestCounter
            ScanningVersion.Background -> backgroundScanRequestCounter
        }
        try {
            counter.incrementAndFetch()
            reconciliationRequestChannel.trySend(Unit)
            awaitCancellation()
        } finally {
            counter.decrementAndFetch()
            reconciliationRequestChannel.trySend(Unit)
        }
    }

    fun requestRescan() {
        reconciliationRequestChannel.trySend(Unit)
    }

    init {
        app.applicationScope.launch { run() }
    }

    private suspend fun run(): Nothing {
        var scanningJob: Job? = null

        @SuppressLint("MissingPermission")
        @RequiresPermission(allOf = [Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT])
        fun reconcile(desiredState: ScanningState) {
            if (desiredState == ScanningState.Errored || desiredState == ScanningState.FinishedScanning)
                throw Exception() // why would you desire these

            // already in the desired state
            if (desiredState == scanningState.value) return

            // stop if needed
            when (scanningState.value) {
                is ScanningState.Scanning -> {
                    scanningJob?.cancel()
                }

                ScanningState.Errored -> return // idk
                ScanningState.NotScanning, ScanningState.FinishedScanning -> {}
            }

            // start if needed
            when (desiredState) {
                is ScanningState.Scanning -> {
                    scanningJob = app.applicationScope.launch {
                        try {
                            scanningState.value = desiredState
                            runScanForAWhile(desiredState.version)
                        } catch (exception: Exception) {
                            if (exception is CancellationException)
                                scanningState.value = ScanningState.NotScanning
                            else
                                scanningState.value = ScanningState.Errored
                            throw exception
                        }
                    }
                }

                ScanningState.NotScanning -> return
                else -> throw Exception()
            }
        }

        while (true) {
            reconciliationRequestChannel.receive()

            val desiredState = getDesiredScanningState(
                foregroundScanRequestCounter.load(),
                backgroundScanRequestCounter.load()
            )
            reconcile(desiredState)
        }

    }

    private fun getDesiredScanningState(uiCount: Int, workerCount: Int): ScanningState {
        if (uiCount > 0) return ScanningState.Scanning(ScanningVersion.Foreground)
        if (workerCount > 0) return ScanningState.Scanning(ScanningVersion.Background)
        return ScanningState.NotScanning
    }

    @RequiresPermission(allOf = [Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT])
    private suspend fun runScanForAWhile(scanVersion: ScanningVersion) {
        val app = context.applicationContext as BottleApplication
        val appViewModel = app.appViewModel

        when (scanVersion) {
            ScanningVersion.Foreground -> {
                withTimeout(30.seconds) {
                    scanAndFlowResults(lowLatencyScanSettings).collect {
                        appViewModel.update(it)
                    }
                }
            }

            ScanningVersion.Background -> {
                withTimeout(30.seconds) {
                    scanAndFlowResults(passiveScanSettings).collect {
                        appViewModel.update(it)
                    }
                }

                if (appViewModel.devices.any())
                    return

                withTimeout(20.seconds) {
                    scanAndFlowResults(activeBackgroundScanSettings).collect {
                        appViewModel.update(it)
                    }
                }
            }
        }

        scanningState.value = ScanningState.FinishedScanning
    }

    @RequiresPermission(Manifest.permission.BLUETOOTH_SCAN)
    private fun scanAndFlowResults(scanSettings: ScanSettings) = callbackFlow {
        bleScanner.startScan(
            scanFilters,
            scanSettings,
            object : ScanCallback() {
                override fun onScanFailed(errorCode: Int) {
                    cancel("Scan failed: ${ScanFailure.fromErrorCode(errorCode)}")
                }

                override fun onScanResult(callbackType: Int, result: ScanResult?) {
                    if (result == null) return
                    trySend(result)
                }

                override fun onBatchScanResults(results: List<ScanResult?>?) {
                }
            }
        )

        awaitClose { bleScanner.stopScan(object : ScanCallback() {}) }
    }

}

enum class ScanningVersion {
    Foreground,
    Background,
}

sealed interface ScanningState {
    data class Scanning(val version: ScanningVersion) : ScanningState

    data object FinishedScanning : ScanningState
    data object NotScanning : ScanningState
    data object Errored : ScanningState
}