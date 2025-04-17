package com.example.codeeditor.utils

import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.OpenableColumns
import java.io.BufferedReader
import java.io.File
import java.io.FileOutputStream
import java.io.InputStreamReader
import java.io.OutputStreamWriter

/**
 * Utility class for file operations
 */
object FileUtils {
    
    /**
     * Read file content from a File object
     */
    fun readFile(file: File): String {
        return file.readText()
    }
    
    /**
     * Read file content from a URI
     */
    fun readFile(context: Context, uri: Uri): String {
        val stringBuilder = StringBuilder()
        context.contentResolver.openInputStream(uri)?.use { inputStream ->
            BufferedReader(InputStreamReader(inputStream)).use { reader ->
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    stringBuilder.append(line)
                    stringBuilder.append("\n")
                }
            }
        }
        return stringBuilder.toString()
    }
    
    /**
     * Save content to a File
     */
    fun saveFile(file: File, content: String) {
        file.writeText(content)
    }
    
    /**
     * Save content to a URI
     */
    fun saveFile(context: Context, uri: Uri, content: String) {
        context.contentResolver.openOutputStream(uri)?.use { outputStream ->
            OutputStreamWriter(outputStream).use { writer ->
                writer.write(content)
            }
        }
    }
    
    /**
     * Get a filename from a URI
     */
    fun getFileName(context: Context, uri: Uri): String? {
        var result: String? = null
        if (uri.scheme == "content") {
            val cursor: Cursor? = context.contentResolver.query(uri, null, null, null, null)
            cursor?.use {
                if (it.moveToFirst()) {
                    val nameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (nameIndex != -1) {
                        result = it.getString(nameIndex)
                    }
                }
            }
        }
        if (result == null) {
            result = uri.path
            val cut = result?.lastIndexOf('/')
            if (cut != -1) {
                result = result?.substring(cut!! + 1)
            }
        }
        return result
    }
    
    /**
     * Get extension from a filename
     */
    fun getFileExtension(fileName: String): String {
        val lastDot = fileName.lastIndexOf('.')
        return if (lastDot > 0) {
            fileName.substring(lastDot + 1).lowercase()
        } else {
            ""
        }
    }
}