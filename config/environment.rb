require 'dotenv'

Dotenv.load

require 'sequel'
DB = Sequel.connect(ENV.fetch('LD_DATABASE_URL'))

