package io.github.humayanx.resinc

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.os.Looper
import android.os.SystemClock
import androidx.exifinterface.media.ExifInterface
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.io.File
import kotlin.math.*

/** A serial background queue bounds memory while keeping both UI threads free. */
class ImageProcessor(messenger: BinaryMessenger) {
    private val channel = MethodChannel(
        messenger, "io.github.humayanx.resinc/images",
        StandardMethodCodec.INSTANCE, messenger.makeBackgroundTaskQueue()
    )

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method != "process") {
                result.notImplemented()
            } else {
                try {
                    @Suppress("UNCHECKED_CAST")
                    result.success(process(call.arguments as Map<String, Any?>))
                } catch (error: Exception) {
                    result.error("image_processing_failed", error.message, null)
                } catch (_: OutOfMemoryError) {
                    result.error("image_memory", "Not enough memory to process this photo.", null)
                }
            }
        }
    }

    fun close() = channel.setMethodCallHandler(null)

    companion object {
        /** Paths and small settings cross the channel, never image buffers. */
        fun process(args: Map<String, Any?>): Map<String, Any> {
            check(Looper.myLooper() != Looper.getMainLooper()) { "Image processing must run off the UI thread" }
            val start = SystemClock.elapsedRealtime()
            val source = args["source"] as String
            val output = File(args["output"] as String)
            require(File(source).canonicalPath != output.canonicalPath)
            val limit = (args["maxDimension"] as? Number)?.toInt() ?: 2560
            val budget = (args["budget"] as? Number)?.toLong()
            require(limit > 0 && (budget == null || budget > 0))
            val quality = ((args["quality"] as? Number)?.toInt() ?: 85).coerceIn(45, 95)
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(source, bounds)
            require(bounds.outWidth > 0 && bounds.outHeight > 0) { "Unsupported image" }
            val scale = min(1.0, min(min(limit, 2560).toDouble() / max(bounds.outWidth, bounds.outHeight),
                sqrt(4_000_000.0 / (bounds.outWidth.toDouble() * bounds.outHeight))))
            // Native sampled decode avoids a full-resolution camera bitmap. A
            // final filtered draw provides exact dimensions without upscaling.
            var sample = 1
            while (sample * 2 <= 1.0 / scale) sample *= 2
            val decode = BitmapFactory.Options().apply {
                inSampleSize = sample
                inPreferredConfig = Bitmap.Config.ARGB_8888
            }
            var original: Bitmap? = null
            var base: Bitmap? = null
            var resized: Bitmap? = null
            try {
                var image = BitmapFactory.decodeFile(source, decode)
                    ?: error("Cannot decode this image")
                original = image
                val exif = try { ExifInterface(source) } catch (_: Exception) { null }
                if (exif != null && (exif.rotationDegrees != 0 || exif.isFlipped)) {
                    val matrix = Matrix()
                    if (exif.isFlipped) matrix.postScale(-1f, 1f)
                    matrix.postRotate(exif.rotationDegrees.toFloat())
                    val oriented = Bitmap.createBitmap(image, 0, 0, image.width, image.height, matrix, true)
                    if (oriented !== image) image.recycle()
                    image = oriented
                    original = image
                }
                val rotated = exif != null && exif.rotationDegrees % 180 != 0
                val fullWidth = max(1, floor((if (rotated) bounds.outHeight else bounds.outWidth) * scale).toInt())
                val fullHeight = max(1, floor((if (rotated) bounds.outWidth else bounds.outHeight) * scale).toInt())
                @Suppress("UNCHECKED_CAST")
                val crop = (args["crop"] as? List<Number>)?.map { it.toDouble() }
                    ?: listOf(0.0, 0.0, 1.0, 1.0)
                require(crop.size == 4 && crop.all { it.isFinite() && it in 0.0..1.0 }
                    && crop[2] > crop[0] && crop[3] > crop[1]) { "Invalid crop" }
                val rect = Rect(
                    floor(crop[0] * image.width).toInt().coerceIn(0, image.width - 1),
                    floor(crop[1] * image.height).toInt().coerceIn(0, image.height - 1),
                    ceil(crop[2] * image.width).toInt().coerceIn(1, image.width),
                    ceil(crop[3] * image.height).toInt().coerceIn(1, image.height)
                )
                val width = max(1, ceil(crop[2] * fullWidth).toInt() - floor(crop[0] * fullWidth).toInt())
                val height = max(1, ceil(crop[3] * fullHeight).toInt() - floor(crop[1] * fullHeight).toInt())
                val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                base = bitmap
                Canvas(bitmap).apply {
                    drawColor(Color.WHITE)
                    drawBitmap(image, rect, RectF(0f, 0f, width.toFloat(), height.toFloat()),
                        Paint(Paint.FILTER_BITMAP_FLAG))
                }
                image.recycle()
                original = null
                var current = bitmap
                var attempts = 0
                var resizeScale = 1.0
                val qualities = if (budget == null) listOf(quality)
                    else listOf(quality, min(quality, 65), 45).distinct()
                @Suppress("UNCHECKED_CAST")
                val attributes = args["exif"] as? Map<String, Any?> ?: emptyMap()
                output.parentFile?.mkdirs()
                repeat(24) {
                    var size = 0L
                    for (q in qualities) {
                        attempts++
                        output.outputStream().use { stream ->
                            check(current.compress(Bitmap.CompressFormat.JPEG, q, stream)) { "JPEG encoding failed" }
                        }
                        // Metadata must be included in the measured byte ceiling.
                        if (args["keepExif"] == true && attributes.isNotEmpty()) {
                            ExifInterface(output.path).apply {
                                attributes.forEach { (key, value) ->
                                    if (!key.contains("thumbnail", ignoreCase = true) && value != null) {
                                        setAttribute(key, value.toString())
                                    }
                                }
                                setAttribute("Orientation", "1")
                                setAttribute("ImageWidth", current.width.toString())
                                setAttribute("ImageLength", current.height.toString())
                                setAttribute("PixelXDimension", current.width.toString())
                                setAttribute("PixelYDimension", current.height.toString())
                                saveAttributes()
                            }
                        }
                        size = output.length()
                        check(size > 0) { "Empty JPEG output" }
                        if (budget == null || size <= budget) {
                            return mapOf("width" to current.width, "height" to current.height,
                                "bytes" to size, "attempts" to attempts,
                                "elapsedMs" to (SystemClock.elapsedRealtime() - start))
                        }
                    }
                    check(current.width > 1 || current.height > 1) { "Cannot meet this file size" }
                    resizeScale *= (sqrt(budget!!.toDouble() / size).coerceIn(.4, .9) * .95)
                    val w = max(1, floor(width * resizeScale).toInt())
                    val h = max(1, floor(height * resizeScale).toInt())
                    resized?.recycle()
                    // Resize from the retained original crop, never from a JPEG.
                    current = Bitmap.createScaledBitmap(bitmap, w, h, true)
                    resized = if (current !== bitmap) current else null
                }
                error("Cannot meet this file size")
            } catch (error: Throwable) {
                output.delete()
                throw error
            } finally {
                resized?.recycle()
                base?.recycle()
                original?.recycle()
            }
        }
    }
}
