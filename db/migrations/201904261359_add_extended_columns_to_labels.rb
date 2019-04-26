Sequel.migration do
  change do
    extension :pg_json
    add_column :labels, :extended_columns, :jsonb
  end
end
