{ mkXfceDerivation
, gobject-introspection
, dbus-glib
, garcon
, glib
, gtk3
, libX11
, libXScrnSaver
, libXrandr
, libwnck
, libxfce4ui
, libxfce4util
, libxklavier
, pam
, python3
, systemd
, xfconf
, lib
, stdenv
}:

let
  # For xfce4-screensaver-configure
  pythonEnv = python3.withPackages (pp: [ pp.pygobject3 ]);
in
mkXfceDerivation {
  category = "apps";
  pname = "xfce4-screensaver";
  version = "4.18.2";

  sha256 = "sha256-j5K5i+hl/miyHste73akZL62K6YTxXmN8mmFK9BCecs=";

  nativeBuildInputs = [
    gobject-introspection
  ];

  buildInputs = [
    dbus-glib
    garcon
    glib
    gtk3
    libX11
    libXScrnSaver
    libXrandr
    libwnck
    libxfce4ui
    libxfce4util
    libxklavier
    pam
    pythonEnv
    xfconf
  ] ++ lib.optionals stdenv.isLinux [
    systemd
  ];

  configureFlags = lib.optionals stdenv.isLinux [
    "--without-console-kit"
  ] ++ lib.optionals stdenv.isFreeBSD [
    "--with-console-kit=yes"
    "--with-systemd=no"
  ];

  makeFlags = [ "DBUS_SESSION_SERVICE_DIR=$(out)/etc" ];

  meta = with lib; {
    description = "Screensaver for Xfce";
    maintainers = with maintainers; [ symphorien ] ++ teams.xfce.members;
  };
}
