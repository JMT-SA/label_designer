# frozen_string_literal: true

module LabelApp
  class BroadcastLabelPublishEventJob < BaseQueJob
    def run(label_publish_log_id)
      @cached_config = {}
      lookup_label_publish_log(label_publish_log_id)

      gather_label_data

      unless @payload.empty?
        create_notification_records
        broadcast_event
      end
      finish
    end

    private

    def broadcast_event
      @repo.all(:label_publish_notifications, LabelPublishNotification, label_publish_log_id: @label_publish_log.id).each do |notification|
        NotifyLabelPublishEventJob.enqueue(notification.id, @payload)
      end
    end

    def lookup_label_publish_log(label_publish_log_id)
      @repo = LabelApp::LabelRepo.new
      @label_publish_log = @repo.find_label_publish_log(label_publish_log_id)
    end

    def gather_label_data
      @payload = {}
      @label_ids = @repo.published_label_ids_for(@label_publish_log.id)
      return if @label_ids.empty?

      @payload = { printer_type: @label_publish_log.printer_type, labels: [] }
      labels = @repo.all(:labels, Label, id: @label_ids)

      labels.each do |label|
        vars = extract_variable_data(label)
        @payload[:labels] << {
          id: label.id,
          label_name: label.label_name,
          variable_set: label.variable_set,
          variables: vars
        }
      end
    end

    def create_notification_records
      @repo.transaction do
        @repo.create_label_publish_notifications(@label_publish_log.id, @label_ids, AppConst::LABEL_PUBLISH_NOTIFY_URLS)
      end
    end

    def extract_variable_data(label)
      varnames = if label.multi_label
                   variable_names_from_multi_label(label.id)
                 else
                   variable_names_from(label.variable_xml)
                 end

      variable_details_for(label.variable_set, varnames)
    end

    def variable_names_from_multi_label(label_id)
      varnames = []
      @repo.sub_label_ids(label_id).each do |sub_label_id|
        sub_label = @repo.find_label(sub_label_id)
        varnames += variable_names_from(sub_label.variable_xml)
      end
      varnames
    end

    def variable_names_from(variable_xml)
      doc = Nokogiri::XML(variable_xml)
      doc.css('variable variable_type').map(&:text)
    end

    def variable_details_for(variable_set, varnames)
      config = config_for(variable_set)
      varnames.map { |varname| { display_varname(varname) => varname.start_with?('CMP:') ? composite_config(config, varname) : config[varname] } }
    end

    def composite_config(config, varname)
      # get tokens within ${} and replace with config resolver
      tokens = varname.scan(/\$\{(.+?)\}/).flatten
      lkp = {}
      tokens.each { |token| lkp[token] = config[token][:resolver] }
      composite_resolver = varname
      # Sort tokens in descending order of length to avoid e.g. gsubbing ISO Weekday using ISO Week's value.
      tokens.sort_by { |t| t.length * -1 }.each { |t| composite_resolver.gsub!(t, lkp[t]) }

      { group: 'Any', resolver: composite_resolver, applications: ['ANY'] }
    end

    def display_varname(varname)
      return varname unless varname.start_with?('CMP:')

      varname.gsub(/CMP:|[${}]/, '')
    end

    def config_for(variable_set)
      @cached_config[variable_set] ||= begin
                                         repo = LabelApp::SharedConfigRepo.new
                                         repo.remote_object_config_for(variable_set)
                                       end
    end
  end
end
