# VM instance at Schoeman Boerdery
server '192.168.17.53', user: 'cms', roles: %w[app db web]
set :deploy_to, '/home/cms/label_designer'
