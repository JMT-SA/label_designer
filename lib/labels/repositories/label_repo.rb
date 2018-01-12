class LabelRepo < RepoBase
  crud_calls_for :labels, name: :label, wrapper: Label
end
