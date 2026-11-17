--Kiểm tra JWT
SELECT id, org_code, org_name, status
FROM organizations
ORDER BY id;

SELECT id, username, full_name, is_active
FROM users
ORDER BY id;

SELECT id, organization_id, user_id, role, is_active
FROM organization_memberships
ORDER BY id;

SELECT id, username, is_active
FROM users
WHERE username = 'admin01';

SELECT
    m.id AS membership_id,
    m.organization_id,
    m.user_id,
    u.username,
    m.role,
    m.is_active
FROM organization_memberships m
JOIN users u ON u.id = m.user_id
ORDER BY m.organization_id, m.id;

--Kiểm tra fly

select * from plots

--Kiểm tra khi thêm farm và qc
SELECT
    u.id AS user_id,
    u.username,
    u.full_name,
    m.id AS membership_id,
    m.organization_id,
    m.role,
    u.is_active AS user_active,
    m.is_active AS membership_active
FROM users u
JOIN organization_memberships m
    ON m.user_id = u.id
ORDER BY u.id;

--Kiểm tra phân công plot
SELECT
    pa.id AS assignment_id,
    p.plot_code,
    u.username,
    m.role,
    pa.assigned_at,
    pa.ended_at
FROM plot_assignments pa
JOIN plots p
    ON p.id = pa.plot_id
   AND p.organization_id = pa.organization_id
JOIN organization_memberships m
    ON m.id = pa.membership_id
   AND m.organization_id = pa.organization_id
JOIN users u
    ON u.id = m.user_id
ORDER BY pa.id DESC;

--xem assignment để patch
SELECT
    pa.id AS assignment_id,
    pa.organization_id,
    p.id AS plot_id,
    p.plot_code,
    u.username,
    m.role,
    pa.assigned_at,
    pa.ended_at
FROM plot_assignments pa
JOIN plots p
    ON p.id = pa.plot_id
   AND p.organization_id = pa.organization_id
JOIN organization_memberships m
    ON m.id = pa.membership_id
   AND m.organization_id = pa.organization_id
JOIN users u
    ON u.id = m.user_id
ORDER BY pa.id DESC;

--Kiểm tra khi patch kết thúc công việc
SELECT id, plot_id, membership_id, assigned_at, ended_at
FROM plot_assignments
WHERE id = 1;


select * from organizations
select * from plots
select * from organization_memberships
