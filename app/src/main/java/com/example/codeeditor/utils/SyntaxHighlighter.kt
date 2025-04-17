package com.example.codeeditor.utils

import io.github.rosemoe.sora.langs.html.HTMLLanguage
import io.github.rosemoe.sora.langs.java.JavaLanguage
import io.github.rosemoe.sora.langs.python.PythonLanguage
import io.github.rosemoe.sora.langs.textmate.TextMateLanguage
import io.github.rosemoe.sora.langs.universal.UniversalLanguage
import io.github.rosemoe.sora.widget.SymbolPairMatch
import org.eclipse.tm4e.core.registry.IGrammarSource

/**
 * Utility class to provide syntax highlighting based on file extension
 */
object SyntaxHighlighter {
    
    /**
     * Get the appropriate language for the given file extension
     */
    fun getLanguage(extension: String): io.github.rosemoe.sora.langs.Language {
        return when (extension.toLowerCase()) {
            "java" -> JavaLanguage()
            "py" -> PythonLanguage()
            "html", "htm" -> HTMLLanguage()
            "kt", "kts" -> createKotlinLanguage()
            "css" -> createCssLanguage()
            "js" -> createJavaScriptLanguage()
            "json" -> createJsonLanguage()
            "ts" -> createTypeScriptLanguage()
            "xml" -> createXmlLanguage()
            "md" -> createMarkdownLanguage()
            else -> createPlainTextLanguage()
        }
    }
    
    /**
     * Create Kotlin language support using TextMate
     */
    private fun createKotlinLanguage(): io.github.rosemoe.sora.langs.Language {
        // This would require TextMate grammar for Kotlin
        // In a real implementation, we would load the tmLanguage file
        // For simplicity, we'll use a basic implementation
        return createBasicLanguage(listOf(
            "fun", "val", "var", "class", "interface", "object", 
            "override", "private", "public", "internal", "protected",
            "import", "package", "return", "if", "else", "when",
            "for", "while", "do", "break", "continue", "this", "super"
        ))
    }
    
    /**
     * Create CSS language support
     */
    private fun createCssLanguage(): io.github.rosemoe.sora.langs.Language {
        // Would use TextMate in a real implementation
        return createBasicLanguage(listOf(
            "body", "div", "span", "class", "id", "color", "background",
            "margin", "padding", "font", "border", "width", "height",
            "@media", "@keyframes", "animation", "transition", "display"
        ))
    }
    
    /**
     * Create JavaScript language support
     */
    private fun createJavaScriptLanguage(): io.github.rosemoe.sora.langs.Language {
        // Would use TextMate in a real implementation
        return createBasicLanguage(listOf(
            "function", "var", "let", "const", "if", "else", "for", "while",
            "return", "class", "new", "this", "import", "export", "default",
            "async", "await", "try", "catch", "finally", "throw", "typeof"
        ))
    }
    
    /**
     * Create JSON language support
     */
    private fun createJsonLanguage(): io.github.rosemoe.sora.langs.Language {
        // Would use TextMate in a real implementation
        return createBasicLanguage(listOf("true", "false", "null"))
    }
    
    /**
     * Create TypeScript language support
     */
    private fun createTypeScriptLanguage(): io.github.rosemoe.sora.langs.Language {
        // Would use TextMate in a real implementation
        return createBasicLanguage(listOf(
            "function", "var", "let", "const", "if", "else", "for", "while",
            "return", "class", "new", "this", "import", "export", "default",
            "async", "await", "try", "catch", "finally", "throw", "typeof",
            "interface", "type", "namespace", "enum", "private", "public"
        ))
    }
    
    /**
     * Create XML language support
     */
    private fun createXmlLanguage(): io.github.rosemoe.sora.langs.Language {
        // Would use TextMate in a real implementation
        return createBasicLanguage(listOf("xml", "version", "encoding", "DOCTYPE"))
    }
    
    /**
     * Create Markdown language support
     */
    private fun createMarkdownLanguage(): io.github.rosemoe.sora.langs.Language {
        // Would use TextMate in a real implementation
        return createBasicLanguage(listOf("#", "##", "###", "*", "**", ">", "-", "+", "```"))
    }
    
    /**
     * Create plain text language (no special highlighting)
     */
    private fun createPlainTextLanguage(): io.github.rosemoe.sora.langs.Language {
        return UniversalLanguage()
    }
    
    /**
     * Create a basic language implementation with the given keywords
     */
    private fun createBasicLanguage(keywords: List<String>): io.github.rosemoe.sora.langs.Language {
        val languageImpl = object : UniversalLanguage() {
            override fun getSymbolPairs(): SymbolPairMatch {
                val pairMatch = SymbolPairMatch()
                pairMatch.putPair('(', ')')
                pairMatch.putPair('[', ']')
                pairMatch.putPair('{', '}')
                pairMatch.putPair('\"', '\"')
                pairMatch.putPair('\'', '\'')
                return pairMatch
            }
            
            override fun getKeywords(): Array<String> {
                return keywords.toTypedArray()
            }
        }
        
        return languageImpl
    }
}
