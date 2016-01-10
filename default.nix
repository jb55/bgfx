{ stdenv
, bison
, flex
, mesa
, xlibs
, fetchFromGitHub
, debugBuild ? false
}:

let capitalize = with stdenv.lib.strings; with stdenv.lib;
                   str: let cs = stringToCharacters str;
                        in concatStrings (singleton (toUpper (head cs)) ++ tail cs);
    bx = stdenv.mkDerivation rec {
      name = "bx-git-${version}";
      version = "0.1";

      src = fetchFromGitHub {
        owner = "bkaradzic";
        repo = "bx";
        rev = "c7b73760c704270eb2312738797c026bd69237bb";
        sha256 = "0wydg14frp6flgqvk67c47609ymcdm33lfk9dcc4a65z5sidlk4k";
      };

      phases = ["unpackPhase" "installPhase"];

      installPhase = ''
        mkdir -p $out
        cp -r * $out
      '';
    };
    genie = stdenv.mkDerivation rec {
      name = "genie-git-${version}";
      version = "0.1";

      src = fetchFromGitHub {
        owner = "bkaradzic";
        repo = "genie";
        rev = "3ca5982b932d75357ca1ec46bfc145048c931149";
        sha256 = "0w1c33s6gg909lslv32nyrl7bckpl53b6mhpjn3lzv9haw1j99bp";
      };

      installPhase = ''
        mkdir -p $out/bin
        cp bin/linux/genie $out/bin
      '';
    };
    buildType = if debugBuild then "debug" else "release";
    buildTypeC = capitalize buildType;

in stdenv.mkDerivation rec {
  name = "bgfx-${version}";
  version = "0.1";

  src = fetchFromGitHub {
    owner = "jb55";
    repo = "bgfx";
    rev = "c0ea53f7051bf2d356cabfbf84c66d733d927379";
    sha256 = "0zfx0126jvrzwmvacay7yg0090p3b3bxwl6vrayid6bhypfy2vh8";
  };

  configurePhase = ''
    # substituteInPlace makefile --replace 'GENIE=' 'GENIE ?='
    # substituteInPlace scripts/genie.lua --replace \
    #   'BX_DIR = path.getabsolute(path.join(BGFX_DIR, "../bx"))' \
    #   "BX_DIR = \"${bx}\""

    export GENIE=${genie}/bin/genie
    export BX_DIR=${bx}

    cd 3rdparty/glsl-optimizer
    ./generateParsers.sh
    cd -
  '';

  buildPhase = ''
    make -j$NIX_BUILD_CORES tools linux-${buildType}64
  '';

  installPhase = ''
    mkdir -p $out/{bin,lib}
    srcout=.build/linux64_gcc/bin
    for file in $(find "$srcout" -executable -type f | grep -v ".so$"); do
      cp -r "$file" $out/bin
    done

    cp -r "examples/runtime/"* $out/bin
    cp -r include $out

    cp "$srcout"/libbgfx${buildTypeC}.a $out/lib
    cp "$srcout"/libbgfx-shared-lib${buildTypeC}.so $out/lib
    cp "$srcout"/libexample-common${buildTypeC}.a $out/lib

    ln -s $out/lib/libexample-common${buildTypeC}.a $out/lib/libexample-common.a

    ln -s $out/lib/libbgfx-shared-lib${buildTypeC}.so $out/lib/libbgfx.so
    ln -s $out/lib/libbgfx-shared-lib${buildTypeC}.so $out/lib/libbgfx-shared-lib.so
    ln -s $out/lib/libbgfx${buildTypeC}.a $out/lib/libbgfx.a

    ln -s $out/bin/geometryc${buildTypeC} $out/bin/geometryc
    ln -s $out/bin/texturec${buildTypeC} $out/bin/texturec
    ln -s $out/bin/shaderc${buildTypeC} $out/bin/shaderc
    ln -s $out/bin/makedisttex${buildTypeC} $out/bin/makedisttex
  '';

  buildInputs = [ xlibs.libX11 flex bison mesa bx ];

  meta = with stdenv.lib; {
    description = uRendering libraryu;
    longDescription = ''
      Cross-platform, graphics API agnostic, "Bring Your Own Engine/Framework"
      style rendering libraryRendering library
    '';
    homepage = "https://github.com/bkaradzic/bgfx";
    maintainers = with maintainers; [ jb55 ];
    license = licenses.bsd2;
  };
}
