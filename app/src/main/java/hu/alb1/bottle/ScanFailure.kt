package hu.alb1.bottle

import android.bluetooth.le.ScanCallback

/** A Kotlin wrapper for [android.bluetooth.le.ScanCallback] SCAN_FAILED_* error codes. */
enum class ScanFailure(val errorCode: Int) {
    /** Fails to start scan as BLE scan with the same settings is already started by the app. */
    ALREADY_STARTED(ScanCallback.SCAN_FAILED_ALREADY_STARTED),

    /** Fails to start scan as app cannot be registered. */
    APPLICATION_REGISTRATION_FAILED(ScanCallback.SCAN_FAILED_APPLICATION_REGISTRATION_FAILED),

    /** Fails to start scan due an internal error. */
    INTERNAL_ERROR(ScanCallback.SCAN_FAILED_INTERNAL_ERROR),

    /** Fails to start power optimized scan as this feature is not supported. */
    FEATURE_UNSUPPORTED(ScanCallback.SCAN_FAILED_FEATURE_UNSUPPORTED),

    /** Fails to start scan as it is out of hardware resources. */
    OUT_OF_HARDWARE_RESOURCES(ScanCallback.SCAN_FAILED_OUT_OF_HARDWARE_RESOURCES),

    /** Fails to start scan as application tries to scan too frequently. */
    SCANNING_TOO_FREQUENTLY(ScanCallback.SCAN_FAILED_SCANNING_TOO_FREQUENTLY),

    /** Fallback for any future error codes added to the Android SDK. */
    UNKNOWN(-1);

    companion object {
        /** Maps the integer error code from [ScanCallback.onScanFailed] to the [ScanFailure] enum. */
        fun fromErrorCode(errorCode: Int): ScanFailure {
            // Note: Use 'values().find' instead of 'entries.find' if you are on a Kotlin version older than 1.9.0
            return entries.find { it.errorCode == errorCode } ?: UNKNOWN
        }
    }
}