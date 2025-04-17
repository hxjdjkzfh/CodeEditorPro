package com.example.codeeditor

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.ImageButton
import android.widget.LinearLayout
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.RecyclerView
import com.example.codeeditor.adapters.TabAdapter
import com.example.codeeditor.fragments.AboutFragment
import com.example.codeeditor.fragments.SettingsFragment
import com.example.codeeditor.model.EditorSettings
import com.example.codeeditor.model.FileTab
import com.example.codeeditor.utils.BackupManager
import com.example.codeeditor.utils.FileUtils
import com.example.codeeditor.utils.SyntaxHighlighter
import io.github.rosemoe.sora.widget.CodeEditor
import java.io.File
import java.util.Timer
import java.util.TimerTask

class EditorActivity : AppCompatActivity(), SettingsFragment.SettingsChangeListener {

    companion object {
        const val EXTRA_FILE_PATH = "file_path"
        const val REQUEST_OPEN_FILE = 1001
        const val REQUEST_SAVE_FILE = 1002
    }

    private lateinit var codeEditor: CodeEditor
    private lateinit var tabsRecyclerView: RecyclerView
    private lateinit var drawerContainer: LinearLayout
    private lateinit var drawerLayout: LinearLayout
    private lateinit var drawerHandle: View
    
    private lateinit var openButton: ImageButton
    private lateinit var saveButton: ImageButton
    private lateinit var saveAsButton: ImageButton
    private lateinit var settingsButton: ImageButton
    private lateinit var aboutButton: ImageButton
    
    private lateinit var tabAdapter: TabAdapter
    private lateinit var settings: EditorSettings
    private lateinit var backupManager: BackupManager
    private lateinit var syntaxHighlighter: SyntaxHighlighter
    
