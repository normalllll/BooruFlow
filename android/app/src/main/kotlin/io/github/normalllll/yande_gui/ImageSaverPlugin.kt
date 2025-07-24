package io.github.normalllll.yande_gui


import android.content.ContentValues
import android.content.Context
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

class ImageSaverPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "image_saver")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "saveImage" -> {
                val filePath: String = call.argument<String>("filePath") ?: run {
                    result.error("ARG", "filePath is null", null); return
                }
                val fileName: String = call.argument<String>("fileName") ?: run {
                    result.error("ARG", "fileName is null", null); return
                }

                scope.launch {
                    val ok = withContext(Dispatchers.IO) {
                        context.saveImage(filePath, fileName)
                    }
                    result.success(ok)
                }
            }

            "existImage" -> {
                val fileName: String = call.argument<String>("fileName") ?: run {
                    result.error("ARG", "fileName is null", null); return
                }

                scope.launch {
                    val ok = withContext(Dispatchers.IO) {
                        context.imageIsExist(fileName, null)
                    }
                    result.success(ok)
                }
            }

            else -> result.notImplemented()
        }
    }

    private suspend fun Context.saveImage(filePath: String, fileName: String): Boolean =
        withContext(Dispatchers.IO) {

            val srcFile = File(filePath)
            if (!srcFile.exists()) return@withContext false

            if (imageIsExist(fileName, null)) {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                    val old =
                        File(
                            Environment.getExternalStoragePublicDirectory(
                                Environment.DIRECTORY_PICTURES
                            ), "Yande/$fileName"
                        )
                    if (old.exists()) old.delete()
                } else {
                    val where =
                        "${MediaStore.Images.Media.RELATIVE_PATH}=? AND ${MediaStore.Images.Media.DISPLAY_NAME}=?"
                    val args = arrayOf("${Environment.DIRECTORY_PICTURES}/Yande/", fileName)
                    contentResolver.delete(
                        MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                        where,
                        args
                    )
                }
            }

            /* --------- Android 9‑ (API‑28) File I/O --------- */
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                val targetDir =
                    File(
                        Environment.getExternalStoragePublicDirectory(
                            Environment.DIRECTORY_PICTURES
                        ), "Yande"
                    )
                if (!targetDir.exists() && !targetDir.mkdirs()) return@withContext false

                val dest = File(targetDir, fileName)
                srcFile.copyTo(dest, overwrite = true)

                MediaScannerConnection.scanFile(
                    this@saveImage,
                    arrayOf(dest.absolutePath),
                    arrayOf(
                        MimeTypeMap.getSingleton()
                            .getMimeTypeFromExtension(dest.extension)
                    )
                ) { _, _ -> }

                return@withContext true
            }

            /* --------- Android 10+ (Scoped Storage) MediaStore --------- */
            val mime = MimeTypeMap.getSingleton()
                .getMimeTypeFromExtension(fileName.substringAfterLast('.', "")) ?: "image/*"

            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mime)
                put(
                    MediaStore.MediaColumns.RELATIVE_PATH,
                    "${Environment.DIRECTORY_PICTURES}/Yande/"
                )
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }

            val uri = contentResolver.insert(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                values
            ) ?: return@withContext false

            try {
                contentResolver.openOutputStream(uri)?.use { out ->
                    srcFile.inputStream().use { it.copyTo(out) }
                } ?: return@withContext false


                values.clear()
                values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                contentResolver.update(uri, values, null, null)
                true
            } catch (e: Exception) {
                contentResolver.delete(uri, null, null)             // rollback
                false
            }
        }


    suspend fun Context.imageIsExist(fileName: String, fileSize: Long?): Boolean =
        withContext(Dispatchers.IO) {

            /* --------- Android 9‑ (API‑28) --------- */
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                val dir = File(
                    Environment.getExternalStoragePublicDirectory(
                        Environment.DIRECTORY_PICTURES
                    ), "Yande"
                )
                val file = File(dir, fileName)
                if (!dir.exists() || !file.exists()) return@withContext false
                return@withContext fileSize?.let { file.length() == it } ?: true
            }

            /* --------- Android 10+ (Scoped Storage) --------- */
            val where =
                "${MediaStore.Images.Media.RELATIVE_PATH}=? AND ${MediaStore.Images.Media.DISPLAY_NAME}=?"
            val args = arrayOf("${Environment.DIRECTORY_PICTURES}/Yande/", fileName)

            contentResolver.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                arrayOf(MediaStore.Images.Media.SIZE),
                where,
                args,
                null
            )?.use { cursor ->
                if (!cursor.moveToFirst()) return@withContext false
                val size = cursor.getLong(
                    cursor.getColumnIndexOrThrow(MediaStore.Images.Media.SIZE)
                )
                return@withContext fileSize?.let { size == it } ?: true
            } ?: false
        }
}

