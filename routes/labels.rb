# frozen_string_literal: true

Dir['./routes/labels/*.rb'].each { |f| require f }

class LabelDesigner < Roda
  route('labels') do |r|
    r.multi_route('labels')
  end
end
