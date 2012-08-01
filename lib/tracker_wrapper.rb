# encoding: utf-8
# My Roadmaps - Redmine plugin to expose global roadmaps 
# Copyright (C) 2012 Stéphane Rondinaud
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class TrackerWrapper
  def initialize(version, tracker)
    @wrapped_tracker = tracker
    @version = version
    # total issue number
    @total_nb = 0
    # total leaves issue number
    @total_leaves = 0
    # closed issue number
    @closed_nb = 0
    # closed leaves issue number
    @closed_leaves = 0
    # number of issues presenting a completion ratio > 0, excluding closed ones
    @done_nb = 0
    # average completion of the @done_nb issues
    @done_pct = 0.0
    # opened issues number
    @opened_nb = 0
    # opened leaves issues number
    @opened_leaves = 0
    # % of closed issues
    @closed_pct = 0
    # % of closed leaves issues
    @closed_leaves_pct = 0
    # % of opened issues
    @opened_pct = 0
    # total number of root issues for the wrapped tracker
    @total_root_nb = 0
    # closed root issue number
    @closed_root_nb = 0
    # % of closed root issues
    @closed_root_pct = 0
    # number of root issues presenting a completion ratio > 0, excluding closed ones
    @done_root_nb = 0
    # average completion of the @done_root_nb issues
    @done_root_pct = 0.0

    # @done_root_pct accumulator 
    @sum_done_root_pct = 0
    # @done_pct accumulator 
    @sum_done_pct = 0
    
    @is_subtasks = true
  end
  
  # adds a new issue to the statistics
  def addIssue(issue)
    
    # global stats
    @total_nb += 1
    @closed_nb += 1 if issue.closed?
    if (issue.leaf?)
      clear_tracker_subtask_status
      @total_leaves += 1
      @closed_leaves += 1 if issue.closed?
      if issue.done_ratio > 0 && !issue.closed?
        @sum_done_pct += issue.done_ratio 
        @done_nb += 1
      end
    end
    
      # root issues stats
    if issue.root_id == issue.id
      @closed_root_nb += 1 if issue.closed?
      @total_root_nb += 1
      if issue.done_ratio > 0 && !issue.closed?
        @sum_done_root_pct += issue.done_ratio 
        @done_root_nb += 1
      end
    end
    
    # subtasks with only subtasks should be accounted for as long as the tracker
    # itself does not contain leaves issues or root issues
    # The "leaves" statistics then contains the relevant information
    if @is_subtasks && (issue.root_id!=issue.id) && !issue.leaf?
      @total_leaves += 1
      @closed_leaves += 1 if issue.closed?
      if issue.done_ratio > 0 && !issue.closed?
        @sum_done_pct += issue.done_ratio 
        @done_nb += 1
      end
    end
    
    if @done_nb>0
      @done_pct = @sum_done_pct.to_f/@done_nb.to_f
    else
      @done_pct = 0
    end
    
    if @done_root_nb>0
      @done_root_pct = @sum_done_root_pct.to_f/@done_root_nb.to_f
    else
      @done_root_pct = 0
    end

    @opened_nb = @total_nb - @closed_nb
    @opened_leaves = @total_leaves - @closed_leaves
    if @total_nb>0
      @closed_pct = @closed_nb.to_f*100.0/@total_nb.to_f
      @opened_pct = @opened_nb.to_f*100.0/@total_nb.to_f
      @closed_leaves_pct = @closed_leaves.to_f*100.0/@total_leaves.to_f
    else
      @closed_pct = 0
      @opened_pct = 0
      @closed_leaves_pct = 0
    end
    
    if @total_root_nb>0
      @closed_root_pct = @closed_root_nb.to_f*100.0/@total_root_nb.to_f unless @total_root_nb == 0
    else
      @closed_root_pct = 0
    end
  end
  
  # clear the is_subtasks flag and reset simulated leaves statistics
  # when a tracker has a "real" issue
  def clear_tracker_subtask_status
    if @is_subtasks
      @is_subtasks = false
      @total_leaves = 0
      @closed_leaves = 0
      @closed_leaves_pct = 0
      @opened_leaves = 0
      @done_nb = 0
      @done_pct = 0
      @sum_done_pct = 0
    end
  end
  
  # returns the overall root issues done %, taking into account closed root issues and % done
  def overall_root_done_pct
    if @total_root_nb == 0
      result = 0
    else 
      result = (@closed_root_nb.to_f*100.0 + @done_root_nb.to_f*@done_root_pct).to_f/@total_root_nb.to_f
    end
    return result
  end
  
  # returns the overall done %, taking into account closed issues and % done
  def overall_done_pct
    if @total_leaves == 0
      result = 0
    else 
      result = (@closed_leaves.to_f*100.0 + @done_nb.to_f*@done_pct).to_f/@total_leaves.to_f
    end
    return result
  end
  
  attr_reader :wrapped_tracker, :total_nb, :total_root_nb, :total_leaves
  attr_reader :closed_nb, :closed_leaves, :closed_root_nb, :done_root_nb, :done_nb, :opened_nb, :opened_leaves 
  attr_reader :closed_pct, :closed_leaves_pct, :closed_root_pct, :done_root_pct, :done_pct, :opened_pct
  attr_reader :is_subtasks
end
