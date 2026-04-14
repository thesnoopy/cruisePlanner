package de.mailsmart.cruiseplanner

import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

class MainActivity : FlutterActivity(), EventChannel.StreamHandler, MethodChannel.MethodCallHandler {
    private val shareMethodChannelName = "de.mailsmart.cruiseplanner/share_intake"
    private val shareEventChannelName = "de.mailsmart.cruiseplanner/share_intake/events"

    private var pendingInitialShareItems: List<Map<String, Any?>>? = null
    private var shareEventSink: EventChannel.EventSink? = null
    private var shareBridgeConfigured = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        configureShareBridge(flutterEngine)
        captureInitialShareIntent()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        publishSharedItems(extractSharedItems(intent))
        clearConsumedShareIntent(intent)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        shareEventSink = events
    }

    override fun onCancel(arguments: Any?) {
        shareEventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInitialSharedItems" -> {
                result.success(pendingInitialShareItems ?: emptyList<Map<String, Any?>>())
                pendingInitialShareItems = null
            }
            else -> result.notImplemented()
        }
    }

    private fun configureShareBridge(flutterEngine: FlutterEngine) {
        if (shareBridgeConfigured) {
            return
        }

        shareBridgeConfigured = true

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            shareMethodChannelName,
        ).setMethodCallHandler(this)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            shareEventChannelName,
        ).setStreamHandler(this)
    }

    private fun captureInitialShareIntent() {
        publishSharedItems(extractSharedItems(intent))
        clearConsumedShareIntent(intent)
    }

    private fun publishSharedItems(items: List<Map<String, Any?>>) {
        if (items.isEmpty()) {
            return
        }

        val eventSink = shareEventSink
        if (eventSink != null) {
            eventSink.success(items)
            return
        }

        pendingInitialShareItems = items
    }

    private fun extractSharedItems(intent: Intent?): List<Map<String, Any?>> {
        if (intent == null) {
            return emptyList()
        }

        return when (intent.action) {
            Intent.ACTION_SEND -> extractSendItems(intent)
            Intent.ACTION_SEND_MULTIPLE -> extractMultipleSendItems(intent)
            else -> emptyList()
        }
    }

    private fun extractSendItems(intent: Intent): List<Map<String, Any?>> {
        val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)?.trim().orEmpty()
        val textValue = intent.getStringExtra(Intent.EXTRA_TEXT)?.trim().orEmpty()
        val primaryUri = intent.getParcelableExtraCompat<Uri>(Intent.EXTRA_STREAM)
        val sharedUris = linkedSetOf<Uri>().apply {
            primaryUri?.let(::add)
            addAll(extractClipDataUris(intent))
        }

        if (sharedUris.isNotEmpty()) {
            return sharedUris.mapNotNull { uri ->
                normalizeSharedFile(
                    uri = uri,
                    explicitMimeType = intent.type,
                    message = textValue.ifEmpty { subject.ifEmpty { null } },
                )
            }
        }

        return listOfNotNull(normalizeSharedText(textValue, subject))
    }

    private fun extractMultipleSendItems(intent: Intent): List<Map<String, Any?>> {
        val textValue = intent.getStringExtra(Intent.EXTRA_TEXT)?.trim().orEmpty()
        val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)?.trim().orEmpty()
        val message = textValue.ifEmpty { subject.ifEmpty { null } }
        val sharedUris = linkedSetOf<Uri>().apply {
            addAll(extractParcelableUriList(intent, Intent.EXTRA_STREAM))
            addAll(extractClipDataUris(intent))
        }

        if (sharedUris.isNotEmpty()) {
            return sharedUris.mapNotNull { uri ->
                normalizeSharedFile(
                    uri = uri,
                    explicitMimeType = intent.type,
                    message = message,
                )
            }
        }

        return listOfNotNull(normalizeSharedText(textValue, subject))
    }

    private fun extractClipDataUris(intent: Intent): List<Uri> {
        val clipData = intent.clipData ?: return emptyList()
        val uris = ArrayList<Uri>(clipData.itemCount)
        for (index in 0 until clipData.itemCount) {
            clipData.getItemAt(index).uri?.let(uris::add)
        }
        return uris
    }

    private fun normalizeSharedText(textValue: String, subject: String): Map<String, Any?>? {
        val normalizedValue = textValue.trim()
        if (normalizedValue.isEmpty()) {
            return null
        }

        return buildMap<String, Any?> {
            put("kind", if (looksLikeUrl(normalizedValue)) "url" else "text")
            put("value", normalizedValue)
            if (subject.isNotEmpty()) {
                put("message", subject)
            }
        }
    }

    private fun normalizeSharedFile(
        uri: Uri,
        explicitMimeType: String?,
        message: String?,
    ): Map<String, Any?>? {
        val normalizedValue = copyUriToCache(uri) ?: normalizeFileLikeValue(uri) ?: return null
        val mimeType = resolveMimeType(uri, explicitMimeType)
        val fileName = resolveDisplayName(uri, normalizedValue)
        val kind = if (mimeType?.startsWith("image/") == true) "image" else "file"

        return buildMap<String, Any?> {
            put("kind", kind)
            put("value", normalizedValue)
            if (mimeType != null) {
                put("mimeType", mimeType)
            }
            if (fileName != null) {
                put("fileName", fileName)
            }
            if (message != null) {
                put("message", message)
            }
        }
    }

    private fun copyUriToCache(uri: Uri): String? {
        val scheme = uri.scheme?.lowercase()
        if (scheme == "file") {
            return uri.path?.trimToNull()
        }
        if (scheme != "content") {
            return null
        }

        val cacheDirectory = File(cacheDir, "share_intake")
        if (!cacheDirectory.exists()) {
            cacheDirectory.mkdirs()
        }

        val displayName = queryDisplayName(uri)
        val fileExtension = displayName?.substringAfterLast('.', "")?.trimToNull()
            ?: MimeTypeMap.getSingleton()
                .getExtensionFromMimeType(contentResolver.getType(uri))
                ?.trimToNull()
        val baseName = displayName?.substringBeforeLast('.', displayName)?.trimToNull() ?: "shared_item"
        val safeExtension = fileExtension?.let { ".$it" }.orEmpty()
        val destinationFile = File(
            cacheDirectory,
            "${baseName}_${UUID.randomUUID()}$safeExtension",
        )

        contentResolver.openInputStream(uri)?.use { inputStream ->
            FileOutputStream(destinationFile).use { outputStream ->
                inputStream.copyTo(outputStream)
            }
        } ?: return null

        return destinationFile.absolutePath
    }

    private fun resolveDisplayName(uri: Uri, normalizedValue: String): String? {
        return queryDisplayName(uri)
            ?: File(normalizedValue).name.trimToNull()
    }

    private fun resolveMimeType(uri: Uri, explicitMimeType: String?): String? {
        val normalizedExplicitType = explicitMimeType.trimToNull()
        if (normalizedExplicitType != null && normalizedExplicitType != "*/*") {
            return normalizedExplicitType
        }

        return contentResolver.getType(uri).trimToNull()
    }

    private fun queryDisplayName(uri: Uri): String? {
        if (uri.scheme?.lowercase() != "content") {
            return null
        }

        val cursor: Cursor = contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME),
            null,
            null,
            null,
        ) ?: return null

        cursor.use {
            if (!it.moveToFirst()) {
                return null
            }

            val columnIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (columnIndex < 0) {
                return null
            }

            return it.getString(columnIndex)?.trimToNull()
        }
    }

    private fun normalizeFileLikeValue(uri: Uri): String? {
        val normalized = uri.toString().trim()
        if (normalized.isEmpty()) {
            return null
        }

        return if (uri.scheme?.lowercase() == "file") {
            uri.path?.trimToNull()
        } else {
            normalized
        }
    }

    private fun looksLikeUrl(value: String): Boolean {
        val normalizedUri = Uri.parse(value)
        val scheme = normalizedUri.scheme?.lowercase()
        return scheme == "http" || scheme == "https"
    }

    private fun clearConsumedShareIntent(intent: Intent?) {
        if (intent == null) {
            return
        }
        if (intent.action != Intent.ACTION_SEND && intent.action != Intent.ACTION_SEND_MULTIPLE) {
            return
        }

        setIntent(
            Intent(intent).apply {
                action = Intent.ACTION_MAIN
                data = null
                clipData = null
                type = null
                replaceExtras(Bundle())
            },
        )
    }

    @Suppress("DEPRECATION")
    private inline fun <reified T> Intent.getParcelableExtraCompat(name: String): T? {
        return getParcelableExtra(name) as? T
    }

    @Suppress("DEPRECATION")
    private fun extractParcelableUriList(intent: Intent, name: String): List<Uri> {
        return intent.getParcelableArrayListExtra<Uri>(name) ?: emptyList()
    }

    private fun String?.trimToNull(): String? {
        val trimmed = this?.trim()
        return if (trimmed.isNullOrEmpty()) null else trimmed
    }
}
