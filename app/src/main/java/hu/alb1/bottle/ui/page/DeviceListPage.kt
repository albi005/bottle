@file:OptIn(ExperimentalTime::class, ExperimentalPagingApi::class)

package hu.alb1.bottle.ui.page

import android.annotation.SuppressLint
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SmallFloatingActionButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.paging.ExperimentalPagingApi
import androidx.paging.LoadState
import androidx.paging.Pager
import androidx.paging.PagingConfig
import androidx.paging.compose.collectAsLazyPagingItems
import hu.alb1.bottle.BluetoothProfileState
import hu.alb1.bottle.BottleApplication
import hu.alb1.bottle.DeviceViewModel
import hu.alb1.bottle.data.TofLogEntry
import hu.alb1.bottle.ui.icon.bluetooth_connected
import kotlinx.coroutines.launch
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import kotlinx.datetime.format
import kotlinx.datetime.format.char
import kotlinx.datetime.toLocalDateTime
import kotlin.math.pow
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@SuppressLint("MissingPermission")
@Composable
fun DeviceListPage(modifier: Modifier = Modifier) {
    val app = LocalContext.current.applicationContext as BottleApplication
    val devices = app.appViewModel.devices.values

    Box(modifier = modifier.padding(16.dp, 0.dp)) {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            for (device in devices) {
                key(device) {
                    DeviceCard(device)
                }
            }

            val scanState = app.bleScanner.scanningState.value
            Box(Modifier.fillMaxWidth().padding(32.dp)) {
                Text(scanState.toString(), Modifier.align(Alignment.Center))
            }
        }
    }
}

@Composable
fun DeviceCard(device: DeviceViewModel, modifier: Modifier = Modifier) {
    var expanded by remember { mutableStateOf(true) }

    Card(
        onClick = {},
        modifier.fillMaxWidth()
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                DevicePingMarker(device.latestPing.value, Modifier.size(24.dp))
                Text(device.name)
                Box(Modifier.size(24.dp)) {
                    when (device.bluetoothConnectionState.value) {
                        BluetoothProfileState.CONNECTING, BluetoothProfileState.DISCONNECTING ->
                            CircularProgressIndicator(
                                Modifier.padding(4.dp),
                                strokeWidth = 2.dp
                            )

                        BluetoothProfileState.DISCONNECTED -> {}
                        BluetoothProfileState.CONNECTED ->
                            Icon(bluetooth_connected, null)
                    }
                }
            }
            Text("MAC: " + device.address)
            Text("RSSI: " + device.rssi.toString())
            Text("Battery: ${device.batteryLevel.intValue}%")
            Text("Sync timestamp: ${Instant.fromEpochSeconds(device.timestamp.longValue).toLocalDateTime(TimeZone.currentSystemDefault())}")
            if (device.batteryLevelLoading.value) {
                CircularProgressIndicator(modifier = Modifier.width(64.dp))
            }

            Text(
                "ToF Logs ${if (expanded) "▲" else "▼"}",
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { expanded = !expanded },
                style = MaterialTheme.typography.labelLarge
            )

            AnimatedVisibility(visible = expanded) {
                TofLogList()
            }
        }
    }
}

