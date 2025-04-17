package com.example.codeeditor

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.appcompat.app.AppCompatActivity
import com.example.codeeditor.utils.FileUtils

/**
 * Splash screen activity that redirects to the EditorActivity
 * Serves as the entry point of the application
 */
class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // Wait a moment then redirect to the editor
        Handler(Looper.getMainLooper()).postDelayed({
            val intent = Intent(this, EditorActivity::class.java)
            
            // Pass file path if app was opened with a file
            if (intent.data != null) {
                val filePath = FileUtils.getPathFromUri(this, intent.data!!)
                if (filePath != null) {
                    intent.putExtra("FILE_PATH", filePath)
                }
            }
            
            startActivity(intent)
            finish()
        }, 1000)
    }
}
