require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:multi_labels, ignore_index_errors: true) do
      foreign_key :label_id, :labels, null: false, key: [:id]
      foreign_key :sub_label_id, :labels, null: false, key: [:id]
      Integer :print_sequence, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:label_id, :sub_label_id], name: :multi_label_sub_label_idx
    end

    pgt_created_at(:multi_labels,
                   :created_at,
                   function_name: :multi_labels_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:multi_labels,
                   :updated_at,
                   function_name: :multi_labels_set_updated_at,
                   trigger_name: :set_updated_at)

    add_column :labels, :multi_label, TrueClass, default: false
  end

  down do
    drop_column :labels, :multi_label
    drop_trigger(:multi_labels, :set_created_at)
    drop_function(:multi_labels_set_created_at)
    drop_trigger(:multi_labels, :set_updated_at)
    drop_function(:multi_labels_set_updated_at)
    drop_table(:multi_labels)
  end
end
