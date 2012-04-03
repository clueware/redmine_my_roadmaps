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
    @total_nb = 0
    @closed_nb = 0
    @done_nb = 0
    @done_pct = 0.0
    @sum_done_pct = 0
    @opened_nb = 0
    @closed_pct = 0
    @opened_pct = 0
    @total_root_nb = 0
  end
  
  def addIssue(issue)
    @total_nb += 1
    
    if issue.root_id == issue.id
      @closed_nb += 1 if issue.closed?
      @total_root_nb += 1
      if issue.done_ratio > 0 && !issue.closed?
        @sum_done_pct += issue.done_ratio 
        @done_nb += 1
      end
    end
    if @done_nb>0
      @done_pct = @sum_done_pct.to_f/@done_nb
    end

    @opened_nb = @total_nb - @closed_nb
    @closed_pct = @closed_nb*100/@total_nb
    @opened_pct = @opened_nb*100/@total_nb
  end
  
  attr_reader :wrapped_tracker, :total_nb, :total_root_nb, :closed_nb, :done_nb, :done_pct, :opened_nb, :closed_pct, :opened_pct
end