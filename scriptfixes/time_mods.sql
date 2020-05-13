-- Drop view that return one or more of these columns to change:
DROP VIEW public.vw_active_users;
DROP VIEW public.vw_bins;
DROP VIEW public.vw_pallet_sequence_flat;
DROP VIEW public.vw_scrapped_pallet_sequence_flat;
DROP VIEW vw_pallet_label;
DROP VIEW vw_packout_details;

-- Drop triggers that depend on one or more of these columns:
DROP TRIGGER pallet_sequences_prod_run_stats_queue ON public.pallet_sequences;
DROP TRIGGER pallets_prod_run_stats_queue ON public.pallets;

-- Drop function using timestamps
DROP FUNCTION public.fn_calc_age_days(integer, timestamp without time zone, timestamp without time zone);

-- Alter all date times to include time zone:

ALTER TABLE audit.current_statuses
ALTER COLUMN action_tstamp_tx TYPE timestamp with time zone;

ALTER TABLE audit.logged_action_details
ALTER COLUMN action_tstamp_tx TYPE timestamp with time zone;

ALTER TABLE audit.status_logs
ALTER COLUMN action_tstamp_tx TYPE timestamp with time zone;


ALTER TABLE address_types
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE addresses
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE basic_pack_codes
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE cargo_temperatures
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE carton_labels
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE cartons
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE cartons_per_pallet
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE commodities
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE commodity_groups
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE contact_method_types
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE contact_methods
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE container_stack_types
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE cultivar_groups
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE cultivars
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE customer_varieties
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE customer_variety_varieties
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE depots
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE destination_cities
ALTER COLUMN updated_at TYPE timestamp with time zone,
ALTER COLUMN created_at TYPE timestamp with time zone;

ALTER TABLE destination_countries
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE destination_regions
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE edi_in_transactions
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE edi_out_rules
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE edi_out_transactions
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE farm_groups
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE farms
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE fruit_actual_counts_for_packs
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE fruit_size_references
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE functional_areas
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE govt_inspection_api_results
ALTER COLUMN results_requested_at TYPE timestamp with time zone,
ALTER COLUMN results_received_at TYPE timestamp with time zone,
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE govt_inspection_pallet_api_results
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE govt_inspection_pallets
ALTER COLUMN inspected_at TYPE timestamp with time zone,
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE govt_inspection_sheets
ALTER COLUMN results_captured_at TYPE timestamp with time zone,
ALTER COLUMN completed_at TYPE timestamp with time zone,
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone,
ALTER COLUMN cancelled_at TYPE timestamp with time zone;

ALTER TABLE grades
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE inspection_failure_reasons
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE inspection_failure_types
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE inspectors
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE inventory_codes
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE label_publish_log_details
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE label_publish_logs
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE label_publish_notifications
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE label_templates
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE labels
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE load_containers
ALTER COLUMN verified_gross_weight_date TYPE timestamp with time zone,
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE load_vehicles
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE load_voyages
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE loads
ALTER COLUMN shipped_at TYPE timestamp with time zone,
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone,
ALTER COLUMN allocated_at TYPE timestamp with time zone;

ALTER TABLE location_assignments
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE location_storage_definitions
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE location_storage_types
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE location_types
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE locations
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE marketing_varieties
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE marks
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE master_lists
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE masterfile_variants
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE mes_modules
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE message_bus
ALTER COLUMN added_at TYPE timestamp with time zone;

ALTER TABLE multi_labels
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE orchards
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE organizations
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE pallet_bases
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE pallet_formats
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

-- vw_pallet_sequence_flat
ALTER TABLE pallet_sequences
ALTER COLUMN scrapped_at TYPE timestamp with time zone,
ALTER COLUMN verified_at TYPE timestamp with time zone,
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone,
ALTER COLUMN removed_from_pallet_at TYPE timestamp with time zone;

ALTER TABLE pallet_stack_types
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE pallet_verification_failure_reasons
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

-- vw_pallet_sequence_flat
ALTER TABLE pallets
ALTER COLUMN scrapped_at TYPE timestamp with time zone,
ALTER COLUMN shipped_at TYPE timestamp with time zone,
ALTER COLUMN govt_first_inspection_at TYPE timestamp with time zone,
ALTER COLUMN govt_reinspection_at TYPE timestamp with time zone,
ALTER COLUMN internal_inspection_at TYPE timestamp with time zone,
ALTER COLUMN internal_reinspection_at TYPE timestamp with time zone,
ALTER COLUMN stock_created_at TYPE timestamp with time zone,
ALTER COLUMN intake_created_at TYPE timestamp with time zone,
ALTER COLUMN first_cold_storage_at TYPE timestamp with time zone,
ALTER COLUMN gross_weight_measured_at TYPE timestamp with time zone,
ALTER COLUMN palletized_at TYPE timestamp with time zone,
ALTER COLUMN partially_palletized_at TYPE timestamp with time zone,
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone,
ALTER COLUMN allocated_at TYPE timestamp with time zone;

ALTER TABLE parties
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE party_addresses
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE party_contact_methods
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE party_roles
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE people
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE plant_resource_types
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE plant_resources
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE pm_boms
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE pm_boms_products
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE pm_products
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE pm_subtypes
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE pm_types
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE port_types
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE ports
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE printer_applications
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE printers
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE product_resource_allocations
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE product_setup_templates
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE product_setups
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE production_regions
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE production_runs
ALTER COLUMN started_at TYPE timestamp with time zone,
ALTER COLUMN closed_at TYPE timestamp with time zone,
ALTER COLUMN re_executed_at TYPE timestamp with time zone,
ALTER COLUMN completed_at TYPE timestamp with time zone,
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE program_functions
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE programs
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE pucs
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE registered_mobile_devices
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE reworks_run_types
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE reworks_runs
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

