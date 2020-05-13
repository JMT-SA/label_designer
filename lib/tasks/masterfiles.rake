# frozen_string_literal: true

namespace :app do
  namespace :masterfiles do
    desc 'SQL Extract of Masterfiles'
    task extract: [:load_app] do
      # Todo - allow list of specific tables
      extractor = SecurityApp::DataToSql.new(nil)
      Crossbeams::Config::MF_BASE_TABLES.each do |table|
        puts "-- #{table.to_s.upcase} --"
        extractor.sql_for(table, nil)
        puts ''
      end

      Crossbeams::Config::MF_TABLES_IN_SEQ.each do |table|
        puts "-- #{table.to_s.upcase} --"
        extractor.sql_for(table, nil)
        puts ''
      end
    end

    desc 'SQL Extract of single Masterfile'
    task :extract_single, [:table] => [:load_app] do |_, args|
      table = args.table
      extractor = SecurityApp::DataToSql.new(nil)
      puts "-- #{table.to_s.upcase} --"
      extractor.sql_for(table.to_sym, nil)
      puts ''
    end
  end
end
