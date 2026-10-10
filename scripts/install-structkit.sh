#!/usr/bin/env bash
# Install StructKit with uv tool install into UV_TOOL_DIR / UV_TOOL_BIN_DIR.
# Versions older than 3.3.1 need --with cachetools (3.3.0 imports it undeclared).
set -euo pipefail

if [[ -z "${UV_TOOL_DIR:-}" || -z "${UV_TOOL_BIN_DIR:-}" ]]; then
  echo "::error::UV_TOOL_DIR and UV_TOOL_BIN_DIR must be set"
  exit 1
fi

mkdir -p "${UV_TOOL_DIR}" "${UV_TOOL_BIN_DIR}"

version="${RESOLVED_VERSION:?RESOLVED_VERSION is required}"
spec="${VERSION_SPEC:-${version}}"

needs_cachetools() {
  local ver="$1"
  if [[ ! "${ver}" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
    return 1
  fi
  local lowest
  lowest="$(printf '%s\n%s\n' "${ver}" "3.3.1" | sort -V | head -n1)"
  [[ "${lowest}" == "${ver}" && "${ver}" != "3.3.1" ]]
}

args=()
if [[ -n "${PYTHON_PATH:-}" ]]; then
  args+=(--python "${PYTHON_PATH}")
fi

pkg=""
if [[ "${spec}" == http://* || "${spec}" == https://* || "${spec}" == git+* ]]; then
  pkg="${spec}"
  if [[ "${pkg}" == http://* || "${pkg}" == https://* ]]; then
    pkg="git+${pkg}"
  fi
else
  pkg="structkit==${version}"
  if needs_cachetools "${version}"; then
    args+=(--with cachetools)
    echo "Adding --with cachetools for structkit ${version} (< 3.3.1)"
  fi
fi

echo "Running: uv tool install ${args[*]} ${pkg}"
uv tool install "${args[@]}" "${pkg}"

echo "Installed executables in ${UV_TOOL_BIN_DIR}:"
ls -la "${UV_TOOL_BIN_DIR}"
