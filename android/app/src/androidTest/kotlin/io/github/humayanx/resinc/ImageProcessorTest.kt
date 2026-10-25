package io.github.humayanx.resinc

import android.graphics.*
import android.os.SystemClock
import android.util.Log
import androidx.exifinterface.media.ExifInterface
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Test
import java.io.File
import java.util.Random

class ImageProcessorTest {
    private fun withDirectory(test: (File) -> Unit) {
        val dir = File(InstrumentationRegistry.getInstrumentation().targetContext.cacheDir,
            "image_test_${System.nanoTime()}").apply { mkdirs() }
        try { test(dir) } finally { dir.deleteRecursively() }
    }

    @Test fun orientationCropAndMetadata() = withDirectory { dir ->
        val source = File(dir, "source.jpg")
        val bitmap = Bitmap.createBitmap(80, 40, Bitmap.Config.ARGB_8888)
        Canvas(bitmap).apply {
            drawColor(Color.RED)
            drawRect(40f, 0f, 80f, 40f, Paint().apply { color = Color.BLUE })
        }
        source.outputStream().use { bitmap.compress(Bitmap.CompressFormat.JPEG, 95, it) }
        bitmap.recycle()
        ExifInterface(source.path).apply {
            setAttribute("Orientation", "6")
            setAttribute("Artist", "ReSinc test")
            setLatLong(12.0, 77.0)
            saveAttributes()
        }
        val before = source.readBytes()
        val crop = File(dir, "crop.jpg")
        val result = ImageProcessor.process(mapOf("source" to source.path, "output" to crop.path,
            "crop" to listOf(0.0, 0.0, 1.0, .5), "budget" to source.length()))
        assertEquals(40, result["width"])
        assertEquals(40, result["height"])
        assertTrue(crop.length() <= source.length())
        val decoded = BitmapFactory.decodeFile(crop.path)
        assertTrue(Color.red(decoded.getPixel(20, 20)) > 200)
        decoded.recycle()
        assertNull(ExifInterface(crop.path).getAttribute("Artist"))
        assertNull(ExifInterface(crop.path).latLong)
        val kept = File(dir, "kept.jpg")
        ImageProcessor.process(mapOf("source" to source.path, "output" to kept.path,
            "keepExif" to true, "exif" to mapOf("Artist" to "ReSinc test", "Orientation" to "6"),
            "budget" to 10000))
        assertEquals("ReSinc test", ExifInterface(kept.path).getAttribute("Artist"))
        assertEquals(1, ExifInterface(kept.path).getAttributeInt("Orientation", 0))
        assertArrayEquals(before, source.readBytes())
    }

    @Test fun photoSizeLimitsAndTiming() = withDirectory { dir ->
        val source = File(dir, "photo.jpg")
        val bitmap = Bitmap.createBitmap(4000, 3000, Bitmap.Config.ARGB_8888)
        val random = Random(42)
        val row = IntArray(4000)
        for (y in 0 until 3000) {
            for (x in row.indices) row[x] = Color.rgb(random.nextInt(256), random.nextInt(256), random.nextInt(256))
            bitmap.setPixels(row, 0, 4000, 0, y, 4000, 1)
        }
        source.outputStream().use { bitmap.compress(Bitmap.CompressFormat.JPEG, 90, it) }
        bitmap.recycle()
        for (crop in listOf(true, false)) {
            val output = File(dir, if (crop) "crop.jpg" else "optimized.jpg")
            val budget = if (crop) source.length() else 198000L
            val args = mutableMapOf<String, Any?>("source" to source.path, "output" to output.path, "budget" to budget)
            if (crop) args["crop"] = listOf(.1, .1, .9, .9)
            val start = SystemClock.elapsedRealtime()
            val result = ImageProcessor.process(args)
            val elapsed = SystemClock.elapsedRealtime() - start
            assertTrue(output.length() in 1..budget)
            val decoded = BitmapFactory.decodeFile(output.path)
            assertEquals(decoded.width, result["width"])
            assertEquals(decoded.height, result["height"])
            assertTrue(decoded.width.toLong() * decoded.height <= 4_000_000)
            decoded.recycle()
            Log.i("ReSincBenchmark", "crop=$crop elapsedMs=$elapsed bytes=${output.length()} attempts=${result["attempts"]}")
        }
        val resolution = File(dir, "resolution.jpg")
        val result = ImageProcessor.process(mapOf("source" to source.path, "output" to resolution.path,
            "maxDimension" to 1280, "quality" to 80))
        assertEquals(1280, result["width"])
        assertEquals(960, result["height"])
        assertEquals(1, result["attempts"])
    }

    @Test fun failedJobRemovesOutput() = withDirectory { dir ->
        val source = File(dir, "source.png")
        val bitmap = Bitmap.createBitmap(20, 20, Bitmap.Config.ARGB_8888)
        source.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
        bitmap.recycle()
        val output = File(dir, "output.jpg")
        try {
            ImageProcessor.process(mapOf("source" to source.path, "output" to output.path, "budget" to 1))
            fail("Impossible ceiling must fail")
        } catch (_: IllegalStateException) {
            assertFalse(output.exists())
        }
    }
}
