#!/usr/bin/env fish

if test (count $argv) -lt 2
    echo "Usage: "(status filename)" /path/to/case.duckdb /path/to/sql-dir [output-file]" >&2
    exit 1
end

set db_file $argv[1]
set test_dir $argv[2]

if test (count $argv) -ge 3
    set output_file $argv[3]
else
    set timestamp (date "+%Y%m%d_%H%M%S")
    set output_file "./duckdb_test_results_$timestamp.txt"
end

set duckdb_bin duckdb
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

set sql_files (find "$test_dir" -maxdepth 1 -type f -name "*.sql" | sort)
if test (count $sql_files) -eq 0
    echo "Error: no .sql files found in $test_dir" >&2
    exit 1
end

set output_dir (dirname -- "$output_file")
if test -n "$output_dir" -a "$output_dir" != "."
    mkdir -p "$output_dir"
end

touch "$output_file"

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
    echo "Output:   $output_file"
    echo ""
end | tee "$output_file" >/dev/null

set failed 0
for sql_file in $sql_files
    set filename (basename "$sql_file")

    set tmp_output (mktemp)

    begin
        echo ""
        hr
        echo "RUNNING: $filename"
        echo "FILE:    $sql_file"
        hr
    end | tee -a "$output_file"

    $duckdb_bin "$db_file" < "$sql_file" > "$tmp_output" 2>&1
    set cmd_status $status

    cat "$tmp_output" | tee -a "$output_file"

    begin
        echo ""
        echo "EXIT CODE: $cmd_status"
        echo ""
    end | tee -a "$output_file"

    if test $cmd_status -ne 0
        set failed 1
    end

    rm -f "$tmp_output"
end

begin
    hr
    echo "Finished: "(date)
    echo "Output:   "(realpath "$output_file")
    echo "Overall:  "(test $failed -eq 0; and echo "SUCCESS"; or echo "FAILURES PRESENT")
    hr
end | tee -a "$output_file"

exit $failed