@Composable
fun TofLogList() {
    val app = LocalContext.current.applicationContext as BottleApplication
    val dao = app.db.tofLogEntryDao()
    val pager = remember {
        Pager(PagingConfig(pageSize = 50)) {
            dao.getAllPaged()
        }
    }
    val lazyPagingItems = pager.flow.collectAsLazyPagingItems()
    val listState = rememberLazyListState()
    val coroutineScope = rememberCoroutineScope()
    var shouldAutoScrollToTop by rememberSaveable { mutableStateOf(true) }

    // Newest logs are at index 0. Keep this as a sticky state like chat: once the
    // user scrolls away, new logs should not pull them back until they return.
    val atTop by remember {
        derivedStateOf {
            listState.firstVisibleItemIndex == 0 && listState.firstVisibleItemScrollOffset == 0
        }
    }
    val newestItemId by remember {
        derivedStateOf {
            lazyPagingItems.itemSnapshotList.items.firstOrNull()?.id
        }
    }

    LaunchedEffect(listState.isScrollInProgress) {
        if (listState.lastScrolledForward && shouldAutoScrollToTop) {
            shouldAutoScrollToTop = false
        }
        if (!listState.isScrollInProgress && atTop && !shouldAutoScrollToTop) {
            shouldAutoScrollToTop = true
        }
    }

    LaunchedEffect(shouldAutoScrollToTop, newestItemId, lazyPagingItems.itemCount) {
        if (shouldAutoScrollToTop && newestItemId != null) {
            listState.scrollToItem(0)
        }
    }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(max = 600.dp)
    ) {
        LazyColumn(
            state = listState,
            modifier = Modifier.fillMaxWidth().heightIn(max = 600.dp)
        ) {
            items(count = lazyPagingItems.itemCount, key = { index -> lazyPagingItems[index]?.id ?: index }) { index ->
                lazyPagingItems[index]?.let { entry ->
                    TofLogItem(
                        entry = entry,
                        modifier = Modifier.animateItem(
                            fadeInSpec = tween(durationMillis = 220, easing = LinearOutSlowInEasing),
                            placementSpec = null,
                            fadeOutSpec = null
                        )
                    )
                }
            }

            when (val state = lazyPagingItems.loadState.append) {
                is LoadState.Loading -> {
                    item {
                        CircularProgressIndicator(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(8.dp),
                            strokeWidth = 2.dp
                        )
                    }
                }
                is LoadState.Error -> {
                    item {
                        Text(
                            "Error loading logs",
                            color = MaterialTheme.colorScheme.error,
                            modifier = Modifier.padding(8.dp)
                        )
                    }
                }
                else -> {}
            }
        }

        if (!atTop) {
            SmallFloatingActionButton(
                onClick = {
                    coroutineScope.launch {
                        shouldAutoScrollToTop = true
                        listState.animateScrollToItem(0)
                    }
                },
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(8.dp),
                containerColor = MaterialTheme.colorScheme.primaryContainer
            ) {
                Text("▲")
            }
        }
    }
}

val f = LocalDateTime.Format {
    year()
    char('.')
    monthNumber()
    char('.')
    day()
    chars(". ")

    hour()
    char(':')
    minute()
    char(':')
    second()
}

@Composable
fun TofLogItem(entry: TofLogEntry, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 2.dp)
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            Text(
                Instant.fromEpochSeconds(entry.timestamp).toLocalDateTime(TimeZone.currentSystemDefault()).format(f),
                style = MaterialTheme.typography.labelSmall
            )
            Text(
                "%.0f".format(tofToVolume1000ml(entry.distanceInMillimeter)) + " ml",
                style = MaterialTheme.typography.labelSmall
            )
            Text(
                "${entry.kcps} kcps",
                style = MaterialTheme.typography.labelSmall
            )
        }
//        Text(
//            "${entry.distanceInMillimeter}mm  kcps=${entry.kcps}  temp=${entry.uvLedTempInOhm}Ω  ${entry.triggerType.name}",
//            style = MaterialTheme.typography.bodySmall
//        )
    }
}

fun tofToVolume1000ml(distanceMm: Int): Double {
    val d = distanceMm.toDouble()
    return -1.1e-6 * d.pow(4) + 5.5211e-4 * d.pow(3) - 0.08516349 * d.pow(2) - 0.2839113 * d + 1026.71212239
}

@Composable
fun DevicePingMarker(
    latestPing: Instant?,
    modifier: Modifier = Modifier,
    pingColor: Color = MaterialTheme.colorScheme.tertiary
) {
    // 1f means finished/idle, 0f means just started
    val pingProgress = remember { Animatable(1f) }

    LaunchedEffect(latestPing) {
        if (latestPing != null) {
            // Snap back to 0 immediately when a new ping comes in
            pingProgress.snapTo(0f)
            // Animate to 1f over 1 second
            pingProgress.animateTo(
                targetValue = 1f,
                animationSpec = tween(durationMillis = 1000, easing = LinearOutSlowInEasing)
            )
        }
    }

    // Box to constrain the max size of the ping
    Canvas(modifier) {
        val progress = pingProgress.value

        drawCircle(
            color = pingColor,
            radius = 4.dp.toPx()
        )

        if (progress < 1f) {
            val minRadius = 4.dp.toPx()
            val maxRadius = size.width / 2f

            val currentRadius = minRadius + ((maxRadius - minRadius) * progress)
            val currentAlpha = 1f - progress
            val currentStrokeWidth = (1f - progress) * 3f

            drawCircle(
                color = pingColor.copy(alpha = currentAlpha),
                radius = currentRadius,
                style = Stroke(width = currentStrokeWidth.dp.toPx())
            )
        }
    }
}
