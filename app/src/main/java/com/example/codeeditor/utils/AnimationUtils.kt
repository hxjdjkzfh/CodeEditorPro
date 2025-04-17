package com.example.codeeditor.utils

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.ValueAnimator
import android.view.View
import android.view.ViewGroup
import android.view.animation.AccelerateDecelerateInterpolator
import android.view.animation.AccelerateInterpolator
import android.view.animation.Animation
import android.view.animation.AnimationUtils
import android.view.animation.DecelerateInterpolator
import android.view.animation.ScaleAnimation
import android.view.animation.TranslateAnimation
import androidx.core.view.ViewCompat
import androidx.core.view.ViewPropertyAnimatorListener
import com.example.codeeditor.R

/**
 * Utility class to handle animations for file operations in the editor
 */
class AnimationUtils {
    companion object {
        private const val SHORT_DURATION = 150L
        private const val MEDIUM_DURATION = 250L
        private const val LONG_DURATION = 350L
        
        /**
         * Animation for drag start - slightly scales up the view and adds elevation
         */
        fun startDragAnimation(view: View) {
            // Scale up slightly
            val scaleAnim = ScaleAnimation(
                1.0f, 1.05f, 1.0f, 1.05f,
                Animation.RELATIVE_TO_SELF, 0.5f,
                Animation.RELATIVE_TO_SELF, 0.5f
            ).apply {
                duration = SHORT_DURATION
                interpolator = DecelerateInterpolator()
                fillAfter = true
            }
            
            view.startAnimation(scaleAnim)
            
            // Add elevation for "lifted" effect
            ViewCompat.animate(view)
                .translationZ(8f)
                .setDuration(SHORT_DURATION)
                .start()
        }
        
        /**
         * Animation for drag end/drop - scales back to normal and removes elevation
         */
        fun endDragAnimation(view: View) {
            // Scale back to normal
            val scaleAnim = ScaleAnimation(
                1.05f, 1.0f, 1.05f, 1.0f,
                Animation.RELATIVE_TO_SELF, 0.5f,
                Animation.RELATIVE_TO_SELF, 0.5f
            ).apply {
                duration = SHORT_DURATION
                interpolator = AccelerateInterpolator()
                fillAfter = true
            }
            
            view.startAnimation(scaleAnim)
            
            // Remove elevation
            ViewCompat.animate(view)
                .translationZ(0f)
                .setDuration(SHORT_DURATION)
                .start()
        }
        
        /**
         * Animation for successful file drop - pulse animation
         */
        fun successDropAnimation(view: View) {
            val pulseAnim = ValueAnimator.ofFloat(1.0f, 1.1f, 1.0f).apply {
                duration = MEDIUM_DURATION
                interpolator = AccelerateDecelerateInterpolator()
                addUpdateListener { animator ->
                    val value = animator.animatedValue as Float
                    view.scaleX = value
                    view.scaleY = value
                }
            }
            pulseAnim.start()
        }
        
        /**
         * Animation for file deletion - fade out and slide down
         */
        fun deleteAnimation(view: View, onAnimationEnd: () -> Unit) {
            // Fade out and slide down animation
            ViewCompat.animate(view)
                .alpha(0f)
                .translationY(view.height.toFloat())
                .setDuration(MEDIUM_DURATION)
                .setListener(object : ViewPropertyAnimatorListener {
                    override fun onAnimationStart(view: View) {}
                    
                    override fun onAnimationEnd(view: View) {
                        onAnimationEnd()
                    }
                    
                    override fun onAnimationCancel(view: View) {
                        onAnimationEnd()
                    }
                })
                .start()
        }
        
        /**
         * Animation for file creation - fade in and slide up
         */
        fun createAnimation(view: View) {
            // Initially set properties
            view.alpha = 0f
            view.translationY = view.height.toFloat()
            
            // Animate to show
            ViewCompat.animate(view)
                .alpha(1f)
                .translationY(0f)
                .setDuration(MEDIUM_DURATION)
                .setInterpolator(DecelerateInterpolator())
                .start()
        }
        
        /**
         * Animation for file move - slide from source to destination
         */
        fun moveAnimation(view: View, fromX: Float, fromY: Float, toX: Float, toY: Float, onAnimationEnd: () -> Unit) {
            val moveAnim = TranslateAnimation(
                fromX, toX,
                fromY, toY
            ).apply {
                duration = LONG_DURATION
                interpolator = AccelerateDecelerateInterpolator()
                setAnimationListener(object : Animation.AnimationListener {
                    override fun onAnimationStart(animation: Animation?) {}
                    
                    override fun onAnimationEnd(animation: Animation?) {
                        onAnimationEnd()
                    }
                    
                    override fun onAnimationRepeat(animation: Animation?) {}
                })
            }
            
            view.startAnimation(moveAnim)
        }
        
        /**
         * Animation for highlighting a file - brief flash animation
         */
        fun highlightAnimation(view: View) {
            // Create a flash animation for highlighting
            val flashAnim = ValueAnimator.ofArgb(
                0x00FFFFFF, // Transparent 
                0x33FFFFFF, // Semi-transparent white
                0x00FFFFFF  // Back to transparent
            ).apply {
                duration = MEDIUM_DURATION
                interpolator = AccelerateDecelerateInterpolator()
                addUpdateListener { animator ->
                    val color = animator.animatedValue as Int
                    view.setBackgroundColor(color)
                }
                addListener(object : AnimatorListenerAdapter() {
                    override fun onAnimationEnd(animation: Animator) {
                        view.background = null // Reset background
                    }
                })
            }
            flashAnim.start()
        }
        
        /**
         * Animation for error shake - side to side motion
         */
        fun errorShakeAnimation(view: View) {
            val shakeAnim = TranslateAnimation(
                -10f, 10f, 0f, 0f
            ).apply {
                duration = 50
                repeatMode = Animation.REVERSE
                repeatCount = 5
            }
            
            view.startAnimation(shakeAnim)
        }
    }
}