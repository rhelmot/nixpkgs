{ lib
, stdenv
, fetchFromGitLab
, fetchpatch
, autoreconfHook
, pkg-config
, cairo
, expat
, flex
, fontconfig
, gd
, gts
, libjpeg
, libpng
, libtool
, pango
, bash
, bison
, xorg
, ApplicationServices
, python3
, fltk
, exiv2
, withXorg ? true
}:

let
  inherit (lib) optional optionals optionalString;
in
stdenv.mkDerivation rec {
  pname = "graphviz";
  version = "9.0.0";

  src = fetchFromGitLab {
    owner = "graphviz";
    repo = "graphviz";
    rev = version;
    hash = "sha256-lLESaULvHkWJjbKjjG9VIcVInqsDmY1OAAKfjCFDThQ=";
  };

  patches = lib.optionals stdenv.hostPlatform.isFreeBSD [
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/8f6f86bd48a3b52427e33ed5b05cfec1c7eea4e3/graphics/graphviz/files/patch-lib_gvpr_compile.c";
      hash = "sha256-IerFOoOCuNvGsNTQp51SlYHB8kY0WK69Z6PW0PGiUhY=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/8f6f86bd48a3b52427e33ed5b05cfec1c7eea4e3/graphics/graphviz/files/patch-lib_gvpr_actions.c";
      hash = "sha256-UrQDyfJvXIqTQwKHdE7HSWQ5Xs5OSgVSPuwIlYs79aI=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
  ];

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    python3
    bison
    flex
  ];

  buildInputs = [
    libpng
    libjpeg
    expat
    fontconfig
    gd
    gts
    pango
    bash
  ] ++ optionals withXorg (with xorg; [ libXrender libXaw libXpm ])
  ++ optionals stdenv.isDarwin [ ApplicationServices ];

  hardeningDisable = [ "fortify" ];

  configureFlags = [
    "--with-ltdl-lib=${libtool.lib}/lib"
    "--with-ltdl-include=${libtool}/include"
  ] ++ optional (xorg == null) "--without-x";

  enableParallelBuilding = true;

  CPPFLAGS = optionalString (withXorg && stdenv.isDarwin)
    "-I${cairo.dev}/include/cairo";

  doCheck = false; # fails with "Graphviz test suite requires ksh93" which is not in nixpkgs

  preAutoreconf = "./autogen.sh";

  postFixup = optionalString withXorg ''
    substituteInPlace $out/bin/vimdot \
      --replace '"/usr/bin/vi"' '"$(command -v vi)"' \
      --replace '"/usr/bin/vim"' '"$(command -v vim)"' \
      --replace /usr/bin/vimdot $out/bin/vimdot \
  '';

  passthru.tests = {
    inherit (python3.pkgs) pygraphviz;
    inherit fltk exiv2;
  };

  meta = with lib; {
    homepage = "https://graphviz.org";
    description = "Graph visualization tools";
    license = licenses.epl10;
    platforms = platforms.unix;
    maintainers = with maintainers; [ bjornfor raskin ];
  };
}