-- vw_bins
ALTER TABLE rmt_bins
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone,
ALTER COLUMN bin_received_date_time TYPE timestamp with time zone,
ALTER COLUMN bin_tipped_date_time TYPE timestamp with time zone,
ALTER COLUMN exit_ref_date_time TYPE timestamp with time zone,
ALTER COLUMN rebin_created_at TYPE timestamp with time zone,
ALTER COLUMN scrapped_at TYPE timestamp with time zone;

ALTER TABLE rmt_classes
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE rmt_container_material_types
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE rmt_container_types
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE rmt_deliveries
ALTER COLUMN date_delivered TYPE timestamp with time zone,
ALTER COLUMN tipping_complete_date_time TYPE timestamp with time zone,
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE rmt_delivery_destinations
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE roles
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE scrap_reasons
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE season_groups
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE seasons
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE security_groups
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE security_permissions
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE serialized_stock_movement_logs
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE standard_pack_codes
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE standard_product_weights
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE std_fruit_size_counts
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE stock_types
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE system_resource_types
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE system_resources
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE target_market_group_types
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE target_market_groups
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE target_markets
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE treatment_types
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE treatments
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE uoms
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE user_email_groups
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE vehicle_types
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE vessel_types
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE vessels
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE voyage_ports
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE voyage_types
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE voyages
ALTER COLUMN completed_at TYPE timestamp with time zone,
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

-- vw_active_users
ALTER TABLE users
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;


-- Re-add function:

CREATE OR REPLACE FUNCTION public.fn_calc_age_days(
    in_id integer,
    date_from timestamp with time zone,
    date_to timestamp with time zone)
  RETURNS double precision AS
$BODY$
  SELECT ABS(date_part('epoch', date_from::timestamp - COALESCE(date_to::timestamp, current_timestamp)) / 86400)
  FROM pallets
  WHERE id = in_id
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION public.fn_calc_age_days(integer, timestamp with time zone, timestamp with time zone)
  OWNER TO postgres;

-- Re-create dropped views:

CREATE OR REPLACE VIEW public.vw_active_users AS
 SELECT users.id,
    users.login_name,
    users.user_name,
    users.password_hash,
    users.email,
    users.active,
    users.created_at,
    users.updated_at
   FROM users
  WHERE users.active;

ALTER TABLE public.vw_active_users
  OWNER TO postgres;


---
-- View: public.vw_pallet_sequence_flat

-- DROP VIEW public.vw_pallet_sequence_flat;

