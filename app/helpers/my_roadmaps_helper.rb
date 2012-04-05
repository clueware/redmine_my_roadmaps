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

module MyRoadmapsHelper
  
  # splits a version name into its constituents, returning an array.
  # Numeric values are converted to a string on 10 positions to ease comparison
  # with non-numeric strings
  def splitVersionName(versionName)
    return versionName.split(/[^a-zA-Z0-9]/).compact.map{ |elem|
      (elem.to_i.to_s!=elem)?(elem.to_s):('%010d' % elem.to_i)
     }
  end
  
end
