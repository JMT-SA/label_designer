INSERT INTO functional_areas (functional_area_name)
VALUES ('Label Designer');

INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Designs', 1, (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer'));

INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs WHERE program_name = 'Designs' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer')), 'LabelDesigner');

INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Master Lists', 1, (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer'));

INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs WHERE program_name = 'Master Lists' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer')), 'LabelDesigner');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Designs' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer')), 'List labels', '/list/labels', 1);
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Designs' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer')), 'New label', '/labels/labels/labels/new', 2);
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Designs' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer')), 'Available printers', '/list/printers', 3);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Master Lists' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer')), 'Container Types', '/list/master_lists/with_params?key=container_type', 1);
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Master Lists' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer')), 'Commodities', '/list/master_lists/with_params?key=commodity', 2);
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Master Lists' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer')), 'Markets', '/list/master_lists/with_params?key=market', 3);
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Master Lists' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer')), 'Languages', '/list/master_lists/with_params?key=language', 4);
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Master Lists' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer')), 'Categories', '/list/master_lists/with_params?key=category', 5);
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Master Lists' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer')), 'Sub-categories', '/list/master_lists/with_params?key=sub_category', 6);



INSERT INTO programs_users (user_id, program_id, security_group_id)
VALUES ((SELECT id FROM users ORDER BY id LIMIT 1),
  (SELECT id FROM programs WHERE program_name = 'Designs' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer')),
  (SELECT id FROM security_groups g WHERE g.security_group_name = 'basic'));

INSERT INTO programs_users (user_id, program_id, security_group_id)
VALUES ((SELECT id FROM users ORDER BY id LIMIT 1),
  (SELECT id FROM programs WHERE program_name = 'Master Lists' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer')),
  (SELECT id FROM security_groups g WHERE g.security_group_name = 'basic'));
