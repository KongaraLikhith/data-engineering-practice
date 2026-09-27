from collections import Counter

from pyspark.sql.functions import col, trim, expr


def validate_schema(df, schema_config):

    expected_columns = list(schema_config["columns"].keys())
    actual_columns = df.columns
    strict_mode = schema_config.get("strict_mode", False)

    # Missing columns
    missing_columns = [
        c for c in expected_columns
        if c not in actual_columns
    ]

    # Extra columns
    extra_columns = [
        c for c in actual_columns
        if c not in expected_columns
    ]

    # Duplicate headers
    column_counts = Counter(actual_columns)

    duplicate_headers = [
        c for c, count in column_counts.items()
        if count > 1
    ]

    # Datatype validation
    actual_types = dict(df.dtypes)
    datatype_mismatches = []

    for column_name, rules in schema_config["columns"].items():

        if column_name not in actual_columns:
            continue

        expected_type = rules["type"]

        if expected_type == "string":

            if actual_types[column_name] != "string":
                datatype_mismatches.append({
                    "column": column_name,
                    "expected": "string",
                    "actual": actual_types[column_name]
                })

        elif expected_type == "utc_timestamp":

            if actual_types[column_name] != "string":
                datatype_mismatches.append({
                    "column": column_name,
                    "expected": "string containing UTC timestamp",
                    "actual": actual_types[column_name]
                })

    # Timestamp parse validation
    parse_failures = []

    if "updated_at" in actual_columns:

        invalid_timestamp_count = (
            df
            .withColumn(
                "_parsed_updated_at",
                expr("try_cast(updated_at AS TIMESTAMP)")
            )
            .filter(
                col("updated_at").isNotNull()
                & (trim(col("updated_at")) != "")
                & col("_parsed_updated_at").isNull()
            )
            .count()
        )

        if invalid_timestamp_count > 0:
            parse_failures.append({
                "column": "updated_at",
                "failure_count": invalid_timestamp_count
            })

    # Exact critical failure reasons
    critical_errors = []

    if missing_columns:
        critical_errors.append(
            f"Missing required columns: {missing_columns}"
        )

    if duplicate_headers:
        critical_errors.append(
            f"Duplicate headers found: {duplicate_headers}"
        )

    if datatype_mismatches:
        critical_errors.append(
            f"Datatype mismatches: {datatype_mismatches}"
        )

    if parse_failures:
        critical_errors.append(
            f"Timestamp parse failures: {parse_failures}"
        )

    if strict_mode and extra_columns:
        critical_errors.append(
            f"Unexpected columns found in strict mode: {extra_columns}"
        )

    critical_failure = bool(critical_errors)

    report = {
        "validation_status": "FAIL" if critical_failure else "PASS",
        "missing_columns": missing_columns,
        "extra_columns": extra_columns,
        "duplicate_headers": duplicate_headers,
        "datatype_mismatches": datatype_mismatches,
        "parse_failures": parse_failures,
        "critical_errors": critical_errors,
        "can_proceed_downstream": not critical_failure
    }

    return report