# Day 4 Trainer Summary

## Project

Relational database ingestion using:

```text
Azure PostgreSQL
      |
      | JDBC
      v
Databricks
      |
      v
Spark
      |
      v
Delta
      |
      v
Bronze
```

## Source

```text
Database:
de_practice

Table:
customer_source

Total:
100,005

Active:
70,005

Inactive:
20,000

NULL:
10,000

Duplicate business keys:
5
```

## Output

```text
Requested status:
active

Extracted:
70,005

Bronze table:
de_prac.day04.customers_bronze

Bronze rows:
70,005
```

## Validation

The project tested:

- JDBC connectivity
- source count
- active-only extraction
- zero matches
- duplicate keys
- NULL statuses
- wrong credentials
- database unavailable
- schema
- source-to-Bronze reconciliation

Final result:

```text
13 PASS
0 FAIL
```

## Problems Solved

1. Cloud Shell firewall timeout.
2. Bash commands entered inside PostgreSQL.
3. Databricks JDBC firewall timeout.
4. Serverless `.cache()` failure.
5. Delta materialization replacement.

## Short Explanation

Day 4 demonstrates database ingestion using Azure PostgreSQL, JDBC, Databricks, PySpark, and Delta Lake.

The source contains 100,005 simulated customer records.

The active extraction produced 70,005 rows.

The final Bronze table also contains 70,005 rows.

All 13 tests passed.
