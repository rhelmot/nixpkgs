# FREEBSD-SPECIFIC OVERRIDES FOR THE HASKELL PACKAGE SET IN NIXPKGS

{ pkgs, haskellLib }:

let
  inherit (pkgs) lib darwin;
in

with haskellLib;

self: super: ({
  time-compat = dontCheck super.time-compat;
})
