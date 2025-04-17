package com.example.codeeditor.fragments

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import androidx.fragment.app.DialogFragment
import com.example.codeeditor.R

/**
 * Dialog fragment for about screen
 */
class AboutFragment : DialogFragment() {
    
    private lateinit var versionText: TextView
    private lateinit var closeButton: Button
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_about, container, false)
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        versionText = view.findViewById(R.id.version_text)
        closeButton = view.findViewById(R.id.close_about_button)
        
        // Set version
        val packageInfo = requireContext().packageManager.getPackageInfo(
            requireContext().packageName, 0
        )
        versionText.text = "Version ${packageInfo.versionName}"
        
        // Set button listener
        closeButton.setOnClickListener {
            dismiss()
        }
    }
}
