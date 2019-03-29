# VM instance at TAD.
server '172.18.0.23', user: 'nsld', roles: %w[app db web]
set :deploy_to, '/home/nsld/label_designer'
set :ssh_options,
    forward_agent: true,
    keys: '~/.ssh/id_rsa'
set :chruby_ruby, 'ruby-2.5.5'
