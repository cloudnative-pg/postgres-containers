[![CloudNativePG](./logo/cloudnativepg.png)](https://cloudnative-pg.io/)

> **IMPORTANT:** Starting in August 2025, the [Official Postgres Image](https://hub.docker.com/_/postgres),
> maintained by the [PostgreSQL Docker Community](https://github.com/docker-library/postgres),
> has discontinued support for Debian `bullseye`.
> In response, the CloudNativePG project has completed the transition to the
> new `bake`-based build process for all `system` images. We now build directly
> on top of the official Debian slim images, fully detaching from the official
> Postgres image. Additional changes are planned as part of epic #287.

---

# CNPG PostgreSQL Container Images

This repository provides maintenance scripts for generating **immutable
application containers** for all supported PostgreSQL versions (13 to 17),
as well as for PostgreSQL 18 beta.

These containers are designed to serve as **operands** for the
[CloudNativePG (CNPG) operator](https://cloudnative-pg.io)
within Kubernetes environments.

## Key Features

The CNPG PostgreSQL Container Images:

- Are based on Debian Linux `stable` and `oldstable`
- Support **multi-architecture builds**, including `linux/amd64` and
  `linux/arm64`.
- Include **build attestations**, such as Software Bills of Materials (SBOMs)
  and provenance metadata.
- Are published on the
  [CloudNativePG GitHub Container Registry](https://github.com/cloudnative-pg/postgres-containers/pkgs/container/postgresql).
- Are **automatically rebuilt weekly** (every Monday) to ensure they remain
  up-to-date.

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
for example: `17.2-minimal-trixie`.

### Standard Images

Standard images are an extension of the `minimal` images, enhanced with the
following additional features:

- PGAudit
- Postgres Failover Slots
- pgvector
- All Locales

Standard images are identifiable by the `standard` tag in their names, such as:
`17.2-standard-trixie`.

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
