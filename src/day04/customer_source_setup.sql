-- ============================================================
-- DAY 4 OF 15
-- CUSTOMER SOURCE SETUP
-- Azure Database for PostgreSQL Flexible Server
-- ============================================================

DROP TABLE IF EXISTS customer_source;

CREATE TABLE customer_source (
    customer_id VARCHAR(20) NOT NULL,
    first_name  VARCHAR(100) NOT NULL,
    last_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(200) NOT NULL,
    city        VARCHAR(100) NOT NULL,
    status      VARCHAR(20)
);

-- Generate 100,000 simulated customers.
INSERT INTO customer_source (
    customer_id,
    first_name,
    last_name,
    email,
    city,
    status
)
SELECT
    'CUST' || LPAD(gs::TEXT, 7, '0'),
    'First' || gs,
    'Last' || gs,
    'customer' || gs || '@example.com',

    CASE
        WHEN gs % 5 = 0 THEN 'Columbus'
        WHEN gs % 5 = 1 THEN 'Austin'
        WHEN gs % 5 = 2 THEN 'Chicago'
        WHEN gs % 5 = 3 THEN 'Phoenix'
        ELSE 'New York'
    END,

    CASE
        WHEN gs % 10 = 0 THEN NULL
        WHEN gs % 10 IN (8, 9) THEN 'inactive'
        ELSE 'active'
    END

FROM generate_series(1, 100000) AS gs;

-- Add five intentional duplicate customer business keys.
INSERT INTO customer_source (
    customer_id,
    first_name,
    last_name,
    email,
    city,
    status
)
VALUES
('CUST0000001','First1','Last1','duplicate1@example.com','Austin','active'),
('CUST0000002','First2','Last2','duplicate2@example.com','Chicago','active'),
('CUST0000003','First3','Last3','duplicate3@example.com','Phoenix','active'),
('CUST0000004','First4','Last4','duplicate4@example.com','New York','active'),
('CUST0000005','First5','Last5','duplicate5@example.com','Columbus','active');

-- Index for status-based extraction.
CREATE INDEX idx_customer_source_status
ON customer_source(status);

ANALYZE customer_source;

-- Total expected: 100005
SELECT COUNT(*) AS total_source_rows
FROM customer_source;

-- Expected:
-- active   70005
-- inactive 20000
-- NULL     10000
SELECT
    COALESCE(status, 'NULL') AS customer_status,
    COUNT(*) AS record_count
FROM customer_source
GROUP BY status
ORDER BY customer_status;

-- Expected: five customer IDs with count = 2.
SELECT
    customer_id,
    COUNT(*) AS occurrence_count
FROM customer_source
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY customer_id;

-- Expected: 10000
SELECT COUNT(*) AS null_status_count
FROM customer_source
WHERE status IS NULL;

-- Expected: 70005
SELECT COUNT(*) AS active_customer_count
FROM customer_source
WHERE status = 'active';

-- Expected: 20000
SELECT COUNT(*) AS inactive_customer_count
FROM customer_source
WHERE status = 'inactive';

-- Expected: 0
SELECT COUNT(*) AS suspended_customer_count
FROM customer_source
WHERE status = 'suspended';

-- Sample active records.
SELECT
    customer_id,
    first_name,
    last_name,
    email,
    city,
    status
FROM customer_source
WHERE status = 'active'
ORDER BY customer_id
LIMIT 20;