CREATE OR REPLACE VIEW public.vw_pallet_sequence_flat AS
 SELECT ps.id,
    ps.pallet_id,
    ps.pallet_number,
    ps.pallet_sequence_number,
    plt_packhouses.plant_resource_code AS plt_packhouse,
    plt_lines.plant_resource_code AS plt_line,
    packhouses.plant_resource_code AS packhouse,
    lines.plant_resource_code AS line,
    locations.location_long_code::text AS location,
    p.shipped,
    p.in_stock,
    p.inspected,
    p.reinspected,
    p.palletized,
    p.partially_palletized,
    p.allocated,
    fn_calc_age_days(p.id, p.created_at, COALESCE(p.shipped_at, p.scrapped_at)) AS pallet_age,
    fn_calc_age_days(p.id, COALESCE(p.govt_reinspection_at, p.govt_first_inspection_at), COALESCE(p.shipped_at, p.scrapped_at)) AS inspection_age,
    fn_calc_age_days(p.id, p.stock_created_at, COALESCE(p.shipped_at, p.scrapped_at)) AS stock_age,
    fn_calc_age_days(p.id, p.first_cold_storage_at, COALESCE(p.shipped_at, p.scrapped_at)) AS cold_age,
    p.first_cold_storage_at,
    fn_calc_age_days(p.id, COALESCE(p.govt_reinspection_at, p.govt_first_inspection_at), COALESCE(p.shipped_at, p.scrapped_at)) - fn_calc_age_days(p.id, p.first_cold_storage_at, COALESCE(p.shipped_at, p.scrapped_at)) AS ambient_age,
    p.internal_inspection_passed,
    p.govt_inspection_passed,
    p.govt_first_inspection_at,
    p.govt_reinspection_at,
    fn_calc_age_days(p.id, p.govt_reinspection_at, COALESCE(p.shipped_at, p.scrapped_at)) AS reinspection_age,
    p.shipped_at,
    p.created_at,
    p.scrapped,
    p.scrapped_at,
    ps.production_run_id,
    farms.farm_code AS farm,
    production_regions.production_region_code AS production_region,
    pucs.puc_code AS puc,
    orchards.orchard_code AS orchard,
    commodities.code AS commodity,
    cultivar_groups.cultivar_group_code AS cultivar_group,
    cultivars.cultivar_name AS cultivar,
    marketing_varieties.marketing_variety_code AS marketing_variety,
    fn_party_role_name(ps.marketing_org_party_role_id) AS marketing_org,
    target_market_groups.target_market_group_name AS packed_tm_group,
    marks.mark_code AS mark,
    inventory_codes.inventory_code,
    cvv.marketing_variety_code AS customer_variety,
    std_fruit_size_counts.size_count_value AS std_size,
    fruit_size_references.size_reference AS size_ref,
    fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
    basic_pack_codes.basic_pack_code AS basic_pack,
    standard_pack_codes.standard_pack_code AS std_pack,
    ps.product_resource_allocation_id AS resource_allocation_id,
    ( SELECT array_agg(clt.treatment_code) AS array_agg
           FROM ( SELECT t.treatment_code
                   FROM treatments t
                     JOIN pallet_sequences cl ON t.id = ANY (cl.treatment_ids)
                  WHERE cl.id = ps.id
                  ORDER BY t.treatment_code DESC) clt) AS treatments,
    ps.client_size_reference AS client_size_ref,
    ps.client_product_code,
    ps.marketing_order_number AS order_number,
    seasons.season_code AS season,
    pm_subtypes.subtype_code AS pm_subtype,
    pm_types.pm_type_code AS pm_type,
    cartons_per_pallet.cartons_per_pallet AS cpp,
    pm_products.product_code AS fruit_sticker,
    pm_products_2.product_code AS fruit_sticker_2,
    p.gross_weight,
    p.gross_weight_measured_at,
    p.nett_weight,
    ps.nett_weight AS sequence_nett_weight,
    p.exit_ref,
    p.phc,
    p.stock_created_at,
    p.intake_created_at,
    p.palletized_at,
    p.partially_palletized_at,
    p.allocated_at,
    p.internal_inspection_at,
    p.internal_reinspection_at,
    pallet_bases.pallet_base_code AS pallet_base,
    pallet_stack_types.stack_type_code AS stack_type,
    fn_pallet_verification_failed(p.id) AS pallet_verification_failed,
    ps.verified,
    ps.verification_passed,
    pallet_verification_failure_reasons.reason AS verification_failure_reason,
    ps.verification_result,
    ps.verified_at,
    pm_boms.bom_code AS bom,
    ps.extended_columns,
    ps.carton_quantity,
    ps.scanned_from_carton_id AS scanned_carton,
    ps.scrapped_at AS seq_scrapped_at,
    ps.exit_ref AS seq_exit_ref,
    ps.pick_ref,
    p.carton_quantity AS pallet_carton_quantity,
    ps.carton_quantity::numeric / p.carton_quantity::numeric AS pallet_size,
    p.build_status,
    fn_current_status('pallets'::text, p.id) AS status,
    fn_current_status('pallet_sequences'::text, ps.id) AS sequence_status,
    p.active,
    p.load_id,
    vessels.vessel_code AS vessel,
    voyages.voyage_code AS voyage,
    voyages.voyage_number,
    load_containers.container_code AS container,
    load_containers.internal_container_code AS internal_container,
    cargo_temperatures.temperature_code AS temp_code,
    load_vehicles.vehicle_number,
    p.cooled,
    pol_ports.port_code AS pol,
    pod_ports.port_code AS pod,
    destination_cities.city_name AS final_destination,
    fn_party_role_name(loads.customer_party_role_id) AS customer,
    fn_party_role_name(loads.consignee_party_role_id) AS consignee,
    fn_party_role_name(loads.final_receiver_party_role_id) AS final_receiver,
    fn_party_role_name(loads.exporter_party_role_id) AS exporter,
    fn_party_role_name(loads.billing_client_party_role_id) AS billing_client,
    destination_countries.country_name AS country,
    destination_regions.destination_region_name AS region,
    pod_voyage_ports.eta,
    pod_voyage_ports.ata,
    pol_voyage_ports.etd,
    pol_voyage_ports.atd,
    COALESCE(p.load_id, 0) AS zero_load_id,
    p.fruit_sticker_pm_product_id,
    p.fruit_sticker_pm_product_2_id,
    ps.pallet_verification_failure_reason_id,
    grades.grade_code AS grade,
    ps.sell_by_code,
    ps.product_chars,
        CASE
            WHEN p.scrapped THEN 'warning'::text
            WHEN p.shipped THEN 'inactive'::text
            WHEN p.allocated THEN 'ready'::text
            WHEN p.in_stock THEN 'ok'::text
            WHEN p.palletized OR p.partially_palletized THEN 'inprogress'::text
            WHEN p.inspected AND NOT p.govt_inspection_passed THEN 'error'::text
            WHEN ps.verified AND NOT ps.verification_passed THEN 'error'::text
            ELSE NULL::text
        END AS colour_rule,
    loads.exporter_certificate_code,
    load_voyages.booking_reference,
    govt_inspection_pallets.govt_inspection_sheet_id,
    COALESCE(p.edi_in_inspection_point, govt_inspection_sheets.inspection_point) AS inspection_point,
    inspected_dest_country.country_name AS inspected_dest_country,
    p.last_govt_inspection_pallet_id,
    p.shipped_at::date AS shipped_date,
    p.pallet_format_id,
    p.temp_tail,
    fn_party_role_name(load_voyages.shipper_party_role_id) AS shipper,
    p.depot_pallet,
    edi_in_transactions.file_name AS edi_in_file,
    p.edi_in_consignment_note_number,
    COALESCE(p.govt_reinspection_at, p.govt_first_inspection_at) AS inspection_date,
    COALESCE(p.edi_in_consignment_note_number,
        CASE
            WHEN NOT p.govt_inspection_passed THEN lpad(govt_inspection_pallets.govt_inspection_sheet_id::text, 10, '0'::text) || 'F'::text
            WHEN p.govt_inspection_passed THEN lpad(govt_inspection_pallets.govt_inspection_sheet_id::text, 10, '0'::text)
            ELSE ''::text
        END) AS addendum_manifest
   FROM pallets p
     JOIN pallet_sequences ps ON p.id = ps.pallet_id
     LEFT JOIN plant_resources plt_packhouses ON plt_packhouses.id = p.plt_packhouse_resource_id
     LEFT JOIN plant_resources plt_lines ON plt_lines.id = p.plt_line_resource_id
     LEFT JOIN plant_resources packhouses ON packhouses.id = ps.packhouse_resource_id
     LEFT JOIN plant_resources lines ON lines.id = ps.production_line_id
     JOIN locations ON locations.id = p.location_id
     JOIN farms ON farms.id = ps.farm_id
     JOIN production_regions ON production_regions.id = farms.pdn_region_id
     JOIN pucs ON pucs.id = ps.puc_id
     JOIN orchards ON orchards.id = ps.orchard_id
     JOIN cultivar_groups ON cultivar_groups.id = ps.cultivar_group_id
     LEFT JOIN cultivars ON cultivars.id = ps.cultivar_id
     LEFT JOIN commodities ON commodities.id = COALESCE(cultivars.commodity_id, cultivar_groups.commodity_id)
     JOIN marketing_varieties ON marketing_varieties.id = ps.marketing_variety_id
     JOIN marks ON marks.id = ps.mark_id
     JOIN inventory_codes ON inventory_codes.id = ps.inventory_code_id
     JOIN target_market_groups ON target_market_groups.id = ps.packed_tm_group_id
     JOIN grades ON grades.id = ps.grade_id
     LEFT JOIN customer_variety_varieties ON customer_variety_varieties.id = ps.customer_variety_variety_id
     LEFT JOIN marketing_varieties cvv ON cvv.id = customer_variety_varieties.marketing_variety_id
     LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = ps.std_fruit_size_count_id
     LEFT JOIN fruit_size_references ON fruit_size_references.id = ps.fruit_size_reference_id
     LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = ps.fruit_actual_counts_for_pack_id
     JOIN basic_pack_codes ON basic_pack_codes.id = ps.basic_pack_code_id
     JOIN standard_pack_codes ON standard_pack_codes.id = ps.standard_pack_code_id
     LEFT JOIN pm_boms ON pm_boms.id = ps.pm_bom_id
     LEFT JOIN pm_subtypes ON pm_subtypes.id = ps.pm_subtype_id
     LEFT JOIN pm_types ON pm_types.id = ps.pm_type_id
     JOIN seasons ON seasons.id = ps.season_id
     JOIN cartons_per_pallet ON cartons_per_pallet.id = ps.cartons_per_pallet_id
     LEFT JOIN pm_products ON pm_products.id = p.fruit_sticker_pm_product_id
     LEFT JOIN pm_products pm_products_2 ON pm_products_2.id = p.fruit_sticker_pm_product_2_id
     LEFT JOIN pallet_formats ON pallet_formats.id = p.pallet_format_id
     LEFT JOIN pallet_bases ON pallet_bases.id = pallet_formats.pallet_base_id
     LEFT JOIN pallet_stack_types ON pallet_stack_types.id = pallet_formats.pallet_stack_type_id
     LEFT JOIN pallet_verification_failure_reasons ON pallet_verification_failure_reasons.id = ps.pallet_verification_failure_reason_id
     LEFT JOIN loads ON loads.id = p.load_id
     LEFT JOIN load_voyages ON loads.id = load_voyages.load_id
     LEFT JOIN voyage_ports pol_voyage_ports ON pol_voyage_ports.id = loads.pol_voyage_port_id
     LEFT JOIN voyage_ports pod_voyage_ports ON pod_voyage_ports.id = loads.pod_voyage_port_id
     LEFT JOIN voyages ON voyages.id = pol_voyage_ports.voyage_id
     LEFT JOIN vessels ON vessels.id = voyages.vessel_id
     LEFT JOIN load_containers ON load_containers.load_id = loads.id
     LEFT JOIN load_vehicles ON load_vehicles.load_id = loads.id
     LEFT JOIN ports pol_ports ON pol_ports.id = pol_voyage_ports.port_id
     LEFT JOIN ports pod_ports ON pod_ports.id = pod_voyage_ports.port_id
     LEFT JOIN destination_cities ON destination_cities.id = loads.final_destination_id
     LEFT JOIN destination_countries ON destination_countries.id = destination_cities.destination_country_id
     LEFT JOIN destination_regions ON destination_regions.id = destination_countries.destination_region_id
     LEFT JOIN cargo_temperatures ON cargo_temperatures.id = load_containers.cargo_temperature_id
     LEFT JOIN govt_inspection_pallets ON govt_inspection_pallets.id = p.last_govt_inspection_pallet_id
     LEFT JOIN govt_inspection_sheets ON govt_inspection_sheets.id = govt_inspection_pallets.govt_inspection_sheet_id
     LEFT JOIN destination_countries inspected_dest_country ON inspected_dest_country.id = govt_inspection_sheets.destination_country_id
     LEFT JOIN edi_in_transactions ON edi_in_transactions.id = p.edi_in_transaction_id
  ORDER BY ps.pallet_number, ps.pallet_sequence_number;

