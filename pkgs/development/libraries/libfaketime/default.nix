{ lib, stdenv, fetchFromGitHub, fetchpatch, perl, coreutils }:

stdenv.mkDerivation rec {
  pname = "libfaketime";
  version = "0.9.10";

  src = fetchFromGitHub {
    owner = "wolfcw";
    repo = "libfaketime";
    rev = "v${version}";
    sha256 = "sha256-DYRuQmIhQu0CNEboBAtHOr/NnWxoXecuPMSR/UQ/VIQ=";
  };

  patches = [
    ./nix-store-date.patch
    (fetchpatch {
      name = "0001-libfaketime.c-wrap-timespec_get-in-TIME_UTC-macro.patch";
      url = "https://github.com/wolfcw/libfaketime/commit/e0e6b79568d36a8fd2b3c41f7214769221182128.patch";
      sha256 = "sha256-KwwP76v0DXNW73p/YBvwUOPdKMAcVdbQSKexD/uFOYo=";
    })
  ] ++ (lib.optionals (stdenv.cc.isClang && !stdenv.isFreeBSD) [
    # https://github.com/wolfcw/libfaketime/issues/277
    ./0001-Remove-unsupported-clang-flags.patch
  ]) ++ lib.optionals stdenv.isFreeBSD [
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/8f6f86bd48a3b52427e33ed5b05cfec1c7eea4e3/devel/libfaketime/files/patch-src_libfaketime.c";
      hash = "sha256-HeMXjf8SMQow7QebTqaxOr8Cp7u7cOD09bw6HKLGIlc=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
    #(fetchpatch {
    #  url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/8f6f86bd48a3b52427e33ed5b05cfec1c7eea4e3/devel/libfaketime/files/patch-src_Makefile";
    #  hash = "sha256-erMgUrMgG7lpGOEAH+tfFOlT7+JGUEZIrUnCTSd+Abs=";
    #  extraPrefix = "";
    #  postFetch = ''
    #    sed -E -i -e 's/\.orig//g' $out
    #  '';
    #})
    ./freebsd-makefile.patch
    ./freebsd.patch
  ];

  postPatch = ''
    patchShebangs test src
    for a in test/functests/test_exclude_mono.sh src/faketime.c ; do
      substituteInPlace $a \
        --replace /bin/bash ${stdenv.shell}
    done
    substituteInPlace src/faketime.c --replace @DATE_CMD@ ${coreutils}/bin/date
  '';

  PREFIX = placeholder "out";
  LIBDIRNAME = "/lib";

  env.FEATS = lib.optionalString stdenv.isFreeBSD "-DFAKE_SLEEP -DFAKE_TIMERS -DFAKE_INTERNAL_CALLS";
  env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.cc.isClang ("-Wno-error=cast-function-type" + lib.optionalString (!stdenv.isFreeBSD) " -Wno-error=format-truncation");

  nativeCheckInputs = [ perl ];

  meta = with lib; {
    description = "Report faked system time to programs without having to change the system-wide time";
    homepage = "https://github.com/wolfcw/libfaketime/";
    license = licenses.gpl2;
    platforms = platforms.all;
    broken = stdenv.isFreeBSD;
    maintainers = [ maintainers.bjornfor ];
    mainProgram = "faketime";
  };
}
