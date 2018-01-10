# frozen_string_literal: true

class MasterListRepo < RepoBase
  build_for_select :master_lists,
                   # label: :description,
                   value: :description,
                   no_active_check: true,
                   order_by: :description

  crud_calls_for :master_lists, name: :master_list, wrapper: MasterList
end
