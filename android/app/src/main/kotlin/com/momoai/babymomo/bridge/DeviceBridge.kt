package com.momoai.babymomo.bridge

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.PowerManager
import android.os.StatFs
import com.momoai.babymomo.pigeon.device.DeviceHostApi
import com.momoai.babymomo.pigeon.device.NativeBatteryState
import com.momoai.babymomo.pigeon.device.NativeDeviceProfile
import java.io.File

class DeviceBridge(private val context: Context, private val messenger: io.flutter.plugin.common.BinaryMessenger) : DeviceHostApi {

    private val flutterApi = com.momoai.babymomo.pigeon.device.DeviceFlutterApi(messenger)

    init {
        // Register BroadcastReceiver for battery updates
        val batteryFilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        context.registerReceiver(object : android.content.BroadcastReceiver() {
            override fun onReceive(ctx: Context?, intent: Intent?) {
                intent?.let {
                    val current = it.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                    val scale = it.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                    val level = if (current >= 0 && scale > 0) current.toDouble() / scale.toDouble() else 0.85
                    
                    val status = it.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
                    val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                            status == BatteryManager.BATTERY_STATUS_FULL
                            
                    // Send to Flutter
                    flutterApi.onBatteryStateChanged(level, isCharging) { _ -> }
                }
            }
        }, batteryFilter)

        // Register Thermal Status Listener if API 29+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            
            // Send initial thermal state
            try {
                flutterApi.onThermalStateChanged(powerManager.currentThermalStatus.toLong()) { _ -> }
            } catch (e: Exception) {}
            
            try {
                powerManager.addThermalStatusListener { status ->
                    flutterApi.onThermalStateChanged(status.toLong()) { _ -> }
                }
            } catch (e: Exception) {}
        }
    }

    override fun getDeviceProfile(callback: (Result<NativeDeviceProfile>) -> Unit) {
        try {
            val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val memoryInfo = ActivityManager.MemoryInfo()
            activityManager.getMemoryInfo(memoryInfo)

            val totalRamMB = memoryInfo.totalMem / (1024 * 1024)
            val availableRamMB = memoryInfo.availMem / (1024 * 1024)

            // Dynamic core parsing
            val cpuCores = Runtime.getRuntime().availableProcessors().toLong()
            val cpuArch = Build.SUPPORTED_ABIS.firstOrNull() ?: System.getProperty("os.arch") ?: "unknown"

            // Check Vulkan capability
            val hasVulkan = context.packageManager.hasSystemFeature("android.hardware.vulkan.version")

            val profile = NativeDeviceProfile(
                totalRamMB = totalRamMB,
                availableRamMB = availableRamMB,
                gpuName = "Android Adreno/Mali Custom Vulkan Core",
                vulkanSupported = hasVulkan,
                cpuCores = cpuCores,
                cpuArchitecture = cpuArch,
                sdkVersion = Build.VERSION.SDK_INT.toLong(),
                deviceModel = Build.MODEL,
                manufacturer = Build.MANUFACTURER
            )
            callback(Result.success(profile))
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }

    override fun getBatteryState(callback: (Result<NativeBatteryState>) -> Unit) {
        try {
            val intentFilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
            val batteryStatus = context.registerReceiver(null, intentFilter)

            val level = batteryStatus?.let {
                val current = it.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                val scale = it.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                if (current >= 0 && scale > 0) current.toDouble() / scale.toDouble() else 0.85
            } ?: 0.85

            val status = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
            val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                    status == BatteryManager.BATTERY_STATUS_FULL

            callback(Result.success(NativeBatteryState(level = level, isCharging = isCharging)))
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }

    override fun getAvailableStorageMB(callback: (Result<Long>) -> Unit) {
        try {
            val path = Environment.getDataDirectory()
            val stat = StatFs(path.path)
            val blockSize = stat.blockSizeLong
            val availableBlocks = stat.availableBlocksLong
            val availableMB = (availableBlocks * blockSize) / (1024 * 1024)
            callback(Result.success(availableMB))
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }
}
