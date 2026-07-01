package de.mailsmart.cruiseplanner

import android.content.Context
import android.os.Build
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.RectF
import android.graphics.pdf.PdfDocument
import android.util.Log
import android.view.View
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.io.File
import java.io.FileOutputStream
import kotlin.math.roundToInt

class UrlSnapshotWebViewFactory(
    private val messenger: BinaryMessenger,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    companion object {
        const val viewType = "de.mailsmart.cruiseplanner/url_snapshot_webview"
        private const val channelBase = "de.mailsmart.cruiseplanner/url_snapshot_webview"
        private const val logTag = "UrlSnapshot"
        private const val captureDelayMs = 700L
        private const val overlapPx = 24
        private const val minCapturePages = 40
        private const val capturePageBuffer = 12
        private const val maxCapturePagesSafetyLimit = 100
        private const val whiteCaptureThreshold = 0.0015
    }

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return UrlSnapshotWebViewPlatformView(
            context = context,
            messenger = messenger,
            viewId = viewId,
        )
    }

    private class UrlSnapshotWebViewPlatformView(
        context: Context,
        messenger: BinaryMessenger,
        viewId: Int,
    ) : PlatformView, MethodChannel.MethodCallHandler {
        private val webView = SnapshotCaptureWebView(context)
        private val methodChannel = MethodChannel(messenger, "$channelBase/$viewId")
        private val eventChannel = EventChannel(messenger, "$channelBase/$viewId/events")
        private var eventSink: EventChannel.EventSink? = null
        private var isCapturing = false
        private var visualStateRequestId = 0L

        private enum class CaptureStrategy(
            val logName: String,
        ) {
            Viewport("viewport"),
            TranslatedFallback("translated_fallback"),
        }

        private data class BitmapCaptureResult(
            val bitmap: Bitmap,
            val nonWhiteRatio: Double,
            val sampleHash: String,
            val strategy: CaptureStrategy,
        )

        init {
            webView.settings.javaScriptEnabled = true
            webView.settings.domStorageEnabled = true
            webView.settings.loadWithOverviewMode = true
            webView.settings.useWideViewPort = true
            webView.layoutParams = android.widget.FrameLayout.LayoutParams(
                android.widget.FrameLayout.LayoutParams.MATCH_PARENT,
                android.widget.FrameLayout.LayoutParams.MATCH_PARENT,
            )
            webView.webChromeClient = object : WebChromeClient() {
                override fun onReceivedTitle(view: WebView?, title: String?) {
                    super.onReceivedTitle(view, title)
                    emitEvent(
                        type = "titleChanged",
                        url = view?.url,
                        pageTitle = title,
                    )
                }
            }
            webView.webViewClient = object : WebViewClient() {
                override fun onPageStarted(view: WebView?, url: String?, favicon: android.graphics.Bitmap?) {
                    super.onPageStarted(view, url, favicon)
                    emitEvent(
                        type = "pageStarted",
                        url = url,
                        pageTitle = view?.title,
                    )
                }

                override fun onPageFinished(view: WebView?, url: String?) {
                    super.onPageFinished(view, url)
                    emitEvent(
                        type = "pageFinished",
                        url = url,
                        pageTitle = view?.title,
                    )
                }

                override fun onReceivedError(
                    view: WebView?,
                    request: WebResourceRequest?,
                    error: WebResourceError?,
                ) {
                    super.onReceivedError(view, request, error)
                    if (request?.isForMainFrame != true) {
                        return
                    }

                    emitEvent(
                        type = "loadFailed",
                        url = request.url?.toString() ?: view?.url,
                        pageTitle = view?.title,
                        message = error?.description?.toString() ?: "Failed to load URL.",
                    )
                }
            }

            methodChannel.setMethodCallHandler(this)
            eventChannel.setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                        eventSink = events
                    }

                    override fun onCancel(arguments: Any?) {
                        eventSink = null
                    }
                },
            )
        }

        override fun getView(): View = webView

        override fun dispose() {
            methodChannel.setMethodCallHandler(null)
            eventChannel.setStreamHandler(null)
            eventSink = null
            webView.stopLoading()
            webView.webChromeClient = null
            webView.webViewClient = WebViewClient()
            webView.destroy()
        }

        override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
            when (call.method) {
                "loadUrl" -> {
                    val url = call.argument<String>("url")?.trim()
                    if (url.isNullOrEmpty()) {
                        result.error("invalid_args", "Missing URL.", null)
                        return
                    }

                    webView.loadUrl(url)
                    result.success(null)
                }
                "reload" -> {
                    webView.reload()
                    result.success(null)
                }
                "capturePdf" -> {
                    val sourceUrl = call.argument<String>("sourceUrl")?.trim()
                    if (sourceUrl.isNullOrEmpty()) {
                        result.error("invalid_args", "Missing sourceUrl.", null)
                        return
                    }

                    capturePdf(sourceUrl, result)
                }
                else -> result.notImplemented()
            }
        }

        private fun capturePdf(sourceUrl: String, result: MethodChannel.Result) {
            if (webView.url.isNullOrBlank() || webView.progress < 100) {
                result.error("page_not_loaded", "No page is currently loaded.", null)
                return
            }
            if (isCapturing) {
                result.error("capture_in_progress", "A PDF capture is already running.", null)
                return
            }

            captureVisibleSegmentsAsPdf(sourceUrl, result)
        }

        private fun emitEvent(
            type: String,
            url: String? = null,
            pageTitle: String? = null,
            message: String? = null,
        ) {
            eventSink?.success(
                hashMapOf<String, Any?>(
                    "type" to type,
                    "url" to url,
                    "pageTitle" to pageTitle,
                    "message" to message,
                ),
            )
        }

        private fun captureVisibleSegmentsAsPdf(
            sourceUrl: String,
            result: MethodChannel.Result,
        ) {
            val viewportWidth = webView.width
            val viewportHeight = webView.height
            if (viewportWidth <= 0 || viewportHeight <= 0) {
                result.error("layout_failed", "The webpage view has no visible size.", null)
                return
            }

            val originalScrollX = webView.scrollX
            val originalScrollY = webView.scrollY
            val nonWhiteRatios = mutableListOf<Double>()
            val sampleHashes = mutableListOf<String>()
            val pdfDocument = PdfDocument()
            var pdfDocumentClosed = false
            isCapturing = true

            fun closePdfDocument() {
                if (pdfDocumentClosed) {
                    return
                }
                pdfDocument.close()
                pdfDocumentClosed = true
            }

            fun finishWithError(code: String, message: String) {
                restoreScrollPosition(originalScrollX, originalScrollY)
                closePdfDocument()
                isCapturing = false
                result.error(code, message, null)
            }

            fun finishWithSuccess(pdfFile: File, pageCount: Int) {
                restoreScrollPosition(originalScrollX, originalScrollY)
                isCapturing = false
                Log.d(
                    logTag,
                    "capture complete pageCount=$pageCount fileSizeBytes=${pdfFile.length()} filePath=${pdfFile.absolutePath}",
                )
                result.success(
                    hashMapOf<String, Any?>(
                        "filePath" to pdfFile.absolutePath,
                        "title" to webView.title,
                        "url" to (webView.url ?: sourceUrl),
                        "pageCount" to pageCount,
                        "fileSizeBytes" to pdfFile.length(),
                    ),
                )
            }

            val initialScrollExtent = webView.verticalScrollExtentPx().takeIf { it > 0 } ?: viewportHeight
            val initialScrollRange = webView.verticalScrollRangePx().takeIf { it > 0 }
                ?: (webView.contentHeight * webView.scale).toInt().coerceAtLeast(viewportHeight)
            val captureStepPx = (initialScrollExtent - overlapPx).coerceAtLeast(1)
            val initialEstimatedPages = estimateRequiredPages(
                scrollRange = initialScrollRange,
                scrollExtent = initialScrollExtent,
                stepPx = captureStepPx,
            )
            val initialMaxPages = determineMaxCapturePages(initialEstimatedPages)
            Log.d(
                logTag,
                "capture start range=$initialScrollRange extent=$initialScrollExtent " +
                    "step=$captureStepPx estimatedPages=$initialEstimatedPages maxPages=$initialMaxPages",
            )

            fun captureStep() {
                val currentOffset = webView.verticalScrollOffsetPx()
                webView.invalidate()
                val captureResult = try {
                    captureVisibleBitmap(
                        webView = webView,
                        width = viewportWidth,
                        height = viewportHeight,
                        pageIndex = nonWhiteRatios.size + 1,
                    )
                } catch (exception: Exception) {
                    finishWithError(
                        "write_failed",
                        exception.message ?: "Failed to capture the visible webpage area.",
                        )
                    return
                }
                val bitmap = captureResult.bitmap
                val nonWhiteRatio = captureResult.nonWhiteRatio
                val sampleHash = captureResult.sampleHash
                nonWhiteRatios.add(nonWhiteRatio)
                sampleHashes.add(sampleHash)
                val pageIndex = nonWhiteRatios.size

                val scrollOffset = webView.verticalScrollOffsetPx()
                val scrollExtent = webView.verticalScrollExtentPx().takeIf { it > 0 } ?: viewportHeight
                val scrollRange = webView.verticalScrollRangePx().takeIf { it > 0 }
                    ?: (webView.contentHeight * webView.scale).toInt().coerceAtLeast(viewportHeight)
                val pdfPageSize = pdfPageSizeForBitmap(bitmap)
                val estimatedPages = estimateRequiredPages(
                    scrollRange = scrollRange,
                    scrollExtent = scrollExtent,
                    stepPx = (scrollExtent - overlapPx).coerceAtLeast(1),
                )
                val maxPages = determineMaxCapturePages(estimatedPages)
                val maxOffset = (scrollRange - scrollExtent).coerceAtLeast(0)
                val isLastPage = currentOffset >= maxOffset
                writeDebugBitmapIfNeeded(
                    bitmap = bitmap,
                    pageIndex = pageIndex,
                    isLastPage = isLastPage,
                )
                Log.d(
                    logTag,
                    "capture page=$pageIndex " +
                        "view=${webView.width}x${webView.height} " +
                        "scrollY=${webView.scrollY} offset=$scrollOffset extent=$scrollExtent range=$scrollRange " +
                        "bitmap=${bitmap.width}x${bitmap.height} " +
                        "pdf=${pdfPageSize.first}x${pdfPageSize.second} " +
                        "nonWhiteRatio=$nonWhiteRatio " +
                        "sampleHash=$sampleHash " +
                        "strategy=${captureResult.strategy.logName}",
                )
                logRepeatedSampleHashIfNeeded(sampleHashes, captureResult.strategy)
                if (nonWhiteRatio <= whiteCaptureThreshold) {
                    Log.d(
                        logTag,
                        "capture page=$pageIndex flagged as near-white strategy=${captureResult.strategy.logName}",
                    )
                }

                try {
                    appendBitmapPageToPdfDocument(
                        pdfDocument = pdfDocument,
                        bitmap = bitmap,
                        pageIndex = pageIndex,
                    )
                } catch (exception: Exception) {
                    if (!bitmap.isRecycled) {
                        bitmap.recycle()
                    }
                    finishWithError(
                        "write_failed",
                        exception.message ?: "Failed to generate PDF document.",
                    )
                    return
                }
                if (!bitmap.isRecycled) {
                    bitmap.recycle()
                }

                if (currentOffset >= maxOffset) {
                    if (shouldRejectBlankCapture(nonWhiteRatios)) {
                        finishWithError(
                            "write_failed",
                            "The captured webpage content was blank after scrolling.",
                        )
                        return
                    }

                    val pdfFile = try {
                        writePdfDocumentToTempFile(pdfDocument).also {
                            pdfDocumentClosed = true
                        }
                    } catch (exception: Exception) {
                        pdfDocumentClosed = true
                        finishWithError(
                            "write_failed",
                            exception.message ?: "Failed to generate PDF document.",
                        )
                        return
                    }
                    if (!pdfFile.exists() || pdfFile.length() <= 0) {
                        finishWithError("empty_pdf", "Generated PDF is empty.")
                        return
                    }
                    finishWithSuccess(pdfFile, pageIndex)
                    return
                }

                if (pageIndex >= maxPages) {
                    Log.d(
                        logTag,
                        "capture limit estimatedPages=$estimatedPages maxPages=$maxPages lastScrollY=${webView.scrollY}",
                    )
                    finishWithError(
                        "capture_limit_exceeded",
                        "Page requires about $estimatedPages pages, limit is $maxPages.",
                    )
                    return
                }

                val nextOffset = (currentOffset + (scrollExtent - overlapPx).coerceAtLeast(1))
                    .coerceAtMost(maxOffset)
                if (nextOffset <= currentOffset) {
                    if (shouldRejectBlankCapture(nonWhiteRatios)) {
                        finishWithError(
                            "write_failed",
                            "The captured webpage content was blank after scrolling.",
                        )
                        return
                    }

                    val pdfFile = try {
                        writePdfDocumentToTempFile(pdfDocument).also {
                            pdfDocumentClosed = true
                        }
                    } catch (exception: Exception) {
                        pdfDocumentClosed = true
                        finishWithError(
                            "write_failed",
                            exception.message ?: "Failed to generate PDF document.",
                        )
                        return
                    }
                    if (!pdfFile.exists() || pdfFile.length() <= 0) {
                        finishWithError("empty_pdf", "Generated PDF is empty.")
                        return
                    }
                    finishWithSuccess(pdfFile, pageIndex)
                    return
                }

                scrollToAndWaitForDraw(
                    scrollX = originalScrollX,
                    scrollY = nextOffset,
                    callback = { captureStep() },
                )
            }

            scrollToAndWaitForDraw(
                scrollX = originalScrollX,
                scrollY = 0,
                callback = { captureStep() },
            )
        }

        private fun appendBitmapPageToPdfDocument(
            pdfDocument: PdfDocument,
            bitmap: Bitmap,
            pageIndex: Int,
        ) {
            val (pageWidth, pageHeight) = pdfPageSizeForBitmap(bitmap)
            Log.d(
                logTag,
                "pdf page=$pageIndex bitmap=${bitmap.width}x${bitmap.height} pdf=${pageWidth}x${pageHeight}",
            )
            val pageInfo = PdfDocument.PageInfo.Builder(
                pageWidth,
                pageHeight,
                pageIndex,
            ).create()
            val page = pdfDocument.startPage(pageInfo)
            val canvas = page.canvas
            canvas.drawColor(Color.WHITE)
            canvas.drawBitmap(
                bitmap,
                null,
                RectF(0f, 0f, pageWidth.toFloat(), pageHeight.toFloat()),
                null,
            )
            pdfDocument.finishPage(page)
        }

        private fun writePdfDocumentToTempFile(pdfDocument: PdfDocument): File {
            val outputFile = File.createTempFile(
                "url_snapshot_",
                ".pdf",
                webView.context.cacheDir,
            )
            try {
                FileOutputStream(outputFile).use { outputStream ->
                    pdfDocument.writeTo(outputStream)
                    outputStream.flush()
                }
                return outputFile
            } catch (exception: Exception) {
                outputFile.delete()
                throw exception
            } finally {
                pdfDocument.close()
            }
        }

        private fun captureVisibleBitmap(
            webView: WebView,
            width: Int,
            height: Int,
            pageIndex: Int,
        ): BitmapCaptureResult {
            val viewportBitmap = captureVisibleViewportBitmap(
                webView = webView,
                width = width,
                height = height,
            )
            val viewportRatio = estimateNonWhiteRatio(viewportBitmap)
            val viewportHash = sampleHashForBitmap(viewportBitmap)
            if (viewportRatio > whiteCaptureThreshold) {
                return BitmapCaptureResult(
                    bitmap = viewportBitmap,
                    nonWhiteRatio = viewportRatio,
                    sampleHash = viewportHash,
                    strategy = CaptureStrategy.Viewport,
                )
            }

            Log.d(
                logTag,
                "capture fallback check page=$pageIndex viewportNonWhiteRatio=$viewportRatio sampleHash=$viewportHash",
            )
            val translatedBitmap = captureTranslatedBitmap(
                webView = webView,
                width = width,
                height = height,
            )
            val translatedRatio = estimateNonWhiteRatio(translatedBitmap)
            val translatedHash = sampleHashForBitmap(translatedBitmap)
            return if (translatedRatio > viewportRatio) {
                if (!viewportBitmap.isRecycled) {
                    viewportBitmap.recycle()
                }
                BitmapCaptureResult(
                    bitmap = translatedBitmap,
                    nonWhiteRatio = translatedRatio,
                    sampleHash = translatedHash,
                    strategy = CaptureStrategy.TranslatedFallback,
                )
            } else {
                if (!translatedBitmap.isRecycled) {
                    translatedBitmap.recycle()
                }
                BitmapCaptureResult(
                    bitmap = viewportBitmap,
                    nonWhiteRatio = viewportRatio,
                    sampleHash = viewportHash,
                    strategy = CaptureStrategy.Viewport,
                )
            }
        }

        private fun restoreScrollPosition(scrollX: Int, scrollY: Int) {
            webView.scrollTo(scrollX, scrollY)
            webView.post {
                webView.scrollTo(scrollX, scrollY)
            }
        }

        private fun scrollToAndWaitForDraw(
            scrollX: Int,
            scrollY: Int,
            callback: () -> Unit,
        ) {
            webView.scrollTo(scrollX, scrollY)
            webView.invalidate()

            val runCallback = {
                webView.postDelayed(
                    {
                        webView.invalidate()
                        callback()
                    },
                    captureDelayMs,
                )
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val requestId = ++visualStateRequestId
                webView.postVisualStateCallback(
                    requestId,
                    object : WebView.VisualStateCallback() {
                        override fun onComplete(requestId: Long) {
                            runCallback()
                        }
                    },
                )
                return
            }

            runCallback()
        }

        private fun captureVisibleViewportBitmap(
            webView: WebView,
            width: Int,
            height: Int,
        ): Bitmap {
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            canvas.drawColor(Color.WHITE)
            webView.draw(canvas)
            return bitmap
        }

        private fun captureTranslatedBitmap(
            webView: WebView,
            width: Int,
            height: Int,
        ): Bitmap {
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            canvas.drawColor(Color.WHITE)
            canvas.save()
            canvas.translate(-webView.scrollX.toFloat(), -webView.scrollY.toFloat())
            webView.draw(canvas)
            canvas.restore()
            return bitmap
        }

        private fun estimateNonWhiteRatio(bitmap: Bitmap): Double {
            val width = bitmap.width
            val height = bitmap.height
            if (width <= 0 || height <= 0) {
                return 0.0
            }

            val stepX = (width / 48).coerceAtLeast(1)
            val stepY = (height / 48).coerceAtLeast(1)
            var sampled = 0
            var nonWhite = 0

            var y = 0
            while (y < height) {
                var x = 0
                while (x < width) {
                    val color = bitmap.getPixel(x, y)
                    sampled++
                    val red = Color.red(color)
                    val green = Color.green(color)
                    val blue = Color.blue(color)
                    val alpha = Color.alpha(color)
                    if (alpha > 8 && (red < 248 || green < 248 || blue < 248)) {
                        nonWhite++
                    }
                    x += stepX
                }
                y += stepY
            }

            if (sampled == 0) {
                return 0.0
            }

            return nonWhite.toDouble() / sampled.toDouble()
        }

        private fun sampleHashForBitmap(bitmap: Bitmap): String {
            val width = bitmap.width
            val height = bitmap.height
            if (width <= 0 || height <= 0) {
                return "0"
            }

            val stepX = (width / 24).coerceAtLeast(1)
            val stepY = (height / 24).coerceAtLeast(1)
            var hash = 1_125_899_906_842_597L

            var y = 0
            while (y < height) {
                var x = 0
                while (x < width) {
                    val color = bitmap.getPixel(x, y)
                    hash = hash xor color.toLong()
                    hash *= 0x100000001b3L
                    x += stepX
                }
                y += stepY
            }

            return java.lang.Long.toHexString(hash)
        }

        private fun logRepeatedSampleHashIfNeeded(
            sampleHashes: List<String>,
            strategy: CaptureStrategy,
        ) {
            if (sampleHashes.size < 2 || sampleHashes.size > 3) {
                return
            }
            if (sampleHashes.distinct().size != 1) {
                return
            }

            Log.d(
                logTag,
                "capture repeated sampleHash pages=1..${sampleHashes.size} hash=${sampleHashes.first()} strategy=${strategy.logName}",
            )
        }

        private fun shouldRejectBlankCapture(nonWhiteRatios: List<Double>): Boolean {
            if (nonWhiteRatios.isEmpty()) {
                return true
            }

            if (nonWhiteRatios.all { it <= whiteCaptureThreshold }) {
                return true
            }

            val firstHasContent = nonWhiteRatios.first() > whiteCaptureThreshold
            val laterPages = nonWhiteRatios.drop(1)
            if (firstHasContent && laterPages.isNotEmpty() && laterPages.all { it <= whiteCaptureThreshold }) {
                return true
            }

            return false
        }

        private fun pdfPageSizeForBitmap(bitmap: Bitmap): Pair<Int, Int> {
            val density = webView.resources.displayMetrics.density.takeIf { it > 0f } ?: 1f
            val pageWidth = (bitmap.width / density).roundToInt().coerceAtLeast(1)
            val pageHeight = (bitmap.height / density).roundToInt().coerceAtLeast(1)
            return pageWidth to pageHeight
        }

        private fun estimateRequiredPages(
            scrollRange: Int,
            scrollExtent: Int,
            stepPx: Int,
        ): Int {
            val safeExtent = scrollExtent.coerceAtLeast(1)
            val safeStepPx = stepPx.coerceAtLeast(1)
            val maxOffset = (scrollRange - safeExtent).coerceAtLeast(0)
            if (maxOffset == 0) {
                return 1
            }
            return 1 + ((maxOffset + safeStepPx - 1) / safeStepPx)
        }

        private fun determineMaxCapturePages(estimatedPages: Int): Int {
            return (estimatedPages + capturePageBuffer)
                .coerceAtLeast(minCapturePages)
                .coerceAtMost(maxCapturePagesSafetyLimit)
        }

        private fun writeDebugBitmapIfNeeded(
            bitmap: Bitmap,
            pageIndex: Int,
            isLastPage: Boolean,
        ) {
            val shouldWriteDebugBitmap =
                pageIndex <= 3 ||
                    pageIndex == 10 ||
                    isLastPage
            if (!shouldWriteDebugBitmap) {
                return
            }

            val fileName = if (isLastPage) {
                "url_snapshot_debug_page_last_${pageIndex}.png"
            } else {
                "url_snapshot_debug_page_${pageIndex}.png"
            }
            val debugFile = File(webView.context.cacheDir, fileName)
            try {
                FileOutputStream(debugFile).use { outputStream ->
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
                    outputStream.flush()
                }
                Log.d(
                    logTag,
                    "debug bitmap saved page=$pageIndex path=${debugFile.absolutePath}",
                )
            } catch (exception: Exception) {
                Log.d(
                    logTag,
                    "debug bitmap save failed page=$pageIndex message=${exception.message}",
                )
            }
        }

        private class SnapshotCaptureWebView(
            context: Context,
        ) : WebView(context) {
            fun verticalScrollOffsetPx(): Int = computeVerticalScrollOffset()

            fun verticalScrollExtentPx(): Int = computeVerticalScrollExtent()

            fun verticalScrollRangePx(): Int = computeVerticalScrollRange()
        }
    }
}
