{ lib, stdenv, fetchFromGitHub, cmake, zlib }:

stdenv.mkDerivation rec {
  pname = "libmysofa";
  version = "1.3.2";

  src = fetchFromGitHub {
    owner = "hoene";
    repo = "libmysofa";
    rev = "v${version}";
    hash = "sha256-eXMGwa6lOtKoUCcHR9BM2S3NWAZkGyZzF3FAjYaWTvg=";
  };

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [ cmake ];
  buildInputs = [ zlib ];

  cmakeFlags = [ "-DBUILD_TESTS=OFF" "-DCODE_COVERAGE=OFF" ];

  postPatch = lib.optionalString stdenv.isFreeBSD ''
    sed -E -i -e "/toh/d" src/hrtf/portable_endian.h
  '';

  meta = with lib; {
    description = "Reader for AES SOFA files to get better HRTFs";
    homepage = "https://github.com/hoene/libmysofa";
    license = licenses.bsd3;
    platforms = platforms.all;
    maintainers = with maintainers; [ ];
  };
}
