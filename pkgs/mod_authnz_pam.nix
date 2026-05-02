{ lib
, stdenv
, fetchFromGitHub
, apacheHttpd
, pam
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "mod_authnz_pam";
  version = "1.2.3";

  src = fetchFromGitHub {
    owner = "adelton";
    repo = "mod_authnz_pam";
    # Upstream tags releases as "mod_authnz_pam-<version>", not "v<version>".
    rev = "mod_authnz_pam-${finalAttrs.version}";
    hash = "sha256-W3Jo3ipLw5izhWNgmLJZYRLIGm0QmqUKf+wJ7rO/mDI=";
  };

  # apxs (from apacheHttpd) is the build driver; libpam provides -lpam.
  buildInputs = [ apacheHttpd pam ];

  # No Makefile in the upstream repo — invoke apxs directly.
  # -c compiles; we deliberately omit -i/-a (those would try to install
  # into the apacheHttpd store path and edit httpd.conf).
  buildPhase = ''
    runHook preBuild
    apxs -c -Wc,-Wall -Wc,-pedantic mod_authnz_pam.c -lpam
    runHook postBuild
  '';

  # apxs leaves the shared object at .libs/mod_authnz_pam.so
  installPhase = ''
    runHook preInstall
    install -Dm755 .libs/mod_authnz_pam.so $out/modules/mod_authnz_pam.so
    runHook postInstall
  '';

  meta = {
    description = "Apache module for PAM authorization and Basic Auth PAM provider";
    homepage = "https://github.com/adelton/mod_authnz_pam";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
})