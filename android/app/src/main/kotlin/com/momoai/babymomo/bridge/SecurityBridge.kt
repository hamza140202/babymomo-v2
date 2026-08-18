package com.momoai.babymomo.bridge

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import com.momoai.babymomo.pigeon.security.*
import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.*
import java.io.File
import java.security.KeyStore
import java.security.MessageDigest
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Android Native implementation of the Security and Cryptography bridge.
 * 
 * Implements [SecurityHostApi] to provide:
 * 1. Hardware-backed AES database encryption key-wrapping via Android KeyStore.
 * 2. High-performance background SHA-256 file hashing on [Dispatchers.IO] coroutines.
 * 3. Real-time, throttled progress updates via [SecurityFlutterApi].
 */
class SecurityBridge(
    private val context: Context,
    binaryMessenger: BinaryMessenger
) : SecurityHostApi {

    private val flutterApi = SecurityFlutterApi(binaryMessenger)
    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())

    companion object {
        private const val MASTER_KEY_ALIAS = "momo_keystore_master_key"
        private const val PREFS_NAME = "momo_secure_prefs"
        private const val KEY_ENCRYPTED_DB = "encrypted_db_key"
        private const val KEY_DB_IV = "db_key_iv"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val ANDROID_KEYSTORE = "AndroidKeyStore"
    }

    override fun getOrCreateSecureKey(callback: (Result<String>) -> Unit) {
        try {
            val sharedPrefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val encryptedKeyBase64 = sharedPrefs.getString(KEY_ENCRYPTED_DB, null)
            val ivBase64 = sharedPrefs.getString(KEY_DB_IV, null)

            val rawDbKey: ByteArray
            if (encryptedKeyBase64 == null || ivBase64 == null) {
                // Generate a cryptographically secure random 256-bit (32 bytes) database key
                val secureRandom = SecureRandom()
                rawDbKey = ByteArray(32)
                secureRandom.nextBytes(rawDbKey)

                // Retrieve or generate KeyStore Master Wrapping Key
                val masterKey = getOrCreateMasterKey()

                // Encrypt the random database key
                val cipher = Cipher.getInstance(TRANSFORMATION)
                cipher.init(Cipher.ENCRYPT_MODE, masterKey)
                val encryptedBytes = cipher.doFinal(rawDbKey)
                val iv = cipher.iv

                // Save to SharedPreferences
                sharedPrefs.edit()
                    .putString(KEY_ENCRYPTED_DB, Base64.encodeToString(encryptedBytes, Base64.NO_WRAP))
                    .putString(KEY_DB_IV, Base64.encodeToString(iv, Base64.NO_WRAP))
                    .apply()
            } else {
                // Decode components
                val encryptedBytes = Base64.decode(encryptedKeyBase64, Base64.NO_WRAP)
                val iv = Base64.decode(ivBase64, Base64.NO_WRAP)

                // Retrieve Master Wrapping Key
                val masterKey = getOrCreateMasterKey()

                // Decrypt database key
                val cipher = Cipher.getInstance(TRANSFORMATION)
                val spec = GCMParameterSpec(128, iv)
                cipher.init(Cipher.DECRYPT_MODE, masterKey, spec)
                rawDbKey = cipher.doFinal(encryptedBytes)
            }

            // Return database key encoded as Base64 to Dart
            val base64Key = Base64.encodeToString(rawDbKey, Base64.NO_WRAP)
            callback(Result.success(base64Key))
        } catch (e: Exception) {
            // Strict Secure Fail policy: crash startup on KeyStore failure to avoid compromised states
            callback(Result.failure(
                FlutterError(
                    "secure_storage_failure",
                    "Strict Secure Fail: Android Keystore cryptographic decryption failed. Reason: ${e.message}",
                    null
                )
            ))
        }
    }

    override fun wipeSecureStorage(callback: (Result<Unit>) -> Unit) {
        try {
            val sharedPrefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            sharedPrefs.edit().clear().apply()

            val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
            if (keyStore.containsAlias(MASTER_KEY_ALIAS)) {
                keyStore.deleteEntry(MASTER_KEY_ALIAS)
            }
            callback(Result.success(Unit))
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }

    override fun computeAndVerifySHA256(
        request: NativeHashRequest,
        callback: (Result<NativeHashResponse>) -> Unit
    ) {
        scope.launch {
            try {
                val file = File(request.filePath)
                if (!file.exists()) {
                    callback(Result.success(
                        NativeHashResponse(
                            hash = "",
                            match = false,
                            success = false,
                            errorMessage = "File does not exist on disk: ${request.filePath}"
                        )
                    ))
                    return@launch
                }

                val totalBytes = file.length()
                val digest = MessageDigest.getInstance("SHA-256")
                val buffer = ByteArray(8192)
                var bytesRead: Long = 0

                file.inputStream().use { input ->
                    var read = input.read(buffer)
                    var lastProgressTime = 0L

                    while (read != -1) {
                        digest.update(buffer, 0, read)
                        bytesRead += read

                        val now = System.currentTimeMillis()
                        // Throttle progress to 150ms intervals to prevent platform channel flooding
                        if (now - lastProgressTime > 150L || bytesRead == totalBytes) {
                            lastProgressTime = now
                            val progress = if (totalBytes > 0) bytesRead.toDouble() / totalBytes.toDouble() else 0.0
                            
                            withContext(Dispatchers.Main) {
                                flutterApi.onHashProgress(request.filePath, progress) { /* no-op response */ }
                            }
                        }
                        read = input.read(buffer)
                    }
                }

                val hashBytes = digest.digest()
                val hexString = hashBytes.joinToString("") { "%02x".format(it) }
                val match = hexString.equals(request.expectedHash, ignoreCase = true)

                val response = NativeHashResponse(
                    hash = hexString,
                    match = match,
                    success = true,
                    errorMessage = null
                )
                callback(Result.success(response))
            } catch (e: Exception) {
                callback(Result.success(
                    NativeHashResponse(
                        hash = "",
                        match = false,
                        success = false,
                        errorMessage = "Cryptographic hashing encountered an error: ${e.message ?: e.toString()}"
                    )
                ))
            }
        }
    }

    /**
     * Retrieves the master AES-256 wrapping key from KeyStore, or creates it if missing.
     */
    private fun getOrCreateMasterKey(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        if (keyStore.containsAlias(MASTER_KEY_ALIAS)) {
            val entry = keyStore.getEntry(MASTER_KEY_ALIAS, null) as? KeyStore.SecretKeyEntry
            if (entry != null) {
                return entry.secretKey
            }
        }

        // Generate Master AES-256 wrapping key within the secure hardware boundary
        val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
        val spec = KeyGenParameterSpec.Builder(
            MASTER_KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            // Strict security requirement: non-exportable hardware-backed key configuration
            .build()

        keyGenerator.init(spec)
        return keyGenerator.generateKey()
    }
}
