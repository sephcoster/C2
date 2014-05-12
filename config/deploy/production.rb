# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary server in each group
# is considered to be the first unless any hosts have the primary
# property set.  Don't declare `role :all`, it's a meta role.

set :branch, "production"

set(:real_revision) { source.query_revision( revision ) { |cmd| capture(cmd) } }
set :user, ENV['USER'] || 'ubuntu'
set :web_user, "www-data"
set :web_group, "www-data"
set :deploy_to, "/projects/#{application}"
set :rails_env, :production

role :web, "ec2-54-185-133-124.us-west-2.compute.amazonaws.com"     # Your HTTP server, Apache/etc
role :app, "ec2-54-185-133-124.us-west-2.compute.amazonaws.com"     # This may be the same as your `Web` server
role :db,  "ec2-54-185-133-124.us-west-2.compute.amazonaws.com", :primary => true     # This is where Rails migrations will run

# before 'deploy:update_code', 'deploy:take_control'
# before 'deploy:symlink_db', 'deploy:delete_rvmrc'

namespace :deploy do

  # task :relinquish_control, :roles => :web do
  #   sudo "chown -R #{web_user}:#{web_group} #{deploy_to}/", :pty => true
  #   sudo "chmod -R g+rx #{deploy_to}/", :pty => true
  # end
end

# require './config/boot'
