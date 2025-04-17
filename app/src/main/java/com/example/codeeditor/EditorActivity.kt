package com.example.codeeditor

import android.app.AlertDialog
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.View
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.GestureDetectorCompat
import androidx.core.view.isVisible
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import io.github.rosemoe.sora.widget.CodeEditor
import io.github.rosemoe.sora.widget.component.EditorAutoCompletion
import io.github.rosemoe.sora.widget.component.Magnifier
import io.github.rosemoe.sora.widget.schemes.EditorColorScheme
import com.example.codeeditor.adapters.TabAdapter
import com.example.codeeditor.fragments.AboutFragment
import com.example.codeeditor.fragments.SettingsFragment
import com.example.codeeditor.model.EditorSettings
import com.example.codeeditor.model.FileTab
import com.example.codeeditor.utils.BackupManager
import com.example.codeeditor.utils.FileUtils
import com.example.codeeditor.utils.SyntaxHighlighter
import java.io.File

class EditorActivity : AppCompatActivity(), TabAdapter.TabInteractionListener {

    private lateinit var codeEditor: CodeEditor
    private lateinit var tabsRecyclerView: RecyclerView
    private lateinit var tabAdapter: TabAdapter
    private lateinit var drawerHandle: View
    private lateinit var drawerLayout: LinearLayout
    private lateinit var openButton: ImageButton
    private lateinit var saveButton: ImageButton
    private lateinit var saveAsButton: ImageButton
    private lateinit var settingsButton: ImageButton
    private lateinit var aboutButton: ImageButton
    
