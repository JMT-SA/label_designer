INSERT INTO functional_areas (functional_area_name)
VALUES ('security');

INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('menu', 1, (SELECT id FROM functional_areas WHERE functional_area_name = 'security'));

INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs WHERE program_name = 'menu' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'security')), 'LabelDesigner');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'menu' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'security')), 'list menu definitions', '/list/menu_definitions', 1);


INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'menu' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'security')), 'security groups', '/list/security_groups', 1);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'menu' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'security')), 'security permissions', '/list/security_permissions', 1);


/*
INSERT INTO functional_areas (functional_area_name)
VALUES ('dataminer');

INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('reports', 1, (SELECT id FROM functional_areas WHERE functional_area_name = 'dataminer'));

INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs WHERE program_name = 'reports' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'dataminer')), 'LabelDesigner');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'reports' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'dataminer')), 'list reports', '/dataminer/', 1);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'reports' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'dataminer')), 'admin', '/dataminer/admin/', 2);
*/

INSERT INTO functional_areas (functional_area_name)
VALUES ('Development');

INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Generators', 1, (SELECT id FROM functional_areas WHERE functional_area_name = 'Development'));

INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs WHERE program_name = 'Generators' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Development')), 'LabelDesigner');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Generators' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Development')), 'New Scaffold', '/development/generators/scaffolds/new', 1);

-- INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
-- VALUES ((SELECT id FROM programs WHERE program_name = 'Generators' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Development')), 'Documentation', '/developer_documentation/start', 2);

INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Masterfiles', 2, (SELECT id FROM functional_areas WHERE functional_area_name = 'Development'));

INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs WHERE program_name = 'Masterfiles' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Development')), 'LabelDesigner');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Masterfiles' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Development')), 'Users', '/list/users', 1);

