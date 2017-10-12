class LabelRepo < RepoBase
  def initialize
    main_table :labels
    table_wrapper Label
  end
end
