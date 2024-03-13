{ stdenv, lib, accountsservice-linux, coreutils, substituteAll, fetchFromGitLab, consolekit2, gettext, glib, polkit, dbus, ... }:
accountsservice-linux.overrideAttrs (orig: rec {
  version = "23.13.9";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "arrowd";
    repo = "accountsservice";
    rev = "1ad459450480baa3e2024db4edee0a30ca0edc20";
    hash = "sha256-J/X5DGwgJhKOxpJW6lQ/BU/5UAUf+OnWmkjd26eOJVQ=";
  };

  patches = [
    # Hardcode dependency paths.
    (substituteAll ({
      src = ./fix-paths-freebsd.patch;
      inherit coreutils;
    }))

    # Do not try to create directories in /var, that will not work in Nix sandbox.
    ./no-create-dirs.patch

    # Disable mutating D-Bus methods with immutable /etc.
    ./Disable-methods-that-change-files-in-etc-freebsd.patch

    # Do not ignore third-party (e.g Pantheon) extensions not matching FHS path scheme.
    # Fixes https://github.com/NixOS/nixpkgs/issues/72396
    ./drop-prefix-check-extensions.patch

    # Detect DM type from config file.
    # `readlink display-manager.service` won't return any of the candidates.
    ./get-dm-type-from-config.patch

  ];

  postPatch = ''
    echo -e '#!${stdenv.shell}\necho "${version}-nixpkgs"' >generate-version.sh
    sed -E -i -e '/wtmp changes/d' meson.build
  '';

  buildInputs = [
    dbus
    gettext
    glib
    polkit
    consolekit2
  ];

  mesonFlags = [
    "-Dadmin_group=wheel"
    "-Dconsolekit=true"
		"-Dgdmconffile=/etc/gdm/custom.conf"
		"-Dlightdmconffile=/etc/lightdm/lightdm.conf"
		"-Dlocalstatedir=/var"
		"-Dsystemdsystemunitdir=no"
		"-Dvapi=false"
    "-Dtests=false"  # uses fgetpwent
  ];

  meta = with lib; orig.meta // {
    platforms = platforms.freebsd;
  };
})
