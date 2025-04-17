package com.example.codeeditor.fragments

import android.content.Context
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.CheckBox
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.SeekBar
import android.widget.TextView
import androidx.fragment.app.DialogFragment
import com.example.codeeditor.R
import com.example.codeeditor.model.EditorSettings

/**
 * Dialog fragment for editing application settings
 */
class SettingsFragment : DialogFragment() {
    
    private lateinit var settings: EditorSettings
    private lateinit var fontSizeSeekBar: SeekBar
    private lateinit var fontSizeValue: TextView
    private lateinit var backupIntervalSeekBar: SeekBar
    private lateinit var backupIntervalValue: TextView
    private lateinit var darkThemeCheckBox: CheckBox
    private lateinit var showLineNumbersCheckBox: CheckBox
    private lateinit var drawerPositionRadioGroup: RadioGroup
    private lateinit var bottomPositionRadio: RadioButton
    private lateinit var leftPositionRadio: RadioButton
    private lateinit var rightPositionRadio: RadioButton
    private lateinit var showHandleCheckBox: CheckBox
    private lateinit var saveButton: Button
    private lateinit var cancelButton: Button
    
    private var listener: SettingsChangeListener? = null
    
    interface SettingsChangeListener {
        fun onSettingsChanged()
    }
    
    override fun onAttach(context: Context) {
        super.onAttach(context)
        if (context is SettingsChangeListener) {
            listener = context
        } else {
            throw RuntimeException("$context must implement SettingsChangeListener")
        }
    }
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        // Inflate the layout
        val view = inflater.inflate(R.layout.fragment_settings, container, false)
        
        // Initialize settings
        settings = EditorSettings(requireContext())
        
        // Initialize views
        initViews(view)
        
        // Set current values
        setCurrentValues()
        
        return view
    }
    
    private fun initViews(view: View) {
        // Font size
        fontSizeSeekBar = view.findViewById(R.id.font_size_seekbar)
        fontSizeValue = view.findViewById(R.id.font_size_value)
        
        // Backup interval
        backupIntervalSeekBar = view.findViewById(R.id.backup_interval_seekbar)
        backupIntervalValue = view.findViewById(R.id.backup_interval_value)
        
        // Dark theme
        darkThemeCheckBox = view.findViewById(R.id.dark_theme_checkbox)
        
        // Line numbers
        showLineNumbersCheckBox = view.findViewById(R.id.show_line_numbers_checkbox)
        
        // Drawer position
        drawerPositionRadioGroup = view.findViewById(R.id.drawer_position_radio_group)
        bottomPositionRadio = view.findViewById(R.id.position_bottom)
        leftPositionRadio = view.findViewById(R.id.position_left)
        rightPositionRadio = view.findViewById(R.id.position_right)
        
        // Show handle
        showHandleCheckBox = view.findViewById(R.id.show_handle_checkbox)
        
        // Buttons
        saveButton = view.findViewById(R.id.save_settings_button)
        cancelButton = view.findViewById(R.id.cancel_settings_button)
        
        // Set listeners
        fontSizeSeekBar.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                val fontSize = progress + 8 // Min font size is 8
                fontSizeValue.text = fontSize.toString()
            }
            
            override fun onStartTrackingTouch(seekBar: SeekBar?) {}
            
            override fun onStopTrackingTouch(seekBar: SeekBar?) {}
        })
        
        backupIntervalSeekBar.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                val interval = progress + 1 // Min interval is 1 minute
                backupIntervalValue.text = interval.toString()
            }
            
            override fun onStartTrackingTouch(seekBar: SeekBar?) {}
            
            override fun onStopTrackingTouch(seekBar: SeekBar?) {}
        })
        
        saveButton.setOnClickListener {
            saveSettings()
            dismiss()
        }
        
        cancelButton.setOnClickListener {
            dismiss()
        }
    }
    
    private fun setCurrentValues() {
        // Font size (range 8-36)
        val fontSize = settings.fontSize.toInt()
        fontSizeSeekBar.progress = fontSize - 8
        fontSizeValue.text = fontSize.toString()
        
        // Backup interval (range 1-60 minutes)
        val backupInterval = settings.backupIntervalMinutes
        backupIntervalSeekBar.progress = backupInterval - 1
        backupIntervalValue.text = backupInterval.toString()
        
        // Dark theme
        darkThemeCheckBox.isChecked = settings.darkTheme
        
        // Line numbers
        showLineNumbersCheckBox.isChecked = settings.showLineNumbers
        
        // Drawer position
        when (settings.drawerPosition) {
            "bottom" -> bottomPositionRadio.isChecked = true
            "left" -> leftPositionRadio.isChecked = true
            "right" -> rightPositionRadio.isChecked = true
        }
        
        // Show handle
        showHandleCheckBox.isChecked = settings.showDrawerHandle
    }
    
    private fun saveSettings() {
        // Save font size
        val fontSize = fontSizeSeekBar.progress + 8
        settings.fontSize = fontSize.toFloat()
        
        // Save backup interval
        val backupInterval = backupIntervalSeekBar.progress + 1
        settings.backupIntervalMinutes = backupInterval
        
        // Save dark theme
        settings.darkTheme = darkThemeCheckBox.isChecked
        
        // Save line numbers
        settings.showLineNumbers = showLineNumbersCheckBox.isChecked
        
        // Save drawer position
        val position = when {
            bottomPositionRadio.isChecked -> "bottom"
            leftPositionRadio.isChecked -> "left"
            rightPositionRadio.isChecked -> "right"
            else -> "bottom"
        }
        settings.drawerPosition = position
        
        // Save show handle
        settings.showDrawerHandle = showHandleCheckBox.isChecked
        
        // Notify listener
        listener?.onSettingsChanged()
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