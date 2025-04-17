package com.example.codeeditor.model

import android.content.Context
import android.content.SharedPreferences

/**
 * Class to handle editor settings and persistence
 */
class EditorSettings(context: Context) {
    
    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    
    /**
     * Dark theme enabled (default: true)
     */
    var darkTheme: Boolean
        get() = prefs.getBoolean(KEY_DARK_THEME, true)
        set(value) = prefs.edit().putBoolean(KEY_DARK_THEME, value).apply()
    
    /**
     * Editor font size in sp (default: 14sp)
     */
    var fontSize: Float
        get() = prefs.getFloat(KEY_FONT_SIZE, 14f)
        set(value) = prefs.edit().putFloat(KEY_FONT_SIZE, value).apply()
    
    /**
     * Backup interval in minutes (default: 1 minute)
     */
    var backupIntervalMinutes: Int
        get() = prefs.getInt(KEY_BACKUP_INTERVAL, 1)
        set(value) = prefs.edit().putInt(KEY_BACKUP_INTERVAL, value).apply()
    
    /**
     * Drawer position (bottom, left, right)
     */
    var drawerPosition: String
        get() = prefs.getString(KEY_DRAWER_POSITION, "bottom") ?: "bottom"
        set(value) = prefs.edit().putString(KEY_DRAWER_POSITION, value).apply()
    
    /**
     * Show drawer handle (default: true)
     */
    var showDrawerHandle: Boolean
        get() = prefs.getBoolean(KEY_SHOW_HANDLE, true)
        set(value) = prefs.edit().putBoolean(KEY_SHOW_HANDLE, value).apply()
    
    /**
     * Path to last opened file (default: empty)
     */
    var lastOpenedFilePath: String
        get() = prefs.getString(KEY_LAST_OPENED_FILE, "") ?: ""
        set(value) = prefs.edit().putString(KEY_LAST_OPENED_FILE, value).apply()
    
    /**
     * Line numbers visible (default: true)
     */
    var showLineNumbers: Boolean
        get() = prefs.getBoolean(KEY_SHOW_LINE_NUMBERS, true)
        set(value) = prefs.edit().putBoolean(KEY_SHOW_LINE_NUMBERS, value).apply()
    
    companion object {
        private const val PREFS_NAME = "editor_settings"
        private const val KEY_DARK_THEME = "dark_theme"
        private const val KEY_FONT_SIZE = "font_size"
        private const val KEY_BACKUP_INTERVAL = "backup_interval"
        private const val KEY_DRAWER_POSITION = "drawer_position"
        private const val KEY_SHOW_HANDLE = "show_handle"
        private const val KEY_LAST_OPENED_FILE = "last_opened_file"
        private const val KEY_SHOW_LINE_NUMBERS = "show_line_numbers"
    }
}