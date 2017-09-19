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

require 'version_synthesis'

class MyRoadmapsController < ApplicationController
  unloadable
  before_filter :authorize_my_roadmaps

  helper :Queries

  def index
    get_query

    @user_synthesis = Hash.new

    if @query.has_filter?('tracker_id')
      tracker_list = Tracker.where(is_in_roadmap: true).where(@query.statement_for('tracker_id').gsub('issues.tracker_id','trackers.id')).order(:position).ids
    else
      tracker_list = Tracker.where(is_in_roadmap: true).order(:position).ids
    end

    # condition hacked from the Query model to match versions
    version_condition = '(versions.status <> \'closed\')'
    version_condition += ' and ('+@query.statement_for('project_id').gsub('issues','versions')+' or exists (select 1 from issues where issues.fixed_version_id = versions.id and '+@query.statement_for('project_id')+'))' if @query.has_filter?('project_id')

    Version.where(version_condition).all() \
    .select{|version| !version.completed? } \
    .each{|version|
      issue_condition = ''
      issue_condition += @query.statement_for('project_id')+' and ' unless @query.statement_for('project_id').nil?
      issue_condition += 'tracker_id in (?) and '+ \
        '( fixed_version_id = ? '+ \
        'or exists (select 1 '+ \
        'from issues as subissues '+ \
        'where issues.root_id = subissues.root_id '+ \
        'and subissues.fixed_version_id = ?) )'

      issue_condition = [issue_condition, tracker_list, version.id, version.id]

      grouped_issues = Hash.new
      Issue.visible.where(issue_condition).includes([:status,:tracker]).find_each do |issue|
        if grouped_issues[issue.project].nil?
          grouped_issues[issue.project]=[issue]
        else
          grouped_issues[issue.project].push(issue)
        end
      end

      grouped_issues.each{|project, issues|
        if @user_synthesis[project].nil?
          @user_synthesis[project] = Hash.new
        end
        if @user_synthesis[project][version].nil?
          @user_synthesis[project][version] = VersionSynthesis.new(project, version, issues.select{|i| i.project_id == project.id})
        else
          @user_synthesis[project][version].add_issues(issues.select{|i| i.project_id == project.id})
        end
      }
    }
  end

  def initialize
  	super
    index=0
    @tracker_styles = Hash.new
    Tracker.where(is_in_roadmap: true).order(:position).ids.each{|tracker_id|
      @tracker_styles[tracker_id]=Hash.new
      @tracker_styles[tracker_id][:opened] = "t"+(index%10).to_s+"_opened"
      @tracker_styles[tracker_id][:done] = "t"+(index%10).to_s+"_done"
      @tracker_styles[tracker_id][:closed] = "t"+(index%10).to_s+"_closed"
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

  class CustomQuery < IssueQuery
    self.queried_class = Issue
    self.view_permission = :view_my_roadmaps

    self.available_columns = [
      QueryColumn.new(:id, :sortable => "#{Issue.table_name}.id", :default_order => 'desc', :caption => '#', :frozen => true),
      QueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :groupable => true),
      QueryColumn.new(:tracker, :sortable => "#{Tracker.table_name}.position", :groupable => true),
      QueryColumn.new(:parent, :sortable => ["#{Issue.table_name}.root_id", "#{Issue.table_name}.lft ASC"], :default_order => 'desc', :caption => :field_parent_issue),
      QueryColumn.new(:status, :sortable => "#{IssueStatus.table_name}.position", :groupable => true),
      QueryColumn.new(:fixed_version, :sortable => lambda {Version.fields_for_order_statement}, :groupable => true),
      QueryColumn.new(:done_ratio, :sortable => "#{Issue.table_name}.done_ratio", :groupable => true),
    ]

    def initialize(attributes=nil, *args)
      super attributes
    end

    def initialize_available_filters
      add_available_filter("project_id",
      :type => :list, :values => Project.visible.collect{|p| [p.name, p.id.to_s]}
    ) if project.nil?

    add_available_filter "tracker_id",
      :type => :list, :values => trackers.select{|t| t.is_in_roadmap}.collect{|s| [s.name, s.id.to_s] }
    end
  end

  def get_query
    @query = CustomQuery.new(:name => "_", :filters => {});
    if params[:f]
      @query.build_from_params(params)
    end
  end
end
