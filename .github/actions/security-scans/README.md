# Security Scans Action

This composite GitHub Action wraps all the security scanners used to
analyze CloudNativePG container images.

---

## Requirements

This composite action relies on the calling workflow’s `GITHUB_TOKEN`.
Make sure your calling workflow includes:

```
permissions:
  contents: read
  packages: read
  security-events: write      # required for SARIF upload
```

---

## Security scanners

- [Dockle](https://github.com/goodwithtech/dockle):
  - Best-practice and configuration checks.

- [Snyk](https://github.com/snyk/actions):
  - Detects vulnerabilities in OS packages, libraries, and dependencies.
  - Generates a `snyk.sarif` that gets uploaded to GitHub Code Scanning

---

## Inputs

| Name             | Description                                        | Required  | Default        |
| ---------------- | -------------------------------------------------- | --------- | -------------- |
| `image`          | The image to scan (e.g. `ghcr.io/org/image:tag`)   | ✅ Yes    | —              |
| `registry_user`  | The user used to pull the image                    | ✅ Yes    | —              |
| `registry_token` | The token used to pull the image                   | ✅ Yes    | —              |
| `snyk_token`     | The Snyk authentication token                      | ❌ No     | —              |
| `dockerfile`     | Path to the image’s Dockerfile (for Snyk scanning) | ❌ No     | `./Dockerfile` |

Note:
- If a `snyk_token` is not provided, Snyk scans won't be performed.
- The `dockerfile` path is currently only required by Snyk.

---

## Usage

Example workflow:

```
jobs:
  security-scan:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: read
      security-events: write
    steps:
      - uses: actions/checkout@v5
      - name: Security checks
        uses: cloudnative-pg/postgres-containers/.github/actions/security-scans@main
        with:
          image: ghcr.io/org/image:tag
          registry_user: ${{ github.actor }}
          registry_token: ${{ secrets.GITHUB_TOKEN }}
          snyk_token: ${{ secrets.SNYK_TOKEN }}
          dockerfile: "./Dockerfile"
```
