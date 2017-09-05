Sequel.migration do
  up do
    alter_table(:labels) do
      set_column_default :label_dimension, '8464'
      set_column_not_null :label_dimension
    end
  end

  down do
    alter_table(:albums) do
      set_column_allow_null :label_dimension
      set_column_default :label_dimension, nil
    end
  end
end
