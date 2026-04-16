package de.mailsmart.cruiseplanner

import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.provider.OpenableColumns
import android.print.PageRange
import android.print.PrintAttributes
import android.print.PrintDocumentAdapter
import android.webkit.MimeTypeMap
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.view.View
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
    private val urlSnapshotMethodChannelName = "de.mailsmart.cruiseplanner/url_snapshot"

    private var pendingInitialShareItems: List<Map<String, Any?>>? = null
    private var shareEventSink: EventChannel.EventSink? = null
    private var shareBridgeConfigured = false
    private var urlSnapshotBridgeConfigured = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        configureShareBridge(flutterEngine)
        configureUrlSnapshotBridge(flutterEngine)
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

    private fun configureUrlSnapshotBridge(flutterEngine: FlutterEngine) {
        if (urlSnapshotBridgeConfigured) {
            return
        }

        urlSnapshotBridgeConfigured = true

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            urlSnapshotMethodChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "captureUrlAsPdf" -> {
                    val sourceUrl = call.argument<String>("sourceUrl")?.trim()
                    if (sourceUrl.isNullOrEmpty()) {
                        result.error("invalid_args", "Missing sourceUrl.", null)
                        return@setMethodCallHandler
                    }

                    captureUrlAsPdf(sourceUrl, result)
                }
                else -> result.notImplemented()
            }
        }
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

    private fun captureUrlAsPdf(sourceUrl: String, result: MethodChannel.Result) {
        runOnUiThread {
            val webView = WebView(this).apply {
                visibility = View.INVISIBLE
                settings.javaScriptEnabled = true
                settings.domStorageEnabled = true
                settings.loadWithOverviewMode = true
                settings.useWideViewPort = true
                webChromeClient = WebChromeClient()
                val widthMeasureSpec = View.MeasureSpec.makeMeasureSpec(1080, View.MeasureSpec.EXACTLY)
                val heightMeasureSpec = View.MeasureSpec.makeMeasureSpec(1920, View.MeasureSpec.EXACTLY)
                measure(widthMeasureSpec, heightMeasureSpec)
                layout(0, 0, 1080, 1920)
            }
            val timeoutHandler = Handler(Looper.getMainLooper())
            var completed = false
            var captureScheduled = false

            fun cleanup() {
                timeoutHandler.removeCallbacksAndMessages(null)
                webView.stopLoading()
                webView.webViewClient = null
                webView.webChromeClient = null
                webView.destroy()
            }

            fun finishSuccess(pdfBytes: ByteArray) {
                if (completed) {
                    return
                }
                completed = true
                val payload = hashMapOf<String, Any?>(
                    "pdfBytes" to pdfBytes,
                    "effectiveUrl" to webView.url,
                    "pageTitle" to webView.title,
                )
                cleanup()
                result.success(payload)
            }

            fun finishError(code: String, message: String) {
                if (completed) {
                    return
                }
                completed = true
                cleanup()
                result.error(code, message, null)
            }

            timeoutHandler.postDelayed({
                finishError("timeout", "Timed out while rendering URL to PDF.")
            }, 30000)

            webView.webViewClient = object : WebViewClient() {
                override fun onPageFinished(view: WebView?, url: String?) {
                    super.onPageFinished(view, url)
                    if (captureScheduled || completed) {
                        return
                    }

                    captureScheduled = true
                    timeoutHandler.postDelayed({
                        renderWebViewToPdf(webView, ::finishSuccess, ::finishError)
                    }, 1000)
                }

                override fun onReceivedError(
                    view: WebView?,
                    request: WebResourceRequest?,
                    error: WebResourceError?,
                ) {
                    super.onReceivedError(view, request, error)
                    if (request?.isForMainFrame == true) {
                        finishError(
                            "load_failed",
                            error?.description?.toString() ?: "Failed to load URL.",
                        )
                    }
                }
            }

            webView.loadUrl(sourceUrl)
        }
    }

    private fun renderWebViewToPdf(
        webView: WebView,
        onSuccess: (ByteArray) -> Unit,
        onError: (String, String) -> Unit,
    ) {
        val outputDirectory = File(cacheDir, "url_snapshot_pdf")
        if (!outputDirectory.exists()) {
            outputDirectory.mkdirs()
        }

        val outputFile = File(outputDirectory, "snapshot_${UUID.randomUUID()}.pdf")
        val attributes = PrintAttributes.Builder()
            .setMediaSize(PrintAttributes.MediaSize.ISO_A4)
            .setResolution(PrintAttributes.Resolution("pdf", "pdf", 300, 300))
            .setMinMargins(PrintAttributes.Margins.NO_MARGINS)
            .build()
        val adapter = webView.createPrintDocumentAdapter("url_snapshot")

        adapter.onLayout(
            null,
            attributes,
            null,
            object : PrintDocumentAdapter.LayoutResultCallback() {
                override fun onLayoutFinished(info: android.print.PrintDocumentInfo?, changed: Boolean) {
                    writePdfFile(
                        adapter = adapter,
                        outputFile = outputFile,
                        onSuccess = onSuccess,
                        onError = onError,
                    )
                }

                override fun onLayoutFailed(error: CharSequence?) {
                    onError(
                        "layout_failed",
                        error?.toString() ?: "Failed to layout PDF document.",
                    )
                }
            },
            null,
        )
    }

    private fun writePdfFile(
        adapter: PrintDocumentAdapter,
        outputFile: File,
        onSuccess: (ByteArray) -> Unit,
        onError: (String, String) -> Unit,
    ) {
        try {
            val parcelFileDescriptor = ParcelFileDescriptor.open(
                outputFile,
                ParcelFileDescriptor.MODE_READ_WRITE or
                    ParcelFileDescriptor.MODE_CREATE or
                    ParcelFileDescriptor.MODE_TRUNCATE,
            )

            adapter.onWrite(
                arrayOf(PageRange.ALL_PAGES),
                parcelFileDescriptor,
                null,
                object : PrintDocumentAdapter.WriteResultCallback() {
                    override fun onWriteFinished(pages: Array<PageRange>) {
                        try {
                            parcelFileDescriptor.close()
                            val pdfBytes = outputFile.readBytes()
                            outputFile.delete()
                            if (pdfBytes.isEmpty()) {
                                onError("write_failed", "Generated PDF is empty.")
                                return
                            }
                            onSuccess(pdfBytes)
                        } catch (exception: Exception) {
                            outputFile.delete()
                            onError(
                                "write_failed",
                                exception.message ?: "Failed to read generated PDF.",
                            )
                        }
                    }

                    override fun onWriteFailed(error: CharSequence?) {
                        try {
                            parcelFileDescriptor.close()
                        } catch (_: Exception) {
                        }
                        outputFile.delete()
                        onError(
                            "write_failed",
                            error?.toString() ?: "Failed to write PDF document.",
                        )
                    }
                },
            )
        } catch (exception: Exception) {
            outputFile.delete()
            onError(
                "write_failed",
                exception.message ?: "Failed to prepare PDF output.",
            )
        }
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
