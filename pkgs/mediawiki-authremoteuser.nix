{
  stdenv,
  fetchzip
}:
stdenv.mkDerivation rec {
  pname = "mediawiki-AuthRemoteUser";
  version = "1.0.0";

  src = fetchzip {
    url = "https://github.com/oetterer/AuthRemoteUser/archive/refs/tags/${version}.tar.gz";
	sha256 = "sha256-D6O+DnuCYwqWHdlq3VgBazjbnIPRII0BhPfNWsyBHtE=";
  };

  dontBuild = true;

  installPhase = ''
    cp -r . $out
  	substituteInPlace $out/src/PluggableAuth.php \
  	  --replace-fail \
  	    'use Title;' \
    		'use MediaWiki\Title\Title;'
	'';
}
