require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers

    create_table(:label_images) do
      primary_key :id
      foreign_key :label_id, :labels, null: false
      File :png_image
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:label_images,
                   :created_at,
                   function_name: :label_images_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:label_images,
                   :updated_at,
                   function_name: :label_images_set_updated_at,
                   trigger_name: :set_updated_at)

    run <<~SQL
      INSERT INTO label_images(label_id, png_image)
      SELECT id, png_image
      FROM labels
      WHERE png_image IS NOT NULL
    SQL

    alter_table :labels do
      drop_column :png_image
    end
  end

  down do
    alter_table :labels do
      add_column :png_image, File
    end

    run <<~SQL
      UPDATE labels
      SET png_image = (SELECT png_image FROM label_images WHERE label_id = labels.id);
    SQL

    drop_trigger(:label_images, :set_created_at)
    drop_function(:label_images_set_created_at)
    drop_trigger(:label_images, :set_updated_at)
    drop_function(:label_images_set_updated_at)
    drop_table(:label_images)
  end
end
