@file:OptIn(ExperimentalAtomicApi::class)

package hu.alb1.bottle

import android.annotation.SuppressLint
import kotlinx.coroutines.Job
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlin.concurrent.atomics.AtomicInt
import kotlin.concurrent.atomics.ExperimentalAtomicApi
import kotlin.concurrent.atomics.decrementAndFetch
import kotlin.concurrent.atomics.incrementAndFetch

class SyncService(val appViewModel: AppViewModel, val bleScanner: BleScanner) {
    suspend fun loop() = coroutineScope {
        var syncJob: Job? = null

        while (true) {
            reconciliationRequests.receive()
            val uiCount = uiOwnerCount.load()
            val workerCount = workerOwnerCount.load()
            val haveOwners = uiCount > 0 || workerCount > 0

            if (haveOwners && syncJob == null) {
                syncJob = launch { sync() }
            }

            if (!haveOwners && syncJob != null) {
                syncJob.cancel()
                syncJob = null
            }

            bleScanner.update(uiCount, workerCount)
        }
    }

    @SuppressLint("MissingPermission")
    suspend fun sync(): Nothing = coroutineScope {
        launch {
            bleScanner.loop().collect {
                appViewModel.update(it)
            }
        }

        try {
            awaitCancellation()
        } finally {
            appViewModel.devices.clear()
        }
    }

    private val uiOwnerCount = AtomicInt(0)
    private val workerOwnerCount = AtomicInt(0)
    private val reconciliationRequests = Channel<Unit>(1)

    suspend fun registerOwner(syncOwnerKind: SyncOwnerKind): Nothing = coroutineScope {
        val counter = when (syncOwnerKind) {
            SyncOwnerKind.Ui -> uiOwnerCount
            SyncOwnerKind.Worker -> workerOwnerCount
        }

        try {
            counter.incrementAndFetch()
            reconciliationRequests.trySend(Unit)
            awaitCancellation()
        } finally {
            counter.decrementAndFetch()
            reconciliationRequests.trySend(Unit)
        }
    }
}

enum class SyncOwnerKind {
    Ui,
    Worker,
}