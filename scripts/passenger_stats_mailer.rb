# frozen_string_literal: true

# require 'logger'

# Scan a directory for EDI in files and process them.
class PassengerStatsMailer < BaseScript
  attr_reader :in_dir, :out_dir, :cnt, :processed_files

  def run # rubocop:disable Metrics/AbcSize
    status = check_status
    procs = status[/^Processes.+$/].split(':').last.strip.to_i
    max = AppConst::MAX_PASSENGER_INSTANCES
    curr = if procs == max
             'OVER'
           elsif procs > max - 5
             'HIGH'
           elsif procs > max - 10
             'BUSY'
           else
             'INFO'
           end
    memory = check_memory
    top = check_top

    send_error_email(subject: "#{curr}: Passenger-stats", message: "#{status}\n\n\n#{memory}\n\n\n#{top}", recipients: 'james@nosoft.biz,hans@nosoft.biz') if threshold_reached?(curr)
    success_response('Mail sent')
  end

  private

  LEVELS = {
    'INFO' => 1,
    'BUSY' => 2,
    'HIGH' => 3,
    'OVER' => 4
  }.freeze

  def threshold_reached?(curr)
    LEVELS[curr] >= LEVELS[AppConst::PASSENGER_USAGE_LEVEL]
  end

  def check_status
    `echo "#{ENV['NSPACKSUDO']}" | sudo -S passenger-status` # rubocop:disable Lint/Env
  end

  def check_memory
    `echo "#{ENV['NSPACKSUDO']}" | sudo -S passenger-memory-stats` # rubocop:disable Lint/Env
  end

  def check_top
    # `top -b -n 1 -o +%CPU -E g` # per-gig option only from 20.04 on...
    `top -b -n 1 -o +%CPU`
  end
end
