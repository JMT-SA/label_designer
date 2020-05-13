Crossbeams::MenuMigrations::Migrator.migration('LabelDesigner') do
  up do
    add_program_function 'Available Modules', functional_area: 'Label Designer', program: 'Designs', url: '/list/mes_modules', seq: 2
  end

  down do
    drop_program_function 'Available Modules', functional_area: 'Label Designer', program: 'Designs'
  end
end
