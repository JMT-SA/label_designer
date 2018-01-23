Sequel.migration do
  change do
    extension :pg_json
    add_column :labels, :sample_data, :jsonb
  end
end
