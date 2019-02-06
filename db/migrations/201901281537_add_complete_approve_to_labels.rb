Sequel.migration do
  up do
    alter_table(:labels) do
      add_column :completed, TrueClass, default: false
      add_column :approved, TrueClass, default: false
    end
  end

  down do
    alter_table(:labels) do
      drop_column :completed
      drop_column :approved
    end
  end
end
