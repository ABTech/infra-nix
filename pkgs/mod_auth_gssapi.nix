{
  lib,
  stdenv,
  apacheHttpd,
  apr,
  aprutil,
  autoconf,
  automake,
  autoreconfHook,
  bison,
  fetchFromGitHub,
  flex,
  krb5,
  libtool,
  openssl,
  pkg-config,
}:

stdenv.mkDerivation rec {

  pname = "mod_auth_gssapi";
  version = "1.6.5";

  src = fetchFromGitHub {
    owner = "gssapi";
    repo = "mod_auth_gssapi";
    rev = "v${version}";
    sha256 = "sha256-DEyQjU7vfipmNB9oU/JwkM/LdMOtnYE/bFCutMyalDo=";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    autoconf
    automake
    libtool
    bison
    flex
  ];

  buildInputs = [
    apacheHttpd
    apr
    aprutil
    krb5
    openssl
  ];

  configureFlags = [
    "--with-apxs2=${apacheHttpd.dev}/bin/apxs"
    "--exec-prefix=$out"
  ];

  installPhase = ''
    mkdir -p $out/modules
    ${apr.dev}/share/build/libtool --mode=install install src/.libs/mod_auth_gssapi.so $out/modules/mod_auth_gssapi.so
  '';

  meta = {
    homepage = "https://github.com/gssapi/mod_auth_gssapi";
    description = "Apache module providing GSSAPI/Kerberos HTTP authentication (SPNEGO)";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };

}