    private val tabs = mutableListOf<FileTab>()
    private var currentTabIndex = -1
    private lateinit var settings: EditorSettings
    private lateinit var backupManager: BackupManager
    private var scaleGestureDetector: ScaleGestureDetector? = null
    private var gestureDetector: GestureDetectorCompat? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_editor)
        
        // Initialize views
        initializeViews()
        
        // Initialize settings
        settings = EditorSettings(this)
        
        // Configure editor appearance based on settings
        applyEditorSettings()
        
        // Initialize backup manager
        backupManager = BackupManager(this)
        
        // Setup tabs
        setupTabs()
        
        // Setup gesture detectors
        setupGestureDetectors()
        
        // Setup drawer
        setupDrawer()
        
        // Start auto-backup
        startAutoBackup()
        
        // Handle intent (file opening)
        handleIntent(intent)
    }
    
    private fun initializeViews() {
        codeEditor = findViewById(R.id.code_editor)
        tabsRecyclerView = findViewById(R.id.tabs_recycler_view)
        drawerHandle = findViewById(R.id.drawer_handle)
        drawerLayout = findViewById(R.id.drawer_layout)
        openButton = findViewById(R.id.open_button)
        saveButton = findViewById(R.id.save_button)
        saveAsButton = findViewById(R.id.save_as_button)
        settingsButton = findViewById(R.id.settings_button)
        aboutButton = findViewById(R.id.about_button)
        
        // Configure editor basic properties
        codeEditor.apply {
            setLineNumberEnabled(true)
            setWordwrap(false)
            isEditable = true
            setEditorLanguage(SyntaxHighlighter.getLanguage("txt"))
        }
        
        // Set button click listeners
        openButton.setOnClickListener { openFile() }
        saveButton.setOnClickListener { saveCurrentFile(false) }
        saveAsButton.setOnClickListener { saveCurrentFile(true) }
        settingsButton.setOnClickListener { openSettings() }
        aboutButton.setOnClickListener { openAbout() }
    }
    
    private fun setupTabs() {
        tabAdapter = TabAdapter(tabs, this)
        tabsRecyclerView.layoutManager = LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false)
        tabsRecyclerView.adapter = tabAdapter
        
        // Create initial empty tab if no files were restored
        if (tabs.isEmpty()) {
            createNewTab()
        }
    }
    
    private fun setupGestureDetectors() {
        // Setup pinch-to-zoom gesture
        scaleGestureDetector = ScaleGestureDetector(this, object : ScaleGestureDetector.SimpleOnScaleGestureListener() {
            override fun onScale(detector: ScaleGestureDetector): Boolean {
                val scaleFactor = detector.scaleFactor
                if (scaleFactor > 1.0f) {
                    // Zoom in
                    codeEditor.textSize = codeEditor.textSize * 1.05f
                } else if (scaleFactor < 1.0f) {
                    // Zoom out
                    codeEditor.textSize = codeEditor.textSize * 0.95f
                }
                return true
            }
        })
        
        // Setup other gestures
        gestureDetector = GestureDetectorCompat(this, object : GestureDetector.SimpleOnGestureListener() {
            override fun onLongPress(e: MotionEvent) {
                // Long press handled by tab adapter
            }
        })
    }
    
    private fun setupDrawer() {
        // Configure drawer based on settings
        updateDrawerPosition(settings.drawerPosition)
        drawerHandle.isVisible = settings.showDrawerHandle
    }
    
    private fun updateDrawerPosition(position: String) {
        // Implementation to change drawer position (left, right, bottom)
        val params = drawerLayout.layoutParams as LinearLayout.LayoutParams
        
        when (position) {
            "left" -> {
                // Set drawer to appear on the left side
                drawerLayout.orientation = LinearLayout.HORIZONTAL
                // Additional layout adjustments as needed
            }
            "right" -> {
                // Set drawer to appear on the right side
                drawerLayout.orientation = LinearLayout.HORIZONTAL
                // Additional layout adjustments as needed
            }
            "bottom" -> {
                // Set drawer to appear at the bottom
                drawerLayout.orientation = LinearLayout.VERTICAL
                // Additional layout adjustments as needed
            }
        }
        
        drawerLayout.layoutParams = params
    }
    
    private fun applyEditorSettings() {
        // Apply theme based on settings
        if (settings.darkTheme) {
            applyDarkTheme()
        } else {
            applyLightTheme()
        }
        
        // Apply font size
        codeEditor.textSize = settings.fontSize
    }
    
    private fun applyDarkTheme() {
        // Windows 98 high contrast black/red theme
        val scheme = codeEditor.colorScheme
        scheme.setColor(EditorColorScheme.WHOLE_BACKGROUND, 0xFF000000.toInt())
        scheme.setColor(EditorColorScheme.TEXT_NORMAL, 0xFFFFFFFF.toInt())
        scheme.setColor(EditorColorScheme.LINE_NUMBER_BACKGROUND, 0xFF000000.toInt())
        scheme.setColor(EditorColorScheme.LINE_NUMBER, 0xFFFF0000.toInt())
        scheme.setColor(EditorColorScheme.LINE_DIVIDER, 0xFF444444.toInt())
        scheme.setColor(EditorColorScheme.SELECTION_INSERT, 0xFFFF0000.toInt())
        scheme.setColor(EditorColorScheme.SELECTION_HANDLE, 0xFFFF0000.toInt())
        scheme.setColor(EditorColorScheme.SELECTED_TEXT_BACKGROUND, 0xFF880000.toInt())
        codeEditor.colorScheme = scheme
    }
    
    private fun applyLightTheme() {
        // Light theme
        val scheme = codeEditor.colorScheme
        scheme.setColor(EditorColorScheme.WHOLE_BACKGROUND, 0xFFFFFFFF.toInt())
        scheme.setColor(EditorColorScheme.TEXT_NORMAL, 0xFF000000.toInt())
        scheme.setColor(EditorColorScheme.LINE_NUMBER_BACKGROUND, 0xFFEEEEEE.toInt())
        scheme.setColor(EditorColorScheme.LINE_NUMBER, 0xFF666666.toInt())
        scheme.setColor(EditorColorScheme.LINE_DIVIDER, 0xFFDDDDDD.toInt())
        scheme.setColor(EditorColorScheme.SELECTION_INSERT, 0xFF0066CC.toInt())
        scheme.setColor(EditorColorScheme.SELECTION_HANDLE, 0xFF0066CC.toInt())
        scheme.setColor(EditorColorScheme.SELECTED_TEXT_BACKGROUND, 0x660099FF.toInt())
        codeEditor.colorScheme = scheme
    }
    
    private fun startAutoBackup() {
        // Create a handler to perform auto-backup
        val handler = Handler(Looper.getMainLooper())
        val backupRunnable = object : Runnable {
            override fun run() {
                if (currentTabIndex >= 0 && currentTabIndex < tabs.size) {
                    val currentTab = tabs[currentTabIndex]
                    
                    // Save current editor content to the tab
                    currentTab.content = codeEditor.text.toString()
                    
                    // Create backup
                    backupManager.createBackup(currentTab)
                }
                
                // Schedule next backup
                handler.postDelayed(this, settings.backupIntervalMinutes * 60 * 1000L)
            }
        }
        
        // Start the auto-backup loop
        handler.post(backupRunnable)
    }
    
    private fun handleIntent(intent: Intent?) {
        intent?.let {
            if (it.hasExtra("FILE_PATH")) {
                val filePath = it.getStringExtra("FILE_PATH")
                filePath?.let { path ->
                    openFileFromPath(path)
                }
            } else {
                // Restore last session
                restoreLastSession()
            }
        } ?: run {
            // No intent, restore last session
            restoreLastSession()
        }
    }
    
    private fun restoreLastSession() {
        // Get last opened file from preferences
        val lastFilePath = settings.lastOpenedFilePath
        val lastCursorPosition = settings.lastCursorPosition
        
        if (lastFilePath.isNotEmpty()) {
            openFileFromPath(lastFilePath)
            codeEditor.setCursor(lastCursorPosition, 0)
        } else {
            // Start with empty tab
            createNewTab()
        }
        
        // Check for any backups that need restoration
        backupManager.checkForBackups().forEach { restoredTab ->
            addTab(restoredTab)
        }
    }
    
    private fun createNewTab() {
        val newTab = FileTab("Untitled", "", null, false, true)
        addTab(newTab)
    }
    
    private fun addTab(tab: FileTab) {
        tabs.add(tab)
        tabAdapter.notifyItemInserted(tabs.size - 1)
        selectTab(tabs.size - 1)
    }
    
    override fun onTabSelected(position: Int) {
        if (currentTabIndex != position) {
            // Save current tab content before switching
            if (currentTabIndex >= 0 && currentTabIndex < tabs.size) {
                tabs[currentTabIndex].content = codeEditor.text.toString()
            }
            
            selectTab(position)
        }
    }
    
    override fun onTabLongPressed(position: Int) {
        // Prompt to close the tab
        if (position >= 0 && position < tabs.size) {
            val tab = tabs[position]
            
            if (tab.isModified) {
                // Show dialog to save before closing
                AlertDialog.Builder(this)
                    .setTitle("Save changes?")
                    .setMessage("This file has unsaved changes. Do you want to save before closing?")
                    .setPositiveButton("Save") { _, _ ->
                        // Save then close
                        saveTab(tab)
                        closeTab(position)
                    }
                    .setNegativeButton("Discard") { _, _ ->
                        // Close without saving
                        closeTab(position)
                    }
                    .setNeutralButton("Cancel", null)
                    .show()
            } else {
                // Close directly
                closeTab(position)
            }
        }
    }
    
    private fun selectTab(position: Int) {
        if (position >= 0 && position < tabs.size) {
            currentTabIndex = position
            val tab = tabs[position]
            
            // Update editor content
            codeEditor.setText(tab.content)
            
            // Set language based on file extension
            val extension = tab.file?.extension ?: "txt"
            codeEditor.setEditorLanguage(SyntaxHighlighter.getLanguage(extension))
            
            // Notify adapter to update UI
            tabAdapter.setSelectedTab(position)
        }
    }
    
    private fun closeTab(position: Int) {
        if (position >= 0 && position < tabs.size) {
            tabs.removeAt(position)
            tabAdapter.notifyItemRemoved(position)
            
            if (tabs.isEmpty()) {
                // Create a new empty tab if all tabs are closed
                createNewTab()
            } else if (currentTabIndex == position) {
                // Select another tab if the current one was closed
                selectTab(if (position > 0) position - 1 else 0)
            } else if (currentTabIndex > position) {
                // Adjust current tab index if a tab before it was removed
                currentTabIndex--
            }
        }
    }
    
    private fun openFile() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
        intent.addCategory(Intent.CATEGORY_OPENABLE)
        intent.type = "*/*"
        startActivityForResult(intent, REQUEST_CODE_OPEN_FILE)
    }
    
    private fun openFileFromPath(filePath: String) {
        val file = File(filePath)
        if (file.exists()) {
            try {
                val content = file.readText()
                
                // Check if file is already open in a tab
                val existingTabIndex = tabs.indexOfFirst { it.file?.absolutePath == filePath }
                if (existingTabIndex >= 0) {
                    // Select the existing tab
                    selectTab(existingTabIndex)
                } else {
                    // Create a new tab
                    val newTab = FileTab(
                        file.name,
                        content,
                        file,
                        false,
                        false
                    )
                    addTab(newTab)
                }
            } catch (e: Exception) {
                Toast.makeText(this, "Failed to open file: ${e.message}", Toast.LENGTH_SHORT).show()
            }
        } else {
            Toast.makeText(this, "File not found: $filePath", Toast.LENGTH_SHORT).show()
        }
    }
    
    private fun saveCurrentFile(saveAs: Boolean) {
        if (currentTabIndex >= 0 && currentTabIndex < tabs.size) {
            val currentTab = tabs[currentTabIndex]
            
            // Update tab content with current editor content
            currentTab.content = codeEditor.text.toString()
            
            if (currentTab.file == null || saveAs) {
                // Need to prompt for file location
                val intent = Intent(Intent.ACTION_CREATE_DOCUMENT)
                intent.addCategory(Intent.CATEGORY_OPENABLE)
                intent.type = "*/*"
                intent.putExtra(Intent.EXTRA_TITLE, currentTab.name)
                startActivityForResult(intent, REQUEST_CODE_SAVE_FILE)
            } else {
                // Save to existing file
                saveTab(currentTab)
            }
        }
    }
    
    private fun saveTab(tab: FileTab) {
        tab.file?.let { file ->
            try {
                file.writeText(tab.content)
                tab.isModified = false
                tabAdapter.notifyDataSetChanged()
                Toast.makeText(this, "File saved", Toast.LENGTH_SHORT).show()
            } catch (e: Exception) {
                Toast.makeText(this, "Failed to save file: ${e.message}", Toast.LENGTH_SHORT).show()
            }
        }
    }
    
    private fun openSettings() {
        val fragment = SettingsFragment()
        fragment.show(supportFragmentManager, "settings")
    }
    
    private fun openAbout() {
        val fragment = AboutFragment()
        fragment.show(supportFragmentManager, "about")
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (resultCode == RESULT_OK && data != null) {
            when (requestCode) {
                REQUEST_CODE_OPEN_FILE -> {
                    data.data?.let { uri ->
                        val filePath = FileUtils.getPathFromUri(this, uri)
                        if (filePath != null) {
                            openFileFromPath(filePath)
                        } else {
                            Toast.makeText(this, "Could not open file", Toast.LENGTH_SHORT).show()
                        }
                    }
                }
                REQUEST_CODE_SAVE_FILE -> {
                    data.data?.let { uri ->
                        if (currentTabIndex >= 0 && currentTabIndex < tabs.size) {
                            val currentTab = tabs[currentTabIndex]
                            
                            try {
                                contentResolver.openOutputStream(uri)?.use { outputStream ->
                                    outputStream.write(currentTab.content.toByteArray())
                                }
                                
                                // Update tab with new file info
                                val filePath = FileUtils.getPathFromUri(this, uri)
                                if (filePath != null) {
                                    val file = File(filePath)
                                    currentTab.file = file
                                    currentTab.name = file.name
                                    currentTab.isModified = false
                                    tabAdapter.notifyDataSetChanged()
                                    Toast.makeText(this, "File saved", Toast.LENGTH_SHORT).show()
                                }
                            } catch (e: Exception) {
                                Toast.makeText(this, "Failed to save file: ${e.message}", Toast.LENGTH_SHORT).show()
                            }
                        }
                    }
                }
            }
        }
    }
    
    override fun onTouchEvent(event: MotionEvent): Boolean {
        // Handle pinch-to-zoom
        scaleGestureDetector?.onTouchEvent(event)
        gestureDetector?.onTouchEvent(event)
        return super.onTouchEvent(event)
    }
    
    override fun onPause() {
        super.onPause()
        // Save current state
        saveEditorState()
    }
    
    private fun saveEditorState() {
        if (currentTabIndex >= 0 && currentTabIndex < tabs.size) {
            val currentTab = tabs[currentTabIndex]
            
            // Update tab content with current editor content
            currentTab.content = codeEditor.text.toString()
            
            // Save last file information to settings
            currentTab.file?.let { file ->
                settings.lastOpenedFilePath = file.absolutePath
                settings.lastCursorPosition = codeEditor.cursor.leftLine
            }
            
            // Backup current tab
            backupManager.createBackup(currentTab)
        }
    }
    
    companion object {
        private const val REQUEST_CODE_OPEN_FILE = 1001
        private const val REQUEST_CODE_SAVE_FILE = 1002
    }
}
