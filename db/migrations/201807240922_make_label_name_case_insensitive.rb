# Change the label_name column to store its values in a case-insensitive manner.
# This ensures that you can't have two files that differ only by case
# (these would be treated as the same file on Windows machines).

Sequel.migration do
  up do
    run 'CREATE EXTENSION IF NOT EXISTS citext;'
    alter_table(:labels) do
      set_column_type :label_name, :citext
    end
  end

  down do
    alter_table(:labels) do
      set_column_type :label_name, :string
    end
  end
end
