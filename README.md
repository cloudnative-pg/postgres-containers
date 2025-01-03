# PostgreSQL Container Images

Maintenance scripts to generate Immutable Application Containers
for all available PostgreSQL versions (13 to 17) to be used as
operands with the [CloudNativePG operator](https://cloudnative-pg.io)
for Kubernetes.

## Images

We build three types of images:
* [system](#system)
* [minimal](#minimal)
* [standard](#standard)

Switching from system images to minimal or standard images on an existing
cluster is not currently supported.

Minimal and standard images are supposed to be used alongside a backup plugin
like [Barman Cloud](https://github.com/cloudnative-pg/plugin-barman-cloud).

Images are available via
[GitHub Container Registry](https://github.com/cloudnative-pg/postgres-containers/pkgs/container/postgresql).

Currently, images are automatically rebuilt once a week (Monday).

### System

These images are built on top of the [Official Postgres image](https://hub.docker.com/_/postgres)
maintained by the [PostgreSQL Docker Community](https://github.com/docker-library/postgres),
by adding the following software:

- Barman Cloud
- PGAudit
- Postgres Failover Slots
- pgvector

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

## SBOMs

Software Bills of Materials (SBOMs) are available for minimal and standard
images. The SBOM for an image can be retrieved with the following command:

```shell
docker buildx imagetools inspect <IMAGE> --format "{{ json .SBOM.SPDX}}"
```

## Testing image builds

Minimal and standard image builds can be tested running bake manually.
You will need a container registry and a builder with the `docker-container`
driver.

```
registry=<REGISTRY_URL> docker buildx bake --builder <BUILDER> --push
```

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
