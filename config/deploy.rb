require 'mina/chruby'
require 'mina/git'
require 'mina/bundler'
require 'mina/deploy'

# Basic settings:

# This is required, because user-input is required to install gems from github.
# Once the gems are published, this can probably be changed back to :pretty.
set :execution_mode, :system
# ---
set :application_name, 'label_designer'
# set :domain, '192.168.50.27'
set :domain, '10.0.0.6'
set :deploy_to, '/home/nsld/label_designer'
set :repository, 'https://github.com/NoSoft-SA/label_designer.git'
# set :branch, 'master'
set :branch, 'develop'

# Optional settings:
set :user, 'nsld'          # Username in the server to SSH to.
#   set :port, '30000'           # SSH port number.
#   set :forward_agent, true     # SSH forward_agent.
set :version_scheme, :datetime

set :rake, 'bundle exec rake'

# Shared dirs and files will be symlinked into the app-folder by the 'deploy:link_shared_paths' step.
# Some plugins already add folders to shared_dirs like `mina/rails` add `public/assets`, `vendor/bundle` and many more
# run `mina -d` to see all folders and files already included in `shared_dirs` and `shared_files`
set :shared_dirs, fetch(:shared_dirs, []).push('public/assets', 'public/tempfiles', 'tmp')
# set :shared_files, fetch(:shared_files, []).push('config/database.yml', 'config/secrets.yml')

# This task is the environment that is loaded for all remote run commands, such as
# `mina deploy` or `mina rake`.
task :remote_environment do
  invoke :chruby, 'ruby-2.5'
end

# Put any custom commands you need to run at setup
# All paths in `shared_dirs` and `shared_paths` will be created on their own.
task :setup do
  # command %{rbenv install 2.3.0 --skip-existing}
end

desc 'Deploys the current version to the server.'
task :deploy do
  # uncomment this line to make sure you pushed your local branch to the remote origin
  # invoke :'git:ensure_pushed'
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    comment %(Migrating database)
    command %(#{fetch(:rake)} db:migrate)
    comment %(Pre-compiling assets)
    command %(RACK_ENV=production #{fetch(:rake)} assets:precompile)
    invoke :'deploy:cleanup'

    # TODO: restart puma & nginx
    # on :launch do
    #   in_path(fetch(:current_path)) do
    #     command %(mkdir -p tmp/)
    #     command %(touch tmp/restart.txt)
    #   end
    # end
  end

  # you can use `run :local` to run tasks on local machine before of after the deploy scripts
  # run(:local){ say 'done' }
end

desc 'Add a user'
task :add_user do
  require 'highline/import'
  require 'bcrypt'

  login = ask('Create a new user: Login code (No spaces, lowercase):')
  name = ask('Create a new user: Name:')
  passwd = ask('Create a new user: Password:') { |q| q.echo = 'x' }
  comment %(Creating new user - #{name})
  pwd_hash = BCrypt::Password.create(passwd)
  sql = "INSERT INTO users (login_name, user_name, password_hash) VALUES ('#{login}', '#{name}', '#{pwd_hash.gsub('$', '\$')}');"

  command %(psql -U postgres -d label_designer -c "#{sql}")
end

desc 'Seed the database'
task :db_seed do
  run :remote do
    command %(cd "#{fetch(:current_path)}/db/seeds")
    command %(psql -U postgres -d label_designer < basic_menu.sql)
    command %(psql -U postgres -d label_designer < security_basics.sql)
    command %(psql -U postgres -d label_designer < label_designer_menu.sql)
    command %(psql -U postgres -d label_designer < initial_user_security.sql)
  end
end

# For help in making your deploy script, see the Mina documentation:
#
#  - https://github.com/mina-deploy/mina/tree/master/docs
