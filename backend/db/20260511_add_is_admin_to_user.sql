-- Rebuild v_user to expose the existing admin column
-- (is_admin column added and removed during development; using pre-existing admin column instead)
DROP VIEW IF EXISTS public.v_user;
CREATE VIEW public.v_user AS
 SELECT u.user_id,
    concat(u.first_name, ' ', u.last_name) AS user_name,
    u.first_name,
    u.last_name,
    u.email,
    u.is_deleted,
    u.can_login,
    u.admin,
    u.organisation,
    ( SELECT count(*) AS count
           FROM public.user_pageview pv
          WHERE (pv.user_id = u.user_id)) AS pageview_count
   FROM public."user" u;

-- Sync identity sequence to current max (fixes duplicate key on insert)
SELECT setval('user_user_id_seq', (SELECT MAX(user_id) FROM "user"));
