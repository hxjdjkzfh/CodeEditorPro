package com.example.codeeditor.adapters

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.cardview.widget.CardView
import androidx.recyclerview.widget.RecyclerView
import com.example.codeeditor.R
import com.example.codeeditor.model.FileTab
import com.example.codeeditor.utils.AnimationUtils
import com.example.codeeditor.utils.DragDropManager

/**
 * Adapter for the tabs in the editor with drag, drop, and delete animations
 */
class TabAdapter(
    private val tabs: MutableList<FileTab>,
    private val onTabSelected: (Int) -> Unit,
    private val onTabClosed: (Int) -> Unit,
    private val onTabMoved: (Int, Int) -> Unit
) : RecyclerView.Adapter<TabAdapter.TabViewHolder>() {
    
    private var selectedTabIndex = 0
    private var dragDropManager: DragDropManager? = null
    private var isDragging = false
    
    inner class TabViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val tabCard: CardView = itemView.findViewById(R.id.tab_card_view)
        val tabName: TextView = itemView.findViewById(R.id.tab_name_text)
        val closeButton: ImageView = itemView.findViewById(R.id.tab_close_button)
        
        init {
            // Normal click listener for tab selection
            itemView.setOnClickListener {
                val position = bindingAdapterPosition
                if (position != RecyclerView.NO_POSITION) {
                    onTabSelected(position)
                    AnimationUtils.highlightAnimation(itemView)
                }
            }
            
            // Close button click listener
            closeButton.setOnClickListener { 
                val position = bindingAdapterPosition
                if (position != RecyclerView.NO_POSITION) {
                    // Анимация удаления вкладки
                    dragDropManager?.animateTabDeletion(itemView) {
                        onTabClosed(position)
                    }
                }
            }
            
            // Long press listener for tab dragging
            itemView.setOnLongClickListener { view ->
                val position = bindingAdapterPosition
                if (position != RecyclerView.NO_POSITION) {
                    // Начинаем перетаскивание вкладки
                    dragDropManager?.startDrag(view)
                }
                true
            }
        }
    }
    
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): TabViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.tab_item, parent, false)
        
        // Initialize drag-drop manager if needed
        if (dragDropManager == null && parent is RecyclerView) {
            dragDropManager = DragDropManager(parent)
            setupDragDropListeners()
        }
        
        return TabViewHolder(view)
    }
    
    override fun onBindViewHolder(holder: TabViewHolder, position: Int) {
        val tab = tabs[position]
        
        // Set tab name (shortened)
        holder.tabName.text = tab.getShortName()
        
        // Set selected state
        if (position == selectedTabIndex) {
            holder.tabCard.setCardBackgroundColor(
                holder.itemView.context.getColor(R.color.tabSelectedBackground)
            )
        } else {
            // Set unsaved state with different background
            if (tab.isUnsaved) {
                holder.tabCard.setCardBackgroundColor(
                    holder.itemView.context.getColor(R.color.tabUnsavedBackground)
                )
            } else {
                holder.tabCard.setCardBackgroundColor(
                    holder.itemView.context.getColor(R.color.tabBackground)
                )
            }
        }
        
        // Set up drag and drop
        dragDropManager?.makeViewDraggable(holder.itemView, tab, position)
        dragDropManager?.setupDropTarget(holder.itemView, position)
    }
    
    override fun getItemCount(): Int = tabs.size
    
    /**
     * Update the selected tab
     */
    fun setSelectedTab(position: Int) {
        val previousSelected = selectedTabIndex
        selectedTabIndex = position
        
        // Update the views
        notifyItemChanged(previousSelected)
        notifyItemChanged(selectedTabIndex)
    }
    
    /**
     * Add a new tab with creation animation
     */
    fun addTab(tab: FileTab, position: Int = tabs.size) {
        tabs.add(position, tab)
        notifyItemInserted(position)
        
        // Get the view for animation after it's bound
        (dragDropManager?.container as? RecyclerView)?.post {
            val viewHolder = (dragDropManager?.container as? RecyclerView)?.findViewHolderForAdapterPosition(position)
            viewHolder?.itemView?.let { view ->
                dragDropManager?.animateTabCreation(view)
            }
        }
    }
    
    /**
     * Remove a tab with deletion animation
     */
    fun removeTab(position: Int) {
        if (position < 0 || position >= tabs.size) return
        
        // Get the view for animation before removing
        val viewToAnimate = (dragDropManager?.container as? RecyclerView)?.findViewHolderForAdapterPosition(position)?.itemView
        
        // If we have a view, animate it before removal
        if (viewToAnimate != null) {
            dragDropManager?.animateTabDeletion(viewToAnimate) {
                // After animation completes, remove the item
                if (position < tabs.size) { // Check again as adapter state might have changed
                    tabs.removeAt(position)
                    notifyItemRemoved(position)
                    
                    // Update selected tab if needed
                    if (position <= selectedTabIndex && selectedTabIndex > 0) {
                        selectedTabIndex--
                    }
                }
            }
        } else {
            // No view to animate, just remove
            tabs.removeAt(position)
            notifyItemRemoved(position)
            
            // Update selected tab if needed
            if (position <= selectedTabIndex && selectedTabIndex > 0) {
                selectedTabIndex--
            }
        }
    }
    
    /**
     * Animate the movement of a tab from one position to another
     */
    fun moveTab(fromPosition: Int, toPosition: Int) {
        if (fromPosition < 0 || fromPosition >= tabs.size || 
            toPosition < 0 || toPosition >= tabs.size) {
            return
        }
        
        // Get the tab being moved
        val tab = tabs[fromPosition]
        
        // Update the internal data
        tabs.removeAt(fromPosition)
        tabs.add(toPosition, tab)
        
        // Notify the adapter
        notifyItemMoved(fromPosition, toPosition)
        
        // Update selected tab if needed
        if (selectedTabIndex == fromPosition) {
            selectedTabIndex = toPosition
        } else if (fromPosition < selectedTabIndex && selectedTabIndex <= toPosition) {
            selectedTabIndex--
        } else if (fromPosition > selectedTabIndex && selectedTabIndex >= toPosition) {
            selectedTabIndex++
        }
        
        // Perform the move animation via animation utility
        onTabMoved(fromPosition, toPosition)
    }
    
    /**
     * Setup drag and drop listeners
     */
    private fun setupDragDropListeners() {
        dragDropManager?.setDragDropListener(object : DragDropManager.DragDropListener {
            override fun onDragStarted(fileTab: FileTab, view: View) {
                isDragging = true
            }
            
            override fun onDropped(fileTab: FileTab, targetPosition: Int): Boolean {
                // Find the source position
                val sourcePosition = tabs.indexOf(fileTab)
                if (sourcePosition != -1 && sourcePosition != targetPosition) {
                    // Move the tab
                    moveTab(sourcePosition, targetPosition)
                    return true
                }
                return false
            }
            
            override fun onDragEnded() {
                isDragging = false
            }
        })
    }
    
    /**
     * Mark a tab as unsaved and update its appearance
     */
    fun setTabUnsaved(position: Int, unsaved: Boolean) {
        if (position >= 0 && position < tabs.size) {
            tabs[position].isUnsaved = unsaved
            notifyItemChanged(position)
            
            // Add a subtle highlight animation if becoming unsaved
            if (unsaved) {
                (dragDropManager?.container as? RecyclerView)?.findViewHolderForAdapterPosition(position)?.itemView?.let { view ->
                    AnimationUtils.highlightAnimation(view)
                }
            }
        }
    }
}