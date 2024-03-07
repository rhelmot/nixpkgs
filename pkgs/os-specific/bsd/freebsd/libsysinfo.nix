{ stdenv, lib, fetchFromGitHub, freebsd, ... }:
stdenv.mkDerivation rec {
  pname = "libsysinfo";
  version = "0.0.3";
  src = fetchFromGitHub {
    owner = "bsdimp";
    repo = "libsysinfo";
    rev = "v${version}";
    hash = "sha256-QUiUJ1oXdzlLrWyOOtONtcGzalCtdZ19bbehaLvmFGk=";
  };

  nativeBuildInputs = [ freebsd.bmakeMinimal ../setup-hook.sh ./setup-hook.sh ];

  MACHINE_ARCH = freebsd.hostArchBsd;
  MACHINE = freebsd.hostArchBsd;
  MACHINE_CPUARCH = freebsd.hostArchBsd;

  installPhase = ''
    cat >libsysinfo.pc <<EOF
    prefix=$out
    exec_prefix=$out
    libdir=$out/lib
    includedir=$out/include

    Name: libsysinfo
    Description: ${meta.description}
    Version: 0.0.3
    Libs: -L$out/lib -lsysinfo
    Libs.private:
    Cflags: -I$out/include
    EOF
    install -D -m 0644 include/sys/sysinfo.h $out/include/sys/sysinfo.h
    install -D -m 0644 libsysinfo.a $out/lib/libsysinfo.a
    install -D -m 0644 libsysinfo.so $out/lib/libsysinfo.so
    install -D -m 0644 libsysinfo.so.0 $out/lib/libsysinfo.so.0
    install -D -m 0644 man/sysinfo.3 $out/man/sysinfo.3
    install -D -m 0644 libsysinfo.pc $out/lib/pkgconfig/libsysinfo.pc
  '';

  meta = with lib; {
    description = "GNU libc's sysinfo port for FreeBSD";
    platforms = platforms.freebsd;
    maintainers = with maintainers; [ rhelmot ];
  };
}
