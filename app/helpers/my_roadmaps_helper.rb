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

require_dependency 'query'

module MyRoadmapsHelper
  
  module VersionPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
    end
    module InstanceMethods
      def splitted_version_name
        return self.name.split(/[^a-zA-Z0-9]/).compact.map{ |elem|
          (elem.to_i.to_s!=elem)?(elem.to_s):('%010d' % elem.to_i)
         }
      end
    end
  end
  
  module QueryPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
    end
    
    module InstanceMethods
      def override_available_filters(new_filters=nil)
        @available_filters = new_filters if (!new_filters.nil? && new_filters.is_a?(Hash))
        @available_filters.each do |field, options|
          options[:name] ||= l("field_#{field}".gsub(/_id$/, ''))
        end
      end
      
      def statement_for(field_name)
        # Copy/pasted from Query.statement
        # filters clauses
        filters_clauses = []
        filters.each_key do |field|
          next if field == "subproject_id" || field != field_name
          v = values_for(field).clone
          next unless v and !v.empty?
          operator = operator_for(field)
    
          # "me" value substitution
          if %w(assigned_to_id author_id watcher_id).include?(field)
            if v.delete("me")
              if User.current.logged?
                v.push(User.current.id.to_s)
                v += User.current.group_ids.map(&:to_s) if field == 'assigned_to_id'
              else
                v.push("0")
              end
            end
          end
    
          if field =~ /^cf_(\d+)$/
            # custom field
            filters_clauses << sql_for_custom_field(field, operator, v, $1)
          elsif respond_to?("sql_for_#{field}_field")
            # specific statement
            filters_clauses << send("sql_for_#{field}_field", field, operator, v)
          else
            # regular field
            filters_clauses << '(' + sql_for_field(field, operator, v, Issue.table_name, field) + ')'
          end
        end if filters and valid?
    
        filters_clauses << project_statement
        filters_clauses.reject!(&:blank?)
    
        filters_clauses.any? ? filters_clauses.join(' AND ') : nil
      end
    end
  end
  
  Query.send(:include, QueryPatch)
  Version.send(:include, VersionPatch)
end
