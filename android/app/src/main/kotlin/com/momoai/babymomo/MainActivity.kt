package com.momoai.babymomo

import android.content.Context
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.momoai.babymomo.bridge.DeviceBridge
import com.momoai.babymomo.bridge.ImageGenBridge
import com.momoai.babymomo.bridge.InferenceBridge
import com.momoai.babymomo.bridge.SecurityBridge
import com.momoai.babymomo.pigeon.device.DeviceHostApi
import com.momoai.babymomo.pigeon.imagegen.ImageGenHostApi
import com.momoai.babymomo.pigeon.inference.InferenceHostApi
import com.momoai.babymomo.pigeon.security.SecurityHostApi

class MainActivity : FlutterActivity() {
    private var wakeLock: PowerManager.WakeLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // Setup WakeLock Channel for background downloading
        MethodChannel(messenger, "com.momoai.babymomo/wakelock").setMethodCallHandler { call, result ->
            when (call.method) {
                "acquire" -> {
                    try {
                        if (wakeLock == null) {
                            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                            wakeLock = powerManager.newWakeLock(
                                PowerManager.PARTIAL_WAKE_LOCK,
                                "BabyMomo::DownloadWakeLock"
                            )
                        }
                        if (wakeLock?.isHeld == false) {
                            wakeLock?.acquire(10 * 60 * 1000L) // 10 minutes timeout
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WAKELOCK_ERROR", e.message, null)
                    }
                }
                "release" -> {
                    try {
                        if (wakeLock?.isHeld == true) {
                            wakeLock?.release()
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WAKELOCK_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Register the Device Bridge host API
        DeviceHostApi.setUp(messenger, DeviceBridge(applicationContext, messenger))

        // Register the Inference Bridge host API
        InferenceHostApi.setUp(messenger, InferenceBridge(messenger))

        // Register the Image Gen Bridge host API (Pollinations + Canvas)
        val imageGenBridge = ImageGenBridge(applicationContext)
        ImageGenHostApi.setUp(messenger, imageGenBridge)

        // Register the Security Bridge host API
        SecurityHostApi.setUp(messenger, SecurityBridge(applicationContext, messenger))

        // ── SD Inference Channel ──
        // Supports dynamic loading of libmomoimagegen.so from internal storage.
        // The .so is downloaded at runtime (not bundled in APK) to keep app size small.
        MethodChannel(messenger, "com.momoai.babymomo/sd_inference").setMethodCallHandler { call, result ->
            when (call.method) {
                "isLibraryAvailable" -> {
                    result.success(imageGenBridge.nativeLibLoaded)
                }
                "initRuntime" -> {
                    // Dynamically load the .so from the provided path (app's internal storage)
                    val soPath = call.argument<String>("soPath")
                    if (soPath == null) {
                        result.error("INVALID_ARGS", "soPath is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val soFile = java.io.File(soPath)
                        if (!soFile.exists()) {
                            result.error("FILE_NOT_FOUND", "Library not found at: $soPath", null)
                            return@setMethodCallHandler
                        }
                        System.load(soFile.absolutePath)
                        imageGenBridge.nativeLibLoaded = true
                        result.success(true)
                    } catch (e: UnsatisfiedLinkError) {
                        result.error("LOAD_ERROR", "Failed to load native library: ${e.message}", null)
                    } catch (e: Exception) {
                        result.error("LOAD_ERROR", e.message, null)
                    }
                }
                "clearRuntime" -> {
                    // Note: Android does not support unloading .so files — only reset our flag
                    imageGenBridge.nativeLibLoaded = false
                    result.success(true)
                }
                "setActiveModel" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        imageGenBridge.setLocalModelPath(path)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "path argument required", null)
                    }
                }
                "clearActiveModel" -> {
                    imageGenBridge.clearLocalModelPath()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}

