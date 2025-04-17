package com.example.codeeditor.utils

import io.github.rosemoe.sora.lang.EmptyLanguage
import io.github.rosemoe.sora.lang.Language
import io.github.rosemoe.sora.langs.java.JavaLanguage
import io.github.rosemoe.sora.widget.CodeEditor

/**
 * Handles syntax highlighting based on file extensions
 */
class SyntaxHighlighter(private val editor: CodeEditor) {
    
    /**
     * Apply syntax highlighting based on file name extension
     */
    fun applyHighlighting(fileName: String) {
        val extension = FileUtils.getFileExtension(fileName)
        val language = getLanguageForExtension(extension)
        editor.setEditorLanguage(language)
        
        // Configure editor for this language
        configureEditorForLanguage(language)
    }
    
    /**
     * Get the appropriate language for a file extension
     */
    private fun getLanguageForExtension(extension: String): Language {
        return when (extension.lowercase()) {
            // Java (the only built-in language in this version)
            "java", "kt", "js", "json", "py", "xml", "html", "css" -> JavaLanguage()
            
            // No specific language support
            else -> EmptyLanguage()
        }
    }
    
    /**
     * Configure the editor based on the language
     */
    private fun configureEditorForLanguage(language: Language) {
        // Set tab size and indent size
        editor.tabWidth = 4
        
        // Set whether to use spaces for tab
        editor.isSpacesForTabs = true
        
        // Additional configuration can be added here
    }
}