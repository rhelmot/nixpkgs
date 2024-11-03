{
  stdenv,
  makeSetupHook,
  compat,
}:

makeSetupHook {
  name = "openbsd-compat-hook";
  substitutions = {
    compat = "${compat}";
    suffixSalt = stdenv.cc.suffixSalt;
  };
} ./setup-hook.sh
