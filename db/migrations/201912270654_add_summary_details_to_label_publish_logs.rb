Sequel.migration do
  up do
    alter_table(:label_publish_logs) do
      add_column :publish_summary, :jsonb
    end
  end

  down do
    alter_table(:label_publish_logs) do
      drop_column :publish_summary
    end
  end
end
