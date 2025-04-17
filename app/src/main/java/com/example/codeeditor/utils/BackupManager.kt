package com.example.codeeditor.utils

import android.content.Context
import com.example.codeeditor.model.FileTab
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.ObjectInputStream
import java.io.ObjectOutputStream
import java.io.Serializable

/**
 * Manages auto-backup functionality
 */
class BackupManager(private val context: Context) {
    
    /**
     * Create a backup of the given tab
     */
    fun createBackup(tab: FileTab) {
        val backupDir = File(context.filesDir, BACKUP_DIR)
        if (!backupDir.exists()) {
            backupDir.mkdirs()
        }
        
        // Create a serializable backup object
        val backup = TabBackup(
            name = tab.name,
            content = tab.content,
            filePath = tab.file?.absolutePath,
            isNew = tab.isNew,
            timestamp = System.currentTimeMillis()
        )
        
        // Generate a unique filename for the backup
        val backupId = if (tab.file != null) {
            // Use file path hash for existing files
            tab.file.absolutePath.hashCode().toString()
        } else {
            // Use content hash for new files
            tab.content.hashCode().toString() + "_new"
        }
        
        val backupFile = File(backupDir, "$backupId.backup")
        
        try {
            FileOutputStream(backupFile).use { fileOut ->
                ObjectOutputStream(fileOut).use { objectOut ->
                    objectOut.writeObject(backup)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    /**
     * Check for backups that need to be restored (unsaved files)
     * Returns a list of tabs created from backups
     */
    fun checkForBackups(): List<FileTab> {
        val restoredTabs = mutableListOf<FileTab>()
        val backupDir = File(context.filesDir, BACKUP_DIR)
        
        if (backupDir.exists()) {
            val backupFiles = backupDir.listFiles { file -> 
                file.name.endsWith(".backup") 
            }
            
            backupFiles?.forEach { backupFile ->
                try {
                    FileInputStream(backupFile).use { fileIn ->
                        ObjectInputStream(fileIn).use { objectIn ->
                            val backup = objectIn.readObject() as TabBackup
                            
                            // Only restore if it's a new file or the original file doesn't exist
                            val originalFile = backup.filePath?.let { File(it) }
                            if (backup.isNew || (originalFile == null || !originalFile.exists())) {
                                val tab = FileTab(
                                    name = backup.name,
                                    content = backup.content,
                                    file = originalFile,
                                    isModified = true,
                                    isNew = backup.isNew
                                )
                                restoredTabs.add(tab)
                            }
                        }
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
        
        return restoredTabs
    }
    
    /**
     * Clean up old backups (call periodically)
     */
    fun cleanupOldBackups() {
        val backupDir = File(context.filesDir, BACKUP_DIR)
        if (backupDir.exists()) {
            val currentTime = System.currentTimeMillis()
            val maxAge = 7 * 24 * 60 * 60 * 1000L // 7 days
            
            backupDir.listFiles { file -> 
                file.name.endsWith(".backup") 
            }?.forEach { backupFile ->
                try {
                    FileInputStream(backupFile).use { fileIn ->
                        ObjectInputStream(fileIn).use { objectIn ->
                            val backup = objectIn.readObject() as TabBackup
                            
                            if (currentTime - backup.timestamp > maxAge) {
                                backupFile.delete()
                            }
                        }
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }
    
    /**
     * Serializable class for storing tab backups
     */
    data class TabBackup(
        val name: String,
        val content: String,
        val filePath: String?,
        val isNew: Boolean,
        val timestamp: Long
    ) : Serializable
    
    companion object {
        private const val BACKUP_DIR = "backups"
    }
}