ALTER TABLE public.vw_pallet_sequence_flat
  OWNER TO postgres;

---

-- View: public.vw_bins

-- DROP VIEW public.vw_bins;

CREATE OR REPLACE VIEW public.vw_bins AS
 SELECT rmt_bins.id,
    rmt_bins.rmt_delivery_id,
    rmt_bins.season_id,
        CASE
            WHEN rmt_bins.qty_bins = 1 THEN true
            ELSE false
        END AS discrete_bin,
    rmt_bins.cultivar_id,
    rmt_bins.orchard_id,
    rmt_bins.farm_id,
    rmt_bins.rmt_class_id,
    rmt_bins.rmt_container_type_id,
    rmt_bins.rmt_container_material_type_id,
    rmt_bins.cultivar_group_id,
    rmt_bins.puc_id,
    rmt_bins.exit_ref,
    rmt_bins.qty_bins,
    rmt_bins.bin_asset_number,
    rmt_bins.tipped_asset_number,
    rmt_bins.rmt_inner_container_type_id,
    rmt_bins.rmt_inner_container_material_id,
    rmt_bins.qty_inner_bins,
    rmt_bins.production_run_rebin_id,
    rmt_bins.production_run_tipped_id,
    rmt_bins.bin_tipping_plant_resource_id,
    rmt_bins.bin_fullness,
    rmt_bins.nett_weight,
    rmt_bins.gross_weight,
    rmt_bins.active,
    rmt_bins.bin_tipped,
    rmt_bins.created_at,
    rmt_bins.updated_at,
    rmt_bins.bin_received_date_time::date AS bin_received_date,
    rmt_bins.bin_received_date_time,
    rmt_bins.bin_tipped_date_time::date AS bin_tipped_date,
    rmt_bins.bin_tipped_date_time,
    rmt_bins.exit_ref_date_time::date AS exit_ref_date,
    rmt_bins.exit_ref_date_time,
    rmt_bins.rebin_created_at,
    rmt_bins.scrapped,
    rmt_bins.scrapped_at,
    cultivar_groups.cultivar_group_code,
    cultivars.cultivar_name,
    cultivars.description AS cultivar_description,
    farms.farm_code,
    orchards.orchard_code,
    pucs.puc_code,
    rmt_classes.rmt_class_code,
    rmt_container_material_types.container_material_type_code,
    rmt_container_types.container_type_code,
    rmt_deliveries.truck_registration_number AS rmt_delivery_truck_registration_number,
    seasons.season_code,
        CASE
            WHEN rmt_bins.bin_tipped THEN 'gray'::text
            ELSE NULL::text
        END AS colour_rule,
    fn_current_status('rmt_bins'::text, rmt_bins.id) AS status
   FROM rmt_bins
     LEFT JOIN cultivar_groups ON cultivar_groups.id = rmt_bins.cultivar_group_id
     LEFT JOIN cultivars ON cultivars.id = rmt_bins.cultivar_id
     LEFT JOIN farms ON farms.id = rmt_bins.farm_id
     LEFT JOIN orchards ON orchards.id = rmt_bins.orchard_id
     LEFT JOIN pucs ON pucs.id = rmt_bins.puc_id
     LEFT JOIN rmt_classes ON rmt_classes.id = rmt_bins.rmt_class_id
     LEFT JOIN rmt_container_material_types ON rmt_container_material_types.id = rmt_bins.rmt_container_material_type_id
     LEFT JOIN rmt_container_types ON rmt_container_types.id = rmt_bins.rmt_container_type_id
     LEFT JOIN rmt_deliveries ON rmt_deliveries.id = rmt_bins.rmt_delivery_id
     JOIN seasons ON seasons.id = rmt_bins.season_id;

