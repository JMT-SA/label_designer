# frozen_string_literal: true

module Crossbeams
  # Documenting module for client run rules.
  # This module mixes in the self-documenting of methods.
  #
  # Each method in an including class should have a keyword argument
  # named "explain", which defaults to false.
  # When passed in as true, the method should just return a description of itself.
  #
  # e.g.
  #   def go_left_or_right?(explain: false)
  #     return 'What this does and when is it useful' if explain
  #
  #     true # The actual return value of the method.
  #   end
  module AutoDocumentation
    EXPLAIN_SET = %i[key explain].freeze

    def rule_name
      self.class.name.sub('Crossbeams::', '').gsub(/([A-Z])/, ' \1').strip
    end

    def to_table
      rules = public_methods(false) - %i[setting method_missing]
      keys = method_missing_keys(rules)
      (rules + keys).sort.map do |m|
        build_method_docs(m, keys.include?(m))
      end
    end

    def method_missing_keys(rules) # rubocop:disable Metrics/AbcSize
      # First find the line number of the first method in the file.
      fn = nil
      start_line = rules.map do |m|
        fn, ln = method(m).source_location
        ln
      end.min
      ar = @settings.keys
      return ar if start_line.nil?

      # Get the body of the class from the earliest method down.
      body = File.readlines(fn).drop(start_line - 2).join

      # And return only those keys that are not referenced in a method.
      # (They are handled by `method_missing`)
      ar.map { |m| body.include?(m.to_s) ? nil : m }.compact
    end

    def build_method_docs(meth, from_key)
      if from_key
        has_explain = true
        rest = []
      else
        params = method(meth).parameters
        has_explain = params.include?(EXPLAIN_SET)
        rest = params.reject { |k| k == EXPLAIN_SET }
      end

      {
        method: _method_nm(meth, rest),
        description: _description(meth, rest, has_explain),
        value: _value(meth, rest)
      }
    end

    def _description(meth, rest, has_explain)
      if has_explain
        if rest.empty?
          send(meth, explain: true)
        else
          args = rest.reject { |r| r.first == :key } # Ignore keyword arguments
          send(meth, *args.map(&:last), explain: true)
        end
      else
        'I AM UNDOCUMENTED... FIXME PLEASE!'
      end
    end

    def _method_nm(meth, rest)
      if rest.empty?
        meth
      else
        "#{meth}(#{rest.map(&:last).join(', ')})"
      end
    end

    def _value(meth, rest)
      if rest.empty?
        send(meth)
      else
        'DYNAMIC - depends on input'
      end
    end
  end
end
