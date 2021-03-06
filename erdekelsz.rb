require 'rubygems'
require 'sinatra'
require 'sinatra/gadgeteer'
require 'gadget'
require 'model'

set :raise_errors, true
set :logging, true

get '/' do
  haml :about
end

get '/gadget.xml' do
  @title = request.query_string
  haml :gadget
end

get %r{/test/(.*)} do
  request.path_info.inspect
end

profile_path = %r{^/profiles/(.*)}

before do
  if request.path_info =~ profile_path and not verify_signature
    halt(401, "oops!")
  end
end

get profile_path do
  if os_viewer[:id] == os_owner[:id]
    @viewer = Profile.get(os_viewer[:id]) || Profile.new(:id => os_viewer[:id])
    @viewer.update_attributes(os_viewer, *@viewer.attributes.keys)
    @matches, @marked = @viewer.marked_profiles.partition do |p|
      @viewer.marked_by.include?(p)
    end
    haml :profile
  else
    @viewer = Profile.get(os_viewer[:id])
    @owner  = Profile.get(os_owner[:id])
    haml :interest
  end
end

post profile_path do
  @viewer = Profile.get(os_viewer[:id])
  @owner  = Profile.get(os_owner[:id])
  @viewer.interests.create :interested_in => @owner
  redirect request.path_info
end

delete profile_path do
  @viewer = Profile.get(os_viewer[:id])
  @owner  = Profile.get(os_owner[:id])
  @viewer.interests.first(:interested_in_id => @owner.id).destroy
  redirect request.path_info
end

helpers do
  def profile_link(p)
    %{<a href="/profile/#{p.id}">#{p.display_name}</a>}
  end
end