ALTER TABLE public.vw_bins
  OWNER TO postgres;

---

      CREATE OR REPLACE VIEW public.vw_packout_details AS 
       SELECT farms.farm_code,
          (SELECT string_agg(sub.orchard_code, '; ') AS string_agg
                 FROM (SELECT DISTINCT orchard_code
                         FROM rmt_bins
                         JOIN orchards ON orchards.id = rmt_bins.orchard_id
                         WHERE rmt_bins.production_run_tipped_id = production_runs.id) sub) AS orchards,
          date_trunc('day'::text, pallet_sequences.created_at) AS pack_date,
          date_part('week'::text, pallet_sequences.created_at) AS pack_week,
          ( SELECT string_agg(sub.rmt_delivery_id::text, '; '::text) AS string_agg
                 FROM ( SELECT DISTINCT rmt_bins.rmt_delivery_id
                         FROM rmt_bins
                        WHERE rmt_bins.production_run_tipped_id = pallet_sequences.production_run_id) sub) AS deliveries,
          production_run_stats.bins_tipped AS no_of_bins,
          production_run_stats.bins_tipped_weight::numeric(12,2) AS total_bin_weight,
          production_run_stats.cartons_verified_weight::numeric(12,2) AS total_packed_weight,
          production_run_stats.pallet_weight::numeric(12,2) AS total_pallet_weight,
              CASE production_run_stats.bins_tipped_weight
                  WHEN 0 THEN 0.0::numeric(7,2)
                  ELSE (production_run_stats.cartons_verified_weight / production_run_stats.bins_tipped_weight * 100::numeric)::numeric(7,2)
              END AS run_carton_percentage,
              CASE production_run_stats.bins_tipped_weight
                  WHEN 0 THEN 0.0::numeric(7,2)
                  ELSE (production_run_stats.pallet_weight / production_run_stats.bins_tipped_weight * 100::numeric)::numeric(7,2)
              END AS run_pallet_percentage,
          COALESCE(cultivars.cultivar_name, cultivar_groups.cultivar_group_code) AS cultivar,
          marketing_varieties.marketing_variety_code,
          pallet_sequences.production_run_id,
          fn_production_run_code(pallet_sequences.production_run_id) AS production_run_code,
          grades.grade_code,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          basic_pack_codes.basic_pack_code AS basic_pack,
          std_fruit_size_counts.size_count_value AS std_size,
          fruit_size_references.size_reference AS size_ref,
          fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
          inventory_codes.inventory_code,
          pallet_sequences.nett_weight::numeric(12,2) AS nett_weight,
          pallet_sequences.carton_quantity,
              CASE production_run_stats.cartons_verified_weight
                  WHEN 0 THEN 0.0::numeric(7,2)
                  ELSE (pallet_sequences.nett_weight / production_run_stats.cartons_verified_weight * 100::numeric)::numeric(7,2)
              END AS percentage
         FROM pallet_sequences
           JOIN production_runs ON production_runs.id = pallet_sequences.production_run_id
           JOIN plant_resources packhouses ON packhouses.id = pallet_sequences.packhouse_resource_id
           JOIN plant_resources lines ON lines.id = pallet_sequences.production_line_id
           JOIN farms ON farms.id = (SELECT farm_id FROM rmt_bins WHERE production_run_tipped_id = production_runs.id LIMIT 1)
           JOIN cultivar_groups ON cultivar_groups.id = pallet_sequences.cultivar_group_id
           LEFT JOIN cultivars ON cultivars.id = pallet_sequences.cultivar_id
           JOIN marketing_varieties ON marketing_varieties.id = pallet_sequences.marketing_variety_id
           JOIN grades ON grades.id = pallet_sequences.grade_id
           LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = pallet_sequences.std_fruit_size_count_id
           LEFT JOIN fruit_size_references ON fruit_size_references.id = pallet_sequences.fruit_size_reference_id
           LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = pallet_sequences.fruit_actual_counts_for_pack_id
           JOIN basic_pack_codes ON basic_pack_codes.id = pallet_sequences.basic_pack_code_id
           JOIN inventory_codes ON inventory_codes.id = pallet_sequences.inventory_code_id
           JOIN production_run_stats ON production_run_stats.production_run_id = pallet_sequences.production_run_id;

      ALTER TABLE public.vw_packout_details
        OWNER TO postgres;

