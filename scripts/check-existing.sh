#!/usr/bin/env bash
# Skip install when the requested StructKit version is already on PATH.
# structkit has no --version flag; the version is read from package metadata.
set -euo pipefail

if [[ -z "${GITHUB_OUTPUT:-}" ]]; then
  echo "::error::GITHUB_OUTPUT is not set"
  exit 1
fi

echo "skip=false" >> "${GITHUB_OUTPUT}"

if ! command -v structkit >/dev/null 2>&1; then
  echo "structkit is not on PATH; install is required"
  exit 0
fi

echo "structkit found at $(command -v structkit)"

if command -v python >/dev/null 2>&1; then
  PYTHON_BIN="${PYTHON_BIN:-python}"
else
  PYTHON_BIN="${PYTHON_BIN:-python3}"
fi

detect_version() {
  local detected="" py bin first interp env_dir

  if detected="$("${PYTHON_BIN}" -c 'from importlib.metadata import version; print(version("structkit"))' 2>/dev/null)"; then
    printf '%s\n' "${detected}"
    return 0
  fi

  env_dir="${UV_TOOL_DIR:-}/structkit"
  for py in "${env_dir}/bin/python" "${env_dir}/bin/python3" "${env_dir}/Scripts/python.exe"; do
    if [[ -x "${py}" ]]; then
      if detected="$("${py}" -c 'from importlib.metadata import version; print(version("structkit"))' 2>/dev/null)"; then
        printf '%s\n' "${detected}"
        return 0
      fi
    fi
  done

  bin="$(command -v structkit)"
  if [[ -f "${bin}" ]]; then
    first="$(head -n 1 "${bin}" 2>/dev/null || true)"
    if [[ "${first}" == "#!"* ]]; then
      interp="${first#\#\!}"
      interp="${interp%% *}"
      if [[ -x "${interp}" ]]; then
        if detected="$("${interp}" -c 'from importlib.metadata import version; print(version("structkit"))' 2>/dev/null)"; then
          printf '%s\n' "${detected}"
          return 0
        fi
      fi
    fi
  fi

  if command -v uv >/dev/null 2>&1; then
    local line
    line="$(uv tool list 2>/dev/null | awk 'BEGIN{IGNORECASE=1} /^structkit[[:space:]]/{print; exit}')"
    if [[ -n "${line}" ]]; then
      detected="$(printf '%s' "${line}" | awk '{print $2}' | sed 's/^v//')"
      if [[ -n "${detected}" ]]; then
        printf '%s\n' "${detected}"
        return 0
      fi
    fi
  fi

  return 1
}

detected=""
if ! detected="$(detect_version)"; then
  echo "Could not determine the version of structkit already on PATH; installing the requested version"
  exit 0
fi

echo "Detected installed structkit version: ${detected}"

if [[ "${detected}" == "${RESOLVED_VERSION}" ]]; then
  echo "Installed version ${detected} matches requested ${RESOLVED_VERSION}; skipping install"
  echo "skip=true" >> "${GITHUB_OUTPUT}"
else
  echo "Installed version ${detected} does not match requested ${RESOLVED_VERSION}; install is required"
fi
