class LabelRepo < RepoBase
  crud_calls_for :labels, wrapper: Label
end
