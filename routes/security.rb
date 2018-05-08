# frozen_string_literal: true

Dir['./routes/security/*.rb'].each { |f| require f }

class LabelDesigner < Roda
  route('security') do |r|
    store_current_functional_area('security')
    r.multi_route('security')
  end
end