---

      CREATE OR REPLACE VIEW public.vw_pallet_label AS
       SELECT pallet_sequences.id,
          pallet_sequences.pallet_id,
          pallet_sequences.pallet_sequence_number,
          farms.farm_code,
          orchards.orchard_code,
          to_char(pallet_sequences.verified_at, 'YYYY-mm-dd') AS pack_date,
          date_part('week'::text, pallet_sequences.verified_at)::integer AS pack_week,
          marketing_varieties.marketing_variety_code,
          marketing_varieties.description AS marketing_variety_description,
          pallet_sequences.production_run_id,
          fn_production_run_code(pallet_sequences.production_run_id) AS production_run_code,
          grades.grade_code,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          standard_pack_codes.standard_pack_code,
          standard_pack_codes.std_pack_label_code,
          std_fruit_size_counts.size_count_value,
          fruit_size_references.size_reference,
          fruit_actual_counts_for_packs.actual_count_for_pack,
          inventory_codes.inventory_code,
          pallets.gross_weight::numeric(12,2) AS gross_weight,
          pallets.nett_weight::numeric(12,2) AS nett_weight,
          pallets.carton_quantity,
          basic_pack_codes.basic_pack_code,
          commodities.code AS commodity,
          commodities.description AS commodity_description,
          cultivar_groups.cultivar_group_code,
          cultivars.cultivar_name,
          marks.mark_code,
          pallets.pallet_number,
          pallets.phc,
          pallet_sequences.pick_ref,
          pucs.puc_code,
          seasons.season_code,
          pallet_sequences.marketing_order_number,
          standard_product_weights.nett_weight AS pack_nett_weight,
          uoms.uom_code AS size_count_uom,
          cvv.marketing_variety_code AS customer_variety_code,
          marketing_org.short_description AS marketing_org_short,
          marketing_org.medium_description AS marketing_org_medium,
          target_market_groups.target_market_group_name AS packed_tm_group,
          ( SELECT string_agg(clt.treatment_code, ', ') AS str_agg
            FROM ( SELECT t.treatment_code
                   FROM treatments t
                   JOIN pallet_sequences cl ON t.id = ANY (cl.treatment_ids)
                  WHERE cl.id = pallet_sequences.id
                  ORDER BY t.treatment_code DESC) clt) AS treatments
         FROM pallet_sequences
           JOIN pallets ON pallets.id = pallet_sequences.pallet_id
           JOIN production_runs ON production_runs.id = pallet_sequences.production_run_id
           JOIN plant_resources packhouses ON packhouses.id = pallet_sequences.packhouse_resource_id
           JOIN plant_resources lines ON lines.id = pallet_sequences.production_line_id
           LEFT JOIN farms ON farms.id = (SELECT farm_id FROM rmt_bins WHERE production_run_tipped_id = production_runs.id LIMIT 1)
           JOIN orchards ON orchards.id = pallet_sequences.orchard_id
           JOIN cultivar_groups ON cultivar_groups.id = pallet_sequences.cultivar_group_id
           LEFT JOIN cultivars ON cultivars.id = pallet_sequences.cultivar_id
           LEFT JOIN commodities ON commodities.id = COALESCE(cultivars.commodity_id, cultivar_groups.commodity_id)
           JOIN marketing_varieties ON marketing_varieties.id = pallet_sequences.marketing_variety_id
           JOIN grades ON grades.id = pallet_sequences.grade_id
           LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = pallet_sequences.std_fruit_size_count_id
           LEFT JOIN fruit_size_references ON fruit_size_references.id = pallet_sequences.fruit_size_reference_id
           LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = pallet_sequences.fruit_actual_counts_for_pack_id
           LEFT JOIN uoms ON uoms.id = std_fruit_size_counts.uom_id
           JOIN standard_pack_codes ON standard_pack_codes.id = pallet_sequences.standard_pack_code_id
           JOIN basic_pack_codes ON basic_pack_codes.id = pallet_sequences.basic_pack_code_id
           LEFT JOIN standard_product_weights ON standard_product_weights.commodity_id = commodities.id
                 AND standard_product_weights.standard_pack_id = pallet_sequences.standard_pack_code_id
           JOIN inventory_codes ON inventory_codes.id = pallet_sequences.inventory_code_id
           JOIN marks ON marks.id = pallet_sequences.mark_id
           JOIN pucs ON pucs.id = pallet_sequences.puc_id
           JOIN seasons ON seasons.id = pallet_sequences.season_id
           LEFT JOIN customer_variety_varieties ON customer_variety_varieties.id = pallet_sequences.customer_variety_variety_id
           LEFT JOIN marketing_varieties cvv ON cvv.id = customer_variety_varieties.marketing_variety_id
           JOIN target_market_groups ON target_market_groups.id = pallet_sequences.packed_tm_group_id
           LEFT OUTER JOIN party_roles org_pr ON org_pr.id = pallet_sequences.marketing_org_party_role_id
           LEFT OUTER JOIN organizations marketing_org ON marketing_org.id = org_pr.organization_id;

      ALTER TABLE public.vw_pallet_label
        OWNER TO postgres;

