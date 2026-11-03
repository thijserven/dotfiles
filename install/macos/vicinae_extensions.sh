#!/bin/bash

set -euo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)}"
export DOTFILES_ROOT

install_extensions() {
    /usr/bin/python3 - <<'PY'
import json
import os
import re
from pathlib import Path, PurePosixPath
import stat
import subprocess
import tempfile
import time
import zipfile

EXTENSIONS = (Path(os.environ["DOTFILES_ROOT"]) / "home/private_dot_config/vicinae/extensions.txt").read_text()
extensions = [line.split("#", 1)[0].strip() for line in EXTENSIONS.splitlines()]
extensions = [extension for extension in extensions if extension]
for extension in extensions:
    if not re.fullmatch(r"[A-Za-z0-9_-]+/[A-Za-z0-9_-]+", extension):
        raise ValueError("Invalid Raycast extension author/name: " + extension)


def download(url):
    return subprocess.check_output([
        "curl", "--fail", "--silent", "--show-error", "--location",
        "--retry", "3", "--connect-timeout", "15", "--max-time", "120",
        "--proto", "=https", "--proto-redir", "=https", url,
    ])


root = Path.home() / ".local/share/vicinae/extensions"
root.mkdir(parents=True, exist_ok=True)
for extension in extensions:
    author, name = extension.split("/")
    target = root / ("store.raycast." + name)
    if os.path.lexists(target):
        continue
    print("Installing Vicinae extension: " + extension, flush=True)
    # Avoid cached metadata containing an expired signed download URL.
    metadata = json.loads(download(
        "https://backend.raycast.com/api/v1/extensions/" + extension
        + "?bootstrap=" + str(time.time_ns())
    ))
    url = metadata["download_url"]
    # Store URLs can use an organization owner rather than the manifest author.
    accounts = [metadata["author"]["handle"], (metadata.get("owner") or {}).get("handle", "")]
    if (metadata["name"] != name or author.casefold() not in [account.casefold() for account in accounts]
            or not isinstance(url, str) or not url.startswith("https://")):
        raise ValueError("Invalid Raycast metadata for " + extension)
    # ponytail: uses Raycast's internal bundle layout; switch to official CLI if one becomes available.
    with tempfile.TemporaryDirectory(prefix=".staging-", dir=root) as staging:
        archive = Path(staging) / "bundle.zip"
        archive.write_bytes(download(url))
        unpacked = Path(staging) / "unpacked"
        with zipfile.ZipFile(archive) as bundle:
            for member in bundle.infolist():
                path = PurePosixPath(member.filename)
                if (path.is_absolute() or ".." in path.parts or "\\" in member.filename
                        or not path.parts or path.parts[0] != name
                        or stat.S_ISLNK(member.external_attr >> 16)):
                    raise ValueError("Unsafe extension archive entry: " + member.filename)
            bundle.extractall(unpacked)
        source = unpacked / name
        manifest = json.loads((source / "package.json").read_text())
        if manifest["name"] != name or manifest["author"].casefold() != metadata["author"]["handle"].casefold():
            raise ValueError("Extension manifest does not match " + extension)
        if os.path.lexists(target):
            raise FileExistsError("Extension appeared during installation: " + str(target))
        source.rename(target)
PY
}

main() {
    install_extensions
}

main "$@"
