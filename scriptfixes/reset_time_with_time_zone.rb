# frozen_string_literal: true

# What this script does:
# ----------------------
# Takes certain timestamp with time zone columns on certain tables and changes them to be
# two hours earlier.
# Applies to transactional data created before 2020-02-14.
#
# Reason for this script:
# -----------------------
# On 2020-02-13 at about 22:00, all timestamp without time zone were converted
# to timestamp with time zone.
# As a result many times display 2 hours later than they should.
#
class ResetTimeWithTimeZone < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    sql = []

    CHANGES.each do |table, columns|
      puts "Updating #{table} for: #{columns.join(', ')}"
      dis = "ALTER TABLE #{table} DISABLE TRIGGER ALL;"
      en = "ALTER TABLE #{table} ENABLE TRIGGER ALL;"
      script = %(#{dis}\n#{columns.map { |col| "UPDATE #{table} SET #{col} = #{col} - interval '2 hours';" }.join("\n")}\n#{en})
      sql << script
      if debug_mode
        puts script
        puts ''
      else
        DB.transaction do
          DB.run(script)
        end
      end
    end

    infodump = <<~STR
      Script: ResetTimeWithTimeZone

      What this script does:
      ----------------------
      Takes certain timestamp with time zone columns on certain tables and changes them to be
      two hours earlier.
      Applies to transactional data created before 2020-02-14.

      Reason for this script:
      -----------------------
      On 2020-02-13 at about 22:00, all timestamp without time zone were converted
      to timestamp with time zone.
      As a result many times display 2 hours later than they should.

      Results:
      --------
      Ran the following SQL:

      #{sql.join("\n")}
    STR

    log_infodump(:data_fix,
                 :timezones,
                 :correct_where_2_hours_ahead,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Applied the time change')
    end
  end

  # TODO: test if any have the correct date?
  CHANGES = {
    label_publish_log_details: %i[created_at updated_at],
    label_publish_logs: %i[created_at updated_at],
    label_publish_notifications: %i[created_at updated_at],
    labels: %i[created_at updated_at]
  }.freeze
end
