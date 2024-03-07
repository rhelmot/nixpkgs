{ lib
, stdenv
, fetchurl
, fetchpatch
, substituteAll
, pkg-config
, glib
, shadow
, gobject-introspection
, polkit
, systemd
, coreutils
, meson
, mesonEmulatorHook
, dbus
, ninja
, python3
, vala
, gettext
, libxcrypt
}:

stdenv.mkDerivation rec {
  pname = "accountsservice";
  version = "23.13.9";

  outputs = [ "out" "dev" ];

  src = fetchurl {
    url = "https://www.freedesktop.org/software/accountsservice/accountsservice-${version}.tar.xz";
    sha256 = "rdpM3q4k+gmS598///nv+nCQvjrCM6Pt/fadWpybkk8=";
  };

  patches = [
    # Hardcode dependency paths.
    (substituteAll ({
      src = ./fix-paths.patch;
      inherit coreutils;
    } // lib.optionalAttrs stdenv.isLinux {
      inherit shadow;
    }))

    # Do not try to create directories in /var, that will not work in Nix sandbox.
    ./no-create-dirs.patch

    # Disable mutating D-Bus methods with immutable /etc.
    ./Disable-methods-that-change-files-in-etc.patch

    # Do not ignore third-party (e.g Pantheon) extensions not matching FHS path scheme.
    # Fixes https://github.com/NixOS/nixpkgs/issues/72396
    ./drop-prefix-check-extensions.patch

    # Detect DM type from config file.
    # `readlink display-manager.service` won't return any of the candidates.
    ./get-dm-type-from-config.patch
  ] ++ lib.optionals stdenv.isFreeBSD [
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/8f6f86bd48a3b52427e33ed5b05cfec1c7eea4e3/sysutils/accountsservice/files/patch-meson.build";
      hash = "sha256-nznjhQ39d/dQwqiZOupwRCoLVSd0vnGZ+4cCFLJA4wQ=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
  ];

  nativeBuildInputs = [
    gettext
    gobject-introspection
    meson
    ninja
    pkg-config
    python3
    vala
  ] ++ lib.optionals (!stdenv.buildPlatform.canExecute stdenv.hostPlatform) [
    #  meson.build:88:2: ERROR: Can not run test applications in this cross environment.
    mesonEmulatorHook
  ];

  buildInputs = [
    dbus
    gettext
    glib
    polkit
    libxcrypt
  ] ++ lib.optionals stdenv.isLinux [
    systemd
  ];

  mesonFlags = [
    "-Dadmin_group=wheel"
    "-Dlocalstatedir=/var"
  ] ++ lib.optionals stdenv.isLinux [
    "-Dsystemdsystemunitdir=${placeholder "out"}/etc/systemd/system"
  ] ++ lib.optionals stdenv.isFreeBSD [
    "-Dsystemdsystemunitdir=no"
  ];

  postPatch = ''
    chmod +x meson_post_install.py
    patchShebangs meson_post_install.py
  '';

  meta = with lib; {
    description = "D-Bus interface for user account query and manipulation";
    homepage = "https://www.freedesktop.org/wiki/Software/AccountsService";
    license = licenses.gpl3Plus;
    maintainers = teams.freedesktop.members ++ (with maintainers; [ pSub ]);
    platforms = platforms.linux ++ platforms.freebsd;
  };
}
