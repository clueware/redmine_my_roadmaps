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

Redmine::Plugin.register :redmine_my_roadmaps do
  name 'My Roadmaps plugin'
  author 'Stéphane Rondinaud'
  description 'This plugin provides a global roadmaps for all the projects of the user.'
  version '0.2.1_redmine3.0'
  url 'https://github.com/clueware/redmine_my_roadmaps'

  permission :view_my_roadmaps, :my_roadmaps => :index
  menu :top_menu, :my_roadmaps, { :controller => 'my_roadmaps', :action => 'index' }, :caption => :my_roadmaps_name, :if => Proc.new { User.current.allowed_to?(:view_my_roadmaps, nil, :global => true) }
end
