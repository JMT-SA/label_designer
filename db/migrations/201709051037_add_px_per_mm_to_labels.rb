Sequel.migration do
  change do
    add_column :labels, :px_per_mm, String, null: false, default: '8'
  end
end
