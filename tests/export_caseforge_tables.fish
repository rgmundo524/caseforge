#!/usr/bin/env fish

function usage
    set -l prog (status filename)
    echo "Usage: $prog [db_file] [output_dir] [mode]"
    echo ""
    echo "Exports one CSV per user table/view from a CaseForge DuckDB for manual review."
    echo ""
    echo "Arguments:"
    echo "  db_file     Path to case.duckdb (default: ./case.duckdb)"
    echo "  output_dir  Directory to write exports into"
    echo "              (default: ./csv_review_exports_YYYYMMDD_HHMMSS)"
    echo "  mode        all | tables | views (default: all)"
    echo ""
    echo "Environment:"
    echo "  DUCKDB_BIN  Override the DuckDB CLI binary (default: duckdb)"
end

function sql_escape_string --argument value
    string replace -a "'" "''" -- "$value"
end

function sql_quote_ident --argument value
    set -l escaped (string replace -a '"' '""' -- "$value")
    printf '"%s"' "$escaped"
end

function safe_file_token --argument value
    string lower -- (string replace -ra '[^A-Za-z0-9._-]' '_' -- "$value")
end

function csv_escape_field --argument value
    set -l escaped (string replace -a '"' '""' -- "$value")
    printf '"%s"' "$escaped"
end

function write_manifest_row --argument manifest schema name kind row_count data_csv columns_csv
    set -l c1 (csv_escape_field "$schema")
    set -l c2 (csv_escape_field "$name")
    set -l c3 (csv_escape_field "$kind")
    set -l c4 (csv_escape_field "$row_count")
    set -l c5 (csv_escape_field "$data_csv")
    set -l c6 (csv_escape_field "$columns_csv")
    printf '%s,%s,%s,%s,%s,%s\n' "$c1" "$c2" "$c3" "$c4" "$c5" "$c6" >> "$manifest"
end

if test (count $argv) -gt 0
    switch $argv[1]
        case -h --help
            usage
            exit 0
    end
end

set -l db_file case.duckdb
set -l output_dir "./csv_review_exports_"(date "+%Y%m%d_%H%M%S")
set -l mode all

if test (count $argv) -ge 1
    set db_file $argv[1]
end
if test (count $argv) -ge 2
    set output_dir $argv[2]
end
if test (count $argv) -ge 3
    set mode $argv[3]
end

if not contains -- "$mode" all tables views
    echo "Error: mode must be one of: all, tables, views" >&2
    exit 1
end

set -l duckdb_bin duckdb
if set -q DUCKDB_BIN
    set duckdb_bin $DUCKDB_BIN
end

if not test -f "$db_file"
    echo "Error: database file not found: $db_file" >&2
    exit 1
end

if not type -q -- "$duckdb_bin"
    echo "Error: duckdb CLI not found: $duckdb_bin" >&2
    exit 1
end

mkdir -p "$output_dir" "$output_dir/tables" "$output_dir/views" "$output_dir/meta"

set -l objects_txt "$output_dir/meta/objects.txt"
set -l manifest_csv "$output_dir/meta/export_manifest.csv"
set -l summary_txt "$output_dir/meta/export_summary.txt"

printf 'schema,object_name,object_type,row_count,data_csv,columns_csv\n' > "$manifest_csv"

set -l objects_txt_sql (sql_escape_string "$objects_txt")
set -l object_query "COPY (
  SELECT table_schema, table_name, table_type
  FROM information_schema.tables
  WHERE table_schema NOT IN ('information_schema', 'pg_catalog')
    AND table_type IN ('BASE TABLE', 'VIEW')
    AND table_name NOT LIKE 'duckdb_%'
  ORDER BY CASE table_type WHEN 'BASE TABLE' THEN 0 ELSE 1 END, table_schema, table_name
) TO '$objects_txt_sql' (FORMAT csv, DELIMITER '|', HEADER false);"

