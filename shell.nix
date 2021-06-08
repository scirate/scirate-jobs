{ pkgs ? import <nixpkgs> {} }:
let
  # Useful for viewing the javascript created in 'public'
  localBuild = pkgs.writeShellScriptBin "localBuild" ''
    set -ex

    for x in src/SciRate/Views/*.elm; do
      name=$(basename $x .elm)
      elm make src/SciRate/Views/''${name}.elm  --output public/build/''${name}.js
    done;
    '';

  # Builds compressed versions of the javascript and copies it
  # to the 'SCIRATE_ROOT_DIR' environment variable.
  releaseBuild = pkgs.writeShellScriptBin "releaseBuild" ''
    set -ex

    if [ -z "''${SCIRATE_ROOT_DIR}" ]
    then
          echo "'SCIRATE_ROOT_DIR' env variable is required."
          exit 1
    fi

    for x in src/SciRate/Views/*.elm; do
      name=$(basename $x .elm)

      elm make src/SciRate/Views/''${name}.elm --output build/''${name}.js --optimize
      uglifyjs build/''${name}.js \
        --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters=true,keep_fargs=false,unsafe_comps=true,unsafe=true,passes=2' \
        --output build/''${name}.js

      uglifyjs build/''${name}.js --mangle --output build/''${name}.js

      cp build/''${name}.js \
        ''${SCIRATE_ROOT_DIR}/app/assets/javascripts/jobs-''${name}.js
    done;
    '';
in
pkgs.stdenv.mkDerivation {
  name = "scirate-jobs";
  buildInputs = [ 
    pkgs.nodePackages.uglify-js
    pkgs.elmPackages.elm 
    pkgs.hasura-cli
    localBuild
    releaseBuild
  ];
}
