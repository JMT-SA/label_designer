require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers

    # LABEL PUBLISH_LOGS
    # ------------------
    create_table(:label_publish_logs, ignore_index_errors: true) do
      primary_key :id
      String :user_name, size: 255, null: false
      String :printer_type, size: 255, null: false
      String :publish_name
      String :status
      String :errors
      TrueClass :complete, default: false
      TrueClass :failed, default: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:label_publish_logs,
                   :created_at,
                   function_name: :label_publish_logs_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:label_publish_logs,
                   :updated_at,
                   function_name: :label_publish_logs_set_updated_at,
                   trigger_name: :set_updated_at)

    # LABEL PUBLISH_LOG_DETAILS
    # -------------------------
    create_table(:label_publish_log_details, ignore_index_errors: true) do
      primary_key :id
      foreign_key :label_publish_log_id, :label_publish_logs, null: false
      foreign_key :label_id, :labels, null: false
      inet :server_ip, null: false
      String :destination
      String :status
      String :errors
      TrueClass :complete, default: false
      TrueClass :failed, default: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:label_publish_log_details,
                   :created_at,
                   function_name: :label_publish_log_details_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:label_publish_log_details,
                   :updated_at,
                   function_name: :label_publish_log_details_set_updated_at,
                   trigger_name: :set_updated_at)
  end

  down do
    drop_trigger(:label_publish_log_details, :set_created_at)
    drop_function(:label_publish_log_details_set_created_at)
    drop_trigger(:label_publish_log_details, :set_updated_at)
    drop_function(:label_publish_log_details_set_updated_at)
    drop_table(:label_publish_log_details)

    drop_trigger(:label_publish_logs, :set_created_at)
    drop_function(:label_publish_logs_set_created_at)
    drop_trigger(:label_publish_logs, :set_updated_at)
    drop_function(:label_publish_logs_set_updated_at)
    drop_table(:label_publish_logs)
  end
end
