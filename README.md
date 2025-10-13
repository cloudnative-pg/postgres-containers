[![CloudNativePG](./logo/cloudnativepg.png)](https://cloudnative-pg.io/)

> **IMPORTANT:** Starting in August 2025, the [Official Postgres Image](https://hub.docker.com/_/postgres),
> maintained by the [PostgreSQL Docker Community](https://github.com/docker-library/postgres),
> has discontinued support for Debian `bullseye`.
> In response, the CloudNativePG project has completed the transition to the
> new `bake`-based build process for all `system` images. We now build directly
> on top of the official Debian slim images, fully detaching from the official
> Postgres image.

---

# CNPG PostgreSQL Container Images

This repository provides maintenance scripts for generating
**immutable application containers** for all supported
[PostgreSQL major versions](https://www.postgresql.org/support/versioning/):

| Version | Release Date | EOL        |
|:-------:|:------------:|:----------:|
|    18   | 2025-09-25   | 2030-11-14 |
|    17   | 2024-09-26   | 2029-11-08 |
|    16   | 2023-09-14   | 2028-11-09 |
|    15   | 2022-10-13   | 2027-11-11 |
|    14   | 2021-09-30   | 2026-11-12 |
|    13   | 2020-09-24   | 2025-11-13 |

These images are designed to serve as operands of the
[CloudNativePG (CNPG) operator](https://cloudnative-pg.io) in Kubernetes
environments, and are not intended for standalone use.

## Key Features

CloudNativePG PostgreSQL container images:

- Are built on top of **Debian Linux** (`stable` and `oldstable`).
- Provide **multi-architecture support**, including `linux/amd64` and
  `linux/arm64`.
- Ship with **build attestations**, such as Software Bills of Materials (SBOMs)
  and provenance metadata.
- Are published in the [CloudNativePG GitHub Container Registry](https://github.com/cloudnative-pg/postgres-containers/pkgs/container/postgresql).
- Are **automatically rebuilt every week** (on Mondays) to remain up to date
  with the latest upstream security and bug fixes.

## Debian Releases

CloudNativePG PostgreSQL container images are based on the official `stable`
and `oldstable` Debian releases, maintained and supported by the
[Debian Project](https://www.debian.org/releases/).

The table below summarises the support lifecycle of relevant Debian versions,
including End-of-Life (EOL) and Long-Term Support (LTS) dates.

| Name                      | Version | Release Date |     EOL    |     LTS    |   Status   |
| ------------------------- | :-----: | :----------: | :--------: | :--------: | :--------- |
| Trixie (`stable`)         |    13   |  2025-08-09  | 2028-08-09 | 2030-06-30 | Supported  |
| Bookworm (`oldstable`)    |    12   |  2023-06-10  | 2026-06-10 | 2028-06-30 | Supported  |
| Bullseye (`oldoldstable`) |    11   |  2021-08-14  | 2024-08-14 | 2026-08-31 | Deprecated |

> **IMPORTANT:** The CloudNativePG project provides full support for
> Debian-based images until each release reaches its official End-of-Life
> (EOL). After EOL and until the start of Long-Term Support (LTS), images for the
> deprecated releases, such as `oldoldstable`, are maintained on a
> **best-effort basis**. If discontinuation becomes necessary before the LTS
> date, a minimum **three-month advance notice** will be posted on this page.

## Image Types

We currently provide and maintain three main types of PostgreSQL images:

* [`minimal`](#minimal-images)
* [`standard`](#standard-images)
* [`system`](#system-images) (*deprecated*)

Both `minimal` and `standard` images are designed to work with backup plugins
such as [Barman Cloud](https://github.com/cloudnative-pg/plugin-barman-cloud).

The `system` images, built on top of the `standard` ones, also include the
Barman Cloud binaries.

### Minimal Images

Minimal images are lightweight and built on top of the
[official Debian images](https://hub.docker.com/_/debian).
They use the [APT PostgreSQL packages](https://wiki.postgresql.org/wiki/Apt)
maintained by the PostgreSQL Global Development Group (PGDG).

These images are identified by the inclusion of `minimal` in their tag names,
for example: `17.6-minimal-trixie`.

> **NOTE**: Starting with PostgreSQL 18, `minimal` images will **not** include
> LLVM JIT support (shipped in the `postgresql-MM-jit` package, where `MM`
> represents the PostgreSQL major version). JIT will be available only in the
> `standard` image.

### Standard Images

Standard images are an extension of the `minimal` images, enhanced with the
following additional features:

- PGAudit
- Postgres Failover Slots
- pgvector
- All Locales
- LLVM JIT support
  - For PostgreSQL 17 and earlier: included in the main PostgreSQL packages,
    also available in `minimal` images
  - From PostgreSQL 18 onwards: provided by the separate `postgresql-MM-jit`
    package

Standard images are identifiable by the `standard` tag in their names, such as:
`17.6-standard-trixie`.

> **Note:** Standard images are designed to offer functionality equivalent to
> the legacy `system` images when used with CloudNativePG. To achieve parity,
> you must use the [Barman Cloud Plugin](https://github.com/cloudnative-pg/plugin-barman-cloud)
> as a replacement for the native Barman Cloud support in `system` images.

### System Images (deprecated)

Starting from September 2025, system images are based on the `standard` image
and include Barman Cloud binaries.

> **IMPORTANT:** The `system` images are deprecated and will be removed once
> in-core support for Barman Cloud in CloudNativePG is phased out. While you
> can still use them as long as in-core Barman Cloud remains available, you
> should plan to migrate to either a `minimal` or `standard` image together
> with the Barman Cloud plugin—or adopt another supported backup solution.

## Image Tags

Each image is identified by its digest and a main tag of the form:

```
MM.mm-TS-TYPE-OS
```

where:

- `MM` is the PostgreSQL major version (e.g. `16`)
- `mm` is the PostgreSQL minor version (e.g. `10`)
- `TS` is the build timestamp with minute precision (e.g. `202509090953`)
- `TYPE` is image type (e.g. `minimal`)
- `OS` is the underlying distribution (e.g. `trixie`)

For example: `16.10-202509090953-minimal-trixie`.

### Rolling Tags

In addition to fully qualified tags, rolling tags are available in the
following formats:

- `MM.mm-TYPE-OS`: latest image for a given PostgreSQL *minor* version
  (`16.10`) of a specific type (`minimal`) on a Debian version (`trixie`).
  For example: `16.10-minimal-trixie`.
- `MM-TYPE-OS`: latest image for a given PostgreSQL *major* version (`16`) of
  a specific type (`minimal`) on a Debian version (`trixie`).
  For example: `16-minimal-trixie`.

### Recommendation

While the most reliable way to reference an image is by its digest, the
`MM.mm-TYPE-OS` tag usually provides a good balance between stability and
convenience for most use cases.

### Deprecated Rolling Tags

For historical reasons, the `system` image also carries two additional rolling
tags:

- `MM.mm`: latest `system` image for a given PostgreSQL *minor* version (e.g.
  `16.10`) on Debian `bullseye`.
- `MM`: latest `system` image for a given PostgreSQL *major* version (e.g.
  `16`) on Debian `bullseye`.

**IMPORTANT:** These tags are **deprecated** and will be **removed when
`bullseye` images reach end of life**. Please migrate to one of the supported
tag formats that explicitly include both the **image type** and the
**distribution version** (e.g. `16.10-minimal-trixie`).

## Image Catalogs

CloudNativePG publishes `ClusterImageCatalog` manifests for CloudNativePG in
the [`artifacts` repository](https://github.com/cloudnative-pg/artifacts/tree/main/image-catalogs),
with one catalog available for each supported combination of image type and
operating system version.

**IMPORTANT:** If you are still relying on the legacy
[`ClusterImageCatalog-bullseye.yaml`](Debian/ClusterImageCatalog-bullseye.yaml)
and [`ClusterImageCatalog-bookworm.yaml`](Debian/ClusterImageCatalog-bookworm.yaml)
manifests, please migrate to the new catalogs as soon as possible. These legacy
manifests are deprecated and will be removed along with the `system` image.

## Build Attestations

CNPG PostgreSQL Container Images are built with the following attestations to
ensure transparency and traceability:

- **[Software Bill of Materials
  (SBOM)](https://docs.docker.com/build/metadata/attestations/sbom/):** A
  comprehensive list of software artifacts included in the image or used during
  its build process, formatted using the [in-toto SPDX predicate standard](https://github.com/in-toto/attestation/blob/main/spec/predicates/spdx.md).

- **[Provenance](https://docs.docker.com/build/metadata/attestations/slsa-provenance/):**
  Metadata detailing how the image was built, following the [SLSA Provenance](https://slsa.dev)
  framework.

For example, you can retrieve the SBOM for a specific image using the following
command:

```bash
docker buildx imagetools inspect <IMAGE> --format "{{ json .SBOM.SPDX }}"
```

This command outputs the SBOM in JSON format, providing a detailed view of the
software components and build dependencies.

## Image Signatures

The [`minimal`](#minimal-images) and [`standard`](#standard-images) CloudNativePG container images are securely signed using
[cosign](https://github.com/sigstore/cosign), a tool within the
[Sigstore](https://www.sigstore.dev/) ecosystem.
This signing process is automated via GitHub Actions and leverages
[short-lived tokens issued through OpenID Connect](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect).

The token issuer is `https://token.actions.githubusercontent.com`, and the
signing identity corresponds to a GitHub workflow executed under the
`cloudnative-pg/postgres-containers` repository. This workflow uses the
[`cosign-installer` action](https://github.com/marketplace/actions/cosign-installer)
to facilitate the signing process.

To verify the authenticity of an image using its digest, you can run the
following `cosign` command:

```sh
cosign verify IMAGE \
  --certificate-identity-regexp="^https://github.com/cloudnative-pg/postgres-containers/" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com"
```

## Building Images

For detailed instructions on building PostgreSQL container images, refer to the
[BUILD.md](BUILD.md) file.

## Automatic Updating using Renovate

[Renovate](https://github.com/renovatebot/renovate) can be used to automatically update various dependencies.
As CloudNativePG's `Cluster` CRDs are not automatically picked up by renovate a custom regex manager must be configured:

```json5
{
  customManagers: [
    {
      // cloudnative-pg instance version
      customType: 'regex',
      managerFilePatterns: [
        '/\\.yaml$/',
      ],
      matchStrings: [
        'imageName: (?<depName>[^\\s:]+):(?<currentValue>[^\\s@]+)(?:@(?<currentDigest>sha256:[a-f0-9]+))?',
      ],
      datasourceTemplate: 'docker',
      // matches: 17.6-202509151215-minimal-trixie
      versioningTemplate: 'regex:^(?<major>\\d+)\\.(?<minor>\\d+)-(?<patch>\\d+)-(?<compatibility>\\S+)$',
      autoReplaceStringTemplate: '{{{newValue}}}{{#if newDigest}}@{{{newDigest}}}{{/if}}',
    }
  ]
}
```

Renovate will never change the `compatibility` part of the tag! So bumping from e.g., `trixie` to the next debian release must be done manually.

## License and copyright

This software is available under [Apache License 2.0](LICENSE).

Copyright The CloudNativePG Contributors.

Barman Cloud is distributed by EnterpriseDB under the
[GNU GPL 3 License](https://github.com/EnterpriseDB/barman/blob/master/LICENSE).

PGAudit is distributed under the
[PostgreSQL License](https://github.com/pgaudit/pgaudit/blob/master/LICENSE).

Postgres Failover Slots is distributed by EnterpriseDB under the
[PostgreSQL License](https://github.com/EnterpriseDB/pg_failover_slots/blob/master/LICENSE).

pgvector is distributed under the
[PostgreSQL License](https://github.com/pgvector/pgvector/blob/master/LICENSE).

## Trademarks

*[Postgres, PostgreSQL and the Slonik Logo](https://www.postgresql.org/about/policies/trademarks/)
are trademarks or registered trademarks of the PostgreSQL Community Association
of Canada, and used with their permission.*
