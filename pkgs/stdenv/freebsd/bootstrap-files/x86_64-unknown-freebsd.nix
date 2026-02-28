# For testing only :)
{
  bootstrapTools = import <nix/fetchurl.nix> {
    url = "https://home.rhelmot.io/tmp/bootstrap/on-server/bootstrap-tools.tar.xz";
    hash = "sha256-s9RFnpMt7kPCvLSS7ipQYmVcOwPwm3HK0NeeIVdgtvw=";
  };
  unpack = import <nix/fetchurl.nix> {
    url = "https://home.rhelmot.io/tmp/bootstrap/on-server/unpack.nar.xz";
    hash = "sha256-+zrjwjQ0H1mIj4Nt09mPORLaMZzTHi0BDrCS+ZTCeFo=";
    name = "unpack";
    unpack = true;
  };
}
