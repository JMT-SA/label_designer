# frozen_string_literal: true

# GHS - Goede Hoop Sitrus
server '192.168.6.21', user: 'ghsadmin', roles: %w[app db web]
set :deploy_to, '/home/ghsadmin/label_designer'
set :chruby_ruby, 'ruby-2.5.8'