    private val tabs = mutableListOf<FileTab>()
    private var currentTabIndex = -1
    private var backupTimer: Timer? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_editor)
        
        // Initialize settings
        settings = EditorSettings(this)
        
        // Initialize views
        initViews()
        
        // Initialize adapters and managers
        initAdapters()
        
        // Setup drawer
        setupDrawer()
        
        // Handle intent (file opening)
        handleIntent(intent)
        
        // Start backup timer
        startBackupTimer()
    }
    
    private fun initViews() {
        codeEditor = findViewById(R.id.code_editor)
        tabsRecyclerView = findViewById(R.id.tabs_recycler_view)
        drawerContainer = findViewById(R.id.drawer_container)
        drawerLayout = findViewById(R.id.drawer_layout)
        drawerHandle = findViewById(R.id.drawer_handle)
        
        openButton = findViewById(R.id.open_button)
        saveButton = findViewById(R.id.save_button)
        saveAsButton = findViewById(R.id.save_as_button)
        settingsButton = findViewById(R.id.settings_button)
        aboutButton = findViewById(R.id.about_button)
        
        // Setup button listeners
        openButton.setOnClickListener { openFile() }
        saveButton.setOnClickListener { saveCurrentFile() }
        saveAsButton.setOnClickListener { saveFileAs() }
        settingsButton.setOnClickListener { showSettings() }
        aboutButton.setOnClickListener { showAbout() }
        
        // Setup code editor
        codeEditor.setTextSize(settings.fontSize)
        
        // Apply dark theme if enabled
        applyTheme()
    }
    
    private fun initAdapters() {
        // Initialize syntax highlighter
        syntaxHighlighter = SyntaxHighlighter(codeEditor)
        
        // Initialize tab adapter
        tabAdapter = TabAdapter(tabs) { position ->
            changeTab(position)
        }
        tabsRecyclerView.adapter = tabAdapter
        
        // Initialize backup manager
        backupManager = BackupManager(this)
        
        // Set a change listener for the editor
        codeEditor.setOnTextChangedListener { _, _ ->
            getCurrentTab()?.let { tab ->
                if (!tab.isUnsaved) {
                    tab.isUnsaved = true
                    tabAdapter.notifyDataSetChanged()
                }
            }
        }
    }
    
    private fun setupDrawer() {
        // Apply drawer position from settings
        when (settings.drawerPosition) {
            "bottom" -> {
                drawerContainer.apply {
                    (layoutParams as? LinearLayout.LayoutParams)?.apply {
                        gravity = android.view.Gravity.BOTTOM
                    }
                }
            }
            "left" -> {
                drawerContainer.apply {
                    (layoutParams as? LinearLayout.LayoutParams)?.apply {
                        gravity = android.view.Gravity.START
                    }
                }
                drawerLayout.orientation = LinearLayout.VERTICAL
            }
            "right" -> {
                drawerContainer.apply {
                    (layoutParams as? LinearLayout.LayoutParams)?.apply {
                        gravity = android.view.Gravity.END
                    }
                }
                drawerLayout.orientation = LinearLayout.VERTICAL
            }
        }
        
        // Show/hide drawer handle based on settings
        drawerHandle.visibility = if (settings.showDrawerHandle) View.VISIBLE else View.GONE
    }
    
    private fun handleIntent(intent: Intent) {
        val filePath = intent.getStringExtra(EXTRA_FILE_PATH)
        if (filePath != null) {
            openFileFromPath(filePath)
        } else if (intent.action == Intent.ACTION_VIEW) {
            val uri = intent.data
            if (uri != null) {
                openFileFromUri(uri)
            } else {
                createNewTab()
            }
        } else {
            // Check for auto-backup files
            restoreBackups()
        }
    }
    
    private fun restoreBackups() {
        val backups = backupManager.getBackupFiles()
        if (backups.isNotEmpty()) {
            // Ask user if they want to restore backups
            AlertDialog.Builder(this)
                .setTitle("Restore Backups")
                .setMessage("Would you like to restore ${backups.size} unsaved files from your last session?")
                .setPositiveButton("Yes") { _, _ ->
                    for (backup in backups) {
                        val content = backupManager.readBackupFile(backup)
                        val tab = FileTab(backup.name.removeSuffix(".bak"), null, true)
                        addTab(tab)
                        currentTabIndex = tabs.indexOf(tab)
                        codeEditor.setText(content)
                    }
                    if (tabs.isNotEmpty()) {
                        changeTab(0)
                    } else {
                        createNewTab()
                    }
                }
                .setNegativeButton("No") { _, _ ->
                    createNewTab()
                }
                .show()
        } else {
            createNewTab()
        }
    }
    
    private fun startBackupTimer() {
        backupTimer?.cancel()
        backupTimer = Timer().apply {
            scheduleAtFixedRate(object : TimerTask() {
                override fun run() {
                    Handler(Looper.getMainLooper()).post {
                        backupUnsavedFiles()
                    }
                }
            }, settings.backupIntervalMinutes * 60 * 1000L, settings.backupIntervalMinutes * 60 * 1000L)
        }
    }
    
    private fun backupUnsavedFiles() {
        for (tab in tabs) {
            if (tab.isUnsaved) {
                val content = if (tab == getCurrentTab()) {
                    codeEditor.text.toString()
                } else {
                    tab.content ?: ""
                }
                backupManager.saveBackup(tab.name, content)
            }
        }
    }
    
    private fun createNewTab() {
        val tab = FileTab("Untitled", null, true)
        addTab(tab)
        changeTab(tabs.indexOf(tab))
        codeEditor.setText("")
    }
    
    private fun addTab(tab: FileTab) {
        tabs.add(tab)
        tabAdapter.notifyDataSetChanged()
    }
    
    private fun changeTab(position: Int) {
        if (position < 0 || position >= tabs.size) return
        
        // Save current tab content
        getCurrentTab()?.let { tab ->
            tab.content = codeEditor.text.toString()
        }
        
        currentTabIndex = position
        val tab = tabs[position]
        
        // Set editor content
        codeEditor.setText(tab.content ?: "")
        
        // Apply syntax highlighting based on file extension
        syntaxHighlighter.applyHighlighting(tab.name)
        
        // Update tab selection
        tabAdapter.setSelectedTab(position)
    }
    
    private fun getCurrentTab(): FileTab? {
        return if (currentTabIndex >= 0 && currentTabIndex < tabs.size) {
            tabs[currentTabIndex]
        } else {
            null
        }
    }
    
    private fun openFile() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
        }
        startActivityForResult(intent, REQUEST_OPEN_FILE)
    }
    
    private fun openFileFromPath(path: String) {
        val file = File(path)
        if (file.exists()) {
            val content = FileUtils.readFile(file)
            val tab = FileTab(file.name, file, false)
            addTab(tab)
            changeTab(tabs.indexOf(tab))
            codeEditor.setText(content)
            
            // Save as last opened file
            settings.lastOpenedFilePath = path
        }
    }
    
    private fun openFileFromUri(uri: Uri) {
        val content = FileUtils.readFile(this, uri)
        val fileName = FileUtils.getFileName(this, uri) ?: "Untitled"
        val tab = FileTab(fileName, null, false)
        tab.uri = uri
        addTab(tab)
        changeTab(tabs.indexOf(tab))
        codeEditor.setText(content)
    }
    
    private fun saveCurrentFile() {
        val tab = getCurrentTab() ?: return
        
        if (tab.file != null) {
            // Save to existing file
            val content = codeEditor.text.toString()
            FileUtils.saveFile(tab.file!!, content)
            tab.isUnsaved = false
            tabAdapter.notifyDataSetChanged()
        } else if (tab.uri != null) {
            // Save to existing uri
            val content = codeEditor.text.toString()
            FileUtils.saveFile(this, tab.uri!!, content)
            tab.isUnsaved = false
            tabAdapter.notifyDataSetChanged()
        } else {
            // No file associated, use save as
            saveFileAs()
        }
    }
    
    private fun saveFileAs() {
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(Intent.EXTRA_TITLE, getCurrentTab()?.name ?: "Untitled")
        }
        startActivityForResult(intent, REQUEST_SAVE_FILE)
    }
    
    private fun showSettings() {
        val fragment = SettingsFragment()
        fragment.show(supportFragmentManager, "settings")
    }
    
    private fun showAbout() {
        val fragment = AboutFragment()
        fragment.show(supportFragmentManager, "about")
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (resultCode == RESULT_OK) {
            when (requestCode) {
                REQUEST_OPEN_FILE -> {
                    data?.data?.let { uri ->
                        openFileFromUri(uri)
                    }
                }
                REQUEST_SAVE_FILE -> {
                    data?.data?.let { uri ->
                        val tab = getCurrentTab() ?: return
                        val content = codeEditor.text.toString()
                        FileUtils.saveFile(this, uri, content)
                        
                        // Update tab name from URI
                        val fileName = FileUtils.getFileName(this, uri) ?: tab.name
                        tab.name = fileName
                        tab.uri = uri
                        tab.isUnsaved = false
                        tabAdapter.notifyDataSetChanged()
                    }
                }
            }
        }
    }
    
    override fun onSettingsChanged() {
        // Apply new font size to editor
        codeEditor.setTextSize(settings.fontSize)
        
        // Update drawer position and visibility
        setupDrawer()
        
        // Apply theme
        applyTheme()
        
        // Restart backup timer with new interval
        startBackupTimer()
    }
    
    private fun applyTheme() {
        // Apply theme based on settings (dark/light theme)
        // This would typically involve changing theme at runtime or recreating activity
        // For simplicity, we'll just apply some colors directly
        if (settings.darkTheme) {
            codeEditor.setBackgroundColor(resources.getColor(R.color.colorBackground, theme))
            codeEditor.setTextColor(resources.getColor(R.color.colorTextPrimary, theme))
        } else {
            codeEditor.setBackgroundColor(resources.getColor(R.color.colorBackgroundLight, theme))
            codeEditor.setTextColor(resources.getColor(R.color.colorTextPrimaryLight, theme))
        }
    }
    
    override fun onPause() {
        super.onPause()
        // Backup unsaved files when activity goes to background
        backupUnsavedFiles()
    }
    
    override fun onDestroy() {
        // Cancel the backup timer
        backupTimer?.cancel()
        backupTimer = null
        super.onDestroy()
    }
    
    override fun onBackPressed() {
        // Check for unsaved changes
        val hasUnsavedChanges = tabs.any { it.isUnsaved }
        if (hasUnsavedChanges) {
            AlertDialog.Builder(this)
                .setTitle("Unsaved Changes")
                .setMessage("You have unsaved changes. Save before exiting?")
                .setPositiveButton("Save All") { _, _ ->
                    // Save all unsaved tabs
                    var allSaved = true
                    for (i in tabs.indices) {
                        if (tabs[i].isUnsaved) {
                            changeTab(i)
                            if (tabs[i].file != null || tabs[i].uri != null) {
                                saveCurrentFile()
                            } else {
                                allSaved = false
                                saveFileAs()
                                break
                            }
                        }
                    }
                    if (allSaved) {
                        finish()
                    }
                }
                .setNegativeButton("Discard") { _, _ ->
                    finish()
                }
                .setNeutralButton("Cancel", null)
                .show()
        } else {
            super.onBackPressed()
        }
    }
}