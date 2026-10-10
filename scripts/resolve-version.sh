#!/usr/bin/env bash
# Resolve inputs.structkit-version to an exact PyPI version or a git URL.
# "latest" is resolved via https://pypi.org/pypi/structkit/json
set -euo pipefail

spec="${INPUT_STRUCTKIT_VERSION:-latest}"
echo "Requested structkit-version: ${spec}"

if [[ -z "${GITHUB_OUTPUT:-}" ]]; then
  echo "::error::GITHUB_OUTPUT is not set"
  exit 1
fi

if command -v python >/dev/null 2>&1; then
  PYTHON_BIN="${PYTHON_BIN:-python}"
else
  PYTHON_BIN="${PYTHON_BIN:-python3}"
fi

write_outputs() {
  local version="$1"
  local cache_key="$2"
  local out_spec="$3"
  {
    echo "version=${version}"
    echo "cache-key=${cache_key}"
    echo "spec=${out_spec}"
  } >> "${GITHUB_OUTPUT}"
}

if [[ "${spec}" == http://* || "${spec}" == https://* || "${spec}" == git+* ]]; then
  cache_key="$(SPEC="${spec}" "${PYTHON_BIN}" -c "import hashlib, os; print(hashlib.sha256(os.environ['SPEC'].encode()).hexdigest()[:16])")"
  write_outputs "${spec}" "git-${cache_key}" "${spec}"
  echo "Resolved git source: ${spec}"
  exit 0
fi

if [[ "${spec}" == "latest" ]]; then
  resolved="$("${PYTHON_BIN}" -c 'import json, urllib.request; print(json.load(urllib.request.urlopen("https://pypi.org/pypi/structkit/json"))["info"]["version"])')"
  echo "Resolved latest to ${resolved} via https://pypi.org/pypi/structkit/json"
else
  resolved="${spec}"
  echo "Using pinned version ${resolved}"
fi

write_outputs "${resolved}" "${resolved}" "${resolved}"
