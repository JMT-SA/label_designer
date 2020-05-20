-- Drop view that return one or more of these columns to change:
DROP VIEW public.vw_active_users;


-- Alter all date times to include time zone:

ALTER TABLE audit.current_statuses
ALTER COLUMN action_tstamp_tx TYPE timestamp with time zone;

ALTER TABLE audit.logged_action_details
ALTER COLUMN action_tstamp_tx TYPE timestamp with time zone;

ALTER TABLE audit.status_logs
ALTER COLUMN action_tstamp_tx TYPE timestamp with time zone;


ALTER TABLE functional_areas
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

ALTER TABLE labels
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE master_lists
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

-- ALTER TABLE mes_modules
-- ALTER COLUMN created_at TYPE timestamp with time zone,
-- ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE message_bus
ALTER COLUMN added_at TYPE timestamp with time zone;

ALTER TABLE multi_labels
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE printer_applications
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE printers
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE program_functions
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE programs
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE registered_mobile_devices
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE security_groups
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE security_permissions
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

ALTER TABLE user_email_groups
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;

-- vw_active_users
ALTER TABLE users
ALTER COLUMN created_at TYPE timestamp with time zone,
ALTER COLUMN updated_at TYPE timestamp with time zone;



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

