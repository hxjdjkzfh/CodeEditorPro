package com.example.codeeditor

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import androidx.appcompat.app.AppCompatActivity
import com.example.codeeditor.fragments.AboutFragment
import com.example.codeeditor.model.EditorSettings
import java.io.File

/**
 * Main activity for the application
 * Serves as a landing page and recent files manager
 */
class MainActivity : AppCompatActivity() {
    
    private lateinit var newFileButton: Button
    private lateinit var openFileButton: Button
    private lateinit var continueEditingButton: Button
    private lateinit var aboutButton: Button
    
    private lateinit var settings: EditorSettings
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        // Initialize settings
        settings = EditorSettings(this)
        
        // Initialize views
        initViews()
        
        // Check for last opened file
        checkLastOpenedFile()
    }
    
    private fun initViews() {
        newFileButton = findViewById(R.id.new_file_button)
        openFileButton = findViewById(R.id.open_file_button)
        continueEditingButton = findViewById(R.id.continue_editing_button)
        aboutButton = findViewById(R.id.about_button)
        
        // Set listeners
        newFileButton.setOnClickListener {
            openEditor(null)
        }
        
        openFileButton.setOnClickListener {
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "*/*"
            }
            startActivityForResult(intent, REQUEST_OPEN_FILE)
        }
        
        continueEditingButton.setOnClickListener {
            val lastFilePath = settings.lastOpenedFilePath
            if (lastFilePath.isNotEmpty()) {
                openEditor(lastFilePath)
            } else {
                // No last file, just open a new one
                openEditor(null)
            }
        }
        
        aboutButton.setOnClickListener {
            val fragment = AboutFragment()
            fragment.show(supportFragmentManager, "about")
        }
    }
    
    private fun checkLastOpenedFile() {
        val lastFilePath = settings.lastOpenedFilePath
        if (lastFilePath.isNotEmpty() && File(lastFilePath).exists()) {
            continueEditingButton.visibility = View.VISIBLE
        } else {
            continueEditingButton.visibility = View.GONE
        }
    }
    
    private fun openEditor(filePath: String?) {
        val intent = Intent(this, EditorActivity::class.java)
        if (filePath != null) {
            intent.putExtra(EditorActivity.EXTRA_FILE_PATH, filePath)
        }
        startActivity(intent)
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (resultCode == RESULT_OK && requestCode == REQUEST_OPEN_FILE) {
            data?.data?.let { uri ->
                val intent = Intent(this, EditorActivity::class.java)
                intent.data = uri
                intent.action = Intent.ACTION_VIEW
                startActivity(intent)
            }
        }
    }
    
    override fun onResume() {
        super.onResume()
        
        // Check for last opened file again in case it has changed
        checkLastOpenedFile()
    }
    
    companion object {
        private const val REQUEST_OPEN_FILE = 1001
    }
}