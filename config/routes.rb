
if Rails.version.to_f >= 3.0
  match "/my_roadmaps", :controller => "my_roadmaps", :action => "index"
else
  ActionController::Routing::Routes.draw do |map|
    map.connect "/my_roadmaps", :controller => "my_roadmaps"
  end
end
