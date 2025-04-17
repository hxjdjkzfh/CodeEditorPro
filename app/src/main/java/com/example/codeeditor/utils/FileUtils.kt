package com.example.codeeditor.utils

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.content.Context
import android.database.Cursor
import android.graphics.drawable.Drawable
import android.net.Uri
import android.provider.OpenableColumns
import android.view.View
import android.view.animation.AccelerateDecelerateInterpolator
import android.view.animation.DecelerateInterpolator
import android.widget.ImageView
import android.widget.TextView
import androidx.core.content.ContextCompat
import java.io.BufferedReader
import java.io.File
import java.io.FileOutputStream
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import android.os.Handler
import android.os.Looper

/**
 * Utility class for file operations with animations
 */
object FileUtils {
    
    private const val ANIMATION_DURATION = 300L
    
    /**
     * Read file content from a File object with load animation
     */
    fun readFile(file: File, statusView: TextView? = null): String {
        // Simulate loading with animation if status view is provided
        statusView?.let { view ->
            val originalText = view.text
            view.text = "Loading..."
            animateTextView(view)
            
            // Reset status after delay
            Handler(Looper.getMainLooper()).postDelayed({
                view.clearAnimation()
                view.text = originalText
            }, ANIMATION_DURATION * 2)
        }
        
        return file.readText()
    }
    
