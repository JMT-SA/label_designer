Sequel.migration do
  change do
    create_table(:labels) do
      primary_key :id
      String :label_name, size: 255, null: false
      String :label_json, text: true
      String :label_dimension, size: 255
      String :variable_xml, text: true
      String :image_path, size: 255
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      File :png_image
    end
  end
end
