-- LABEL ADMIN GROUP AND PERMISSIONS
INSERT INTO security_permissions (security_permission)
VALUES ('export');
INSERT INTO security_permissions (security_permission)
VALUES ('approve');


INSERT INTO security_groups (security_group_name)
VALUES ('label_admin');

INSERT INTO security_groups_security_permissions (security_group_id, security_permission_id)
SELECT g.id,
(SELECT id FROM security_permissions WHERE security_permission = 'read')
FROM security_groups g WHERE g.security_group_name = 'label_admin';
INSERT INTO security_groups_security_permissions (security_group_id, security_permission_id)
SELECT g.id,
(SELECT id FROM security_permissions WHERE security_permission = 'new')
FROM security_groups g WHERE g.security_group_name = 'label_admin';
INSERT INTO security_groups_security_permissions (security_group_id, security_permission_id)
SELECT g.id,
(SELECT id FROM security_permissions WHERE security_permission = 'edit')
FROM security_groups g WHERE g.security_group_name = 'label_admin';
INSERT INTO security_groups_security_permissions (security_group_id, security_permission_id)
SELECT g.id,
(SELECT id FROM security_permissions WHERE security_permission = 'delete')
FROM security_groups g WHERE g.security_group_name = 'label_admin';
INSERT INTO security_groups_security_permissions (security_group_id, security_permission_id)
SELECT g.id,
(SELECT id FROM security_permissions WHERE security_permission = 'export')
FROM security_groups g WHERE g.security_group_name = 'label_admin';
INSERT INTO security_groups_security_permissions (security_group_id, security_permission_id)
SELECT g.id,
(SELECT id FROM security_permissions WHERE security_permission = 'approve')
FROM security_groups g WHERE g.security_group_name = 'label_admin';


INSERT INTO security_groups (security_group_name)
VALUES ('label_approver');

INSERT INTO security_groups_security_permissions (security_group_id, security_permission_id)
SELECT g.id,
(SELECT id FROM security_permissions WHERE security_permission = 'read')
FROM security_groups g WHERE g.security_group_name = 'label_approver';
INSERT INTO security_groups_security_permissions (security_group_id, security_permission_id)
SELECT g.id,
(SELECT id FROM security_permissions WHERE security_permission = 'approve')
FROM security_groups g WHERE g.security_group_name = 'label_approver';
