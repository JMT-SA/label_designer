require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers

    pgt_created_at(:labels,
                   :created_at,
                   function_name: :labels_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:labels,
                   :updated_at,
                   function_name: :labels_set_updated_at,
                   trigger_name: :set_updated_at)
  end

  down do
    drop_trigger(:labels, :set_created_at)
    drop_function(:labels_set_created_at)
    drop_trigger(:labels, :set_updated_at)
    drop_function(:labels_set_updated_at)
  end
end
