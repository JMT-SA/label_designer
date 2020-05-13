# frozen_string_literal: true

module Labels
  module Publish
    module Batch
      class PublishState
        def self.call(res) # rubocop:disable Metrics/AbcSize
          label_states = res.body

          header_cols, cols = publishing_table_headers(label_states)
          rows = publishing_table_rows(label_states)
          layout = Crossbeams::Layout::Page.build({}) do |page|
            current_state(page, res)
            page.add_table rows, cols.dup.unshift('Label'), header_captions: Hash[header_cols], cell_classes: publishing_table_classes(cols)
            page.add_text summary(res.publish_summary) if res.publish_summary
            end_note(page, res, label_states)
          end

          layout
        end

        def self.summary(publish_summary)
          ar = [publish_summary['summary']]
          ar << "Failed to publish remotely: #{publish_summary['failed_remotes'].join(', ')}" if publish_summary['failed_remotes'] && !publish_summary['failed_remotes'].empty?
          ar.join('<br>')
        end

        def self.publishing_table_headers(label_states)
          header_cols = label_states.map { |h| [h[:destination], "#{h[:destination]}<br>#{h[:server_ip]}"] }.uniq
          cols = header_cols.map(&:first)
          [header_cols, cols]
        end

        def self.publishing_table_rows(label_states)
          label_states.group_by { |h| h[:label_name] }.map { |k, v| { 'Label' => k }.merge(Hash[v.map { |a| [a[:destination], [a[:status], a[:errors]].compact.join(' ')] }]) }
        end

        def self.current_state(page, res)
          if res.done
            if res.failed
              page.add_notice("Action failed #{res.errors}", notice_type: :error)
            else
              page.add_notice('Publish action is complete', notice_type: :success)
            end
          else
            page.add_text '<div class="content-target content-loading"><div></div><div></div><div></div> Publishing in progress...'
          end
        end

        def self.end_note(page, res, label_states)
          return unless res.done && published_labels?(label_states)

          if AppConst::LABEL_PUBLISH_NOTIFY_URLS.empty?
            page.add_text(sql(label_states, res.chosen_printer), toggle_button: true, toggle_caption: 'Toggle SQL for template insert', syntax: :sql)
          else
            app_word = AppConst::LABEL_PUBLISH_NOTIFY_URLS.length == 1 ? 'application' : 'applications'
            page.add_text("<strong>Note:</strong> Label layout notifications have been sent to #{AppConst::LABEL_PUBLISH_NOTIFY_URLS.length} #{app_word}.", wrapper: :p)
          end
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
