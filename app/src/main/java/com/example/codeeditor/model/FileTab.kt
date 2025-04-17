package com.example.codeeditor.model

import android.net.Uri
import java.io.File

/**
 * Represents a file tab in the editor
 * 
 * @param name The display name of the tab (usually the filename)
 * @param file The associated file (if any)
 * @param isUnsaved Whether the file has unsaved changes
 */
class FileTab(
    var name: String,
    var file: File?,
    var isUnsaved: Boolean
) {
    var uri: Uri? = null
    var content: String? = null
    
    /**
     * Get a short name for the tab display
     * If the name is too long, it will be truncated for display purposes
     */
    fun getShortName(): String {
        return if (name.length > 15) {
            name.substring(0, 12) + "..."
        } else {
            name
        }
    }
    
    /**
     * Get the file extension or empty string if no extension
     */
    fun getFileExtension(): String {
        val lastDot = name.lastIndexOf('.')
        return if (lastDot > 0) {
            name.substring(lastDot + 1).lowercase()
        } else {
            ""
        }
    }
}