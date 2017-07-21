class LabelRepo < RepoBase
  def initialize
    set_main_table :labels
    set_wrapper Label
  end
end
