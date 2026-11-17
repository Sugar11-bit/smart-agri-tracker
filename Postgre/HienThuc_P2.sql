--Chuẩn bị dữ liệu planting và loại cây
--test
SELECT id, crop_code, crop_name
FROM crop_types
ORDER BY id;

SELECT id, organization_id, plot_code
FROM plots
ORDER BY id;
-- > Thêm dữ liệu
INSERT INTO crop_types (
    crop_code, crop_name, life_cycle
)
VALUES (
    'COFFEE', 'Ca phe', 'PERENNIAL'
)
ON CONFLICT (crop_code) DO NOTHING;


select * from production_cycles

--Kiểm tra productCycle
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'production_cycles'
ORDER BY ordinal_position;

--Lấy planting
SELECT
    id AS planting_id,
    organization_id,
    planting_code,
    status
FROM plantings
ORDER BY id DESC;

-- sau khi post productioncycle 
SELECT
    id,
    organization_id,
    planting_id,
    cycle_code,
    cycle_year,
    start_date,
    end_date,
    status
FROM production_cycles
ORDER BY id DESC;

--Kiểm tra tạo plot trên web adm
SELECT id, organization_id, farm_code, farm_name
FROM farms
ORDER BY id DESC
LIMIT 10;

SELECT id, organization_id, farm_id,
       plot_code, plot_name, area_hectares
FROM plots
ORDER BY id DESC
LIMIT 10;

--thêm dữ liệu croptype
INSERT INTO crop_types (
    crop_code,
    crop_name,
    life_cycle
)
VALUES
    ('COFFEE', 'Cà phê', 'PERENNIAL'),
    ('PERSIMMON', 'Hồng', 'PERENNIAL')
ON CONFLICT (crop_code) DO NOTHING;
select * from crop_types
