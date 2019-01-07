Sequel.migration do
  up do
    alter_table(:labels) do
      add_column :variable_set, String
    end

    run "UPDATE labels SET variable_set = 'CMS';"
  end

  down do
    alter_table(:labels) do
      drop_column :variable_set
    end
  end
end
