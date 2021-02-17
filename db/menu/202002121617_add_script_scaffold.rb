Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New Script Scaffold', functional_area: 'Development', program: 'Generators', url: '/development/generators/script_scaffolds/new', seq: 2
    change_program_function 'Documentation', functional_area: 'Development', program: 'Generators', seq: 3
    change_program_function 'SQL Formatter', functional_area: 'Development', program: 'Generators', seq: 4
  end

  down do
    drop_program_function 'New Script Scaffold', functional_area: 'Development', program: 'Generators'
    change_program_function 'Documentation', functional_area: 'Development', program: 'Generators', seq: 2
    change_program_function 'SQL Formatter', functional_area: 'Development', program: 'Generators', seq: 3
  end
end
