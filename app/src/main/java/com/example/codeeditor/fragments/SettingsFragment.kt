package com.example.codeeditor.fragments

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.CheckBox
import android.widget.EditText
import android.widget.Spinner
import android.widget.Switch
import androidx.fragment.app.DialogFragment
import com.example.codeeditor.R
import com.example.codeeditor.model.EditorSettings

/**
 * Dialog fragment for editor settings
 */
class SettingsFragment : DialogFragment() {
    
    private lateinit var settings: EditorSettings
    
    private lateinit var themeSwitch: Switch
    private lateinit var fontSizeEdit: EditText
    private lateinit var backupIntervalEdit: EditText
    private lateinit var drawerPositionSpinner: Spinner
    private lateinit var showHandleCheckbox: CheckBox
    private lateinit var saveButton: Button
    private lateinit var cancelButton: Button
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_settings, container, false)
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        // Initialize settings
        settings = EditorSettings(requireContext())
        
        // Initialize views
        themeSwitch = view.findViewById(R.id.theme_switch)
        fontSizeEdit = view.findViewById(R.id.font_size_edit)
        backupIntervalEdit = view.findViewById(R.id.backup_interval_edit)
        drawerPositionSpinner = view.findViewById(R.id.drawer_position_spinner)
        showHandleCheckbox = view.findViewById(R.id.show_handle_checkbox)
        saveButton = view.findViewById(R.id.save_settings_button)
        cancelButton = view.findViewById(R.id.cancel_settings_button)
        
        // Setup spinner
        val drawerPositions = arrayOf("bottom", "left", "right")
        val adapter = ArrayAdapter(
            requireContext(),
            android.R.layout.simple_spinner_item,
            drawerPositions
        )
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        drawerPositionSpinner.adapter = adapter
        
        // Load current settings
        loadSettings()
        
        // Setup button listeners
        saveButton.setOnClickListener {
            saveSettings()
            dismiss()
        }
        
        cancelButton.setOnClickListener {
            dismiss()
        }
    }
    
    private fun loadSettings() {
        themeSwitch.isChecked = settings.darkTheme
        fontSizeEdit.setText(settings.fontSize.toString())
        backupIntervalEdit.setText(settings.backupIntervalMinutes.toString())
        
        // Set spinner selection
        val position = when (settings.drawerPosition) {
            "bottom" -> 0
            "left" -> 1
            "right" -> 2
            else -> 0
        }
        drawerPositionSpinner.setSelection(position)
        
        showHandleCheckbox.isChecked = settings.showDrawerHandle
    }
    
    private fun saveSettings() {
        try {
            settings.darkTheme = themeSwitch.isChecked
            settings.fontSize = fontSizeEdit.text.toString().toFloatOrNull() ?: 14f
            settings.backupIntervalMinutes = backupIntervalEdit.text.toString().toIntOrNull() ?: 1
            settings.drawerPosition = drawerPositionSpinner.selectedItem.toString()
            settings.showDrawerHandle = showHandleCheckbox.isChecked
            
            // Notify activity that settings have changed
            (activity as? SettingsChangeListener)?.onSettingsChanged()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    interface SettingsChangeListener {
        fun onSettingsChanged()
    }
}
