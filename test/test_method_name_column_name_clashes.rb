# frozen_string_literal: true

require File.join(File.expand_path('./../', __FILE__), 'test_helper')

class TestMethodNameColumnNameClashes < Minitest::Test
  def test_valid_names_for_repositories
    all_repo_methods = ObjectSpace.each_object(BaseRepo.singleton_class).map { |c| c.instance_methods(false) }.flatten
    all_cols = Set.new
    BaseRepo::DB_TABLE_COLS.each {|_, cols| all_cols += cols.keys }
    clashes = all_repo_methods.select { |m| all_cols.include?(m) }.uniq
    shared_names = []
    ObjectSpace.each_object(BaseRepo.singleton_class).each do |c|
      clashes.each { |cl| shared_names << "#{c.to_s.ljust(40)} : #{cl}" if c.instance_methods(false).include?(cl) }
    end

    ok = if shared_names.empty?
           true
         else
           puts "\nRepositories with method names that equal table column names - please rename"
           puts "----------------------------------------------------------------------------\n"
           puts shared_names.join("\n")
           puts "----------------------------------------------------------------------------\n"
           false
         end

    assert ok, 'Found repo method name that matches table column name.'
  end

  def test_valid_names_for_interactors
    # skip 'To be implemented when existing methods have been renamed'

    all_repo_methods = ObjectSpace.each_object(BaseInteractor.singleton_class).map { |c| c.instance_methods(false) }.flatten
    all_cols = Set.new
    BaseRepo::DB_TABLE_COLS.each {|_, cols| all_cols += cols.keys }
    clashes = all_repo_methods.select { |m| all_cols.include?(m) }.uniq
    shared_names = []
    ObjectSpace.each_object(BaseInteractor.singleton_class).each do |c|
      clashes.each { |cl| shared_names << "#{c.to_s.ljust(50)} : #{cl}" if c.instance_methods(false).include?(cl) }
    end

    ok = if shared_names.empty?
           true
         else
           puts "\nInteractors with method names that equal table column names - please rename"
           puts "---------------------------------------------------------------------------\n"
           puts shared_names.join("\n")
           puts "---------------------------------------------------------------------------\n"
           false
         end

    assert ok, 'Found intereactor method name that matches table column name.'
  end
end
