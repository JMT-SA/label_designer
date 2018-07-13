# frozen_string_literal: true

module UiRules
  class LabelPublishRule < Base
    def generate_rules
      @repo = LabelApp::PrinterRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields targets_fields if @mode == :select_targets

      form_name 'batch'
    end

    def targets_fields
      res = LabelApp::MesServerRepo.new.publish_target_list
      raise res.message unless res.success
      printer_types = res.instance.map { |i| i['PrinterTypes'] }.flatten.uniq.sort
      targets = res.instance.map { |i| [i['Alias'], i['NetworkInterface']] }.sort
      # tmp = { 'PublishServerList' =>
      #   [{ 'Code' => 'CMS-03', 'Function' => 'messerver', 'NetworkInterface' => '192.168.50.200', 'Port' => 2000, 'Alias' => 'Summerville CMS', 'PrinterTypes' => %w[Zebra Argox Datamax] },
      #    { 'Code' => 'CMS-01', 'Function' => 'messerver', 'NetworkInterface' => '192.168.50.202', 'Port' => 2000, 'Alias' => 'Hermitage CMS', 'PrinterTypes' => %w[Zebra Argox] },
      #    { 'Code' => 'CMS-02', 'Function' => 'messerver', 'NetworkInterface' => '192.168.50.201', 'Port' => 2000, 'Alias' => 'Kirkwood CMS', 'PrinterTypes' => %w[Zebra Argox] }] }
      # plist = tmp['PublishServerList']
      # printer_types = plist.map { |t| t['PrinterTypes'] }.flatten.uniq.sort
      # targets = plist.map { |t| [t['Alias'], t['NetworkInterface']] }.sort
      {
        printer_type: { renderer: :select, options: printer_types },
        target_destinations: { renderer: :multi, options: targets }
      }
    end

    def make_form_object
      make_new_form_object
    end

    def make_new_form_object
      @form_object = OpenStruct.new(target_destinations: nil)
    end
  end
end
