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

class IssueWrapper
  def initialize(wrapped_issue, depth)
    @wrapped_issue = wrapped_issue
    @depth = depth    
  end
  
  def <=>(other)
    [((self.wrapped_issue.root_id==self.wrapped_issue.id)?(self.wrapped_issue.tracker):(self.wrapped_issue.root.tracker)), \
      self.wrapped_issue.root_id, \
      self.wrapped_issue.self_and_ancestors.to_a, \
      self.wrapped_issue.tracker, \
      self.wrapped_issue.id] \
    <=> \
    [((other.wrapped_issue.root_id==other.wrapped_issue.id)?(other.wrapped_issue.tracker):(other.wrapped_issue.root.tracker)), \
      other.wrapped_issue.root_id, \
      other.wrapped_issue.self_and_ancestors.to_a, \
      other.wrapped_issue.tracker, \
      other.wrapped_issue.id]
  end

  attr_reader :wrapped_issue, :depth
end
