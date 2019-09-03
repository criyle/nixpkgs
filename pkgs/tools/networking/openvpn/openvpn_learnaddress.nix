{ stdenv, fetchgit, makeWrapper,  coreutils, gawk, utillinux }:

stdenv.mkDerivation {
  name = "openvpn-learnaddress-19b03c3";

  src = fetchgit {
    url = https://gist.github.com/4058733.git;
    rev = "19b03c3beb0190df46ea07bf4b68244acb8eae80";
    sha256 = "16pcyvyhwsx34i0cjkkx906lmrwdd9gvznvqdwlad4ha8l8f8z42";
  };

  buildInputs = [ makeWrapper coreutils gawk utillinux ];

  installPhase = ''
    install -Dm555 ovpn-learnaddress $out/libexec/openvpn/openvpn-learnaddress

    wrapProgram $out/libexec/openvpn/openvpn-learnaddress \
        --prefix PATH : ${stdenv.lib.makeBinPath [ coreutils gawk utillinux ]}
  '';

  meta = {
    description = "Openvpn learn-address script to manage a hosts-like file";
    homepage = https://gist.github.com/offlinehacker/4058733/;
    maintainers = [ stdenv.lib.maintainers.offline ];
    platforms = stdenv.lib.platforms.unix;
  };
}
