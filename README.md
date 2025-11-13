# DAS SQL Queries

This repository collects the ad-hoc and repeatable reporting queries that power the DAS data team for Marathon Myanmar's Shwe Zay and M Kitchen units. Every script in the repo is read-only and intended for analytics, validation, and troubleshooting workflows—there are **no** DDL/DML statements.

## Repository layout

| File | Description |
| --- | --- |
| `mkitchen.sql` | Scratchpad of exploratory sales, customer, and product lookups, including delivery pipeline joins and example window functions for identifying sales-order creators. |
| `mkitchen-weeklyKPI.sql` | Parameterised (Go template) report used to monitor inventory age, weekly sales-order coverage, customer-channel metrics, and SKU activity. |
| `mkitchen-sodump.sql` | Opinionated export of sales orders and line items for spreadsheet-friendly dumps. |
| `mkitchen-readonlydb.sql` | Quick start queries for validating read-only replicas and confirming user access. |
| `mkitchen-query (test).sql` | Playground for testing alternative filters or MySQL syntax before promoting into the canonical scripts. |
| `schema.graphqls` | Reference GraphQL schema mirroring the DAS domain model (products, customers, accounting). Useful when mapping SQL fields to API responses. |

> Tip: If you add a new SQL file, keep the filename descriptive (e.g. `warehouse-inventory-aging.sql`) so report consumers can quickly discover the correct script.

## Running a script

1. Authenticate against the DAS MySQL instance (replace `DB_HOST` etc. with your credentials):
   ```bash
   mysql -h "$DB_HOST" -u "$DB_USER" -p --default-character-set=utf8mb4
   ```
2. Copy the relevant section from any `.sql` file and paste it into the MySQL shell. Statements are intentionally separated by blank lines to make it easy to execute one block at a time.
3. Export the result set when needed:
   ```bash
   mysql --batch --raw < mkitchen-sodump.sql > sales_orders.tsv
   ```

All queries assume the `das-db` schema. The initial statements in each file (`SHOW DATABASES;`, `USE \`das-db\`;`, etc.) help you verify the connection context before running heavier joins.

## Template parameters

Some KPI queries (for example `mkitchen-weeklyKPI.sql`) include Go-template placeholders such as `{{ if .BranchId }}` to let you inject optional filters from dashboards or automation. When executing manually:

- Remove the `{{ ... }}` blocks entirely, or
- Replace the expressions with concrete values (e.g., `AND bills.branch_id = '34'`).

## Working safely with production data

- Always scope queries by `business_id` (e.g., `84093770-29ad-4e8e-9da1-babe583c0d69`) unless you explicitly need a cross-business view.
- Use date filters (`BETWEEN`, `>=`, `<`) to limit scan ranges and keep dashboards responsive.
- Prefer `LEFT JOIN` for optional relationships (delivery methods, billing addresses, product categories) to avoid dropping rows unexpectedly.
- Never add `INSERT`, `UPDATE`, or `DELETE` statements to this repository.

## Contributing

1. Create or modify a `.sql` file with your new read-only query.
2. Document any required parameters or assumptions in SQL comments at the top of the block.
3. Run the query in staging/readonly before opening a PR.
4. Update this README if you introduce a brand-new report area so others can find it easily.

For schema-driven work, consult `schema.graphqls` to ensure SQL columns align with GraphQL field names exposed to clients.
