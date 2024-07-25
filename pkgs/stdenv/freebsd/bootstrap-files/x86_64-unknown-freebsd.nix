{
  unpack = import <nix/fetchurl.nix> {
    url = "https://s3.us-east-005.backblazeb2.com/nixbsd/pzbwg76m172dd8nyda5sqhrnap8xbgv9-unpack.nar.xz";
    hash = "sha256-yS/35HSatp2koF8Hy5sGCQONJhZlWjxlSTRVRPfzPMc=";
    name = "boostrapUnpacked";
    unpack = true;
  };
  bootstrapTools = import <nix/fetchurl.nix> {
    url = "https://s3.us-east-005.backblazeb2.com/nixbsd/sqy299j5d6ky7zl8zqz4z7kah7jlghmg-bootstrap-tools.tar.xz";
    hash = "sha256-eoE807Sp83yCY8cWb4SwkVmkZ+6pGbyfyBirlbACMls=";
    name = "bootstrapTools.tar.xz";
  };
}
