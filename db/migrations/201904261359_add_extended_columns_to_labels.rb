Sequel.migration do
  up do
    extension :pg_json
    add_column :labels, :extended_columns, :jsonb
  end
  down do
    extension :pg_json
    drop_column :labels, :extended_columns
  end
end
