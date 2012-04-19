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

class VersionSynthesis
  def initialize(version, issues)
    @version = version
    @project = version.project
    @issues = Array.new

    @trackers = Array.new
    
    @max_depth=0
    issues.each{ |issue|
      if @trackers.select{|wrapper| wrapper.wrapped_tracker == issue.tracker }.length!=1
        current_tracker = TrackerWrapper.new(version,issue.tracker) 
        @trackers.push(current_tracker)
      else
        current_tracker = @trackers.select{|wrapper| wrapper.wrapped_tracker == issue.tracker }[0]
      end
      current_tracker.addIssue(issue)
      depth=issues.select{|iss| (iss.lft<issue.lft) && (iss.rgt>issue.rgt) && (iss.id!=issue.id) && (iss.root_id==issue.root_id) }.length
      @issues.push(IssueWrapper.new(issue,depth))
      if @max_depth<depth
        @max_depth = depth
      end
    }
    @done_pct = 0
    @done_nb = 0
    @total_nb = 0
    @closed_nb = 0
    @opened_nb = 0
    @closed_pct = 0
    @opened_pct = 0
    @trackers.each{|wrapper|
      @total_nb += wrapper.total_nb
      @closed_nb += wrapper.closed_nb
      @opened_nb += wrapper.opened_nb
      @done_nb += wrapper.done_nb
      @done_pct += wrapper.done_pct
    }
    if @done_nb > 0
      @done_pct /= @done_nb
    end
    if @total_nb > 0
      @closed_pct = @closed_nb*100/@total_nb
      @opened_pct = @opened_nb*100/@total_nb
    end
    @trackers.sort{|a,b| a.wrapped_tracker.position<=>b.wrapped_tracker.position}
  end

  attr_reader :version, :project, :max_depth, :issues, :trackers, :done_nb, :done_pct, :closed_nb, :closed_pct, :opened_nb, :opened_pct
end