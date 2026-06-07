@file:OptIn(ExperimentalTime::class)

package hu.alb1.bottle.ui.page

import android.annotation.SuppressLint
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import hu.alb1.bottle.BottleApplication
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
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    DevicePingMarker(device.latestPing.value, Modifier.size(24.dp))
                    Text(device.name)
                    Text(device.address)
                    Text(device.rssi.toString())
                }
            }
        }
    }
}

@Composable
fun DevicePingMarker(
    latestPing: Instant?, // Replace with your actual date/time type
    modifier: Modifier = Modifier,
    pingColor: Color = Color(0xFF007AFF) // Classic bright blue
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
            val minRadius = 6.dp.toPx()
            val maxRadius = size.width / 2f

            val currentRadius = minRadius + ((maxRadius - minRadius) * progress)
            val currentAlpha = 1f - progress
            val currentStrokeWidth = (1f - progress) * 3f;

            drawCircle(
                color = pingColor.copy(alpha = currentAlpha),
                radius = currentRadius,
                style = Stroke(width = currentStrokeWidth.dp.toPx())
            )
        }
    }
}