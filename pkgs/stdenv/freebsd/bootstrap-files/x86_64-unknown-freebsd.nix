{
  unpack = import <nix/fetchurl.nix> {
    url = "https://s3.us-east-005.backblazeb2.com/nixbsd/kvmqx0askgdy4yb9hkd6mdp5wxylhdzf-unpack.nar.xz";
    hash = "sha256-03Jp/wqXY1he1eVF5uAdGVrOTTg+d+NPfJZWgi8HG+Q=";
    name = "boostrapUnpacked";
    unpack = true;
  };
  bootstrapTools = import <nix/fetchurl.nix> {
    url = "https://s3.us-east-005.backblazeb2.com/nixbsd/hxbyy4fc6gxx41v8212g2m3h6v9awb6p-bootstrap-tools.tar.xz";
    hash = "sha256-tUuBuUZhBK2OFAzzRpFGNFsMscvLMW9TN4Vy8VT0aw8=";
    name = "bootstrapTools.tar.xz";
  };
}
