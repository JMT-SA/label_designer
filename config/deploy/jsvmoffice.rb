# JS VM instance at NoSoft offices
server '192.168.50.11', user: 'nsld', roles: %w[app db web]
set :deploy_to, '/home/nsld/label_designer'
