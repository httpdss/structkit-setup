# StructKit Setup

[![GitHub](https://img.shields.io/github/license/httpdss/structkit-setup)](LICENSE)

GitHub Action that installs [StructKit](https://github.com/httpdss/structkit) onto `PATH` for CI. Companion to [structkit-action](https://github.com/httpdss/structkit-action).

This action does **not** run `validate` or `generate`. Call it first when you need StructKit installed; then run commands yourself or use `httpdss/structkit-action`.

## Quick start

### Setup alone

```yaml
jobs:
  use-structkit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: httpdss/structkit-setup@v1
      - run: structkit --help
      - run: structkit generate --help
```

### Setup followed by structkit-action

```yaml
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: httpdss/structkit-setup@v1
      - uses: httpdss/structkit-action@v1
        with:
          command: validate
```

### Pin a version

```yaml
- uses: httpdss/structkit-setup@v1
  with:
    structkit-version: "3.3.0"
    python-version: "3.12"
```

### Install from git

```yaml
- uses: httpdss/structkit-setup@v1
  with:
    structkit-version: "https://github.com/httpdss/structkit.git@main"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `structkit-version` | Exact PyPI version, `latest`, or a git URL | No | `latest` |
| `python-version` | Python version for the tool environment | No | `3.x` |
| `cache` | Cache the uv tool and bin directories | No | `true` |

`latest` is resolved to an exact version from [`https://pypi.org/pypi/structkit/json`](https://pypi.org/pypi/structkit/json) before install and cache keying.

## Outputs

| Output | Description |
|--------|-------------|
| `version` | Resolved version (exact PyPI version, or the git URL) |
| `cache-hit` | `true` when the tool cache was restored |

```yaml
- uses: httpdss/structkit-setup@v1
  id: structkit
- run: echo "Installed ${{ steps.structkit.outputs.version }} (cache-hit=${{ steps.structkit.outputs.cache-hit }})"
```

## How it works

1. Sets up Python (`actions/setup-python`).
2. Resolves `latest` to an exact PyPI version.
3. Installs [uv](https://github.com/astral-sh/setup-uv).
4. Restores a cache of a dedicated uv tool directory and bin directory. The cache key is `runner.os` + `runner.arch` + the resolved Python version + the resolved StructKit version.
5. Runs `uv tool install structkit==<version>` into those directories, unless the same version is already on `PATH`.
6. Adds the bin directory to `GITHUB_PATH`.
7. Verifies the install with `structkit --help` (StructKit has no `--version` flag).

For StructKit versions older than 3.3.1 the installer adds `--with cachetools`. 3.3.0 imports `cachetools` without declaring it.

If `structkit` is already on `PATH` at the requested version, the install (and cache restore) are skipped.

## Releases

This repository uses automated release management with semantic versioning:

- **Release Drafting**: Releases are automatically drafted when PRs are merged to main
- **First Release**: Will be tagged as `v1.0.0`
- **Pinning Recommendations**:
  - Use `@v1` to automatically get minor and patch updates (recommended for most users)
  - Use `@v1.0.0` to pin to a specific version

## License

Apache License 2.0 - see [LICENSE](LICENSE).

## Related projects

- [StructKit](https://github.com/httpdss/structkit) - The StructKit CLI
- [structkit-action](https://github.com/httpdss/structkit-action) - Run `validate` / `generate` in CI (does not install StructKit)
