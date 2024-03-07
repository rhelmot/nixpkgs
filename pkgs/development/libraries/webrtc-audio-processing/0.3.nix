{ lib, stdenv, fetchurl, fetchpatch, darwin, autoreconfHook, pkg-config }:

stdenv.mkDerivation rec {
  pname = "webrtc-audio-processing";
  version = "0.3.1";

  src = fetchurl {
    url = "https://freedesktop.org/software/pulseaudio/webrtc-audio-processing/webrtc-audio-processing-${version}.tar.xz";
    sha256 = "1gsx7k77blfy171b6g3m0k0s0072v6jcawhmx1kjs9w5zlwdkzd0";
  };

  outputs = [ "out" "dev" ];

  nativeBuildInputs = lib.optionals stdenv.isFreeBSD [ autoreconfHook pkg-config ];

  patches = [
    ./enable-riscv.patch
    ./enable-powerpc.patch
  ] ++ lib.optionals stdenv.isFreeBSD (let mkpatch = (patch: fetchpatch (patch // { extraPrefix = ""; postFetch = ''sed -E -i -e 's/\.orig//g' $out''; })); in [
    (mkpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/8f6f86bd48a3b52427e33ed5b05cfec1c7eea4e3/audio/webrtc-audio-processing0/files/patch-configure.ac";
      hash = "sha256-4/ajwcYPk0hDAfJb2TMD9WmrbgRw0jketv0BlP37tAk=";
    })
    (mkpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/8f6f86bd48a3b52427e33ed5b05cfec1c7eea4e3/audio/webrtc-audio-processing0/files/patch-webrtc_base_checks.cc";
      hash = "sha256-TkGYXgypxf+IVBWgixvb21eZ//BV0JKQ42GxRySMYY8=";
    })
    (mkpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/8f6f86bd48a3b52427e33ed5b05cfec1c7eea4e3/audio/webrtc-audio-processing0/files/patch-webrtc_base_platform__thread.cc";
      hash = "sha256-m9s2PUTQ63YNkTS/iqAHTpAeqxEemyMtPO4Qi9VTf3U=";
    })
    (mkpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/8f6f86bd48a3b52427e33ed5b05cfec1c7eea4e3/audio/webrtc-audio-processing0/files/patch-webrtc_base_stringutils.h";
      hash = "sha256-VaoDJXualvu7pNVaLWlkM/lYjnrokEyHv6jCed7eb84=";
    })
    (mkpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/8f6f86bd48a3b52427e33ed5b05cfec1c7eea4e3/audio/webrtc-audio-processing0/files/patch-webrtc_system__wrappers_source_condition__variable.cc";
      hash = "sha256-afduejd8oWjnQ8Cp8NHM0ChAFo145k2Hnq9yVDe5vsY=";
    })
  ]);

  buildInputs = lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [ ApplicationServices ]);

  patchPhase = lib.optionalString stdenv.hostPlatform.isMusl ''
    substituteInPlace webrtc/base/checks.cc --replace 'defined(__UCLIBC__)' 1
  '';

  meta = with lib; {
    homepage = "https://www.freedesktop.org/software/pulseaudio/webrtc-audio-processing";
    description = "A more Linux packaging friendly copy of the AudioProcessing module from the WebRTC project";
    license = licenses.bsd3;
    # https://gitlab.freedesktop.org/pulseaudio/webrtc-audio-processing/-/blob/v0.3.1/webrtc/rtc_base/system/arch.h
    # + our patches
    platforms = intersectLists platforms.unix (platforms.arm ++ platforms.aarch64 ++ platforms.mips ++ platforms.power ++ platforms.riscv ++ platforms.x86);
  };
}
