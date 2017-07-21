LabelSchema = Dry::Validation.Schema do
  required(:label_name).filled(:str?)
end
