# frozen_string_literal: true

Dir['./routes/development/*.rb'].each { |f| require f }

class LabelDesigner < Roda
  route('development') do |r|
    r.multi_route('development')
  end
end
