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
