# frozen_string_literal: true

module LabelApp
  class PublishStep < BaseStep
    def initialize(user)
      super(user, :lbl_publish_steps)
    end

    def step_2_desc
      current_step = read
      [
        "Printer: #{current_step[:chosen_printer]}",
        "Targets: #{current_step[:chosen_targets].map { |t| current_step[:lookup][t][:name] }.join(', ')}"
      ]
    end

    def step_3_desc
      current_step = read
      [
        "Printer: #{current_step[:chosen_printer]}",
        "Targets: #{current_step[:chosen_targets].map { |t| current_step[:lookup][t][:name] }.join(', ')}",
        "#{current_step[:label_ids].length} Labels"
      ]
    end
  end
end
