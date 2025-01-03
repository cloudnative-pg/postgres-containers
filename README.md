# PostgreSQL Container Images

Maintenance scripts to generate Immutable Application Containers
for all available PostgreSQL versions (13 to 17) to be used as
operands with the [CloudNativePG operator](https://cloudnative-pg.io)
for Kubernetes.

Currently, images are automatically rebuilt once a week (Monday).

Images are available via
[GitHub Container Registry](https://github.com/cloudnative-pg/postgres-containers/pkgs/container/postgresql).

## Older Images  

In January 2025, we transitioned to a new image build process.
The previous system, which relied on the [Official Postgres image](https://hub.docker.com/_/postgres)
maintained by the [PostgreSQL Docker Community](https://github.com/docker-library/postgres),
included Barman Cloud built from source. This legacy system will be retained
for backward compatibility but is slated for eventual deprecation.  

The [`Debian`](Debian) folder contains the image catalogues to be used as
[`ClusterImageCatalog`](https://cloudnative-pg.io/documentation/current/image_catalog/)
and
[`ImageCatalog`](https://cloudnative-pg.io/documentation/current/image_catalog/).  

## License and copyright

This software is available under [Apache License 2.0](LICENSE).

Copyright The CloudNativePG Contributors.

## Trademarks

*[Postgres, PostgreSQL and the Slonik Logo](https://www.postgresql.org/about/policies/trademarks/)
are trademarks or registered trademarks of the PostgreSQL Community Association
of Canada, and used with their permission.*

