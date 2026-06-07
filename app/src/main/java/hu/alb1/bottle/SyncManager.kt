package hu.alb1.bottle

import android.content.Context
import androidx.compose.runtime.mutableStateMapOf
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.time.Duration.Companion.seconds

class SyncManager(
    private val context: Context,
    private val applicationScope: CoroutineScope
) {
    private val mutex = Mutex()
    private val activeSyncs = mutableStateMapOf<String, Deferred<Unit>>()

    /**
     * Starts or joins an existing sync for the given device.
     * This function returns when the sync is complete.
     */
    suspend fun sync(deviceAddress: String) {
        val deferred = mutex.withLock {
            activeSyncs.getOrPut(deviceAddress) {
                applicationScope.async {
                    try {
                        runSyncLoop(deviceAddress)
                    } finally {
                        mutex.withLock {
                            activeSyncs.remove(deviceAddress)
                        }
                    }
                }
            }
        }
        deferred.await()
    }

    private suspend fun runSyncLoop(address: String) {
        // TODO: Replace with actual BLE connection and data transfer logic
        println("Starting sync for $address")
        
        // Simulating work
        for (i in 1..10) {
            println("Syncing $address: $i/10")
            delay(2.seconds)
        }
        
        println("Sync finished for $address")
    }
}
