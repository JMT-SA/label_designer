Sequel.migration do
  up do
    alter_table :labels do
      add_column :print_rotation, Integer, default: 0
    end
  end
  down do
    alter_table :labels do
      drop_column :print_rotation
    end
  end
end
