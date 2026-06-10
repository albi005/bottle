package hu.alb1.bottle

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import kotlinx.coroutines.withTimeout
import kotlin.time.Duration.Companion.seconds

class SyncWorker(val appContext: Context, workerParams: WorkerParameters) :
    CoroutineWorker(appContext, workerParams) {
    override suspend fun doWork(): Result {
        return Result.success()

        if (ActivityCompat.checkSelfPermission(
                appContext,
                Manifest.permission.BLUETOOTH_SCAN
            ) != PackageManager.PERMISSION_GRANTED
            ||
            ActivityCompat.checkSelfPermission(
                appContext,
                Manifest.permission.BLUETOOTH_CONNECT
            ) != PackageManager.PERMISSION_GRANTED
        )
            return Result.failure()

        val bleScanner = (appContext as BottleApplication).bleScanner

        withTimeout(60.seconds){
            bleScanner.ensureScanning(ScanningVersion.Background)
        }

        return Result.success()
    }
}