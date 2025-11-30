# shell.nix
let
  pkgs = import <nixpkgs> {};
in
  pkgs.mkShell.override
  {
    stdenv = pkgs.clangStdenv;
  }
  {
    packages = with pkgs; [
      # --- C stuff ---
      clang
      clang-tools
      cmake
      cppcheck
      gnumake
      libgcc
      lcov

      # --- Docs ---
      doxygen
      typst

      # --- Debugging ---
      gdb
      lldb

      # --- Testing ---
      hyperfine
      valgrind

      # --- CLI tools ---
      bat
      visidata
      eza
    ];

    buildInputs = with pkgs; [
      gcc
      glibc
      zlib
    ];
    nativeBuildInputs = [pkgs.pkg-config];

    shellHook =
      # bash
      ''
        export TYPST_ROOT="$(pwd)"
      '';
  }
