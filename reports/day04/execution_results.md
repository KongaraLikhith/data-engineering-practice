# Day 4 Execution Results

## Source

```text
Database: de_practice
Table: customer_source
Total rows: 100,005
```

## Extraction

```text
Requested status: active
Extracted rows: 70,005
```

## Validation

```text
Schema valid: True
Status valid: True
Invalid status rows: 0
NULL statuses in active output: 0
Duplicate business keys: 5
```

## Bronze

```text
Table:
de_prac.day04.customers_bronze

Rows:
70,005
```

## Reconciliation

```text
Extract count : 70,005
Bronze count  : 70,005
Result        : PASS
```

## Final Tests

```text
13 PASS
0 FAIL
```