    /**
     * Read file content from a URI with load animation
     */
    fun readFile(context: Context, uri: Uri, statusView: TextView? = null): String {
        // Simulate loading with animation if status view is provided
        statusView?.let { view ->
            val originalText = view.text
            view.text = "Loading..."
            animateTextView(view)
            
            // Reset status after delay
            Handler(Looper.getMainLooper()).postDelayed({
                view.clearAnimation()
                view.text = originalText
            }, ANIMATION_DURATION * 2)
        }
        
        val stringBuilder = StringBuilder()
        context.contentResolver.openInputStream(uri)?.use { inputStream ->
            BufferedReader(InputStreamReader(inputStream)).use { reader ->
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    stringBuilder.append(line)
                    stringBuilder.append("\n")
                }
            }
        }
        return stringBuilder.toString()
    }
    
    /**
     * Save content to a File with save animation
     */
    fun saveFile(file: File, content: String, saveIcon: ImageView? = null) {
        // Animate save icon if provided
        saveIcon?.let { icon ->
            animateSaveIcon(icon)
        }
        
        file.writeText(content)
    }
    
    /**
     * Save content to a URI with save animation
     */
    fun saveFile(context: Context, uri: Uri, content: String, saveIcon: ImageView? = null) {
        // Animate save icon if provided
        saveIcon?.let { icon ->
            animateSaveIcon(icon)
        }
        
        context.contentResolver.openOutputStream(uri)?.use { outputStream ->
            OutputStreamWriter(outputStream).use { writer ->
                writer.write(content)
            }
        }
    }
    
    /**
     * Delete a file with animation
     */
    fun deleteFile(file: File, fileView: View? = null, onComplete: () -> Unit = {}) {
        if (fileView != null) {
            // Animate file deletion
            val fadeOut = ObjectAnimator.ofFloat(fileView, View.ALPHA, 1f, 0f)
            fadeOut.duration = ANIMATION_DURATION
            fadeOut.addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    // Delete file after animation finishes
                    if (file.exists()) {
                        file.delete()
                    }
                    onComplete()
                }
            })
            fadeOut.start()
        } else {
            // No view to animate, just delete
            if (file.exists()) {
                file.delete()
            }
            onComplete()
        }
    }
    
    /**
     * Move a file with animation
     */
    fun moveFile(source: File, destination: File, sourceView: View? = null, 
                destinationView: View? = null, onComplete: () -> Unit = {}) {
        if (sourceView != null && destinationView != null) {
            // Calculate start and end positions
            val startX = sourceView.x + sourceView.width / 2
            val startY = sourceView.y + sourceView.height / 2
            val endX = destinationView.x + destinationView.width / 2
            val endY = destinationView.y + destinationView.height / 2
            
            // Create a moving dot to animate
            val parentView = sourceView.parent as? View
            if (parentView != null) {
                val movingDot = View(parentView.context)
                movingDot.setBackgroundResource(android.R.drawable.presence_online) // Green dot
                val dotSize = 24 // size in dp
                val density = parentView.resources.displayMetrics.density
                val sizePx = (dotSize * density).toInt()
                
                // Add the dot to the parent view
                (parentView as? android.view.ViewGroup)?.addView(movingDot)
                movingDot.layoutParams.width = sizePx
                movingDot.layoutParams.height = sizePx
                
                // Position at start position
                movingDot.x = startX - sizePx / 2
                movingDot.y = startY - sizePx / 2
                
                // Animate from source to destination
                val moveXAnimator = ObjectAnimator.ofFloat(movingDot, View.X, startX - sizePx / 2, endX - sizePx / 2)
                val moveYAnimator = ObjectAnimator.ofFloat(movingDot, View.Y, startY - sizePx / 2, endY - sizePx / 2)
                
                moveXAnimator.duration = ANIMATION_DURATION
                moveYAnimator.duration = ANIMATION_DURATION
                
                moveXAnimator.interpolator = DecelerateInterpolator()
                moveYAnimator.interpolator = DecelerateInterpolator()
                
                moveXAnimator.addListener(object : AnimatorListenerAdapter() {
                    override fun onAnimationEnd(animation: Animator) {
                        // Remove the dot and perform the actual file move
                        (parentView as? android.view.ViewGroup)?.removeView(movingDot)
                        
                        if (source.exists()) {
                            source.copyTo(destination, overwrite = true)
                            source.delete()
                        }
                        
                        onComplete()
                    }
                })
                
                moveXAnimator.start()
                moveYAnimator.start()
            } else {
                // No parent view, just move the file
                if (source.exists()) {
                    source.copyTo(destination, overwrite = true)
                    source.delete()
                }
                onComplete()
            }
        } else {
            // No views to animate, just move the file
            if (source.exists()) {
                source.copyTo(destination, overwrite = true)
                source.delete()
            }
            onComplete()
        }
    }
    
    /**
     * Animate a text view for loading effect
     */
    private fun animateTextView(textView: TextView) {
        val pulseAnim = ValueAnimator.ofFloat(1.0f, 1.1f, 1.0f)
        pulseAnim.duration = ANIMATION_DURATION
        pulseAnim.repeatCount = ValueAnimator.INFINITE
        pulseAnim.interpolator = AccelerateDecelerateInterpolator()
        pulseAnim.addUpdateListener { animator ->
            val value = animator.animatedValue as Float
            textView.scaleX = value
            textView.scaleY = value
        }
        pulseAnim.start()
    }
    
    /**
     * Animate save icon for save operation
     */
    private fun animateSaveIcon(icon: ImageView) {
        // Store original drawable
        val originalDrawable = icon.drawable
        
        // Scale and rotate animation
        val rotateAnimation = ObjectAnimator.ofFloat(icon, View.ROTATION, 0f, 360f)
        rotateAnimation.duration = ANIMATION_DURATION
        rotateAnimation.repeatCount = 0
        rotateAnimation.interpolator = AccelerateDecelerateInterpolator()
        
        val scaleDownX = ObjectAnimator.ofFloat(icon, View.SCALE_X, 1f, 0.8f, 1f)
        val scaleDownY = ObjectAnimator.ofFloat(icon, View.SCALE_Y, 1f, 0.8f, 1f)
        scaleDownX.duration = ANIMATION_DURATION
        scaleDownY.duration = ANIMATION_DURATION
        
        // Start animations
        rotateAnimation.start()
        scaleDownX.start()
        scaleDownY.start()
        
        // Change color briefly for feedback
        Handler(Looper.getMainLooper()).postDelayed({
            // Reset to original drawable
            icon.drawable = originalDrawable
        }, ANIMATION_DURATION)
    }
    
    /**
     * Get a filename from a URI
     */
    fun getFileName(context: Context, uri: Uri): String? {
        var result: String? = null
        if (uri.scheme == "content") {
            val cursor: Cursor? = context.contentResolver.query(uri, null, null, null, null)
            cursor?.use {
                if (it.moveToFirst()) {
                    val nameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (nameIndex != -1) {
                        result = it.getString(nameIndex)
                    }
                }
            }
        }
        if (result == null) {
            result = uri.path
            val cut = result?.lastIndexOf('/')
            if (cut != -1) {
                result = result?.substring(cut!! + 1)
            }
        }
        return result
    }
    
    /**
     * Get extension from a filename
     */
    fun getFileExtension(fileName: String): String {
        val lastDot = fileName.lastIndexOf('.')
        return if (lastDot > 0) {
            fileName.substring(lastDot + 1).lowercase()
        } else {
            ""
        }
    }
    
    /**
     * Create a new file with animation
     */
    fun createNewFile(file: File, fileView: View? = null, onComplete: () -> Unit = {}) {
        if (fileView != null) {
            // Initially hide the view
            fileView.alpha = 0f
            fileView.scaleX = 0.5f
            fileView.scaleY = 0.5f
            
            // Animation for file creation
            val fadeIn = ObjectAnimator.ofFloat(fileView, View.ALPHA, 0f, 1f)
            val scaleXAnimator = ObjectAnimator.ofFloat(fileView, View.SCALE_X, 0.5f, 1f)
            val scaleYAnimator = ObjectAnimator.ofFloat(fileView, View.SCALE_Y, 0.5f, 1f)
            
            fadeIn.duration = ANIMATION_DURATION
            scaleXAnimator.duration = ANIMATION_DURATION
            scaleYAnimator.duration = ANIMATION_DURATION
            
            fadeIn.interpolator = DecelerateInterpolator()
            
            fadeIn.addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    // Create the actual file after animation completes
                    file.createNewFile()
                    onComplete()
                }
            })
            
            fadeIn.start()
            scaleXAnimator.start()
            scaleYAnimator.start()
        } else {
            // No view to animate, just create the file
            file.createNewFile()
            onComplete()
        }
    }
}