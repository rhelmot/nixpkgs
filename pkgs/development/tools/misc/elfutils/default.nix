{ lib, stdenv, fetchurl, fetchpatch, pkg-config, musl-fts
, musl-obstack, m4, zlib, zstd, bzip2, bison, flex, gettext, xz, setupDebugInfoDirs
, argp-standalone, gnulib, autoreconfHook
, enableDebuginfod ? true, sqlite, curl, libmicrohttpd, libarchive
, gitUpdater
}:

# TODO: Look at the hardcoded paths to kernel, modules etc.
stdenv.mkDerivation rec {
  pname = "elfutils";
  version = "0.190";

  src = fetchurl {
    url = "https://sourceware.org/elfutils/ftp/${version}/${pname}-${version}.tar.bz2";
    hash = "sha256-jgCjqbXwS8HcJzroYoHS0m7UEgILOR/8wjGY8QIx1pI=";
  };

  patches = [
    ./debug-info-from-env.patch
    (fetchpatch {
      name = "fix-aarch64_fregs.patch";
      url = "https://git.alpinelinux.org/aports/plain/main/elfutils/fix-aarch64_fregs.patch?id=2e3d4976eeffb4704cf83e2cc3306293b7c7b2e9";
      sha256 = "zvncoRkQx3AwPx52ehjA2vcFroF+yDC2MQR5uS6DATs=";
    })
    (fetchpatch {
      name = "musl-asm-ptrace-h.patch";
      url = "https://git.alpinelinux.org/aports/plain/main/elfutils/musl-asm-ptrace-h.patch?id=2e3d4976eeffb4704cf83e2cc3306293b7c7b2e9";
      sha256 = "8D1wPcdgAkE/TNBOgsHaeTZYhd9l+9TrZg8d5C7kG6k=";
    })
    (fetchpatch {
      name = "musl-macros.patch";
      url = "https://git.alpinelinux.org/aports/plain/main/elfutils/musl-macros.patch?id=2e3d4976eeffb4704cf83e2cc3306293b7c7b2e9";
      sha256 = "tp6O1TRsTAMsFe8vw3LMENT/vAu6OmyA8+pzgThHeA8=";
    })
    (fetchpatch {
      name = "musl-strndupa.patch";
      url = "https://git.alpinelinux.org/aports/plain/main/elfutils/musl-strndupa.patch?id=2e3d4976eeffb4704cf83e2cc3306293b7c7b2e9";
      sha256 = "sha256-7daehJj1t0wPtQzTv+/Rpuqqs5Ng/EYnZzrcf2o/Lb0=";
    })
  ] ++ lib.optionals stdenv.hostPlatform.isMusl [ ./musl-error_h.patch ]
  ++ lib.optionals stdenv.hostPlatform.isFreeBSD [
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/main/devel/elfutils/files/patch-configure.ac";
      hash = "sha256-RLkpY47N/WkYvEgQtef/jAJawGILE5cKlnOZieHGzhM=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/6a6ba556400b5737ceabfc81f666aa536327e01e/devel/elfutils/files/patch-lib_eu-config.h";
      hash = "sha256-27u6+41GzOBfOr7RePqmH18uTc9Mjp7i2Kh0FMFidjw=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\.orig//g' $out
        sed -E -i -e 's/\(memchr/(void*)(memchr/g' $out
      '';
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/8f6f86bd48a3b52427e33ed5b05cfec1c7eea4e3/devel/elfutils/files/patch-lib_stdio__ext.h";
      hash = "sha256-brYjUubwupSjQr/Y22iq0EIjmwOH1EOPGtxor+J87tI=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's|lib/stdio_ext.h.orig|/dev/null|g' $out
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/8f6f86bd48a3b52427e33ed5b05cfec1c7eea4e3/devel/elfutils/files/patch-lib_Makefile.am";
      hash = "sha256-+E7wQYWJD7H0CgS2mtcK5jB1FOf13vxkMp7miD0gOM8=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/aebdd1266f80ee0af8a14205336694115d88658f/devel/elfutils/files/patch-lib_vasnprintf.h";
      hash = "sha256-g16NT5yvJK+5KuVj5TlffrdNJGdKZfLwuMzfYL2FHnE=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's|lib/vasnprintf.h.orig|/dev/null|g' $out
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/8f6f86bd48a3b52427e33ed5b05cfec1c7eea4e3/devel/elfutils/files/patch-libelf_gelf.h";
      hash = "sha256-2/F5SOtCbQrNN4GtZ4OTDxvMj8KY55oBXB1seK2RI5Y=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/8f6f86bd48a3b52427e33ed5b05cfec1c7eea4e3/devel/elfutils/files/patch-libelf_elf.h";
      hash = "sha256-uCPef/WnmQoiwIQ7bGbAJFxXgEs5Aio5X7t9VC0uDKg=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/8f6f86bd48a3b52427e33ed5b05cfec1c7eea4e3/devel/elfutils/files/patch-libdw_dwarf__getsrclines.c";
      hash = "sha256-fU3WqpAs/gq4dMPMXdnk8fwZn9pCpm/TqyYl3aKXhEc=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
  ];

  postPatch = ''
    patchShebangs tests/*.sh
  '' + lib.optionalString stdenv.hostPlatform.isRiscV ''
    # disable failing test:
    #
    # > dwfl_thread_getframes: No DWARF information found
    sed -i s/run-backtrace-dwarf.sh//g tests/Makefile.in
  '' + lib.optionalString stdenv.isFreeBSD ''
    sed -E -i -e "s/2.63/2.64/g" configure.ac
    #${gnulib}/bin/gnulib-tool --source-base gnulib --import obstack vasnprintf exitfail gettext
    #sed -E -i -e "s/noinst_LIBRARIES =/noinst_LIBRARIES = libeu.a/g" lib/Makefile.am
    #mv lib/Makefile.am\~ lib/Makefile.am
    cp ${gnulib}/lib/{obstack*,gettext.h} lib
    echo '#pragma once' >> lib/exitfail.h
    echo '#define exit_failure EXIT_FAILURE' >> lib/exitfail.h
    sed -E -i -e "/alloca.h/d" lib/libeu.h
    sed -E -i -e "s_sys/vfs.h_sys/mount.h_g" debuginfod/debuginfod.cxx
    sed -E -i -e "/mount.h/a #include <sys/socket.h>" debuginfod/debuginfod.cxx
    sed -E -i -e "/mount.h/a #include <netinet/in.h>" debuginfod/debuginfod.cxx
    sed -E -i -e "s/tid\(\) pthread_self/tid() (double)(long)pthread_self/g" debuginfod/debuginfod.cxx
    sed -E -i -e "/linux.limits.h/d" debuginfod/debuginfod-client.c
    sed -E -i -e "s/CLOCK_MONOTONIC_RAW/CLOCK_MONOTONIC/g" debuginfod/debuginfod-client.c
    sed -E -i -e 's/\<ETIME\>/EINVAL/g' debuginfod/debuginfod-client.c
    sed -E -i -e 's/#define DEFFILEMODE .*/#define DEFFILEMODE 0666/g' lib/system.h
  '';

  postConfigure = lib.optionalString stdenv.isFreeBSD ''
    echo '#define _GL_CONFIG_H_INCLUDED 1' >> config.h
    echo '#define _GL_ATTRIBUTE_SPEC_PRINTF_STANDARD __printf__' >> config.h
    echo '#define _GL_ATTRIBUTE_FORMAT(spec) __attribute__ ((__format__ spec))' >> config.h
  '';

  env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.isFreeBSD "-Wno-error=format-nonliteral -Wno-error=unused-command-line-argument -DFREEBSD_HAS_MEMPCPY -Wno-error=macro-redefined -DHAVE_CONFIG_H";
  env.NIX_LDFLAGS = lib.optionalString stdenv.isFreeBSD "-lintl";

  outputs = [ "bin" "dev" "out" "man" ];

  # We need bzip2 in NativeInputs because otherwise we can't unpack the src,
  # as the host-bzip2 will be in the path.
  nativeBuildInputs = [ m4 bison flex gettext bzip2 ]
    ++ lib.optional enableDebuginfod pkg-config
    ++ lib.optionals stdenv.isFreeBSD [autoreconfHook];
  buildInputs = [ zlib zstd bzip2 xz ]
    ++ lib.optionals stdenv.hostPlatform.isMusl [
    argp-standalone
    musl-fts
    musl-obstack
  ] ++ lib.optionals enableDebuginfod [
    sqlite
    curl
    libmicrohttpd
    libarchive
  ] ++ lib.optionals stdenv.isFreeBSD [
    argp-standalone
  ];

  propagatedNativeBuildInputs = [ setupDebugInfoDirs ];

  configureFlags = [
    "--program-prefix=eu-" # prevent collisions with binutils
    "--enable-deterministic-archives"
    (lib.enableFeature enableDebuginfod "libdebuginfod")
    (lib.enableFeature enableDebuginfod "debuginfod")
  ];

  enableParallelBuilding = true;

  # Backtrace unwinding tests rely on glibc-internal symbol names.
  # Musl provides slightly different forms and fails.
  # Let's disable tests there until musl support is fully upstreamed.
  doCheck = !stdenv.hostPlatform.isMusl && !stdenv.isFreeBSD;
  doInstallCheck = !stdenv.hostPlatform.isMusl && !stdenv.isFreeBSD;

  passthru.updateScript = gitUpdater {
    url = "https://sourceware.org/git/elfutils.git";
    rev-prefix = "elfutils-";
  };

  meta = with lib; {
    homepage = "https://sourceware.org/elfutils/";
    description = "A set of utilities to handle ELF objects";
    platforms = platforms.linux ++ platforms.freebsd;
    # https://lists.fedorahosted.org/pipermail/elfutils-devel/2014-November/004223.html
    broken = stdenv.hostPlatform.isStatic;
    # licenses are GPL2 or LGPL3+ for libraries, GPL3+ for bins,
    # but since this package isn't split that way, all three are listed.
    license = with licenses; [ gpl2Only lgpl3Plus gpl3Plus ];
    maintainers = with maintainers; [ eelco r-burns ];
  };
}
