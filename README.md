# PostgreSQL Container Images

Maintenance scripts to generate Immutable Application Containers
for all available PostgreSQL versions (10 to 14) to be used as
operands with the [CloudNativePG operator](https://cloudnative-pg.io)
for Kubernetes. PostgreSQL 15 beta images are also available for evaluation
and testing.

These images are built on top of the [Official Postgres image](https://hub.docker.com/_/postgres)
maintained by the [PostgreSQL Docker Community](https://github.com/docker-library/postgres),
by adding the following software:

- Barman Cloud
- PGAudit

Barman Cloud is distributed by EnterpriseDB under the
[GNU GPL 3 License](https://github.com/2ndquadrant-it/barman/blob/master/LICENSE).

PGAudit is distributed under the
[PostgreSQL License](https://github.com/pgaudit/pgaudit/blob/master/LICENSE).

Images are available via
[GitHub Container Registry](https://github.com/cloudnative-pg/postgres-containers/pkgs/container/postgresql).

## License and copyright

This software is available under [Apache License 2.0](LICENSE).

Copyright The CloudNativePG Contributors.

## Trademarks

*[Postgres, PostgreSQL and the Slonik Logo](https://www.postgresql.org/about/policies/trademarks/)
are trademarks or registered trademarks of the PostgreSQL Community Association
of Canada, and used with their permission.*

