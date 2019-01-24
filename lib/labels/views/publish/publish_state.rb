# frozen_string_literal: true

module Labels
  module Publish
    module Batch
      class PublishState
        def self.call(res) # rubocop:disable Metrics/AbcSize
          label_states = res.body
          header_cols = label_states.map { |h| [h[:destination], "#{h[:destination]}<br>#{h[:server_ip]}"] }.uniq
          cols = header_cols.map(&:first)
          rows = label_states.group_by { |h| h[:label_name] }.map { |k, v| { 'Label' => k }.merge(Hash[v.map { |a| [a[:destination], [a[:status], a[:errors]].compact.join(' ')] }]) }

          layout = Crossbeams::Layout::Page.build({}) do |page|
            if res.done
              page.add_text 'Publish action is complete'
              page.add_text("Action failed #{res.errors}", wrapper: :b) if res.failed
            else
              page.add_text '<div class="content-target content-loading"><div></div><div></div><div></div> Publishing in progress...'
            end
            page.add_table rows, cols.dup.unshift('Label'), header_captions: Hash[header_cols], cell_classes: publishing_table_classes(cols)

            if res.done && published_labels?(label_states)
              page.add_text(sql(label_states, res.chosen_printer), toggle_button: true, toggle_caption: 'Toggle SQL for template insert', syntax: :sql)
            end
          end

          layout
        end

        def self.publishing_table_classes(targets)
          rules = {}
          lkps = { 'PUBLISHING' => 'orange', true => 'red', false => 'green' }
          targets.each do |target|
            rules[target] = ->(status) { lkps[status.to_s] || lkps[status.to_s.include?('FAIL')] }
          end
          rules
        end

        def self.published_labels?(label_states)
          label_states.any? { |l| !l[:failed] }
        end

        def self.sql(label_states, chosen_printer)
          sql = []
          label_states.reject { |l| l[:failed] }.map { |l| l[:label_name] }.uniq.each do |label_name|
            sql << <<~SQL
              INSERT INTO dbo.mes_label_template_files
              (label_template_file, mes_peripheral_type_id, mes_peripheral_type_code, created_at, updated_at)
              SELECT '#{label_name}.nsld', mp.id, mp.code, getdate(), getdate()
              FROM mes_peripheral_types mp
              WHERE UPPER(mp.code) = '#{chosen_printer.upcase}';
            SQL
          end
          sql.join("\n")
        end
      end
    end
  end
end
