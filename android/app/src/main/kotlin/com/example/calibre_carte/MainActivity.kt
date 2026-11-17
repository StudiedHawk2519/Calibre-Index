package com.calibre_carte.app

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.webkit.MimeTypeMap
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.util.concurrent.Executors
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "calibre_index/download_storage"
        private const val PICK_DIRECTORY_REQUEST = 52041
    }

    private val ioExecutor = Executors.newSingleThreadExecutor()
    private var directoryPickerResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickDirectory" -> pickDirectory(result)
                "listFiles" -> runStorageOperation(result) {
                    listChildFileNames(call.requiredString("directoryUri"))
                }
                "deleteFile" -> runStorageOperation(result) {
                    val directoryUri = call.requiredString("directoryUri")
                    val fileName = call.requiredString("fileName")
                    val fileUri = findChildDocumentUri(directoryUri, fileName)
                        ?: return@runStorageOperation false
                    DocumentsContract.deleteDocument(contentResolver, fileUri)
                }
                "writeFile" -> runStorageOperation(result) {
                    val directoryUri = call.requiredString("directoryUri")
                    val sourcePath = call.requiredString("sourcePath")
                    val fileName = call.requiredString("fileName")
                    val mimeType = call.requiredString("mimeType")
                    writeFile(directoryUri, sourcePath, fileName, mimeType)
                    true
                }
                "openFile" -> openFile(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun pickDirectory(result: MethodChannel.Result) {
        if (directoryPickerResult != null) {
            result.error("picker_active", "A folder picker is already open.", null)
            return
        }

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PREFIX_URI_PERMISSION,
            )
        }

        directoryPickerResult = result
        try {
            startActivityForResult(intent, PICK_DIRECTORY_REQUEST)
        } catch (error: ActivityNotFoundException) {
            directoryPickerResult = null
            result.error("picker_unavailable", error.message, null)
        }
    }

    @Deprecated("Deprecated in Android")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_DIRECTORY_REQUEST) return

        val result = directoryPickerResult ?: return
        directoryPickerResult = null
        val directoryUri = data?.data
        if (resultCode != Activity.RESULT_OK || directoryUri == null) {
            result.success(null)
            return
        }

        val grantFlags = data.flags and (
            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
        try {
            contentResolver.takePersistableUriPermission(directoryUri, grantFlags)
            result.success(directoryUri.toString())
        } catch (error: SecurityException) {
            result.error("permission_denied", error.message, null)
        }
    }

    private fun openFile(call: MethodCall, result: MethodChannel.Result) {
        val directoryUri = call.argument<String>("directoryUri")
        val fileName = call.argument<String>("fileName")
        if (directoryUri == null || fileName == null) {
            result.error("invalid_arguments", "A folder and file name are required.", null)
            return
        }

        ioExecutor.execute {
            try {
                val fileUri = findChildDocumentUri(directoryUri, fileName)
                runOnUiThread {
                    if (fileUri == null) {
                        result.success(false)
                        return@runOnUiThread
                    }

                    val extension = fileName.substringAfterLast('.', "")
                    val mimeType = contentResolver.getType(fileUri)
                        ?: MimeTypeMap.getSingleton()
                            .getMimeTypeFromExtension(extension.lowercase())
                        ?: "application/octet-stream"
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(fileUri, mimeType)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    try {
                        startActivity(intent)
                        result.success(true)
                    } catch (error: ActivityNotFoundException) {
                        result.success(false)
                    }
                }
            } catch (error: Exception) {
                result.error("open_failed", error.message, null)
            }
        }
    }

    private fun runStorageOperation(
        result: MethodChannel.Result,
        operation: () -> Any?,
    ) {
        ioExecutor.execute {
            try {
                result.success(operation())
            } catch (error: Exception) {
                result.error("storage_failed", error.message, null)
            }
        }
    }

    private fun findChildDocumentUri(
        directoryUriString: String,
        fileName: String,
    ): Uri? {
        val treeUri = Uri.parse(directoryUriString)
        val treeDocumentId = DocumentsContract.getTreeDocumentId(treeUri)
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            treeDocumentId,
        )
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
        )

        contentResolver.query(childrenUri, projection, null, null, null)?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            )
            val nameColumn = cursor.getColumnIndexOrThrow(
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            )
            while (cursor.moveToNext()) {
                if (cursor.getString(nameColumn) == fileName) {
                    return DocumentsContract.buildDocumentUriUsingTree(
                        treeUri,
                        cursor.getString(idColumn),
                    )
                }
            }
        }
        return null
    }

    private fun listChildFileNames(directoryUriString: String): List<String> {
        val treeUri = Uri.parse(directoryUriString)
        val treeDocumentId = DocumentsContract.getTreeDocumentId(treeUri)
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            treeDocumentId,
        )
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
        )
        val fileNames = mutableListOf<String>()

        contentResolver.query(childrenUri, projection, null, null, null)?.use { cursor ->
            val nameColumn = cursor.getColumnIndexOrThrow(
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            )
            val mimeColumn = cursor.getColumnIndexOrThrow(
                DocumentsContract.Document.COLUMN_MIME_TYPE,
            )
            while (cursor.moveToNext()) {
                if (
                    cursor.getString(mimeColumn) !=
                    DocumentsContract.Document.MIME_TYPE_DIR
                ) {
                    fileNames.add(cursor.getString(nameColumn))
                }
            }
        }
        return fileNames
    }

    private fun writeFile(
        directoryUriString: String,
        sourcePath: String,
        fileName: String,
        mimeType: String,
    ) {
        val treeUri = Uri.parse(directoryUriString)
        val treeDocumentId = DocumentsContract.getTreeDocumentId(treeUri)
        val targetUri = findChildDocumentUri(directoryUriString, fileName)
            ?: DocumentsContract.createDocument(
                contentResolver,
                DocumentsContract.buildDocumentUriUsingTree(treeUri, treeDocumentId),
                mimeType,
                fileName,
            )
            ?: throw IOException("The selected folder could not create the book file.")

        val sourceFile = File(sourcePath)
        if (!sourceFile.isFile) {
            throw IOException("The downloaded book file could not be found.")
        }
        val output = contentResolver.openOutputStream(targetUri, "wt")
            ?: throw IOException("The selected folder could not open the book file.")
        output.use { stream ->
            FileInputStream(sourceFile).use { input ->
                input.copyTo(stream)
            }
        }
    }

    private fun MethodCall.requiredString(key: String): String {
        return argument<String>(key)
            ?: throw IllegalArgumentException("Missing required argument: $key")
    }
}
