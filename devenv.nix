{ pkgs, ... }:
let
  python = pkgs.python311.withPackages (ps: with ps; [
    pandas
    numpy
    pyyaml
  ]);
in
{
  packages = [
    pkgs.just
    pkgs.git
    pkgs.zip
    pkgs.jq
    pkgs.texliveFull
    pkgs.latexmk
    pkgs.inkscape
    python
  ];

  languages.rust.enable = true;
  languages.rust.version = "stable";

  languages.python.enable = true;
  languages.python.package = pkgs.python311;

  enterShell = ''
    echo "caseforge dev environment loaded"
    echo "Python: $(python --version)"
    echo "Rust: $(rustc --version)"
    echo "Try: just build"
  '';
}
