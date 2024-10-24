{ callPackage, fetchurl, fetchpatch, ... } @ args:

callPackage ./generic.nix (args // rec {
  version = "1.81.0";

  src = fetchurl {
    urls = [
      "mirror://sourceforge/boost/boost_${builtins.replaceStrings ["."] ["_"] version}.tar.bz2"
      "https://boostorg.jfrog.io/artifactory/main/release/${version}/source/boost_${builtins.replaceStrings ["."] ["_"] version}.tar.bz2"
    ];
    # SHA256 from http://www.boost.org/users/history/version_1_81_0.html
    sha256 = "71feeed900fbccca04a3b4f2f84a7c217186f28a940ed8b7ed4725986baf99fa";
  };

  # patches backported from 1.86
  patches = [
    (fetchpatch {
      name = "openbsd-fiber-futex.patch";
      url = "https://github.com/boostorg/fiber/pull/315/commits/d486740347c3d2c2116f9f1e50623936c00e7889.patch";
      hash = "sha256-upDPbHhfJfV6s4W4R2kW5PaMtyxKmvNDVWmTuwlkp9U=";
      relative = "include";
    })
    (fetchpatch {
      name = "openbsd-atomic-futex.patch";
      url = "https://github.com/boostorg/atomic/commit/6ee31382b271193064db2bfe0a446260c5b344c0.patch";
      hash = "sha256-8MKIK9UjVKTlGAkDCpj6Y/PdwoYLTPktNSxSNuCOueg=";
      relative = "include";
    })
   ];
})
