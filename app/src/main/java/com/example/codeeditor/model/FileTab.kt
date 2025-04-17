package com.example.codeeditor.model

import java.io.File

/**
 * Represents a tab in the editor
 *
 * @property name The display name of the tab
 * @property content The text content in the tab
 * @property file The file associated with the tab (null if new/unsaved)
 * @property isModified Flag indicating if content has been modified since last save
 * @property isNew Flag indicating if this is a new file (never saved)
 */
data class FileTab(
    var name: String,
    var content: String,
    var file: File?,
    var isModified: Boolean,
    var isNew: Boolean
) {
    /**
     * Returns a shortened version of the name for tab display
     */
    fun getShortName(): String {
        return if (name.length > 10) {
            name.take(7) + "..."
        } else {
            name
        }
    }
}
