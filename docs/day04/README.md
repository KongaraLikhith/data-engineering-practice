# Day 4 of 15 — PostgreSQL JDBC Ingestion with Databricks

## Objective

Day 4 implements relational database ingestion for customer master data.

The business requirement is to retrieve active customer records from a relational database so downstream processing can use current customer reference data.

The final implementation uses:

- Azure Database for PostgreSQL Flexible Server
- PostgreSQL
- JDBC
- Databricks Serverless
- PySpark
- Delta Lake
- Unity Catalog
- Databricks Volumes

---

## Final Architecture

```text
Azure Database for PostgreSQL
        |
        | JDBC
        v
Databricks Serverless
        |
        v
Spark DataFrame
        |
        v
Run-Specific Delta Extract
        |
        v
Validation
        |
        v
de_prac.day04.customers_bronze
        |
        +--> Logs
        +--> Reports
        +--> Test Results
```

---

# 1. Azure PostgreSQL Setup

Azure Database for PostgreSQL Flexible Server was created from the Azure Portal.

Configuration:

```text
Resource Group       rg-de-practice
Server               de-practice-postgres-day04
Region               Central US
Workload             Dev/Test
PostgreSQL           Version 18
Compute Tier         Burstable
Compute Size         Standard_B1ms
CPU                  1 vCore
Memory               2 GiB
Storage              32 GiB
Performance Tier     P4
Storage Autogrow     Disabled
High Availability    Disabled
Geo-Redundancy       Disabled
Backup Retention     7 days
Authentication       PostgreSQL authentication
Administrator        deadmin
Encryption           Service-managed key
```

B1ms was selected because this is a training workload and the simulated source contains approximately 100,000 records.

The Azure Portal displayed eligible free-service allowances for B1ms compute and 32 GB storage at creation time.

Actual charges always depend on the Azure subscription.

---

# 2. Azure Networking

The PostgreSQL server was configured with:

```text
Public Access         Enabled
PostgreSQL Port       5432
SSL                   Required
Private Endpoint      Not used
```

Public access was required because the Databricks Free Edition Serverless environment was outside the Azure PostgreSQL virtual network.

Firewall access was required for:

- the local development machine
- Azure Cloud Shell
- Databricks Serverless outbound traffic

Personal IP addresses are intentionally not stored in this repository.

---

# 3. Azure Cloud Shell

Azure Cloud Shell was used to administer PostgreSQL.

Cloud Shell was started without mounting persistent storage because persistent shell files were not needed.

PostgreSQL connection format:

```bash
psql "host=<POSTGRES_HOST> port=5432 dbname=postgres user=deadmin sslmode=require"
```

The database password was entered interactively.

The password is not stored in GitHub.

---

# 4. Problem Encountered — Cloud Shell Timeout

The first Cloud Shell connection failed with:

```text
connection to server failed:
Connection timed out
```

## Cause

The PostgreSQL firewall initially allowed the public IP address of the developer laptop.

Azure Cloud Shell runs from a different environment and therefore uses a different source IP.

## Troubleshooting

The Cloud Shell public IP was checked using:

```bash
curl -s https://ifconfig.me
```

That source IP was then added to the PostgreSQL firewall.

## Result

Cloud Shell successfully connected to PostgreSQL.

---

# 5. Problem Encountered — Bash vs PostgreSQL Shell

An Azure CLI command was accidentally entered while still inside PostgreSQL.

PostgreSQL prompt:

```text
de_practice=>
```

Cloud Shell Bash prompt:

```text
zoro [ ~ ]$
```

Difference:

```text
de_practice=>   SQL / PostgreSQL commands
zoro [ ~ ]$     Bash / Azure CLI commands
```

Azure CLI commands such as:

```bash
az postgres flexible-server firewall-rule create ...
```

must be executed from Bash.

PostgreSQL can be exited with:

```text
\q
```

---

# 6. PostgreSQL Database Setup

Database:

```text
de_practice
```

The active PostgreSQL session was changed to the database using:

```text
\c de_practice
```

Source table:

```text
customer_source
```

Schema:

```text
customer_id
first_name
last_name
email
city
status
```

The complete source setup SQL is stored at:

```text
src/day04/customer_source_setup.sql
```

---

# 7. Large Simulated Customer Dataset

PostgreSQL `generate_series()` was used to create 100,000 base customer rows.

Status-generation rules:

```text
Every 10th row        -> NULL
Rows ending in 8 or 9 -> inactive
Remaining rows        -> active
```

Base distribution:

```text
Active      70,000
Inactive    20,000
NULL        10,000
```

Five additional active rows were inserted using existing `customer_id` values.

Final source distribution:

| Metric | Count |
|---|---:|
| Total source rows | 100,005 |
| Active | 70,005 |
| Inactive | 20,000 |
| NULL status | 10,000 |
| Duplicate business keys | 5 |

Intentional duplicate IDs:

```text
CUST0000001
CUST0000002
CUST0000003
CUST0000004
CUST0000005
```

