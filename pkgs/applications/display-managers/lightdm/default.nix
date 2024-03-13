{ lib, stdenv
, buildPackages
, fetchFromGitHub
, nix-update-script
, substituteAll
, plymouth
, pam
, pkg-config
, autoconf
, automake
, libtool
, libxcb
, glib
, libXdmcp
, itstool
, intltool
, libxklavier
, libgcrypt
, audit
, busybox
, coreutils
, polkit
, accountsservice
, gtk-doc
, gnome
, gobject-introspection
, vala
, fetchpatch
, withQt5 ? false
, qtbase
, yelp-tools
}:

stdenv.mkDerivation rec {
  pname = "lightdm";
  version = "1.32.0";

  outputs = [ "out" "dev" ];

  src = fetchFromGitHub {
    owner = "canonical";
    repo = pname;
    rev = version;
    sha256 = "sha256-ttNlhWD0Ran4d3QvZ+PxbFbSUGMkfrRm+hJdQxIDJvM=";
  };

  nativeBuildInputs = [
    autoconf
    automake
    yelp-tools
    gnome.yelp-xsl
    gobject-introspection
    gtk-doc
    intltool
    itstool
    libtool
    pkg-config
    vala
  ];

  buildInputs = [
    accountsservice
    glib
    libXdmcp
    libgcrypt
    libxcb
    libxklavier
    pam
    polkit
  ] ++ lib.optional withQt5 qtbase
  ++ lib.optionals stdenv.isLinux [
    audit
  ];

  patches = [
    # Adds option to disable writing dmrc files
    (fetchpatch {
      url = "https://src.fedoraproject.org/rpms/lightdm/raw/4cf0d2bed8d1c68970b0322ccd5dbbbb7a0b12bc/f/lightdm-1.25.1-disable_dmrc.patch";
      sha256 = "06f7iabagrsiws2l75sx2jyljknr9js7ydn151p3qfi104d1541n";
    })
  ] ++ lib.optionals stdenv.isLinux [
    # Hardcode plymouth to fix transitions.
    # For some reason it can't find `plymouth`
    # even when it's in PATH in environment.systemPackages.
    (substituteAll {
      src = ./fix-paths.patch;
      plymouth = "${plymouth}/bin/plymouth";
    })
  ] ++ lib.optionals stdenv.isFreeBSD [
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/ea678ae15ce13bf16f5a2ea2b1d5a34a267e3127/x11/lightdm/files/patch-liblightdm-gobject_language.c";
      hash = "sha256-KX+Zybb9io7w+uGZZcaDDVze8/0HM6KTHOYqihwfIis=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/ea678ae15ce13bf16f5a2ea2b1d5a34a267e3127/x11/lightdm/files/patch-src_session-child.c";
      hash = "sha256-4PLuK6BwdY9MeLKzqJ12LkFlNwn46x83C24t0FCU0X4=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/ea678ae15ce13bf16f5a2ea2b1d5a34a267e3127/x11/lightdm/files/patch-tests_src_libsystem.c";
      hash = "sha256-vItXFqAS263PmlAq/FrOEoZsETlOIp8fvQGLcTE1v70=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/ea678ae15ce13bf16f5a2ea2b1d5a34a267e3127/x11/lightdm/files/patch-src_x-server.c";
      hash = "sha256-CDnANUhZLvpR90d+etCwlrOUqzLa+ar3T4pkrmvxLAU=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/ea678ae15ce13bf16f5a2ea2b1d5a34a267e3127/x11/lightdm/files/patch-data_lightdm.conf";
      hash = "sha256-UByI6G9fgbD4VNus9oCiDm4wIVpf126MxMswdCA8KaM=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
  ];

  dontWrapQtApps = true;

  preConfigure = "NOCONFIGURE=1 ./autogen.sh";

  configureFlags = [
    "--localstatedir=/var"
    "--sysconfdir=/etc"
    "--disable-tests"
    "--disable-dmrc"
  ] ++ lib.optional withQt5 "--enable-liblightdm-qt5";

  installFlags = [
    "sysconfdir=${placeholder "out"}/etc"
    "localstatedir=\${TMPDIR}"
  ];

  prePatch = let
  whichProvider = if stdenv.isLinux then buildPackages.busybox else buildPackages.which;
  rmProvider = if stdenv.isLinux then busybox else coreutils;
  in ''
    substituteInPlace autogen.sh \
      --replace "which" "${whichProvider}/bin/which"

    substituteInPlace src/shared-data-manager.c \
      --replace /bin/rm ${rmProvider}/bin/rm
  '';

  postInstall = ''
    rm -rf $out/etc/apparmor.d $out/etc/init $out/etc/pam.d
  '';

  passthru = {
    updateScript = nix-update-script { };
  };


  meta = with lib; {
    homepage = "https://github.com/canonical/lightdm";
    description = "A cross-desktop display manager";
    platforms = platforms.linux ++ platforms.freebsd;
    license = licenses.gpl3;
    maintainers = with maintainers; [ ] ++ teams.pantheon.members;
  };
}
