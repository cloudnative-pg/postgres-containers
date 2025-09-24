# Image Catalogs Generator Action

This composite GitHub Action generates [CloudNativePG ImageCatalogs](https://cloudnative-pg.io/documentation/current/image_catalog/)
from a container registry.
It wraps the [`catalogs_generator.py`](./catalogs_generator.py) script and makes it easy to
run inside CI pipelines.

---

## How it works

1. The script retrieves all image tags from a container registry.
2. A regular expression is applied to select the tags to include in the ImageCatalog.
3. Matching tags are sorted using [semantic versioning](https://semver.org/).
4. For each PostgreSQL major version, the latest matching tag is chosen.
5. The action generates:

   - One `ClusterImageCatalog` YAML file per requested distribution and image
     type
   - A `kustomization.yaml` to install/update all cluster catalogs at once

---

## Inputs

| Name            | Required  | Description                                           | Example                           |
| --------------- | --------- | ----------------------------------------------------- | --------------------------------- |
| `registry`      | ✅ yes    | The container registry to query.                      | `ghcr.io/cloudnative-pg/postgres` |
| `image-types`   | ✅ yes    | Comma-separated list of image types.                  | `minimal,standard`                |
| `distributions` | ✅ yes    | Comma-separated list of supported OS distributions.   | `bookworm,trixie`                 |
| `regex`         | ✅ yes    | Regular expression used to match image tags.          | *See [Regex](#regex)*             |
| `output-dir`    | ✅ yes    | Directory where generated catalogs will be written.   | `./`                              |
| `family`        | ❌ no     | Family name for generated catalogs (filename prefix). | `my-custom-family`                |

---

## Regex

The `regex` input defines which tags are added to the `ClusterImageCatalog`.

- The **first capturing group** must be the PostgreSQL major version:

    - `(\d+)` → e.g. `18`

- Subsequent capturing groups are optional and may include:

    - an additional version: `(\d+(?:\.\d+)+)` → e.g. `1.2.3`
    - a 12 digit timestamp: `(\d{12})` → e.g. `202509161052`

**Examples:**

```regex
# Matches '18-202509161052', '18.1-202509161052', etc.
'(\d+)(?:\.\d+|beta\d+|rc\d+|alpha\d+)-(\d{12})'

# Matches '18-3.0.6-202509161052', '18.1-3.0.6-202509161052', etc.
'(\d+)(?:\.\d+|beta\d+|rc\d+|alpha\d+)-(\d+(?:\.\d+){1,3})-(\d{12})'
```

> **Note:** Each `image-types` and `distributions` will be combined together
> to form a suffix, `-<img_type>-<distribution>`, which will internally be
> appended to the `regex` provided. Tags that do not contain explicit
> image type and distribution as a suffix are currently not supported.

---

### Family

The optional `family` input customises:

1. **File prefix**: `<family>-minimal-trixie.yaml`
2. **`metadata.name`** in the ImageCatalog: `<family>-minimal-trixie`
3. **`images.cnpg.io/family` label** on the ImageCatalog object

---

## Usage

Example workflow:

```
jobs:
  generate-catalogs:
    runs-on: ubuntu-latest
    steps:
      - name: Generate image catalogs
        uses: cloudnative-pg/postgres-containers/.github/actions/generate-catalogs@main
        with:
          registry: ghcr.io/cloudnative-pg/postgresql
          image-types: minimal,standard
          distributions: bookworm,trixie
          regex: '(\d+)(?:\.\d+|beta\d+|rc\d+|alpha\d+)-(\d{12})'
          output-dir: .
```

This generates:

```
./catalog-minimal-bookworm.yaml
./catalog-standard-bookworm.yaml
./catalog-minimal-trixie.yaml
./catalog-standard-trixie.yaml
```

The generated `kustomization.yaml` will look like:

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- catalog-minimal-bookworm.yaml
- catalog-standard-bookworm.yaml
- catalog-minimal-trixie.yaml
- catalog-standard-trixie.yaml
```