---

# 8. PostgreSQL Source Validation

Total source count:

```text
100005
```

Status distribution:

```text
active      70005
inactive    20000
NULL        10000
```

Duplicate results:

```text
CUST0000001    2
CUST0000002    2
CUST0000003    2
CUST0000004    2
CUST0000005    2
```

Zero-match test:

```text
status = suspended
count  = 0
```

---

# 9. Databricks Setup

Existing Unity Catalog catalog:

```text
de_prac
```

Day 4 schema:

```text
de_prac.day04
```

Unity Catalog Volume:

```text
/Volumes/de_prac/day04/data-files
```

Folders created:

```text
bronze/
logs/
reports/
quarantine/
```

Final Databricks structure:

```text
de_prac
└── day04
    ├── customers_bronze
    ├── day04_test_results
    └── data-files
        ├── bronze
        ├── logs
        ├── reports
        └── quarantine
```

---

# 10. Databricks Notebook

Notebook:

```text
notebooks/Day04_Database_Ingestion.ipynb
```

Notebook widgets were used for runtime configuration:

```text
requested_status
jdbc_host
jdbc_port
jdbc_database
jdbc_user
jdbc_password
```

Example:

```text
requested_status = active
jdbc_database    = de_practice
jdbc_port        = 5432
```

The database password is not committed to GitHub.

---

# 11. JDBC Configuration

JDBC URL format:

```text
jdbc:postgresql://<HOST>:5432/de_practice?sslmode=require
```

Properties:

```python
jdbc_properties = {
    "user": jdbc_user,
    "password": jdbc_password,
    "driver": "org.postgresql.Driver"
}
```

The notebook tests the connection before beginning extraction.

Successful output:

```text
JDBC CONNECTION SUCCESSFUL
```

---

# 12. Problem Encountered — Databricks JDBC Timeout

The first Databricks JDBC attempt failed.

Main error:

```text
java.net.SocketTimeoutException:
Connect timed out
```

## Cause

The PostgreSQL firewall did not yet allow all required Databricks Serverless outbound traffic.

Allowing only one observed Databricks IP was not sufficient for a reliable Serverless connection.

## Fix

The required Databricks Serverless outbound network ranges were added to the Azure PostgreSQL firewall.

After the firewall changes propagated:

```text
JDBC CONNECTION SUCCESSFUL
```

---

# 13. Active Customer Extraction

Requested status:

```text
active
```

Extracted rows:

```text
70,005
```

Extracted schema:

```text
customer_id
first_name
last_name
email
city
status
```

Schema validation:

```text
PASS
```

Status validation:

```text
Requested status : active
Invalid rows     : 0
Result           : PASS
```

---

# 14. Problem Encountered — cache() on Serverless

The first successful JDBC implementation attempted:

```python
customer_df.cache()
```

Databricks Serverless returned:

```text
PERSIST TABLE is not supported on serverless compute.
SQLSTATE: 0A000
```

## Cause

The Serverless compute environment did not support the persistence operation used by `.cache()`.

## Fix

The JDBC result was materialized to a run-specific Delta location instead.

Updated flow:

```text
PostgreSQL
    |
    v
JDBC DataFrame
    |
    v
Run-Specific Delta Extract
    |
    v
Read Delta
    |
    v
Validation
    |
    v
Bronze
```

Example run location:

```text
/Volumes/de_prac/day04/data-files/bronze/run_<timestamp>_status-active
```

This also avoided repeatedly querying PostgreSQL during validation.

---

# 15. Bronze Table

Final table:

```text
de_prac.day04.customers_bronze
```

Additional ingestion metadata:

```text
ingestion_timestamp
source_system
run_id
```

Source system:

```text
azure_postgresql
```

---

# 16. Successful Pipeline Result

The successful run produced:

```text
JDBC CONNECTION SUCCESSFUL

Extracted record count:
70,005

Schema validation:
PASS

Status validation:
PASS

Duplicate customer IDs:
5

NULL statuses in active output:
0
```

---

# 17. Source-to-Bronze Reconciliation

Extract count:

```text
70,005
```

Bronze count:

```text
70,005
```

Result:

```text
Source-to-Bronze reconciliation PASSED
```

---

# 18. Execution Logs

Execution logs are stored under:

```text
/Volumes/de_prac/day04/data-files/logs/
```

Logs record:

- Run ID
- Source database
- Source table
- Requested status
- Extract count
- Duplicate count
- NULL count
- Schema validation result
- Status validation result
- Bronze count
- Output path

Passwords are not written into logs.

---

# 19. Validation Reports

Reports are stored under:

```text
/Volumes/de_prac/day04/data-files/reports/
```

Final test results are also stored in:

```text
de_prac.day04.day04_test_results
```

---

# 20. Edge-Case Testing

The final test suite covered:

