{ lib
, stdenv
, fetchFromGitLab
, fetchpatch
, gitUpdater
, pkg-config
, meson
, ninja
, libevdev
, epoll-shim
, mtdev
, udev
, libwacom
, documentationSupport ? false
, doxygen
, graphviz
, runCommand
, eventGUISupport ? false
, cairo
, glib
, gtk3
, testsSupport ? false
, check
, valgrind
, python3
, nixosTests
}:

let
  mkFlag = optSet: flag: "-D${flag}=${lib.boolToString optSet}";

  sphinx-build =
    let
      env = python3.withPackages (pp: with pp; [
        sphinx
        recommonmark
        sphinx-rtd-theme
      ]);
    in
    # Expose only the sphinx-build binary to avoid contaminating
    # everything with Sphinx’s Python environment.
    runCommand "sphinx-build" { } ''
      mkdir -p "$out/bin"
      ln -s "${env}/bin/sphinx-build" "$out/bin"
    '';
in

stdenv.mkDerivation rec {
  pname = "libinput";
  version = "1.25.0";

  outputs = [ "bin" "out" "dev" ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "libinput";
    repo = "libinput";
    rev = version;
    hash = "sha256-c2FU5OW+CIgtYTQy+bwIbaw3SP1pVxaLokhO+ag5/1s=";
  };

  patches = [
    ./udev-absolute-path.patch
  ] ++ lib.optionals stdenv.hostPlatform.isFreeBSD [
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/8f6f86bd48a3b52427e33ed5b05cfec1c7eea4e3/x11/libinput/files/patch-meson.build";
      hash = "sha256-j5QUwwEa86lUzMVl9fZ+8TirlCzdrMKczT616EDSkAk=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/8f6f86bd48a3b52427e33ed5b05cfec1c7eea4e3/x11/libinput/files/patch-src_evdev.c";
      hash = "sha256-XFsTMC5MhBdvlz0t+apY7hhT1DptJFG180uUT3JEjek=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
  ];

  nativeBuildInputs = [
    pkg-config
    meson
    ninja
  ] ++ lib.optionals documentationSupport [
    doxygen
    graphviz
    sphinx-build
  ];

  buildInputs = [
    libevdev
    mtdev
    libwacom
    (python3.withPackages (pp: with pp; [
      pp.libevdev # already in scope
      pyudev
      pyyaml
      setuptools
    ]))
  ] ++ lib.optionals eventGUISupport [
    # GUI event viewer
    cairo
    glib
    gtk3
  ] ++ lib.optionals stdenv.hostPlatform.isFreeBSD [
    epoll-shim
  ];

  propagatedBuildInputs = [
    udev
  ];

  nativeCheckInputs = [
    check
    valgrind
  ];

  mesonFlags = [
    (mkFlag documentationSupport "documentation")
    (mkFlag eventGUISupport "debug-gui")
    (mkFlag testsSupport "tests")
    "--sysconfdir=/etc"
    "--libexecdir=${placeholder "bin"}/libexec"
  ] ++ lib.optionals stdenv.hostPlatform.isFreeBSD [
    "-Depoll-dir=${lib.getDev epoll-shim}"
  ];

  doCheck = testsSupport && stdenv.hostPlatform == stdenv.buildPlatform;

  postPatch = ''
    patchShebangs \
      test/symbols-leak-test \
      test/check-leftover-udev-rules.sh \
      test/helper-copy-and-exec-from-tmp.sh

    # Don't create an empty directory under /etc.
    sed -i "/install_emptydir(dir_etc \/ 'libinput')/d" meson.build
  '';

  passthru = {
    tests = {
      libinput-module = nixosTests.libinput;
    };
    updateScript = gitUpdater {
      patchlevel-unstable = true;
    };
  };

  meta = with lib; {
    description = "Handles input devices in Wayland compositors and provides a generic X.Org input driver";
    homepage = "https://www.freedesktop.org/wiki/Software/libinput/";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = with maintainers; [ codyopel ] ++ teams.freedesktop.members;
    changelog = "https://gitlab.freedesktop.org/libinput/libinput/-/releases/${version}";
  };
}
