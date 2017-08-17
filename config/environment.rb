require 'dotenv'

Dotenv.load('.env.local', '.env')

require 'sequel'
DB = Sequel.connect(ENV.fetch('LD_DATABASE_URL'))

