Sequel.migration do
  up do
    run "SELECT audit.audit_table('labels', 'true', 'true', '{sample_data, updated_at}'::text[]);"
  end

  down do
    drop_trigger(:labels, :audit_trigger_row)
    drop_trigger(:labels, :audit_trigger_stm)
  end
end
