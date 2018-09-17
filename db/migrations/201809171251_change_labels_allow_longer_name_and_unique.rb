# require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    alter_table(:labels) do
      add_unique_constraint :label_name, name: :labels_unique_label_name
      drop_constraint(:name_max_length)
    end
  end

  down do
    alter_table(:labels) do
      drop_constraint(:labels_unique_label_name)
      add_constraint(:name_max_length) { char_length(label_name) < 17 }
    end
  end
end
