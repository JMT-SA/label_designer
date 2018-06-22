# config valid for current version and patch releases of Capistrano
# lock '~> 3.10.1' # --- Handled by bundler...
set :chruby_ruby, 'ruby-2.5.1'

set :application, 'label_designer'
set :repo_url, 'git@github.com:NoSoft-SA/label_designer.git'

# *********************************************************************************************************************************************************
# NB. On first deploy, go to the realease on the server and run the bundle install command:
# /usr/local/bin/chruby-exec ruby-2.5.0 -- bundle install --path /home/nsld/label_designer/shared/bundle --without development test --deployment --quiet
# (modified as appropriate). This will prompt for github user/password -  so that the gems from github can be fetched. Subsequent deploys should just work.
# *********************************************************************************************************************************************************

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :branch, :master # WHILE testing...

set :rack_env, :production # SET THESE UP IN deploy files (hm6, hm7, nosoft, schb...)

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/home/nsld/label_designer' # Set in config in deploy/ dir

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, 'config/database.yml', 'config/secrets.yml'
append :linked_files, 'public/js/ag-enterprise-activation.js', '.env.local'

# Default value for linked_dirs is []
# append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system'
append :linked_dirs, 'log', 'tmp', 'public/assets', 'public/tempfiles', 'vendor/bundle'

# Default value for default_env is {}
# set :default_env, { path: '/opt/ruby/bin:$PATH' }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

desc 'Runs rake db:migrate if migrations are set'
task :migrate do
  on primary :db do
    within release_path do
      with rack_env: fetch(:rack_env) do
        execute :rake, 'db:migrate'
      end
    end
  end
end

desc 'Runs rake assets:precompile'
task :precompile do
  on primary :app do
    within release_path do
      with rack_env: fetch(:rack_env) do
        execute :rake, 'assets:precompile'
      end
    end
  end
end

namespace :devops do
  desc 'Add a user'
  task :add_user do
    require 'bcrypt'

    puts("\n--------------------------------------------------------------------------------------------------")
    puts('Create a new user: (login and passwd values: No spaces, all lowercase; user name can have spaces.)')
    puts("--------------------------------------------------------------------------------------------------\n\n")
    ask(:login_name, nil)
    ask(:password, nil, echo: false)
    ask(:user_name, nil)
    login_name = fetch(:login_name).downcase
    pwd_hash = BCrypt::Password.create(fetch(:password))
    user_name = fetch(:user_name)

    on primary :db do
      within release_path do
        with rack_env: fetch(:rack_env) do
          execute :rake, "db:add_user['#{login_name}','#{pwd_hash}','#{user_name}']"
        end
      end
    end
  end
end

namespace :devops do
  desc 'Copy initial files'
  task :copy_initial do
    on roles(:app) do |_|
      upload! 'public/js/ag-enterprise-activation.js', "#{shared_path}/public/js/ag-enterprise-activation.js"
    end
  end
end

namespace :deploy do
  after :updated, :migrate_and_precompile do
    invoke 'migrate'
    invoke 'precompile'
  end
end
