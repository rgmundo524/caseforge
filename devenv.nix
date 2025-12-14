{ pkgs, ... }:
{
  packages = [
    pkgs.just
    pkgs.git
    pkgs.zip
    pkgs.jq
    pkgs.texliveFull
    pkgs.latexmk
    pkgs.inkscape
  ];

  languages.rust.enable = true;
  languages.rust.version = "stable";

  languages.python.enable = true;
  languages.python.package = pkgs.python311;
  languages.python.packages = ps: with ps; [
    pandas
    numpy
    pyyaml
  ];
}
