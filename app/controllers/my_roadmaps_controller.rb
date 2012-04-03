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

require 'version_synthesis'

class MyRoadmapsController < ApplicationController
  unloadable
  before_filter :authorize_my_roadmaps 
  
  def index
    if @user_synthesis.nil?
      @user_synthesis = Hash.new
    else
      @user_synthesis.clear
    end
    
    @tracker_numbers = Array.new
    @all_trackers = params[:all_trackers] ? params[:all_trackers].present? : false
    if @all_trackers
      Tracker.find(:all).sort{ |a,b| a.id<=>b.id }.each{ |tracker|
        @tracker_numbers.push(tracker.id)
      }
    else 
      Tracker.find(:all, :conditions => ['is_in_roadmap = ?', 1]).sort{ |a,b| a.id<=>b.id }.each{ |tracker|
        @tracker_numbers.push(tracker.id)
      }
    end

    Version.find(:all, :visible, :conditions => ['versions.status <> ?', 'closed']) \
      .select{|version| version.project.visible? && !version.completed? } \
      .each{|version|
        issues = Issue.find(:all, :visible, :conditions => ['fixed_version_id = ? && tracker_id in (?)', version.id, @tracker_numbers]) \
        .select{|iss|
          (iss.root_id == iss.id || Issue.find(:all, :conditions => ['root_id = ? and fixed_version_id = ?', iss.root_id, version.id]).length>0)
        }
      @user_synthesis[version] = VersionSynthesis.new(version, issues)
    }
  end
  
  private
  
  def authorize_my_roadmaps
    if !(User.current.allowed_to?(:view_my_roadmaps, nil, :global => true) || User.current.admin?)
      render_403
      return false
    end
    return true
  end
end