| # | Test | Result |
|---:|---|---|
| 1 | JDBC connection | PASS |
| 2 | Source total count | PASS |
| 3 | Active-only extraction | PASS |
| 4 | Zero-match extraction | PASS |
| 5 | Duplicate business keys | PASS |
| 6 | Source NULL status | PASS |
| 7 | NULL excluded from active extract | PASS |
| 8 | Duplicate keys preserved during ingestion | PASS |
| 9 | Source-to-Bronze reconciliation | PASS |
| 10 | Bronze active-only validation | PASS |
| 11 | Wrong credentials rejected | PASS |
| 12 | Database unavailable handled | PASS |
| 13 | Bronze schema validation | PASS |

Final result:

```text
Passed : 13
Failed : 0
Total  : 13
```

```text
ALL DAY 4 TESTS PASSED
```

---

# 21. Final Results

| Metric | Result |
|---|---:|
| Source rows | 100,005 |
| Active source rows | 70,005 |
| Inactive source rows | 20,000 |
| NULL source rows | 10,000 |
| Duplicate business keys | 5 |
| Active extracted | 70,005 |
| Bronze rows | 70,005 |
| Invalid output statuses | 0 |
| NULL rows in active output | 0 |
| Tests passed | 13 |
| Tests failed | 0 |

---

# 22. Acceptance Criteria Mapping

| Requirement | Implementation |
|---|---|
| Configurable DB connection | Databricks widgets |
| Relational database | Azure PostgreSQL |
| Active filter | Runtime status filtering |
| DataFrame creation | PySpark |
| Extract count | Logged |
| Error handling | Negative JDBC tests |
| Zero matches | `suspended` test |
| Duplicate records | 5 intentional duplicate IDs |
| NULL status | 10,000 source rows |
| Wrong credentials | Tested |
| Database unavailable | Tested |
| Bronze output | Delta table |
| Reconciliation | 70,005 vs 70,005 |

---

# 23. Parameterized Query Note

The original assignment explicitly requested a SQL pattern such as:

```sql
WHERE status = ?
```

The Spark JDBC DataFrame implementation used here does not use the same JDBC `PreparedStatement` bind-marker workflow.

The final validation implementation uses a runtime Spark filter:

```python
df.filter(
    F.col("status") == F.lit(status)
)
```

This avoids unrestricted SQL construction but is not a literal JDBC `PreparedStatement` using `?`.

If a trainer requires the exact prepared-statement implementation, a separate demonstration can be added.

---

# 24. Trainer Demo

Recommended live walkthrough:

```text
1. Show the Azure PostgreSQL server.

2. Show:
   de_practice.customer_source

3. Show total:
   100,005

4. Show status counts:
   active   = 70,005
   inactive = 20,000
   NULL     = 10,000

5. Open:
   Day04_Database_Ingestion.ipynb

6. Show notebook parameters.

7. Run:
   requested_status = active

8. Show:
   JDBC CONNECTION SUCCESSFUL

9. Show:
   Extracted rows = 70,005

10. Open:
    de_prac.day04.customers_bronze

11. Show:
    Bronze rows = 70,005

12. Open:
    de_prac.day04.day04_test_results

13. Show:
    13 PASS
    0 FAIL

14. Change:
    active -> inactive

15. Rerun as the small live change.
```

---

# 25. Simple Trainer Explanation

Day 4 demonstrates relational database ingestion using Azure PostgreSQL and Databricks.

The PostgreSQL source contains 100,005 simulated customer records including active, inactive, NULL-status, and duplicate-key scenarios.

Databricks connects to PostgreSQL through JDBC.

For the active run, 70,005 records were extracted.

Because `.cache()` was unsupported on Databricks Serverless, the JDBC result was materialized to Delta before repeated validation.

The final output was written to:

```text
de_prac.day04.customers_bronze
```

The extracted count and Bronze count both equal 70,005.

The final validation suite completed with:

```text
13 PASS
0 FAIL
```

---

# 26. Main Problems Encountered

1. Cloud Shell initially could not connect to PostgreSQL.
2. Cloud Shell required its own PostgreSQL firewall access.
3. Azure CLI commands were accidentally executed inside `psql`.
4. Databricks JDBC initially timed out.
5. Databricks Serverless required proper outbound firewall access.
6. `.cache()` was unsupported on Serverless.
7. Delta materialization was used instead.

---

# 27. Lessons Learned

Day 4 provided hands-on practice with:

- Azure Database for PostgreSQL
- PostgreSQL
- relational ingestion
- large simulated data
- Azure firewall rules
- Cloud Shell
- JDBC
- Databricks Serverless
- PySpark
- Spark DataFrames
- Delta Lake
- Unity Catalog
- Databricks Volumes
- Bronze ingestion
- runtime parameters
- duplicate detection
- NULL handling
- wrong-credential testing
- unavailable-database testing
- source-to-target reconciliation
- logging
- validation
- troubleshooting

The main lesson is that database ingestion involves more than SQL.

Networking, authentication, runtime configuration, compute limitations, validation, error handling, reconciliation, and observability are all important parts of a real Data Engineering pipeline.
