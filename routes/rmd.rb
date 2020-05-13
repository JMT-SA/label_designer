# frozen_string_literal: true

Dir['./routes/rmd/*.rb'].sort.each { |f| require f }

class LabelDesigner < Roda
  route('rmd') do |r|
    store_current_functional_area('rmd')

    r.multi_route('rmd')
  end
end
