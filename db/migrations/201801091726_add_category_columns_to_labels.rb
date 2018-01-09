Sequel.migration do
  change do
    add_column :labels, :container_type, String
    add_column :labels, :commodity, String
    add_column :labels, :market, String
    add_column :labels, :language, String
    add_column :labels, :category, String
    add_column :labels, :sub_category, String
  end
end
