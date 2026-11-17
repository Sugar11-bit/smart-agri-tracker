
-- BUỔI 1
--Tạo role 
CREATE ROLE smat_app
WITH LOGIN PASSWORD 'Duong@13042005';

--Tạo database
CREATE DATABASE smat_dev
OWNER smat_app
ENCODING 'UTF8';

--Đổi mật khẩu
ALTER ROLE smat_app
WITH LOGIN PASSWORD 'Duong@13042005';

--Xem database và user
SELECT current_user, current_database();

-- Kiểm tra quyền phục vụ Flyway
SELECT datname, pg_get_userbyid(datdba) AS owner
FROM pg_database
WHERE datname = 'smat_dev';


--smat_app quản lý schema của ứng dụng, một cách cấu hình là dùng tài khoản quản trị
GRANT CONNECT ON DATABASE smat_dev TO smat_app;
GRANT USAGE, CREATE ON SCHEMA public TO smat_app;


SELECT
  current_user,
  current_database(),
  has_schema_privilege(
    current_user, 'public', 'CREATE'
  ) AS can_create;



  --kết nối database smat_dev.kiểm tra flyway  
  --Tình huống	Hành động
--Chưa có bảng nào	Có thể bắt đầu migration V1
--Chỉ có flyway_schema_history	          Kiểm tra lịch sử bên trong
--Đã có organizations, farms, plots...	  Kiểm tra schema hiện tại, không tạo trùng
--Có các bảng không rõ nguồn gốc	  	  Xác minh trước khi chạy Flyway
SELECT
    current_user,
    current_database();

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

--
SELECT
    installed_rank,
    version,
    description,
    success
FROM public.flyway_schema_history
ORDER BY installed_rank;


--Kiểm tra migration
SELECT
    version,
    description,
    success
FROM public.flyway_schema_history
ORDER BY installed_rank;

--Xác minh 9table tạo
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;


--BUỔI 2
--Test DB-01 — Hai tổ chức được sử dụng cùng mã Farm
BEGIN;

INSERT INTO organizations (org_code, org_name)
VALUES
('TEST-ORG-A', 'Test Organization A'),
('TEST-ORG-B', 'Test Organization B');

INSERT INTO farms (
    organization_id, farm_code, farm_name
)
SELECT id, 'FARM-001', 'Test Farm'
FROM organizations
WHERE org_code IN ('TEST-ORG-A', 'TEST-ORG-B');

SELECT
    o.org_code,
    f.farm_code,
    f.farm_name
FROM farms f
JOIN organizations o ON o.id = f.organization_id
WHERE o.org_code IN ('TEST-ORG-A', 'TEST-ORG-B')
ORDER BY o.org_code;

ROLLBACK;


--Test DB-02 — Chặn mã Farm trùng trong cùng tổ chức
BEGIN;

INSERT INTO organizations (org_code, org_name)
VALUES ('TEST-ORG-C', 'Test Organization C');

INSERT INTO farms (
    organization_id, farm_code, farm_name
)
SELECT id, 'FARM-DUP', 'First Farm'
FROM organizations
WHERE org_code = 'TEST-ORG-C';

-- Cố ý trùng farm_code trong cùng organization
INSERT INTO farms (
    organization_id, farm_code, farm_name
)
SELECT id, 'FARM-DUP', 'Duplicate Farm'
FROM organizations
WHERE org_code = 'TEST-ORG-C';

-- Sau khi thấy lỗi 23505, chạy ROLLBACK riêng.
--> chạy roolback
ROLLBACK;


--Test DB-03 — Chặn Plot tham chiếu Farm khác tổ chức
BEGIN;

INSERT INTO organizations (org_code, org_name)
VALUES
('TEST-TENANT-A', 'Tenant A'),
('TEST-TENANT-B', 'Tenant B');

INSERT INTO farms (
    organization_id, farm_code, farm_name
)
SELECT id, 'FARM-A', 'Farm of Tenant A'
FROM organizations
WHERE org_code = 'TEST-TENANT-A';

-- Cố tình gán Plot của B vào Farm của A
INSERT INTO plots (
    organization_id,
    farm_id,
    plot_code,
    plot_name,
    area_hectares
)
SELECT
    b.id,
    f.id,
    'CF-001',
    'Invalid cross-tenant plot',
    1.0000
FROM organizations b
CROSS JOIN farms f
JOIN organizations a
    ON a.id = f.organization_id
WHERE b.org_code = 'TEST-TENANT-B'
  AND a.org_code = 'TEST-TENANT-A'
  AND f.farm_code = 'FARM-A';

ROLLBACK;
-- Sau khi thấy lỗi 23503, chạy ROLLBACK riêng.



--Test DB-04 — Chặn diện tích khu đất không hợp lệ
BEGIN;

INSERT INTO organizations (org_code, org_name)
VALUES ('TEST-AREA', 'Area Validation Test');

INSERT INTO farms (
    organization_id, farm_code, farm_name
)
SELECT id, 'FARM-AREA', 'Area Test Farm'
FROM organizations
WHERE org_code = 'TEST-AREA';

INSERT INTO plots (
    organization_id,
    farm_id,
    plot_code,
    plot_name,
    area_hectares
)
SELECT
    organization_id,
    id,
    'PLOT-ZERO',
    'Invalid Plot',
    0
FROM farms
WHERE farm_code = 'FARM-AREA';

-- Sau khi thấy lỗi 23514, chạy ROLLBACK riêng.


--Kiểm tra version
select version();


--Thử API
INSERT INTO organizations (org_code, org_name)
VALUES ('ORG-DEMO', 'SMAT Demo Cooperative')
ON CONFLICT (org_code) DO NOTHING;

INSERT INTO farms (
    organization_id, farm_code, farm_name
)
SELECT id, 'FARM-001', 'Demo Coffee Farm'
FROM organizations
WHERE org_code = 'ORG-DEMO'
ON CONFLICT (organization_id, farm_code)
DO NOTHING;

SELECT
    o.id AS organization_id,
    o.org_code,
    f.farm_code,
    f.farm_name
FROM organizations o
JOIN farms f ON f.organization_id = o.id
WHERE o.org_code = 'ORG-DEMO';
--Cách 2
SELECT
    o.id AS organization_id,
    o.org_code,
    f.id AS farm_id,
    f.farm_code,
    f.farm_name
FROM organizations o
JOIN farms f ON f.organization_id = o.id
WHERE o.org_code = 'ORG-DEMO';

--BU

SELECT
    o.id AS organization_id,
    o.org_code,
    f.id AS farm_id,
    f.farm_code
FROM organizations o
JOIN farms f ON f.organization_id = o.id
ORDER BY o.id, f.id;

--Kiểm tra GET POST trong postman với table plots
select * from plots

SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('plantings', 'production_cycles')
ORDER BY table_name, ordinal_position;

select * from plantings