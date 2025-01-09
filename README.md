> **IMPORTANT:** As of January 2025, we have transitioned to a new image build
> process. Previously, the images were based on the
> [Official Postgres image](https://hub.docker.com/_/postgres), maintained by the
> [PostgreSQL Docker Community](https://github.com/docker-library/postgres),
> and included > Barman Cloud built from source.
> This legacy approach, referred to as `system` images, will remain available
> for backward compatibility but is planned for deprecation.

---

# PostgreSQL Container Images

This repository provides maintenance scripts to generate immutable application
containers for all supported PostgreSQL versions (13 to 17).

These images are designed to serve as operands for the
[CloudNativePG operator](https://cloudnative-pg.io)
inside Kubernetes and are available on the
[GitHub Container Registry](https://github.com/cloudnative-pg/postgres-containers/pkgs/container/postgresql).

Images are automatically rebuilt weekly on Mondays.

## Image Types

We currently build and support two primary types of images:

- [`minimal`](#minimal)
- [`standard`](#standard)

For backward compatibility, we also maintain the [`system`](#system-images) image type.

> *Note:* Switching from `system` images to `minimal` or `standard` images on
> an existing cluster is not supported.

Both `minimal` and `standard` images are intended to be used with backup
plugins, such as [Barman Cloud](https://github.com/cloudnative-pg/plugin-barman-cloud).

### System Images

System images are based on the [Official Postgres image](https://hub.docker.com/_/postgres), maintained by the
[PostgreSQL Docker Community](https://github.com/docker-library/postgres).
These images include additional software to extend PostgreSQL functionality:

- Barman Cloud
- PGAudit
- Postgres Failover Slots
- pgvector

The [`Debian`](Debian) folder contains image catalogs, which can be used as:
- [`ClusterImageCatalog`](https://cloudnative-pg.io/documentation/current/image_catalog/)
- [`ImageCatalog`](https://cloudnative-pg.io/documentation/current/image_catalog/)

> **Deprecation Notice:** System images and the associated Debian-based image
> catalogs will be deprecated in future releases of CloudNativePG and
> eventually removed. Users are encouraged to migrate to `minimal` or
> `standard` images as soon as feasible.

### Minimal

These images are build on top of [official Debian images](https://hub.docker.com/_/debian)
by installing PostgreSQL.

Minimal images include `minimal` in the tag name, e.g.
`17.2-standard-bookworm`.

### Standard

These images are build on top of the minimal images by adding the following
software:

- PGAudit
- Postgres Failover Slots
- pgvector

and all the locales.

Standard images include `standard` in the tag name, e.g.
`17.2-standard-bookworm`.

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
