# frozen_string_literal: true

module Crossbeams
  # Base class for ClientRules.
  # Implements a way of calling CLIENT_SETTINGS keys from inheriting classes as methods.
  class BaseClientRules
    attr_reader :client_code

    def initialize(key)
      @client_code = key
    end

    # Get the setting for a particular key
    def setting(key)
      return @settings[key] unless AppConst.test?

      self.class::CLIENT_SETTINGS[AppConst::TEST_SETTINGS.client_code.to_sym][key]
    end

    def respond_to_missing?(method, include_private = false)
      return @settings.key?(method) || super unless AppConst.test?

      self.class::CLIENT_SETTINGS[AppConst::TEST_SETTINGS.client_code.to_sym].key?(method) || super
    end

    def method_missing(method, *args)
      return super unless respond_to?(method)

      if args.any? { |a| a.is_a?(Hash) && a[:explain] }
        method.to_s.capitalize.gsub('_', ' ')
      else
        setting(method)
      end
    end

    def check_client_setting_keys # rubocop:disable Metrics/AbcSize
      ar = []
      keys = self.class::CLIENT_SETTINGS.keys
      refs = self.class::CLIENT_SETTINGS[keys.first].keys
      count = refs.length
      keys.each do |client|
        next if self.class::CLIENT_SETTINGS[client].keys.length == count

        # TODO: should get the set with the most keys 1st and compare to that..
        diff = refs - self.class::CLIENT_SETTINGS[client].keys
        ar << "#{client}: #{diff.join(', ')}"
      end
      ar.unshift 'All clients do not have the same number of settings!' unless ar.empty? # keys.all? { |k| self.class::CLIENT_SETTINGS[k].keys.length == count }
      ar.empty? ? [] : [ar.join('<br>')]
    end
  end
end
