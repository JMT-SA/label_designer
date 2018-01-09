Sequel.migration do
  up do
    alter_table(:labels) do
     add_constraint(:name_max_length) { char_length(label_name) < 17 }
    end
  end

  down do
    alter_table(:labels) do
     drop_constraint(:name_max_length)
    end
  end
end
