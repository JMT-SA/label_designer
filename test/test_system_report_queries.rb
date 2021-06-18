# frozen_string_literal: true

require File.join(File.expand_path('./../', __FILE__), 'test_helper')

class TestSystemReportQueries < MiniTestWithHooks
  def test_valid_ddl
    @current = 'No file loaded yet'
    @param = nil
    queries = Dir.glob('reports/*.yml')
    queries.each do |file|
      @current = file
      @param = nil

      persistor = Crossbeams::Dataminer::YamlPersistor.new(file)
      rpt = Crossbeams::Dataminer::Report.load(persistor)
      res = DB[rpt.runnable_sql].first
      if res.nil?
        assert_nil res
      else
        assert_instance_of Hash, res, "Report #{file} did not return a hash"
      end

      # Check that query parameters with SELECTs for building lists are valid:
      rpt.query_parameter_definitions.map { |d| { col: d.caption, sql: d.list_def } }.each do |list|
        next unless list[:sql].is_a?(String)
        next unless list[:sql].match?(/select/i)

        @param = list[:col]
        res = DB[list[:sql]].first
        if res.nil?
          assert_nil res
        else
          assert_instance_of Hash, res, "Report #{file} did not return a hash for param #{list[:col]}"
        end
      end
    end
  rescue StandardError
    if @param
      puts "Failure for DM report query definition: #{@current}. Query for parameter '#{@param}' fails"
    else
      puts "Failure for DM report query definition: #{@current}"
    end
    raise
  end
end
