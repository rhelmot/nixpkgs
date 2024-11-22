{
  mkDerivation,
  pathDefinesHook,
  runtimeShell,
}:

mkDerivation {
  path = "sbin/init";
  extraNativeBuildInputs = [ pathDefinesHook ];
  PATH_DEFINE__PATH_BSHELL = runtimeShell;
  meta.mainProgram = "init";
}
