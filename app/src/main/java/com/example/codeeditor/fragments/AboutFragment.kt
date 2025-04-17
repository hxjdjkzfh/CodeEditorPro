package com.example.codeeditor.fragments

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import androidx.fragment.app.DialogFragment
import com.example.codeeditor.BuildConfig
import com.example.codeeditor.R

/**
 * Dialog fragment for displaying app information
 */
class AboutFragment : DialogFragment() {
    
    private lateinit var versionTextView: TextView
    private lateinit var closeButton: Button
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        // Inflate the layout
        val view = inflater.inflate(R.layout.fragment_about, container, false)
        
        // Initialize views
        versionTextView = view.findViewById(R.id.version_text)
        closeButton = view.findViewById(R.id.close_button)
        
        // Set version text
        versionTextView.text = getString(R.string.version_info, BuildConfig.VERSION_NAME)
        
        // Set close button listener
        closeButton.setOnClickListener {
            dismiss()
        }
        
        return view
    }
    
    override fun onStart() {
        super.onStart()
        
        // Make dialog full width
        dialog?.window?.setLayout(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        )
    }
}