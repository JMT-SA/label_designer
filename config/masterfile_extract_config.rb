# frozen_string_literal: true

module Crossbeams
  module Config
    MF_BASE_TABLES = %i[
      master_lists
      user_email_groups
    ].freeze

    # self-referential tables. First insert all where the key is NULL, then the rest.
    # This hash is in the form: table_name: self-referencing key
    MF_TABLES_SELF_REF = {
    }.freeze

    MF_TABLES_IN_SEQ = %i[
    ].freeze

    # For arrays of ids
    MF_LKP_ARRAY_RULES = {
    }.freeze

    # The subquery is the subquery to be injected in the INSERT statement.
    # The values gets the key value to be used in the subquery for a particular row.
    MF_LKP_RULES = {
      user_id: { subquery: 'SELECT id FROM users WHERE login_name = ?', values: 'SELECT login_name FROM users WHERE id = ?' },
      security_group_id: { subquery: 'SELECT id FROM security_groups WHERE security_group_name = ?', values: 'SELECT security_group_name FROM security_groups WHERE id = ?' },
      functional_area_id: { subquery: 'SELECT id FROM FROM functional_areas WHERE functional_area_name = ?', values: 'SELECT f.functional_area_name FROM functional_areas f WHERE f.id = ?' },
      program_id: { subquery: 'SELECT id FROM programs WHERE program_name = ? AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = ?)', values: 'SELECT p.program_name, f.functional_area_name FROM programs p JOIN functional_areas f ON f.id = p.functional_area_id WHERE p.id = ?' },
      program_function_id: { subquery: 'SELECT id FROM program_functions WHERE program_function_name = ? AND program_id = (SELECT id FROM programs WHERE program_name = ? AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = ?))', values: 'SELECT pf.program_function_name, p.program_name, f.functional_area_name FROM program_functions pf JOIN programs p ON p.id = pf.program_id JOIN functional_areas f ON f.id = p.functional_area_id WHERE pf.id = ?' },
      zzz: {}
    }.freeze

    MF_LKP_PARTY_ROLES = %i[
      owner_party_role_id
      rmt_material_owner_party_role_id
    ].freeze
  end
end
