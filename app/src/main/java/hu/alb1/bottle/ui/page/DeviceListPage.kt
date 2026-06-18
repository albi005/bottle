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
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.paging.ExperimentalPagingApi
import androidx.paging.Pager
import androidx.paging.PagingConfig
import androidx.paging.LoadState
import androidx.paging.compose.collectAsLazyPagingItems
import hu.alb1.bottle.BluetoothProfileState
import hu.alb1.bottle.BottleApplication
import hu.alb1.bottle.DeviceViewModel
import hu.alb1.bottle.ScanningState
import hu.alb1.bottle.data.TofLogEntry
import hu.alb1.bottle.ui.icon.bluetooth_connected
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
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
                when (scanState) {
                    is ScanningState.Scanning -> {
                        CircularProgressIndicator(
                            Modifier.align(Alignment.Center)
                        )
                    }
                    ScanningState.Errored -> Text("Errored")
                    else -> {}
                }
            }
        }
    }
}

@Composable
fun DeviceCard(device: DeviceViewModel, modifier: Modifier = Modifier) {
    var expanded by remember { mutableStateOf(false) }

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
                ToFLogList()
            }
        }
    }
}

@Composable
fun ToFLogList() {
    val app = LocalContext.current.applicationContext as BottleApplication
    val dao = app.db.tofLogEntryDao()
    val pager = remember {
        Pager(PagingConfig(pageSize = 20)) {
            dao.getAllPaged()
        }
    }
    val lazyPagingItems = pager.flow.collectAsLazyPagingItems()

    LazyColumn(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(max = 300.dp)
    ) {
        items(count = lazyPagingItems.itemCount) { index ->
            lazyPagingItems[index]?.let { entry ->
                ToFLogItem(entry)
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
}

@Composable
fun ToFLogItem(entry: TofLogEntry, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 2.dp)
    ) {
        Text(
            "${Instant.fromEpochSeconds(entry.timestamp).toLocalDateTime(TimeZone.currentSystemDefault())}",
            style = MaterialTheme.typography.bodySmall
        )
        Text(
            "${entry.distanceInMillimeter}mm  kcps=${entry.kcps}  temp=${entry.uvLedTempInOhm}Ω  ${entry.triggerType.name}",
            style = MaterialTheme.typography.bodySmall
        )
    }
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
