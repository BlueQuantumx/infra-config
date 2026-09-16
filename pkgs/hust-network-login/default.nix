{
  lib,
  stdenvNoCC,
  fetchzip,
}:

stdenvNoCC.mkDerivation rec {
  pname = "hust-network-login";
  version = "0.1.3";

  src = fetchzip {
    url = "https://github.com/black-binary/hust-network-login/releases/download/v${version}/aarch64-unknown-linux-musl.zip";
    hash = "sha256-ow++an9x8Ib+YWay65qFP0JgCohqc39bHRh0dTUdrUk=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
		runHook preInstall

		mkdir -p "$out/bin"

		executable="$(find . -type f -perm -0100 | sort | head -n 1)"
		if [ -z "$executable" ]; then
			echo "No executable found in release archive" >&2
			exit 1
		fi

		install -Dm755 "$executable" "$out/bin/${pname}"

		runHook postInstall
	'';

  meta = with lib; {
    description = "HUST network login client";
    homepage = "https://github.com/black-binary/hust-network-login";
    license = licenses.mit;
    mainProgram = pname;
    platforms = [ "aarch64-linux" ];
  };
}
