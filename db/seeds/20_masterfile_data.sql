-- USER_EMAIL_GROUPS --
INSERT INTO user_email_groups (mail_group) VALUES('label_approvers') ON CONFLICT DO NOTHING;
INSERT INTO user_email_groups (mail_group) VALUES('label_publishers') ON CONFLICT DO NOTHING;
