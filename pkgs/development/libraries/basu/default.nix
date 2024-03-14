{ lib
, stdenv
, fetchFromSourcehut
, audit
, pkg-config
, libcap
, gperf
, meson
, ninja
, python3
, getent
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "basu";
  version = "0.2.1";

  src = fetchFromSourcehut {
    owner = "~emersion";
    repo = "basu";
    rev = "v${finalAttrs.version}";
    hash = "sha256-zIaEIIo8lJeas2gVjMezO2hr8RnMIT7iiCBilZx5lRQ=";
  };

  outputs = [ "out" "dev" "lib" ];

  buildInputs = [
    gperf
  ] ++ lib.optionals stdenv.isLinux [
    audit
    libcap
  ];

  nativeBuildInputs = [
    pkg-config
    meson
    ninja
    python3
    getent
  ];

  mesonFlags = lib.optionals stdenv.isFreeBSD [
    "-Daudit=disabled"
    "-Dlibcap=disabled"
  ];

  preConfigure = ''
    pushd src/basic
    patchShebangs \
      generate-cap-list.sh generate-errno-list.sh generate-gperfs.py
    popd
  '';

  meta = {
    homepage = "https://sr.ht/~emersion/basu";
    description = "The sd-bus library, extracted from systemd";
    license = lib.licenses.lgpl21Only;
    maintainers = with lib.maintainers; [ AndersonTorres ];
    platforms = lib.platforms.linux ++ lib.platforms.freebsd;
  };
})
