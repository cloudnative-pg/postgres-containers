# PostgreSQL Container Images

Maintenance scripts to generate Immutable Application Containers
for all available PostgreSQL versions (12 to 16) to be used as
operands with the [CloudNativePG operator](https://cloudnative-pg.io)
for Kubernetes.

These images are built on top of the [Official Postgres image](https://hub.docker.com/_/postgres)
maintained by the [PostgreSQL Docker Community](https://github.com/docker-library/postgres),
by adding the following software:

- Barman Cloud
- PGAudit
- Postgres Failover Slots
- pgvector
- wal2json

Barman Cloud is distributed by EnterpriseDB under the
[GNU GPL 3 License](https://github.com/EnterpriseDB/barman/blob/master/LICENSE).

PGAudit is distributed under the
[PostgreSQL License](https://github.com/pgaudit/pgaudit/blob/master/LICENSE).

Postgres Failover Slots is distributed by EnterpriseDB under the
[PostgreSQL License](https://github.com/EnterpriseDB/pg_failover_slots/blob/master/LICENSE).

pgvector is distributed under the
[PostgreSQL License](https://github.com/pgvector/pgvector/blob/master/LICENSE).

wal2json is distributed under the
[BSD-3-Clause License](https://github.com/eulerto/wal2json/blob/master/LICENSE)

Images are available via
[GitHub Container Registry](https://github.com/cloudnative-pg/postgres-containers/pkgs/container/postgresql).

## License and copyright

This software is available under [Apache License 2.0](LICENSE).

Copyright The CloudNativePG Contributors.

## Trademarks

*[Postgres, PostgreSQL and the Slonik Logo](https://www.postgresql.org/about/policies/trademarks/)
are trademarks or registered trademarks of the PostgreSQL Community Association
of Canada, and used with their permission.*

