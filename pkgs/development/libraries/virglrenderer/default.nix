{ lib, stdenv, fetchurl, meson, ninja, pkg-config, python3
, libGLU, libepoxy, libX11, libdrm, mesa
}:

stdenv.mkDerivation rec {
  pname = "virglrenderer";
  version = "1.0.0";

  src = fetchurl {
    url = "https://gitlab.freedesktop.org/virgl/virglrenderer/-/archive/${version}/virglrenderer-${version}.tar.bz2";
    hash = "sha256-KMGPP2MeuATHFXKr5oW9HuFOMmmYpmkVLvMvQi0cEdg=";
  };

  separateDebugInfo = true;

  buildInputs = [ libGLU libepoxy libX11 libdrm mesa ];

  nativeBuildInputs = [ meson ninja pkg-config python3 ];

  env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.isFreeBSD "-Dpthread_set_name_np=pthread_setname_np -DETIME=ENOENT";

  patches = lib.optionals stdenv.isFreeBSD [
    ./freebsd.patch
  ];

  meta = with lib; {
    description = "A virtual 3D GPU library that allows a qemu guest to use the host GPU for accelerated 3D rendering";
    homepage = "https://virgil3d.github.io/";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.freebsd;
    maintainers = [ maintainers.xeji ];
  };
}