if not $duckdb_bin -readonly -init /dev/null "$db_file" -c "$object_query"
    echo "Error: failed to enumerate database objects" >&2
    exit 1
end

if not test -s "$objects_txt"
    echo "Error: no exportable tables/views found in $db_file" >&2
    exit 1
end

set -l exported 0
set -l failed 0

printf 'CASEFORGE CSV EXPORT\n' > "$summary_txt"
printf 'Started: %s\n' (date) >> "$summary_txt"
printf 'Database: %s\n' "$db_file" >> "$summary_txt"
printf 'Output: %s\n' "$output_dir" >> "$summary_txt"
printf 'Mode: %s\n\n' "$mode" >> "$summary_txt"

while read -l line
    test -n "$line"; or continue

    set -l parts (string split '|' -- "$line")
    if test (count $parts) -lt 3
        continue
    end

    set -l schema $parts[1]
    set -l name $parts[2]
    set -l table_type $parts[3]

    switch "$mode"
        case tables
            if test "$table_type" != 'BASE TABLE'
                continue
            end
        case views
            if test "$table_type" != 'VIEW'
                continue
            end
    end

    if test "$table_type" = 'BASE TABLE'
        set -l kind tables
    else
        set -l kind views
    end

    set -l file_token (safe_file_token "$schema""__""$name")
    set -l data_csv "$output_dir/$kind/$file_token.csv"
    set -l columns_csv "$output_dir/meta/$file_token"__columns.csv

    set -l qschema (sql_quote_ident "$schema")
    set -l qname (sql_quote_ident "$name")
    set -l schema_literal (sql_escape_string "$schema")
    set -l name_literal (sql_escape_string "$name")
    set -l data_csv_sql (sql_escape_string "$data_csv")
    set -l columns_csv_sql (sql_escape_string "$columns_csv")

    set -l export_sql "COPY (SELECT * FROM $qschema.$qname) TO '$data_csv_sql' (FORMAT csv, HEADER);"
    set -l columns_sql "COPY (
      SELECT
        table_schema,
        table_name,
        column_name,
        ordinal_position,
        data_type,
        is_nullable,
        column_default
      FROM information_schema.columns
      WHERE table_schema = '$schema_literal'
        AND table_name = '$name_literal'
      ORDER BY ordinal_position
    ) TO '$columns_csv_sql' (FORMAT csv, HEADER);"

    echo "Exporting $schema.$name -> $data_csv"

    if not $duckdb_bin -readonly -init /dev/null "$db_file" -c "$export_sql"
        echo "  FAILED data export: $schema.$name" >&2
        set failed (math "$failed + 1")
        continue
    end

    if not $duckdb_bin -readonly -init /dev/null "$db_file" -c "$columns_sql"
        echo "  FAILED column export: $schema.$name" >&2
        set failed (math "$failed + 1")
        continue
    end

    set -l row_count ($duckdb_bin -readonly -init /dev/null -list -noheader "$db_file" -c "SELECT count(*) FROM $qschema.$qname;")
    if test -z "$row_count"
        set row_count unknown
    end

    write_manifest_row "$manifest_csv" "$schema" "$name" "$table_type" "$row_count" "$data_csv" "$columns_csv"
    printf '%s\t%s\t%s\t%s\n' "$schema" "$name" "$table_type" "$row_count" >> "$summary_txt"

    set exported (math "$exported + 1")
end < "$objects_txt"

printf '\nFinished: %s\n' (date) >> "$summary_txt"
printf 'Exported: %s\n' "$exported" >> "$summary_txt"
printf 'Failed: %s\n' "$failed" >> "$summary_txt"
printf 'Manifest: %s\n' "$manifest_csv" >> "$summary_txt"

echo ""
echo "Done."
echo "  Exported objects: $exported"
echo "  Failed objects:   $failed"
echo "  Output dir:       $output_dir"
echo "  Manifest:         $manifest_csv"
echo "  Summary:          $summary_txt"

if test "$failed" -gt 0
    exit 1
end
