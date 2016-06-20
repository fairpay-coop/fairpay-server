# config valid only for current version of Capistrano
lock '3.5.0'

set :rvm_ruby_version, '2.3.0'
set :application, 'fairpay-server'
#set :repo_url, 'git@github.com:fairpay-coop/fairpay-server.git'
# Default branch is :master
#set :branch, 'develop'

set :repo_url, 'git@github.com:twiddlebells/abuntoo-standalone-server.git'
set :branch, 'abuntoo'

# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/home/deploy/fairpay-server'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml', '.env')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')


# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5


##
## JE: temporarily remove this to see whap happens
##

# namespace :deploy do
#
#   after :restart, :clear_cache do
#     on roles(:web), in: :groups, limit: 3, wait: 10 do
#       # Here we can do anything such as:
#       # within release_path do
#       #   execute :rake, 'cache:clear'
#       # end
#       invoke 'unicorn:reload'
#     end
#   end
#
#   after 'publishing', 'restart'
# end


