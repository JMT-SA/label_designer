-- FUNCTIONAL AREA dataminer
INSERT INTO functional_areas (functional_area_name)
VALUES ('dataminer');


-- PROGRAM: reports
INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('reports', 1,
        (SELECT id FROM functional_areas WHERE functional_area_name = 'dataminer'));

-- LINK program to webapp
INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs
                   WHERE program_name = 'reports'
                     AND functional_area_id = (SELECT id
                                               FROM functional_areas
                                               WHERE functional_area_name = 'dataminer')),
                                               'LabelDesigner');


-- PROGRAM FUNCTION admin
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence,
                               group_name, restricted_user_access, show_in_iframe)
VALUES ((SELECT id FROM programs WHERE program_name = 'reports'
          AND functional_area_id = (SELECT id FROM functional_areas
                                    WHERE functional_area_name = 'dataminer')),
        'admin',
        '/dataminer/admin/reports',
        2,
        NULL,
        true,
        false);


-- PROGRAM FUNCTION Grid admin
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence,
                               group_name, restricted_user_access, show_in_iframe)
VALUES ((SELECT id FROM programs WHERE program_name = 'reports'
          AND functional_area_id = (SELECT id FROM functional_areas
                                    WHERE functional_area_name = 'dataminer')),
        'Grid admin',
        '/dataminer/admin/grids',
        4,
        NULL,
        false,
        false);


-- PROGRAM FUNCTION list reports
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence,
                               group_name, restricted_user_access, show_in_iframe)
VALUES ((SELECT id FROM programs WHERE program_name = 'reports'
          AND functional_area_id = (SELECT id FROM functional_areas
                                    WHERE functional_area_name = 'dataminer')),
        'list reports',
        '/dataminer/reports',
        1,
        NULL,
        false,
        false);


-- PROGRAM FUNCTION Prepared Reports
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence,
                               group_name, restricted_user_access, show_in_iframe)
VALUES ((SELECT id FROM programs WHERE program_name = 'reports'
          AND functional_area_id = (SELECT id FROM functional_areas
                                    WHERE functional_area_name = 'dataminer')),
        'Prepared Reports',
        '/dataminer/prepared_reports/list',
        4,
        NULL,
        false,
        false);


-- PROGRAM FUNCTION ALL Prepared Reports
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence,
                               group_name, restricted_user_access, show_in_iframe)
VALUES ((SELECT id FROM programs WHERE program_name = 'reports'
          AND functional_area_id = (SELECT id FROM functional_areas
                                    WHERE functional_area_name = 'dataminer')),
        'ALL Prepared Reports',
        '/dataminer/prepared_reports/list_all',
        5,
        NULL,
        true,
        false);
