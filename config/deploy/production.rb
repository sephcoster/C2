# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary server in each group
# is considered to be the first unless any hosts have the primary
# property set.  Don't declare `role :all`, it's a meta role.

set :stage, :production
set :branch, "production"

# set(:real_revision) { source.query_revision( revision ) { |cmd| capture(cmd) } }
set :use_sudo, false

# set :user, ENV['USER'] || 'ubuntu'
set :user, 'ubuntu'
# set :web_user, "www-data"
set :web_user, "ubuntu"
set :web_group, "www-data"
set :deploy_to, "/projects/test/C2"
set :rails_env, :production

set :application, "c2"
set :scm, "git"
set :repo_url, "https://github.com/18F/C2.git"

server 'ec2-54-185-133-124.us-west-2.compute.amazonaws.com', user: 'ubuntu', roles: %w{web app db}
role :app, %w{ec2-54-185-133-124.us-west-2.compute.amazonaws.com}
role :web, %w{ec2-54-185-133-124.us-west-2.compute.amazonaws.com}
role :db,  %w{ec2-54-185-133-124.us-west-2.compute.amazonaws.com}


namespace :deploy do
  task :take_control do
    sudo "chown -R #{user} #{deploy_to}/", :pty => true
  end

  task :relinquish_control do
    sudo "chown -R #{web_user}:#{web_group} #{deploy_to}/", :pty => true
    sudo "chmod -R g+rx #{deploy_to}/", :pty => true
  end
end

# before 'deploy:updating', 'deploy:take_control'
# after "deploy", "deploy:relinquish_control"
