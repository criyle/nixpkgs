{ lib, stdenv, fetchurl, jre
, fetchFromGitHub, cmake, ninja, pkg-config, darwin

# ANTLR 4.8 & 4.9
, libuuid

# ANTLR 4.9
, utf8cpp }:

let

  mkAntlr = { version, sourceSha256, jarSha256 }: lib.fixedPoints.makeExtensible (self: {
    source = fetchFromGitHub {
      owner = "antlr";
      repo = "antlr4";
      rev = version;
      sha256 = sourceSha256;
    };

    antlr = stdenv.mkDerivation {
      pname = "antlr";
      inherit version;

      src = fetchurl {
        url = "https://www.antlr.org/download/antlr-${version}-complete.jar";
        sha256 = jarSha256;
      };

      dontUnpack = true;

      installPhase = ''
        mkdir -p "$out"/{share/java,bin}
        cp "$src" "$out/share/java/antlr-${version}-complete.jar"

        echo "#! ${stdenv.shell}" >> "$out/bin/antlr"
        echo "'${jre}/bin/java' -cp '$out/share/java/antlr-${version}-complete.jar:$CLASSPATH' -Xmx500M org.antlr.v4.Tool \"\$@\"" >> "$out/bin/antlr"

        echo "#! ${stdenv.shell}" >> "$out/bin/grun"
        echo "'${jre}/bin/java' -cp '$out/share/java/antlr-${version}-complete.jar:$CLASSPATH' org.antlr.v4.gui.TestRig \"\$@\"" >> "$out/bin/grun"

        chmod a+x "$out/bin/antlr" "$out/bin/grun"
        ln -s "$out/bin/antlr"{,4}
      '';

      inherit jre;

      passthru = {
        inherit (self) runtime;
        jarLocation = "${self.antlr}/share/java/antlr-${version}-complete.jar";
      };

      meta = with lib; {
        description = "Powerful parser generator";
        longDescription = ''
          ANTLR (ANother Tool for Language Recognition) is a powerful parser
          generator for reading, processing, executing, or translating structured
          text or binary files. It's widely used to build languages, tools, and
          frameworks. From a grammar, ANTLR generates a parser that can build and
          walk parse trees.
        '';
        homepage = "https://www.antlr.org/";
        sourceProvenance = with sourceTypes; [ binaryBytecode ];
        license = licenses.bsd3;
        platforms = platforms.unix;
      };
    };

    runtime = {
      cpp = stdenv.mkDerivation {
        pname = "antlr-runtime-cpp";
        inherit version;
        src = self.source;

        outputs = [ "out" "dev" "doc" ];

        nativeBuildInputs = [ cmake ninja pkg-config ];
        buildInputs =
          lib.optional stdenv.isDarwin darwin.apple_sdk.frameworks.CoreFoundation;

        postUnpack = ''
          export sourceRoot=$sourceRoot/runtime/Cpp
        '';

        meta = with lib; {
          description = "C++ target for ANTLR 4";
          homepage = "https://www.antlr.org/";
          license = licenses.bsd3;
          platforms = platforms.unix;
        };
      };
    };
  });

in {
  antlr4_11 = (
    (mkAntlr {
      version = "4.11.1";
      sourceSha256 = "sha256-SUeDgfqLjYQorC8r/CKlwbYooTThMOILkizwQV8pocc=";
      jarSha256 = "sha256-YpdeGStK8mIrcrXwExVT7jy86X923CpBYy3MVeJUc+E=";
    }).extend (self: super: {
      runtime.cpp = super.runtime.cpp.overrideAttrs {
        cmakeFlags = [
          # Generate CMake config files, which are not installed by default.
          "-DANTLR4_INSTALL=ON"

          # Disable tests, since they require downloading googletest, which is
          # not available in a sandboxed build.
          "-DANTLR_BUILD_CPP_TESTS=OFF"
        ];
      };
    })
  ).antlr;

  antlr4_9 = (
    (mkAntlr {
      version = "4.9.3";
      sourceSha256 = "1af3cfqwk7lq1b5qsh1am0922fyhy7wmlpnrqdnvch3zzza9n1qm";
      jarSha256 = "0dnz2x54kigc58bxnynjhmr5iq49f938vj6p50gdir1xdna41kdg";
    }).extend (self: super: {
      runtime.cpp = super.runtime.cpp.overrideAttrs (attrs: {
        patchFlags = [ "-p3" ];
        buildInputs = [ utf8cpp ]
          ++ lib.optional stdenv.isLinux libuuid
          ++ attrs.buildInputs;
      });
    })
  ).antlr;

  antlr4_8 = (
    (mkAntlr {
      version = "4.8";
      sourceSha256 = "1qal3add26qxskm85nk7r758arladn5rcyjinmhlhznmpbbv9j8m";
      jarSha256 = "0nms976cnqyr1ndng3haxkmknpdq6xli4cpf4x4al0yr21l9v93k";
    }).extend (self: super: {
      runtime.cpp = super.runtime.cpp.overrideAttrs (attrs: {
        cmakeFlags = ["-DANTLR4_INSTALL=ON"];
        buildInputs = lib.optional stdenv.isLinux libuuid ++ attrs.buildInputs;
      });
    })
  ).antlr;
}
