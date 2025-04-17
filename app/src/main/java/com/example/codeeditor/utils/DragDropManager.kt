package com.example.codeeditor.utils

import android.content.ClipData
import android.content.ClipDescription
import android.os.Build
import android.view.DragEvent
import android.view.View
import android.view.ViewGroup
import com.example.codeeditor.model.FileTab

/**
 * Manager class that handles drag and drop operations for file tabs
 */
class DragDropManager(private val container: ViewGroup) {
    
    companion object {
        const val DRAG_TAG_FILE = "file_tab"
    }
    
    interface DragDropListener {
        fun onDragStarted(fileTab: FileTab, view: View)
        fun onDropped(fileTab: FileTab, targetPosition: Int): Boolean
        fun onDragEnded()
    }
    
    private var listener: DragDropListener? = null
    
    /**
     * Set the listener to receive drag and drop events
     */
    fun setDragDropListener(listener: DragDropListener) {
        this.listener = listener
    }
    
    /**
     * Make a view draggable
     */
    fun makeViewDraggable(view: View, fileTab: FileTab, position: Int) {
        view.tag = position // Store the position in the view's tag
        
        // Set long click listener to start drag
        view.setOnLongClickListener { v ->
            // Start drag operation
            val item = ClipData.Item(position.toString())
            val dragData = ClipData(
                DRAG_TAG_FILE,
                arrayOf(ClipDescription.MIMETYPE_TEXT_PLAIN),
                item
            )
            
            // Apply animation for drag start
            AnimationUtils.startDragAnimation(v)
            
            // Start the drag
            val shadowBuilder = View.DragShadowBuilder(v)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                v.startDragAndDrop(
                    dragData,
                    shadowBuilder,
                    fileTab, // The data to be dragged
                    0
                )
            } else {
                @Suppress("DEPRECATION")
                v.startDrag(
                    dragData,
                    shadowBuilder,
                    fileTab, // The data to be dragged
                    0
                )
            }
            
            // Notify listener
            listener?.onDragStarted(fileTab, v)
            
            true // Consumed the long click
        }
    }
    
    /**
     * Set up a view to be a drop target
     */
    fun setupDropTarget(targetView: View, position: Int) {
        // Set drag listener on the target view
        targetView.setOnDragListener { v, event ->
            when (event.action) {
                DragEvent.ACTION_DRAG_STARTED -> {
                    // Check if we can accept this drag (must be a file tab)
                    event.clipDescription.hasMimeType(ClipDescription.MIMETYPE_TEXT_PLAIN)
                }
                
                DragEvent.ACTION_DRAG_ENTERED -> {
                    // Visual indication that we're over a valid drop target
                    v.alpha = 0.7f
                    true
                }
                
                DragEvent.ACTION_DRAG_LOCATION -> {
                    // Ignore events for drag location
                    true
                }
                
                DragEvent.ACTION_DRAG_EXITED -> {
                    // Reset visual indication
                    v.alpha = 1.0f
                    true
                }
                
                DragEvent.ACTION_DROP -> {
                    // Handle the drop
                    val droppedFileTab = event.localState as FileTab
                    
                    // Try to perform the drop
                    val success = listener?.onDropped(droppedFileTab, position) ?: false
                    
                    if (success) {
                        // Animation for successful drop
                        AnimationUtils.successDropAnimation(v)
                    }
                    
                    // Reset visual indication
                    v.alpha = 1.0f
                    
                    success
                }
                
                DragEvent.ACTION_DRAG_ENDED -> {
                    // Get the drag source view
                    val dragView = event.localState as? View
                    
                    // End drag animation
                    dragView?.let {
                        AnimationUtils.endDragAnimation(it)
                    }
                    
                    // Reset any visual indication
                    v.alpha = 1.0f
                    
                    // Notify listener
                    listener?.onDragEnded()
                    
                    true
                }
                
                else -> false
            }
        }
    }
    
    /**
     * Create an animation for tab deletion
     */
    fun animateTabDeletion(view: View, onAnimationEnd: () -> Unit) {
        AnimationUtils.deleteAnimation(view, onAnimationEnd)
    }
    
    /**
     * Create an animation for tab creation
     */
    fun animateTabCreation(view: View) {
        AnimationUtils.createAnimation(view)
    }
    
    /**
     * Create an animation for tab movement
     */
    fun animateTabMove(view: View, fromX: Float, fromY: Float, toX: Float, toY: Float, onAnimationEnd: () -> Unit) {
        AnimationUtils.moveAnimation(view, fromX, fromY, toX, toY, onAnimationEnd)
    }
}