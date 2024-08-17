{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "tinyxxd";
  version = "1.3.3";
  src = fetchFromGitHub {
    repo = "tinyxxd";
    owner = "xyproto";
    rev = "v${finalAttrs.version}";
    hash = "sha256-mup4xHt5Prpcwz2QU0qz+9/KYOE0HNrLx9b7z5o47ag=";
  };

  outputs = [
    "out"
    "xxd"
  ];

  installFlags = [ "PREFIX=$(out)" ];

  postInstall = ''
    mkdir -p $xxd/bin
    ln -s $out/bin/tinyxxd $xxd/bin/xxd
  '';

  meta = {
    homepage = "https://github.com/xyproto/tinyxxd";
    description = "Drop-in replacement and standalone version of the hex dump utility that comes with ViM";
    license = lib.licenses.gpl2;
    mainProgram = "tinyxxd";
    maintainers = with lib.maintainers; [ philiptaron ];
    platforms = lib.platforms.unix;
  };
})
