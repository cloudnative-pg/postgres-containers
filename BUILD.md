# Building PostgreSQL Container Images for CloudNativePG

This guide outlines the process for building PostgreSQL operand images for
CloudNativePG using [Docker Bake](https://docs.docker.com/build/bake/) and a
[GitHub workflow](.github/workflows/bake.yaml).

The central component of this framework is the
[Bake file (`docker-bake.hcl`)](docker-bake.hcl).

## Prerequisites

Ensure the following tools and components are available before proceeding:

1. [Docker Buildx](https://github.com/docker/buildx): A CLI plugin for advanced
image building.
2. Build Driver for Multi-Architecture Images: For example, `docker-container`
(see [Build Drivers](https://docs.docker.com/build/builders/drivers/)).
3. [Distribution Registry](https://distribution.github.io/distribution/):
Formerly known as Docker Registry, to host and manage the built images.

## Verifying Requirements

To confirm your environment is properly set up, run:

```bash
docker buildx bake --check
```

If warnings appear, you may need to switch to a different build driver (e.g.,
`docker-container`). Use the following commands to configure it:

```bash
docker buildx create --driver docker-container --name docker-container
docker buildx use docker-container
```

## Default Target

The `default` target in Bake represents a Cartesian product of the following
dimensions:

- **Base Image**
- **Format** (e.g. `minimal` or `standard`)
- **Platforms**
- **PostgreSQL Versions**

## Building Images

To build PostgreSQL images using the `default` target — that is, for all the
combinations of base image, format, platforms, and PostgreSQL versions — run:

```bash
docker buildx bake --push
```

> *Note:* The `--push` flag is required to upload the images to the registry.
> Without it, the images will remain cached within the builder container,
> making testing impossible.

If you want to limit the build to a specific combination, you can specify the
target in the `VERSION-FORMAT-BASE` format. For example, to build an image for
PostgreSQL 17 with the `minimal` format on the `bullseye` base image:

```bash
docker buildx bake --push postgresql-17-minimal-bullseye
```

You can also limit the build to a single platform, for example AMD64, with:

```bash
docker buildx bake --set *.platform=linux/amd6
```

## SBOMs

Software Bills of Materials (SBOMs) are available for minimal and standard
images. The SBOM for an image can be retrieved with the following command:

```shell
docker buildx imagetools inspect <IMAGE> --format "{{ json .SBOM.SPDX}}"
```

## Trademarks

*[Postgres, PostgreSQL and the Slonik Logo](https://www.postgresql.org/about/policies/trademarks/)
are trademarks or registered trademarks of the PostgreSQL Community Association
of Canada, and used with their permission.*
