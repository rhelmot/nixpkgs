{
  lib,
  stdenv,
  perl,
  toPerlModule,
}:

{
  buildInputs ? [ ],
  nativeBuildInputs ? [ ],
  outputs ? [
    "out"
    "devdoc"
  ],
  src ? null,

  makeMakerFlags ? null,

  # enabling or disabling does nothing for perl packages so set it explicitly
  # to false to not change hashes when enableParallelBuildingByDefault is enabled
  enableParallelBuilding ? false,

  doCheck ? true,
  checkTarget ? "test",

  # Prevent CPAN downloads.
  PERL_AUTOINSTALL ? "--skipdeps",

  # From http://wiki.cpantesters.org/wiki/CPANAuthorNotes: "allows
  # authors to skip certain tests (or include certain tests) when
  # the results are not being monitored by a human being."
  AUTOMATED_TESTING ? true,

  # current directory (".") is removed from @INC in Perl 5.26 but many old libs rely on it
  # https://metacpan.org/pod/release/XSAWYERX/perl-5.26.0/pod/perldelta.pod#Removal-of-the-current-directory-%28%22.%22%29-from-@INC
  PERL_USE_UNSAFE_INC ? "1",

  env ? { },

  postPatch ? "patchShebangs .",
  disallowedReferences ? null,

  ...
}@attrs:

lib.throwIf (attrs ? name)
  "buildPerlPackage: `name` (\"${attrs.name}\") is deprecated, use `pname` and `version` instead"

  (
    let
      buildPerl = perl.__spliced.buildHost or perl;
      # haha what
      combinedFlags = lib.optionals (!stdenv.buildPlatform.canExecute stdenv.hostPlatform) [ "PERL_ARCHLIB=${perl}/${perl.archPrefix}" ]
        ++ lib.optionals (makeMakerFlags != null) makeMakerFlags;
      finalFlags = if makeMakerFlags == null && stdenv.buildPlatform.canExecute stdenv.hostPlatform then null else combinedFlags;

      defaultMeta = {
        homepage = "https://metacpan.org/dist/${attrs.pname}";
        inherit (perl.meta) platforms;
      };
      combinedDisallowed = lib.optionals (disallowedReferences != null) disallowedReferences
      ++ lib.optionals (!stdenv.buildPlatform.canExecute stdenv.hostPlatform) [ buildPerl ];
      combinedPostFixup = if !stdenv.buildPlatform.canExecute stdenv.hostPlatform then attrs.postFixup or "" + ''
        for output in $outputs; do
          (grep -Irl ${buildPerl} ''${!output} || true) | while read -r filename; do
            substituteInPlace "$filename" \
              --replace-quiet "${buildPerl}/bin/perl" "${perl}/bin/perl" \
              --replace-quiet "/usr/bin/perl" "${perl}/bin/perl" \
              --replace-quiet "-I${buildPerl}/${buildPerl.libPrefix}/${buildPerl.version}" ""
          done
        done
      '' else attrs.postFixup or null;

      package = stdenv.mkDerivation (
        attrs
        // {
          name = "perl${perl.version}-${attrs.pname}-${attrs.version}";

          builder = ./builder.sh;

          buildInputs = buildInputs ++ [ perl ];
          nativeBuildInputs =
            nativeBuildInputs
            ++ (if !(stdenv.buildPlatform.canExecute stdenv.hostPlatform) then [ perl ] else [ perl ]);

          makeMakerFlags = finalFlags;

          postFixup = combinedPostFixup;

          inherit
            outputs
            src
            doCheck
            checkTarget
            enableParallelBuilding
            postPatch
            ;
          env = {
            inherit PERL_AUTOINSTALL AUTOMATED_TESTING PERL_USE_UNSAFE_INC;
            fullperl = buildPerl;
          } // env;

          meta = defaultMeta // (attrs.meta or { });
        } // lib.optionalAttrs (combinedDisallowed != null) {
          disallowedReferences = combinedDisallowed;
        }
      );

    in
    toPerlModule package
  )
