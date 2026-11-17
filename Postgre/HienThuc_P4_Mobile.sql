--MOBILE

--Kiểm tra khi tạo Migration bên backend 
SELECT
    installed_rank,
    version,
    description,
    success
FROM flyway_schema_history
ORDER BY installed_rank;

--Kiểm tra farming log 
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'farming_logs'
ORDER BY ordinal_position;

--Xác minh dữ liệu khi thêm farming-logs
SELECT
    id,
    client_log_id,
    organization_id,
    farmer_user_id,
    plot_id,
    planting_id,
    production_cycle_id,
    activity_type,
    activity_date,
    notes,
    client_created_at,
    server_received_at
FROM farming_logs
ORDER BY id DESC
LIMIT 20;

select * from plots


--Flutter 
SELECT
    p.organization_id,
    p.plot_id,
    p.id AS planting_id,
    p.planting_code,
    p.status AS planting_status,
    c.id AS production_cycle_id,
    c.cycle_code,
    c.status AS cycle_status
FROM plantings p
JOIN production_cycles c
  ON c.organization_id = p.organization_id
 AND c.planting_id = p.id
WHERE p.status = 'ACTIVE'
ORDER BY p.plot_id, p.id;

--Kiểm tra cấu trúc
SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN (
      'plantings',
      'production_cycles',
      'plot_assignments',
      'organization_memberships'
  )
ORDER BY table_name, ordinal_position;
--
SELECT
    p.organization_id,
    p.plot_id,
    p.id AS planting_id,
    p.planting_code,
    p.status AS planting_status,
    c.id AS cycle_id,
    c.cycle_code,
    c.status AS cycle_status
FROM plantings p
LEFT JOIN production_cycles c
    ON c.organization_id = p.organization_id
   AND c.planting_id = p.id
ORDER BY p.plot_id, p.id, c.id;

--
SELECT
    u.id AS user_id,
    u.username,
    u.is_active AS user_active,
    m.id AS membership_id,
    m.organization_id,
    m.role,
    m.is_active AS membership_active,
    pa.id AS assignment_id,
    pa.plot_id,
    pa.assigned_at,
    pa.ended_at,
    p.plot_code,
    p.status AS plot_status,
    o.status AS organization_status
FROM users u
JOIN organization_memberships m
    ON m.user_id = u.id
LEFT JOIN plot_assignments pa
    ON pa.membership_id = m.id
   AND pa.organization_id = m.organization_id
LEFT JOIN plots p
    ON p.id = pa.plot_id
   AND p.organization_id = pa.organization_id
JOIN organizations o
    ON o.id = m.organization_id
WHERE u.username = 'farmer01'
ORDER BY pa.assigned_at DESC NULLS LAST;