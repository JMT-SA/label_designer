Sequel.migration do
  up do
    alter_table(:labels) do
      add_column :variable_set, String
      add_column :active, TrueClass, default: true
      add_column :created_by, String
      add_column :updated_by, String
    end

    run "UPDATE labels SET variable_set = 'CMS';"

    alter_table(:labels) do
      set_column_not_null :variable_set
    end
  end

  down do
    alter_table(:labels) do
      drop_column :variable_set
      drop_column :active
      drop_column :created_by
      drop_column :updated_by
    end
  end
end
