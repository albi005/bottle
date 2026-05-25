package com.example.bottle

import android.content.Intent
import androidx.annotation.NonNull
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.HydrationRecord
import androidx.health.connect.client.records.metadata.Metadata
import androidx.health.connect.client.records.metadata.Device
import androidx.health.connect.client.units.Volume
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import java.time.Instant
import java.time.ZoneOffset

class HealthConnectPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var healthConnectClient: HealthConnectClient? = null
    private var appContext: android.content.Context? = null
    private val scope = CoroutineScope(Dispatchers.Main)

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        appContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "bottle/health_connect")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        healthConnectClient = null
        appContext = null
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> result.success(getClient() != null)
            "hasPermissions" -> checkPermissions(result)
            "requestPermissions" -> requestPermissions(result)
            "openSettings" -> openSettings(result)
            "writeHydration" -> writeHydrationRecords(call, result)
            else -> result.notImplemented()
        }
    }

    private fun getClient(): HealthConnectClient? {
        if (healthConnectClient != null) return healthConnectClient
        val ctx = appContext ?: return null
        val status = HealthConnectClient.getSdkStatus(ctx)
        if (status != HealthConnectClient.SDK_AVAILABLE) return null
        healthConnectClient = HealthConnectClient.getOrCreate(ctx)
        return healthConnectClient
    }

    private fun checkPermissions(result: MethodChannel.Result) {
        val client = getClient()
        if (client == null) { result.success(false); return }
        val perms = runBlocking {
            client.permissionController.getGrantedPermissions()
        }
        val writePerm = HealthPermission.getWritePermission(HydrationRecord::class)
        result.success(perms.contains(writePerm))
    }

    private fun requestPermissions(result: MethodChannel.Result) {
        val ctx = appContext ?: return
        ctx.startActivity(Intent(
            HealthConnectClient.ACTION_HEALTH_CONNECT_SETTINGS).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        })
        result.success(false)
    }

    private fun openSettings(result: MethodChannel.Result?) {
        val ctx = appContext ?: return
        ctx.startActivity(Intent(
            HealthConnectClient.ACTION_HEALTH_CONNECT_SETTINGS).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        })
        result?.success(true)
    }

    private fun writeHydrationRecords(call: MethodCall, result: MethodChannel.Result) {
        val client = getClient() ?: run {
            result.error("UNAVAILABLE", "Health Connect not available", null)
            return
        }
        val records = call.argument<List<Map<String, Any>>>("records") ?: run {
            result.success(null)
            return
        }
        val hydrationRecords = records.mapNotNull { r ->
            val startTime = Instant.parse(r["startTime"] as String)
            val endTime = Instant.parse(r["endTime"] as String)
            val volumeMl = (r["volumeMl"] as Double)

            HydrationRecord(
                startTime = startTime,
                startZoneOffset = ZoneOffset.UTC,
                endTime = endTime,
                endZoneOffset = ZoneOffset.UTC,
                volume = Volume.milliliters(volumeMl),
                metadata = Metadata.autoRecorded(Device(type = Device.TYPE_UNKNOWN)),
            )
        }
        if (hydrationRecords.isEmpty()) { result.success(null); return }
        scope.launch {
            try {
                client.insertRecords(hydrationRecords)
                result.success(null)
            } catch (e: Exception) {
                result.error("WRITE_FAILED", e.message, null)
            }
        }
    }
}
