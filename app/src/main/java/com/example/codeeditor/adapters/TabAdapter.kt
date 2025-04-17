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
 * Adapter for the tabs RecyclerView
 */
class TabAdapter(
    private val tabs: List<FileTab>,
    private val listener: TabInteractionListener
) : RecyclerView.Adapter<TabAdapter.TabViewHolder>() {
    
    private var selectedTabPosition = -1
    
    interface TabInteractionListener {
        fun onTabSelected(position: Int)
        fun onTabLongPressed(position: Int)
    }
    
    class TabViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val tabCardView: CardView = itemView.findViewById(R.id.tab_card_view)
        val tabNameText: TextView = itemView.findViewById(R.id.tab_name_text)
    }
    
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): TabViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.tab_item, parent, false)
        return TabViewHolder(view)
    }
    
    override fun onBindViewHolder(holder: TabViewHolder, position: Int) {
        val tab = tabs[position]
        
        // Set tab name
        holder.tabNameText.text = tab.getShortName()
        
        // Set background based on selected state and modified state
        if (position == selectedTabPosition) {
            holder.tabCardView.setCardBackgroundColor(
                holder.itemView.context.getColor(R.color.tabSelectedBackground)
            )
        } else if (tab.isModified || tab.isNew) {
            // Yellow background for unsaved tabs
            holder.tabCardView.setCardBackgroundColor(
                holder.itemView.context.getColor(R.color.tabUnsavedBackground)
            )
        } else {
            holder.tabCardView.setCardBackgroundColor(
                holder.itemView.context.getColor(R.color.tabBackground)
            )
        }
        
        // Set click listener
        holder.tabCardView.setOnClickListener {
            listener.onTabSelected(position)
        }
        
        // Set long click listener
        holder.tabCardView.setOnLongClickListener {
            listener.onTabLongPressed(position)
            true
        }
    }
    
    override fun getItemCount(): Int = tabs.size
    
    fun setSelectedTab(position: Int) {
        val previousSelected = selectedTabPosition
        selectedTabPosition = position
        
        if (previousSelected >= 0) {
            notifyItemChanged(previousSelected)
        }
        
        if (selectedTabPosition >= 0) {
            notifyItemChanged(selectedTabPosition)
        }
    }
}
