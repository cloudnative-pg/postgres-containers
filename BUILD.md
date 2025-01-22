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
(see [Build Drivers](https://docs.docker.com/build/builders/drivers/) and
["Install QEMU Manually"](https://docs.docker.com/build/building/multi-platform/#install-qemu-manually)).
3. [Distribution Registry](https://distribution.github.io/distribution/):
Formerly known as Docker Registry, to host and manage the built images.

### Verifying Requirements

To confirm your environment is properly set up, run:

```bash
docker buildx bake --check
```

If errors appear, you may need to switch to a different build driver. For
example, use the following commands to configure a `docker-container` build
driver:

```bash
docker buildx create \
  --name docker-container \
  --driver docker-container \
  --use \
  --driver-opt network=host \
  --bootstrap
```

> *Note:* The `--driver-opt network=host` setting is required only for testing
> when you push to a distribution registry listening on `localhost`.

> *Note:* This page is not intended to serve as a comprehensive guide for
> building multi-architecture images with Docker and Bake. If you encounter any
> issues, please refer to the resources listed above for detailed instructions
> and troubleshooting.

## Default Target

The `default` target in Bake represents a Cartesian product of the following
dimensions:

- **Base Image**
- **Type** (e.g. `minimal` or `standard`)
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
target in the `VERSION-TYPE-BASE` format. For example, to build an image for
PostgreSQL 17 with the `minimal` format on the `bookworm` base image:

```bash
docker buildx bake --push postgresql-17-minimal-bookworm
```

You can also limit the build to a single platform, for example AMD64, with:

```bash
docker buildx bake --push --set "*.platform=linux/amd64"
```

The two can be mixed as well:

```bash
docker buildx bake --push \
  --set "*.platform=linux/amd64" \
  postgresql-17-minimal-bookworm
```

## The Distribution Registry

The images must be pushed to any registry server that complies with the **OCI
Distribution Specification**.

By default, the build process assumes a registry server running locally at
`localhost:5000`. To use a different registry, set the `registry` environment
variable when executing the `docker` command, as shown:

```bash
registry=<REGISTRY_URL> docker buildx ...
```

## Local Testing

You can test the image-building process locally if you meet the necessary
[prerequisites](prerequisites).

To do this, you'll need a local registry server. If you don't already have one,
you can deploy a temporary, disposable [distribution registry](https://distribution.github.io/distribution/about/deploying/)
with the following command:

```bash
docker run -d --rm -p 5000:5000 --name registry registry:2
```

This command runs a lightweight, temporary instance of the `registry:2`
container on port `5000`.

## Image Signing Workflow

Postgres operand images are securely signed with [cosign](https://github.com/sigstore/cosign)
based on their digest through a GitHub workflow, using the
[`cosign-installer` action](https://github.com/marketplace/actions/cosign-installer), which leverages
[short-lived tokens issued through OpenID Connect](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect).

## Trademarks

*[Postgres, PostgreSQL and the Slonik Logo](https://www.postgresql.org/about/policies/trademarks/)
are trademarks or registered trademarks of the PostgreSQL Community Association
of Canada, and used with their permission.*
