# Image Catalogs Generator Action

This composite GitHub Action generates [CloudNativePG's ImageCatalogs](https://cloudnative-pg.io/documentation/current/image_catalog/)
from a container registry.
It wraps the [catalogs_generator.py](./catalogs_generator.py) Python script and makes it easy to run in CI pipelines.

## How it works

The script uses a regular expression on the tags retrieved from the registry to match the tags that should be used inside the ImageCatalog,
then it sorts them using [semantic versioning](https://semver.org/), and for each available PostgreSQL major version it
selects the latest tag entry.

A new ImageCatalog YAML file is generated for each distribution and image_type requested, alongside a `kustomization.yaml` that
can be used to install all the catalogs at once.

## Inputs

| Name            | Required | Description                                                     | Example                                     |
| --------------- | -------- | --------------------------------------------------------------- | --------------------------------------------|
| `registry`      | ✅ yes   | The container registry to interrogate.                          | `ghcr.io/cloudnative-pg/postgresql`         |
| `image-types`   | ✅ yes   | Comma-separated list of image types.                            | `minimal,standard`                          |
| `distributions` | ✅ yes   | Comma-separated list of supported OS distributions.             | `bookworm,trixie`                           |
| `regex`         | ✅ yes   | Regular expression used to match image tags.                    |  See [Regex Input](#regex)                  |
| `output-dir`    | ✅ yes   | Path to the directory where generated catalogs are written.     | `path/to/the/directory`                     |
| `family`        | ❌ no    | Family name assigned to the catalogs (used as filename prefix). | `my-custom-family` (it can be any string)   |

### regex

This is the regular expression used to match the tags that should be added to the ImageCatalog.
The first capturing group **must** be the PostgreSQL major version: `(\d+)` (e.g `18`)
Subsequent capturing groups are optional, and can contain
* an additional version: `(\d+(?:\.\d+)+)` (e.g `1.2.3`)
* a 12 digit timestamp: `(\d{12})` (e.g `202509161052`)

Example of valid regex:
```
## Matches '18-202509161052', '18.1-202509161052' etc..
'(\d+)(?:\.\d+|beta\d+|rc\d+|alpha\d+)-(\d{12})'

## Matches '18-3.0.6-202509161052', '18.1-3.0.6-202509161052' etc..
'(\d+)(?:\.\d+|beta\d+|rc\d+|alpha\d+)-(\d+(?:\.\d+){1,3})-(\d{12})'
```

> **Note:** Each `image-types` and `distributions` will be combined together
> to form a suffix, `-<img_type>-<distribution>`, which will internally be
> appended to the `regex` provided. Tags that do not contain explicit
> image type and distribution as a suffix are currently not supported.

### family

The `family` is an optional string input which can be used to customize:
1. The prefix used to create the ImageCatalog YAML files (e.g `<my-family>-minimal-trixie.yaml`)
2. The `metadata.name` of the ImageCatalog object (e.g `<my-family>-minimal-trixie`)
3. The value assigned to the `images.cnpg.io/family` label of the ImageCatalog object

## Usage

In a workflow, call the action like this:

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

This would output ImageCatalogs such as:

```
./catalog-minimal-bookworm.yaml
./catalog-standard-bookworm.yaml
./catalog-minimal-trixie.yaml
./catalog-standard-trixie.yaml
```

plus a `kustomization.yaml` which would look like this:

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- catalog-minimal-bookworm.yaml
- catalog-standard-bookworm.yaml
- catalog-minimal-trixie.yaml
- catalog-standard-trixie.yaml
```