package com.example.codeeditor.utils

import android.content.Context
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.MediaStore
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

/**
 * Utility class for file operations
 */
object FileUtils {
    
    /**
     * Get the file path from a content URI
     */
    fun getPathFromUri(context: Context, uri: Uri): String? {
        // Handle DocumentProvider
        if (DocumentsContract.isDocumentUri(context, uri)) {
            // ExternalStorageProvider
            if (isExternalStorageDocument(uri)) {
                val docId = DocumentsContract.getDocumentId(uri)
                val split = docId.split(":")
                val type = split[0]
                
                if ("primary".equals(type, ignoreCase = true)) {
                    return "${context.getExternalFilesDir(null)}/${split[1]}"
                }
            } 
            // MediaProvider
            else if (isMediaDocument(uri)) {
                val docId = DocumentsContract.getDocumentId(uri)
                val split = docId.split(":")
                val contentUri = when (split[0]) {
                    "image" -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                    "video" -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                    "audio" -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                    else -> null
                }
                
                contentUri?.let {
                    val selection = "_id=?"
                    val selectionArgs = arrayOf(split[1])
                    return getDataColumn(context, contentUri, selection, selectionArgs)
                }
            }
            // DownloadsProvider
            else if (isDownloadsDocument(uri)) {
                val id = DocumentsContract.getDocumentId(uri)
                val contentUri = Uri.parse("content://downloads/public_downloads")
                return getDataColumn(context, contentUri, "_id=?", arrayOf(id))
            }
        } 
        // MediaStore (general)
        else if ("content".equals(uri.scheme, ignoreCase = true)) {
            return getDataColumn(context, uri, null, null)
        } 
        // File
        else if ("file".equals(uri.scheme, ignoreCase = true)) {
            return uri.path
        }
        
        // If we can't resolve the path, create a temp file with the content
        return try {
            val inputStream = context.contentResolver.openInputStream(uri)
            if (inputStream != null) {
                val fileName = getFileNameFromUri(context, uri) ?: "temp_file"
                val tempFile = File(context.cacheDir, fileName)
                
                FileOutputStream(tempFile).use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
                
                tempFile.absolutePath
            } else {
                null
            }
        } catch (e: IOException) {
            e.printStackTrace()
            null
        }
    }
    
    /**
     * Get file name from URI
     */
    private fun getFileNameFromUri(context: Context, uri: Uri): String? {
        var fileName: String? = null
        
        context.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val nameIndex = cursor.getColumnIndex(MediaStore.MediaColumns.DISPLAY_NAME)
                if (nameIndex >= 0) {
                    fileName = cursor.getString(nameIndex)
                }
            }
        }
        
        return fileName
    }
    
    private fun getDataColumn(
        context: Context, 
        uri: Uri, 
        selection: String?, 
        selectionArgs: Array<String>?
    ): String? {
        val column = "_data"
        val projection = arrayOf(column)
        
        context.contentResolver.query(uri, projection, selection, selectionArgs, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val columnIndex = cursor.getColumnIndexOrThrow(column)
                return cursor.getString(columnIndex)
            }
        }
        
        return null
    }
    
    private fun isExternalStorageDocument(uri: Uri): Boolean {
        return "com.android.externalstorage.documents" == uri.authority
    }
    
    private fun isDownloadsDocument(uri: Uri): Boolean {
        return "com.android.providers.downloads.documents" == uri.authority
    }
    
    private fun isMediaDocument(uri: Uri): Boolean {
        return "com.android.providers.media.documents" == uri.authority
    }
    
    /**
     * Get file extension
     */
    fun getFileExtension(fileName: String): String {
        return fileName.substringAfterLast('.', "txt")
    }
}
