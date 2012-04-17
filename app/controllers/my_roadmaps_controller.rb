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

  helper :queries
  include QueriesHelper
  
  def index

    get_query
    
    if @user_synthesis.nil?
      @user_synthesis = Hash.new
    else
      @user_synthesis.clear
    end
    
    if @query.has_filter?('tracker_id')
      tracker_list = Tracker.find(:all, :conditions => [@query.statement_for('tracker_id').sub('issues.tracker_id','trackers.id')], :order => 'position')
    else 
      tracker_list = Tracker.find(:all, :conditions => ['is_in_roadmap = ?', 1], :order => 'position')
    end

    # condition hacked from the Query model to match versions
    version_condition = '(versions.status <> \'closed\')'
    version_condition += ' and ('+@query.statement_for('project_id').gsub('issues','versions')+' or exists (select 1 from issues where issues.fixed_version_id = versions.id and '+@query.statement_for('project_id')+'))' if @query.has_filter?('project_id')

    Version.find(:all, :conditions => [version_condition] ) \
      .select{|version| !version.completed? } \
      .each{|version|
        affected_project_ids = [version.project.id]
        case
        when version.sharing == 'none'
          # do nothing: the version is not shared
        when version.sharing == 'descendants'
          version.project.descendants.visible.each{|p|
            affected_project_ids.push(p.id)
          }
        when (version.sharing == 'hierarchy') || (version.sharing ==  'tree')
          version.project.hierarchy.visible.each{|p|
              affected_project_ids.push(p.id)
            }
        when version.sharing == 'system'
          Projects.visible.each{|p|
              affected_project_ids.push(p.id)
            }
        end
        # list affected projects
        issue_condition = @query.statement_for('project_id')+' and '+ \
                           'tracker_id in (?) and '+ \
                           '( fixed_version_id = ? '+ \
                            'or exists (select 1 '+ \
                              'from issues as subissues '+ \
                              'where issues.root_id = subissues.root_id '+ \
                              'and subissues.fixed_version_id = ?) )'
        if User.current.admin?
          issue_condition = [issue_condition,
                             tracker_list, version.id, version.id]
        else
          issue_condition = [issue_condition + \
                              'and (assigned_to_id is null or assigned_to_id = ?)',
                             tracker_list, version.id, version.id, User.current.id ]
        end

        issues = Issue.visible.find(:all, :conditions => issue_condition ) \
        .select{|iss|
          (( iss.fixed_version_id == version.id && iss.root_id == iss.id) || Issue.find(:all, :conditions => ['root_id = ? and fixed_version_id = ?', iss.root_id, version.id]).length>0)
        }
      @user_synthesis[version] = VersionSynthesis.new(version, issues) if issues.length > 0
    }
  end
  
  def initialize
    index=0
    @tracker_styles = Hash.new
    Tracker.find(:all, :conditions => ['is_in_roadmap = ?', 1], :order => 'position' ).each{ |tracker|
      @tracker_styles[tracker]=Hash.new
      @tracker_styles[tracker][:opened] = "t"+(index%10).to_s+"_opened"
      @tracker_styles[tracker][:done] = "t"+(index%10).to_s+"_done"
      @tracker_styles[tracker][:closed] = "t"+(index%10).to_s+"_closed"
      index += 1
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
  
  def get_query
    @query = Query.new(:name => "_", :filters => {})
    user_projects = Project.visible
    user_trackers = Tracker.find(:all, :conditions => ['is_in_roadmap = ?', 1])
    filters = Hash.new
    filters['project_id'] = { :type => :list_optional, :order => 1, :values => user_projects.sort{|a,b| a.self_and_ancestors.join('/')<=>b.self_and_ancestors.join('/') }.collect{|s| [s.self_and_ancestors.join('/'), s.id.to_s] } } unless user_projects.empty?
    filters['tracker_id'] = { :type => :list, :order => 2, :values => Tracker.find(:all, :conditions => ['is_in_roadmap = ?', 1], :order => 'position' ).collect{|s| [s.name, s.id.to_s] } } unless user_trackers.empty?
    @query.override_available_filters(filters)
    if params[:f]
      build_query_from_params
    end
    @query.filters={ 'project_id' => {:operator => "*", :values => [""]} } if @query.filters.length==0
  end
end
