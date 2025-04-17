package com.example.codeeditor.utils

import android.content.Context
import java.io.File

/**
 * Manages automatic backups of unsaved files
 */
class BackupManager(private val context: Context) {
    
    private val backupDirectory: File
        get() {
            val dir = File(context.filesDir, BACKUP_DIR)
            if (!dir.exists()) {
                dir.mkdirs()
            }
            return dir
        }
    
    /**
     * Save a backup of a file
     */
    fun saveBackup(fileName: String, content: String) {
        val backupFile = File(backupDirectory, "$fileName.bak")
        backupFile.writeText(content)
    }
    
    /**
     * Get all backup files
     */
    fun getBackupFiles(): List<File> {
        val files = backupDirectory.listFiles { file ->
            file.name.endsWith(".bak")
        }
        return files?.toList() ?: emptyList()
    }
    
    /**
     * Read content from a backup file
     */
    fun readBackupFile(file: File): String {
        return file.readText()
    }
    
    /**
     * Delete a specific backup file
     */
    fun deleteBackup(fileName: String) {
        val backupFile = File(backupDirectory, "$fileName.bak")
        if (backupFile.exists()) {
            backupFile.delete()
        }
    }
    
    /**
     * Clear all backup files
     */
    fun clearAllBackups() {
        val files = backupDirectory.listFiles()
        files?.forEach { it.delete() }
    }
    
    companion object {
        private const val BACKUP_DIR = "backups"
    }
}