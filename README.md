# Data Engineering Practice

## Day 1 - Customer Bronze Ingestion

### Objective
Ingest customer CSV data into the Bronze/raw layer while preserving the original source values.

### Implementation
- Generated 100,000 fictional customer records.
- Stored source data as CSV in a Databricks Volume.
- Read the CSV using PySpark.
- Preserved all source columns as strings.
- Added ingestion metadata:
  - ingestion_timestamp
  - source_file_name
  - source_row_number
  - run_id
- Created Delta table:
  - de_prac.day01.customers_bronze
- Validated source count against Bronze count.
- Logged ingestion results.

### Edge Cases Tested
- Valid file
- Header-only file
- Empty file
- Missing file
- Duplicate rows
- Extra whitespace

### Data Locations

Source:
`/Volumes/de_prac/day01/data-files/incoming/customers`

Logs:
`/Volumes/de_prac/day01/data-files/logs/customer_ingestion_log`

Bronze Table:
`de_prac.day01.customers_bronze`

### Result
Source records: 100,000  
Bronze records: 100,000  
Count validation: PASS

<!-- DAY04_DATABASE_INGESTION -->

## Day 4 — PostgreSQL JDBC Database Ingestion

Day 4 implements relational database ingestion using **Azure PostgreSQL, JDBC, Databricks Serverless, PySpark, Delta Lake, and Unity Catalog**.

### Architecture

```text
Azure PostgreSQL
        ↓ JDBC
Databricks
        ↓
Spark
        ↓
Validation
        ↓
Bronze Delta Table
```

### Results

| Metric | Result |
|---|---:|
| Source rows | 100,005 |
| Active extracted | 70,005 |
| Bronze rows | 70,005 |
| NULL source rows | 10,000 |
| Duplicate business keys | 5 |
| Tests passed | 13 |
| Tests failed | 0 |

### Day 4 Files

- [Databricks Notebook](notebooks/Day04_Database_Ingestion.ipynb)
- [PostgreSQL Setup SQL](src/day04/customer_source_setup.sql)
- [Detailed Documentation](docs/day04/README.md)
- [Test Results](tests/day04/test_results.md)
- [Execution Results](reports/day04/execution_results.md)
- [Trainer Summary](reports/day04/trainer_summary.md)
