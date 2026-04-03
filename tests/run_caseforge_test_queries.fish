#!/usr/bin/env fish

if test (count $argv) -lt 2
    echo "Usage: $argv[0] /path/to/case.duckdb /path/to/sql-dir [output-file]" >&2
    exit 1
end

set -l db_file $argv[1]
set -l test_dir $argv[2]

if test (count $argv) -ge 3
    set -l output_file $argv[3]
else
    set -l timestamp (date "+%Y%m%d_%H%M%S")
    set -l output_file "./duckdb_test_results_$timestamp.txt"
end

set -l duckdb_bin duckdb
if set -q DUCKDB_BIN
    set duckdb_bin $DUCKDB_BIN
end

if not test -f "$db_file"
    echo "Error: Database file not found: $db_file" >&2
    exit 1
end

if not test -d "$test_dir"
    echo "Error: SQL directory not found: $test_dir" >&2
    exit 1
end

if not type -q $duckdb_bin
    echo "Error: duckdb binary not found in PATH (or DUCKDB_BIN)." >&2
    exit 1
end

set -l sql_files (find "$test_dir" -maxdepth 1 -type f -name "*.sql" | sort)

if test (count $sql_files) -eq 0
    echo "Error: no .sql files found in $test_dir" >&2
    exit 1
end

function hr
    printf '%s\n' "======================================================================"
end

begin
    hr
    echo "DUCKDB TEST RUN"
    hr
    echo "Started:  "(date)
    echo "Database: "(realpath "$db_file")
    echo "Queries:  "(realpath "$test_dir")
    echo "Runner:   fish"
    echo "DuckDB:   $duckdb_bin"
    echo ""
end > "$output_file"

for sql_file in $sql_files
    set -l filename (basename "$sql_file")

    if test "$filename" = "build_from_normalized.sql"
        continue
    end

    set -l tmp_output (mktemp)

    begin
        echo ""
        hr
        echo "RUNNING: $filename"
        echo "FILE:    $sql_file"
        hr
    end | tee -a "$output_file"

    $duckdb_bin "$db_file" < "$sql_file" > "$tmp_output" 2>&1
    set -l cmd_status $status

    cat "$tmp_output" | tee -a "$output_file"

    begin
        echo ""
        echo "EXIT CODE: $cmd_status"
        echo ""
    end | tee -a "$output_file"

    rm -f "$tmp_output"
end

begin
    hr
    echo "Finished: "(date)
    echo "Output:   "(realpath "$output_file")
    hr
end | tee -a "$output_file"
