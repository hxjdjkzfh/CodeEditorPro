package com.example.codeeditor.model

import android.content.Context
import android.content.SharedPreferences

/**
 * Class to manage editor settings
 */
class EditorSettings(context: Context) {
    
    private val preferences: SharedPreferences = context.getSharedPreferences(
        PREFERENCES_NAME, Context.MODE_PRIVATE
    )
    
    // Theme settings
    var darkTheme: Boolean
        get() = preferences.getBoolean(KEY_DARK_THEME, true)
        set(value) = preferences.edit().putBoolean(KEY_DARK_THEME, value).apply()
    
    // Font size settings
    var fontSize: Float
        get() = preferences.getFloat(KEY_FONT_SIZE, 14f)
        set(value) = preferences.edit().putFloat(KEY_FONT_SIZE, value).apply()
    
    // Auto backup interval (in minutes)
    var backupIntervalMinutes: Int
        get() = preferences.getInt(KEY_BACKUP_INTERVAL, 1)
        set(value) = preferences.edit().putInt(KEY_BACKUP_INTERVAL, value).apply()
    
    // Drawer position ("left", "right", "bottom")
    var drawerPosition: String
        get() = preferences.getString(KEY_DRAWER_POSITION, "bottom") ?: "bottom"
        set(value) = preferences.edit().putString(KEY_DRAWER_POSITION, value).apply()
    
    // Show drawer handle
    var showDrawerHandle: Boolean
        get() = preferences.getBoolean(KEY_SHOW_DRAWER_HANDLE, true)
        set(value) = preferences.edit().putBoolean(KEY_SHOW_DRAWER_HANDLE, value).apply()
    
    // Last opened file path
    var lastOpenedFilePath: String
        get() = preferences.getString(KEY_LAST_FILE_PATH, "") ?: ""
        set(value) = preferences.edit().putString(KEY_LAST_FILE_PATH, value).apply()
    
    // Last cursor position
    var lastCursorPosition: Int
        get() = preferences.getInt(KEY_LAST_CURSOR_POSITION, 0)
        set(value) = preferences.edit().putInt(KEY_LAST_CURSOR_POSITION, value).apply()
    
    companion object {
        private const val PREFERENCES_NAME = "editor_settings"
        private const val KEY_DARK_THEME = "dark_theme"
        private const val KEY_FONT_SIZE = "font_size"
        private const val KEY_BACKUP_INTERVAL = "backup_interval"
        private const val KEY_DRAWER_POSITION = "drawer_position"
        private const val KEY_SHOW_DRAWER_HANDLE = "show_drawer_handle"
        private const val KEY_LAST_FILE_PATH = "last_file_path"
        private const val KEY_LAST_CURSOR_POSITION = "last_cursor_position"
    }
}
