Dir['./lib/labels/entities/*.rb'].each { |f| require f }
Dir['./lib/labels/validations/*.rb'].each { |f| require f }
Dir['./lib/labels/repositories/*.rb'].each { |f| require f }
Dir['./lib/labels/views/*.rb'].each { |f| require f }
