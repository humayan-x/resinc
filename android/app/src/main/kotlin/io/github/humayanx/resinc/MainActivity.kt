package io.github.humayanx.resinc

import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "io.github.humayanx.resinc/gallery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "getExistingGalleryImages" -> {
                    val fileNames = call.argument<List<String>>("fileNames") ?: emptyList()
                    val existing = checkExistingImages(fileNames)
                    result.success(existing)
                }
                "isImageInGallery" -> {
                    val fileName = call.argument<String>("fileName")
                    if (fileName == null) {
                        result.success(false)
                    } else {
                        result.success(checkExistingImages(listOf(fileName)).contains(fileName))
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun checkExistingImages(fileNames: List<String>): List<String> {
        if (fileNames.isEmpty()) return emptyList()

        val existing = mutableSetOf<String>()
        val picturesDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), "ReSinc")
        val dcimDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM), "ReSinc")

        for (name in fileNames) {
            try {
                if (File(picturesDir, name).exists() || File(dcimDir, name).exists()) {
                    existing.add(name)
                }
            } catch (_: Exception) {}
        }

        val remaining = fileNames.filter { !existing.contains(it) }
        if (remaining.isNotEmpty()) {
            try {
                val projection = arrayOf(MediaStore.Images.Media.DISPLAY_NAME)
                remaining.chunked(50).forEach { chunk ->
                    val placeholders = chunk.joinToString(",") { "?" }
                    val selection = "${MediaStore.Images.Media.DISPLAY_NAME} IN ($placeholders)"
                    val selectionArgs = chunk.toTypedArray()

                    contentResolver.query(
                        MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                        projection,
                        selection,
                        selectionArgs,
                        null
                    )?.use { cursor ->
                        val nameIndex = cursor.getColumnIndex(MediaStore.Images.Media.DISPLAY_NAME)
                        if (nameIndex != -1) {
                            while (cursor.moveToNext()) {
                                val name = cursor.getString(nameIndex)
                                if (name != null) {
                                    existing.add(name)
                                }
                            }
                        }
                    }
                }
            } catch (_: Exception) {}
        }

        return existing.toList()
    }
}
