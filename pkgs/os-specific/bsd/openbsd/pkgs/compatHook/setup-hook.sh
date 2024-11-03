useOpenBSDCompat () {
  export NIX_CFLAGS_COMPILE_@suffixSalt@+="-isystem @compat@/include"
}

postHooks+=(useOpenBSDCompat)
