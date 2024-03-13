{ lib
, stdenv
, fetchFromGitHub
, fetchpatch
, dbus
, libdrm
, evdev-proto
, libudev-devd
, autoreconfHook
, pkg-config
, glib
, libxslt
, gobject-introspection
}:

stdenv.mkDerivation {
  pname = "ConsoleKit2";
  version = "1.2.6";

  src = fetchFromGitHub {
    owner = "arrowd";
    repo = "ConsoleKit2";
    rev = "3ead222361800ca2b893354741ad43e6526c9b8b";
    hash = "sha256-6HO1grbkJtutYmM6oRFP8yv0bCgTIB4R3s2Mz2pli98=";
  };

  patches = [
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/dce7c84bbbee09a7d97c60af6aa11eb90e4c0aaa/sysutils/consolekit2/files/patch-data_ConsoleKit.conf";
      hash = "sha256-Ti4H4JDF3aOWlRrQ7kxqWLOrCRFWIKJhDA11A0SXoNQ=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/dce7c84bbbee09a7d97c60af6aa11eb90e4c0aaa/sysutils/consolekit2/files/patch-doc_Makefile.am";
      hash = "sha256-tXCFOZiwVYGzW8CY8cTmWz9yTwjT+bXjm0/F1f+yQNU=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
  ];

  nativeBuildInputs = [ autoreconfHook pkg-config ];
  buildInputs = [
    dbus
    libdrm
    evdev-proto
    libudev-devd
    glib
    libxslt
    gobject-introspection
  ];

  meta = with lib; {
    description = "Framework from defining and tracking users";
    platforms = platforms.freebsd;
    maintainers = [maintainers.rhelmot];
  };
}
