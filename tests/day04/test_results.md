# Day 4 Test Results

## Final Result

```text
Passed : 13
Failed : 0
Total  : 13

ALL DAY 4 TESTS PASSED
```

## Detailed Results

| # | Test | Expected | Actual | Result |
|---:|---|---|---|---|
| 1 | JDBC connection | Successful | Successful | PASS |
| 2 | Source total count | 100,005 | 100,005 | PASS |
| 3 | Active-only extraction | 70,005 | 70,005 | PASS |
| 4 | Zero matches | 0 | 0 | PASS |
| 5 | Duplicate business keys | 5 | 5 | PASS |
| 6 | Source NULL status | 10,000 | 10,000 | PASS |
| 7 | NULL excluded from active extract | 0 | 0 | PASS |
| 8 | Duplicate keys preserved | 5 | 5 | PASS |
| 9 | Source-to-Bronze reconciliation | 70,005 | 70,005 | PASS |
| 10 | Bronze active-only validation | 0 invalid | 0 invalid | PASS |
| 11 | Wrong credentials | Rejected | Rejected | PASS |
| 12 | Database unavailable | Connection failure | Connection failure | PASS |
| 13 | Bronze schema validation | Expected schema | Expected schema | PASS |

## Source Counts

```text
Total source rows : 100,005
Active            : 70,005
Inactive          : 20,000
NULL status       : 10,000
Duplicate keys    : 5
```

## Bronze

```text
Table:
de_prac.day04.customers_bronze

Rows:
70,005
```

## Databricks Test Results Table

```text
de_prac.day04.day04_test_results
```
