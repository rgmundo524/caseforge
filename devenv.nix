{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = [ 
    pkgs.git 
    pkgs.duckdb
  ];

  # https://devenv.sh/languages/
  languages.python.enable = true;
  languages.python.venv.enable = true;
  languages.python.venv.requirements = ''
    duckdb
    pandas
    polars
    pyarrow
    httpx
    pydantic
  '';

  languages.javascript.enable = true;
  languages.javascript.bun.enable = true;
  languages.javascript.npm.enable = true;
  languages.javascript.corepack.enable = true;
 
  languages.javascript.npm.install.enable = false;

  # https://devenv.sh/processes/
  # processes.cargo-watch.exec = "cargo-watch";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  # scripts.hello.exec = ''
  #   echo hello from $GREET
  # '';

enterShell = ''
  echo "Node:   $(node --version)"
  echo "npm:    $(npm --version)"
  echo "Python: $(python --version)"
  echo "DuckDB: $(duckdb --version)"
  exec fish
'';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
enterTest = ''
  echo "Checking Node..."
  node --version | grep -E "^v(20|22)\."   # adjust if you pin specific major

  echo "Checking npm..."
  npm --version

  echo "Checking Python..."
  python --version | grep "3."

  echo "Checking DuckDB..."
  duckdb --version

  echo "Environment OK"
'';

  # https://devenv.sh/pre-commit-hooks/
  # pre-commit.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
