package com.example.codeeditor.adapters

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.cardview.widget.CardView
import androidx.recyclerview.widget.RecyclerView
import com.example.codeeditor.R
import com.example.codeeditor.model.FileTab

/**
 * Adapter for the tabs in the editor
 */
class TabAdapter(
    private val tabs: List<FileTab>,
    private val onTabSelected: (Int) -> Unit
) : RecyclerView.Adapter<TabAdapter.TabViewHolder>() {
    
    private var selectedTabIndex = 0
    
    inner class TabViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val tabCard: CardView = itemView.findViewById(R.id.tab_card_view)
        val tabName: TextView = itemView.findViewById(R.id.tab_name_text)
        
        init {
            // Normal click listener for tab selection
            itemView.setOnClickListener {
                onTabSelected(bindingAdapterPosition)
            }
            
            // Long press listener for tab closing
            itemView.setOnLongClickListener {
                // Tab closing is handled in the activity
                true
            }
        }
    }
    
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): TabViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.tab_item, parent, false)
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
}