---
      CREATE OR REPLACE VIEW public.vw_scrapped_pallet_sequence_flat AS
       SELECT ps.id,
          ps.scrapped_from_pallet_id AS pallet_id,
          ps.pallet_number,
          ps.pallet_sequence_number,
          plt_packhouses.plant_resource_code AS plt_packhouse,
          plt_lines.plant_resource_code AS plt_line,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          locations.location_long_code::text AS location,
          p.shipped,
          p.in_stock,
          p.inspected,
          p.reinspected,
          p.palletized,
          p.partially_palletized,
          p.allocated,
          fn_calc_age_days(p.id, p.created_at, COALESCE(p.shipped_at, p.scrapped_at)) AS pallet_age,
          fn_calc_age_days(p.id, COALESCE(p.govt_reinspection_at, p.govt_first_inspection_at), COALESCE(p.shipped_at, p.scrapped_at)) AS inspection_age,
          fn_calc_age_days(p.id, p.stock_created_at, COALESCE(p.shipped_at, p.scrapped_at)) AS stock_age,
          fn_calc_age_days(p.id, p.first_cold_storage_at, COALESCE(p.shipped_at, p.scrapped_at)) AS cold_age,
          p.first_cold_storage_at,
          fn_calc_age_days(p.id, COALESCE(p.govt_reinspection_at, p.govt_first_inspection_at), COALESCE(p.shipped_at, p.scrapped_at)) - fn_calc_age_days(p.id, p.first_cold_storage_at, COALESCE(p.shipped_at, p.scrapped_at)) AS ambient_age,
          p.internal_inspection_passed,
          p.govt_inspection_passed,
          p.govt_first_inspection_at,
          p.govt_reinspection_at,
          fn_calc_age_days(p.id, p.govt_reinspection_at, COALESCE(p.shipped_at, p.scrapped_at)) AS reinspection_age,
          p.shipped_at,
          p.created_at,
          p.scrapped,
          p.scrapped_at,
          ps.production_run_id,
          farms.farm_code AS farm,
          pucs.puc_code AS puc,
          orchards.orchard_code AS orchard,
          commodities.code AS commodity,
          cultivar_groups.cultivar_group_code AS cultivar_group,
          cultivars.cultivar_name AS cultivar,
          marketing_varieties.marketing_variety_code AS marketing_variety,
          fn_party_role_name(ps.marketing_org_party_role_id) AS marketing_org,
          target_market_groups.target_market_group_name AS packed_tm_group,
          marks.mark_code AS mark,
          inventory_codes.inventory_code,
          cvv.marketing_variety_code AS customer_variety,
          std_fruit_size_counts.size_count_value AS std_size,
          fruit_size_references.size_reference AS size_ref,
          fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
          basic_pack_codes.basic_pack_code AS basic_pack,
          standard_pack_codes.standard_pack_code AS std_pack,
          ps.product_resource_allocation_id AS resource_allocation_id,
          ( SELECT array_agg(clt.treatment_code) AS array_agg
                 FROM ( SELECT t.treatment_code
                         FROM treatments t
                           JOIN pallet_sequences cl ON t.id = ANY (cl.treatment_ids)
                        WHERE cl.id = ps.id
                        ORDER BY t.treatment_code DESC) clt) AS treatments,
          ps.client_size_reference AS client_size_ref,
          ps.client_product_code,
          ps.marketing_order_number AS order_number,
          seasons.season_code AS season,
          pm_subtypes.subtype_code AS pm_subtype,
          pm_types.pm_type_code AS pm_type,
          cartons_per_pallet.cartons_per_pallet AS cpp,
          pm_products.product_code AS fruit_sticker,
          pm_products_2.product_code AS fruit_sticker_2,
          p.gross_weight,
          p.gross_weight_measured_at,
          p.nett_weight,
          ps.nett_weight AS sequence_nett_weight,
          p.exit_ref,
          p.phc,
          p.stock_created_at,
          p.intake_created_at,
          p.palletized_at,
          p.partially_palletized_at,
          p.allocated_at,
          p.internal_inspection_at,
          p.internal_reinspection_at,
          pallet_bases.pallet_base_code AS pallet_base,
          pallet_stack_types.stack_type_code AS stack_type,
          fn_pallet_verification_failed(p.id) AS pallet_verification_failed,
          ps.verified,
          ps.verification_passed,
          pallet_verification_failure_reasons.reason AS verification_failure_reason,
          ps.verification_result,
          ps.verified_at,
          pm_boms.bom_code AS bom,
          ps.extended_columns,
          ps.carton_quantity,
          ps.scanned_from_carton_id AS scanned_carton,
          ps.scrapped_at AS seq_scrapped_at,
          ps.exit_ref AS seq_exit_ref,
          ps.pick_ref,
          p.carton_quantity AS pallet_carton_quantity,
          ps.carton_quantity::numeric / p.carton_quantity::numeric AS pallet_size,
          p.build_status,
          fn_current_status('pallets'::text, p.id) AS status,
          fn_current_status('pallet_sequences'::text, ps.id) AS sequence_status,
          p.active,
          p.load_id,
          vessels.vessel_code AS vessel,
          voyages.voyage_code AS voyage,
          voyages.voyage_number,
          load_containers.container_code AS container,
          load_containers.internal_container_code AS internal_container,
          cargo_temperatures.temperature_code AS temp_code,
          load_vehicles.vehicle_number,
          p.cooled,
          pol_ports.port_code AS pol,
          pod_ports.port_code AS pod,
          destination_cities.city_name AS final_destination,
          fn_party_role_name(loads.customer_party_role_id) AS customer,
          fn_party_role_name(loads.consignee_party_role_id) AS consignee,
          fn_party_role_name(loads.final_receiver_party_role_id) AS final_receiver,
          fn_party_role_name(loads.exporter_party_role_id) AS exporter,
          fn_party_role_name(loads.billing_client_party_role_id) AS billing_client,
          destination_countries.country_name AS country,
          destination_regions.destination_region_name AS region,
          pod_voyage_ports.eta,
          pod_voyage_ports.ata,
          pol_voyage_ports.etd,
          pol_voyage_ports.atd,
          COALESCE(p.load_id, 0) AS zero_load_id,
          p.fruit_sticker_pm_product_id,
          p.fruit_sticker_pm_product_2_id,
          ps.pallet_verification_failure_reason_id,
          grades.grade_code AS grade,
          ps.sell_by_code,
          ps.product_chars,
          p.pallet_format_id,
              CASE
                  WHEN p.scrapped THEN 'warning'::text
                  ELSE NULL::text
              END AS colour_rule
         FROM pallets p
           JOIN pallet_sequences ps ON p.id = ps.scrapped_from_pallet_id
           JOIN plant_resources plt_packhouses ON plt_packhouses.id = p.plt_packhouse_resource_id
           JOIN plant_resources plt_lines ON plt_lines.id = p.plt_line_resource_id
           JOIN plant_resources packhouses ON packhouses.id = ps.packhouse_resource_id
           JOIN plant_resources lines ON lines.id = ps.production_line_id
           JOIN locations ON locations.id = p.location_id
           JOIN farms ON farms.id = ps.farm_id
           JOIN pucs ON pucs.id = ps.puc_id
           JOIN orchards ON orchards.id = ps.orchard_id
           JOIN cultivar_groups ON cultivar_groups.id = ps.cultivar_group_id
           LEFT JOIN cultivars ON cultivars.id = ps.cultivar_id
           LEFT JOIN commodities ON commodities.id = COALESCE(cultivars.commodity_id, cultivar_groups.commodity_id)
           JOIN marketing_varieties ON marketing_varieties.id = ps.marketing_variety_id
           JOIN marks ON marks.id = ps.mark_id
           JOIN inventory_codes ON inventory_codes.id = ps.inventory_code_id
           JOIN target_market_groups ON target_market_groups.id = ps.packed_tm_group_id
           JOIN grades ON grades.id = ps.grade_id
           LEFT JOIN customer_variety_varieties ON customer_variety_varieties.id = ps.customer_variety_variety_id
           LEFT JOIN marketing_varieties cvv ON cvv.id = customer_variety_varieties.marketing_variety_id
           LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = ps.std_fruit_size_count_id
           LEFT JOIN fruit_size_references ON fruit_size_references.id = ps.fruit_size_reference_id
           LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = ps.fruit_actual_counts_for_pack_id
           JOIN basic_pack_codes ON basic_pack_codes.id = ps.basic_pack_code_id
           JOIN standard_pack_codes ON standard_pack_codes.id = ps.standard_pack_code_id
           LEFT JOIN pm_boms ON pm_boms.id = ps.pm_bom_id
           LEFT JOIN pm_subtypes ON pm_subtypes.id = ps.pm_subtype_id
           LEFT JOIN pm_types ON pm_types.id = ps.pm_type_id
           JOIN seasons ON seasons.id = ps.season_id
           JOIN cartons_per_pallet ON cartons_per_pallet.id = ps.cartons_per_pallet_id
           LEFT JOIN pm_products ON pm_products.id = p.fruit_sticker_pm_product_id
           LEFT JOIN pm_products pm_products_2 ON pm_products_2.id = p.fruit_sticker_pm_product_2_id
           LEFT JOIN pallet_formats ON pallet_formats.id = p.pallet_format_id
           LEFT JOIN pallet_bases ON pallet_bases.id = pallet_formats.pallet_base_id
           LEFT JOIN pallet_stack_types ON pallet_stack_types.id = pallet_formats.pallet_stack_type_id
           LEFT JOIN pallet_verification_failure_reasons ON pallet_verification_failure_reasons.id = ps.pallet_verification_failure_reason_id
           LEFT JOIN loads ON loads.id = p.load_id
           LEFT JOIN voyage_ports pol_voyage_ports ON pol_voyage_ports.id = loads.pol_voyage_port_id
           LEFT JOIN voyage_ports pod_voyage_ports ON pod_voyage_ports.id = loads.pod_voyage_port_id
           LEFT JOIN voyages ON voyages.id = pol_voyage_ports.voyage_id
           LEFT JOIN vessels ON vessels.id = voyages.vessel_id
           LEFT JOIN load_containers ON load_containers.load_id = loads.id
           LEFT JOIN load_vehicles ON load_vehicles.load_id = loads.id
           LEFT JOIN ports pol_ports ON pol_ports.id = pol_voyage_ports.port_id
           LEFT JOIN ports pod_ports ON pod_ports.id = pod_voyage_ports.port_id
           LEFT JOIN destination_cities ON destination_cities.id = loads.final_destination_id
           LEFT JOIN destination_countries ON destination_countries.id = destination_cities.destination_country_id
           LEFT JOIN destination_regions ON destination_regions.id = destination_countries.destination_region_id
           LEFT JOIN cargo_temperatures ON cargo_temperatures.id = load_containers.cargo_temperature_id
        ORDER BY p.pallet_number, ps.pallet_sequence_number;

      ALTER TABLE public.vw_scrapped_pallet_sequence_flat
        OWNER TO postgres;

---

CREATE TRIGGER pallet_sequences_prod_run_stats_queue
  AFTER INSERT OR UPDATE OF carton_quantity, scrapped_at, nett_weight
  ON public.pallet_sequences
  FOR EACH ROW
  EXECUTE PROCEDURE public.fn_add_run_to_stats_queue();

---

CREATE TRIGGER pallets_prod_run_stats_queue
  AFTER UPDATE OF scrapped_at
  ON public.pallets
  FOR EACH ROW
  EXECUTE PROCEDURE public.fn_add_run_to_stats_queue_for_pallet();

