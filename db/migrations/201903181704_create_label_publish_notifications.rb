require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers

    create_table(:label_publish_notifications, ignore_index_errors: true) do
      primary_key :id
      foreign_key :label_publish_log_id, :label_publish_logs, null: false
      foreign_key :label_id, :labels, null: false
      String :url, size: 255, null: false
      TrueClass :complete, default: false
      TrueClass :failed, default: false
      String :errors
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index :label_publish_log_id, name: :fki_lbl_pub_note_lbl_pub_log
      index :label_id, name: :fki_lbl_pub_note_label
    end

    pgt_created_at(:label_publish_notifications,
                   :created_at,
                   function_name: :label_publish_notifications_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:label_publish_notifications,
                   :updated_at,
                   function_name: :label_publish_notifications_set_updated_at,
                   trigger_name: :set_updated_at)

    alter_table(:label_publish_log_details) do
      add_index :label_publish_log_id, name: :fki_lbl_pub_details_lbl_pub_log
      add_index :label_id, name: :fki_lbl_pub_details_label
    end
  end

  down do
    alter_table(:label_publish_log_details) do
      drop_index :label_publish_log_id, name: :fki_lbl_pub_details_lbl_pub_log
      drop_index :label_id, name: :fki_lbl_pub_details_label
    end

    drop_trigger(:label_publish_notifications, :set_created_at)
    drop_function(:label_publish_notifications_set_created_at)
    drop_trigger(:label_publish_notifications, :set_updated_at)
    drop_function(:label_publish_notifications_set_updated_at)
    drop_table(:label_publish_notifications)
  end
end
