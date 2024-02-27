{ lib
, stdenv
, fetchFromGitHub
, fetchpatch
, ffmpeg-full
, libaom
, meson
, nasm
, ninja
, testers
, xxd
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libvmaf";
  version = "3.0.0";

  src = fetchFromGitHub {
    owner = "netflix";
    repo = "vmaf";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-6mwU2so1YM2pyWkJbDHVl443GgWtQazbBv3gTMBq5NA=";
  };

  sourceRoot = "${finalAttrs.src.name}/libvmaf";

  patches = lib.optionals stdenv.hostPlatform.isFreeBSD [
    (fetchpatch {
      name = "patch-meson.build";
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/2cf7924/multimedia/vmaf/files/patch-meson.build";
      hash = "sha256-Dkjs0Msn/mcSUsdLyfa/VQ2/7RvcNuyc+m7R3OuJ04Q=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
  ];

  nativeBuildInputs = [ meson ninja nasm xxd ];

  mesonFlags = [ "-Denable_avx512=true" ];

  outputs = [ "out" "dev" ];
  doCheck = false;

  passthru.tests = {
    inherit libaom ffmpeg-full;
    version = testers.testVersion {
      package = finalAttrs.finalPackage;
    };
    pkg-config = testers.hasPkgConfigModules {
      package = finalAttrs.finalPackage;
      moduleNames = [ "libvmaf" ];
    };
  };

  meta = with lib; {
    description = "Perceptual video quality assessment based on multi-method fusion (VMAF)";
    homepage = "https://github.com/Netflix/vmaf";
    changelog = "https://github.com/Netflix/vmaf/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = licenses.bsd2Patent;
    maintainers = [ maintainers.cfsmp3 maintainers.marsam ];
    mainProgram = "vmaf";
    platforms = platforms.unix;
  };
})
