{ lib
, stdenv
, fetchurl
, pkg-config
, freetype
, cmake
, static ? stdenv.hostPlatform.isStatic
, overrideCC
}:

stdenv.mkDerivation rec {
  version = "1.3.14";
  pname = "graphite2";

  src = fetchurl {
    url = "https://github.com/silnrsi/graphite/releases/download/"
      + "${version}/graphite2-${version}.tgz";
    sha256 = "1790ajyhk0ax8xxamnrk176gc9gvhadzy78qia4rd8jzm89ir7gr";
  };

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [ pkg-config cmake ];
  buildInputs = [ freetype ];

  patches = lib.optionals stdenv.isDarwin [ ./macosx.patch ];
  postPatch = ''
    # disable broken 'nametabletest' test, fails on gcc-13:
    #   https://github.com/silnrsi/graphite/pull/74
    substituteInPlace tests/CMakeLists.txt \
      --replace 'add_subdirectory(nametabletest)' '#add_subdirectory(nametabletest)'

    # support cross-compilation by using target readelf binary:
    substituteInPlace Graphite.cmake \
      --replace 'readelf' "${stdenv.cc.targetPrefix}readelf"
  '';

  cmakeFlags = lib.optionals static [
    "-DBUILD_SHARED_LIBS=OFF"
  ];

  # RTTI and unwind tables pull in references to libc++abi, which is frowned upon by harfbuzz
  # it is unknown why this only manifests on freebsd
  NIX_CFLAGS_COMPILE = lib.optionalString stdenv.isFreeBSD "-fno-rtti -fno-exceptions -Xclang -fcxx-exceptions";
  postBuild = lib.optionalString stdenv.isFreeBSD ''
    patchelf --remove-needed libc++abi.so.1 --remove-needed libc++.so.1 src/libgraphite2.so
  '';

  # Remove a test that fails to statically link (undefined reference to png and
  # freetype symbols)
  postConfigure = lib.optionalString static ''
    sed -e '/freetype freetype.c/d' -i ../tests/examples/CMakeLists.txt
  '';

  doCheck = true;

  meta = with lib; {
    description = "An advanced font engine";
    homepage = "https://graphite.sil.org/";
    license = licenses.lgpl21;
    maintainers = [ maintainers.raskin ];
    mainProgram = "gr2fonttest";
    platforms = platforms.unix ++ platforms.windows;
  };
}
