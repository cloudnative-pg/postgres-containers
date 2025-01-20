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

# Image Signatures

Every image is signed using cosign and an ephemeral key with GitHub as the OIDC provider, the images can be
verify using the following command:

```shell
cosign verify --certificate-identity-regexp="https://github.com/cloudnative-pg/postgres-containers/.github/workflows/" \
--certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
ghcr.io/cloudnative-pg/postgresql(-testing)@<sha256 image>
```

Using the following image:
`ghcr.io/cloudnative-pg/postgresql-testing@sha256:e5d7aaf92103ecabd4ea4c109e49727692b1c47174fb77d8e17ef1e29685d7dd`
We can execute the following command with the following output

```shell
cosign verify --certificate-identity-regexp="https://github.com/cloudnative-pg/postgres-containers/.github/workflows/" --certificate-oidc-issuer="https://token.actions.githubusercontent.com" ghcr.io/cloudnative-pg/postgresql-testing@sha256:e5d7aaf92103ecabd4ea4c109e49727692b1c47174fb77d8e17ef1e29685d7dd | jq

Verification for ghcr.io/cloudnative-pg/postgresql-testing@sha256:e5d7aaf92103ecabd4ea4c109e49727692b1c47174fb77d8e17ef1e29685d7dd --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The code-signing certificate was verified using trusted certificate authority certificates
[
  {
    "critical": {
      "identity": {
        "docker-reference": "ghcr.io/cloudnative-pg/postgresql-testing"
      },
      "image": {
        "docker-manifest-digest": "sha256:e5d7aaf92103ecabd4ea4c109e49727692b1c47174fb77d8e17ef1e29685d7dd"
      },
      "type": "cosign container image signature"
    },
    "optional": {
      "1.3.6.1.4.1.57264.1.1": "https://token.actions.githubusercontent.com",
      "1.3.6.1.4.1.57264.1.2": "workflow_dispatch",
      "1.3.6.1.4.1.57264.1.3": "504be3a25448fa5277f712ee8df1ded1066ed164",
      "1.3.6.1.4.1.57264.1.4": "Bake images",
      "1.3.6.1.4.1.57264.1.5": "cloudnative-pg/postgres-containers",
      "1.3.6.1.4.1.57264.1.6": "refs/heads/dev/136",
      "Bundle": {
        "SignedEntryTimestamp": "MEQCIGTI2BU4HroJxyY5iSLckxjezt9j8HiVSkyNsRn2GfgBAiBwrfzC872HdkpjWD3p9VH6lxAQg3N+UAcyKlFO08EJBw==",
        "Payload": {
          "body": "eyJhcGlWZXJzaW9uIjoiMC4wLjEiLCJraW5kIjoiaGFzaGVkcmVrb3JkIiwic3BlYyI6eyJkYXRhIjp7Imhhc2giOnsiYWxnb3JpdGhtIjoic2hhMjU2IiwidmFsdWUiOiI2NGEyZjMzMGQzYTZkN2YwOTBlNmEzNWQ0MWI1ZDljZGM1ZDQ1YzRhZTRhNWYwNTk1YTZiNjIzN2QzNzBkOWIxIn19LCJzaWduYXR1cmUiOnsiY29udGVudCI6Ik1FWUNJUUMvMGdYamRVNThhbG1OQ2pRUjVmb0RUK2JCcmlWa2UyNUNUeGNlM2FSem5BSWhBUFRyeUFMRHdGTDFOTjgrVVpxTGZSWHFwNjJtcld5VUpLNXlqSXhPYUVlMSIsInB1YmxpY0tleSI6eyJjb250ZW50IjoiTFMwdExTMUNSVWRKVGlCRFJWSlVTVVpKUTBGVVJTMHRMUzB0Q2sxSlNVaFBWRU5EUW5JclowRjNTVUpCWjBsVllXMVdURFpXVERWSVFuTnJhbUZGTjNKaE9FRnBMMFp3UzBKUmQwTm5XVWxMYjFwSmVtb3dSVUYzVFhjS1RucEZWazFDVFVkQk1WVkZRMmhOVFdNeWJHNWpNMUoyWTIxVmRWcEhWakpOVWpSM1NFRlpSRlpSVVVSRmVGWjZZVmRrZW1SSE9YbGFVekZ3WW01U2JBcGpiVEZzV2tkc2FHUkhWWGRJYUdOT1RXcFZkMDFVU1hkTlZGa3dUa1JOTVZkb1kwNU5hbFYzVFZSSmQwMVVXVEZPUkUweFYycEJRVTFHYTNkRmQxbElDa3R2V2tsNmFqQkRRVkZaU1V0dldrbDZhakJFUVZGalJGRm5RVVZtVDIxb2QwVlhPVXBxUm5sMmRFczJRbkJ1Ym1WeE1GWlhUMk5vTjJwcVVUTkNNWFFLYm5scWRGWXZUVlE1Y1VWb1J6WXhORlpoVVhaM2FVVmxTVmRLTVRCaVIzaENjWHB5YkhoQ2FsaFNPV1psUVZaMGIyRlBRMEprTkhkbloxaGhUVUUwUndwQk1WVmtSSGRGUWk5M1VVVkJkMGxJWjBSQlZFSm5UbFpJVTFWRlJFUkJTMEpuWjNKQ1owVkdRbEZqUkVGNlFXUkNaMDVXU0ZFMFJVWm5VVlUwWlUxMENuUmxWekZ5ZGt4RFQxWlZUR0phTVhSVU1GVk9RMnMwZDBoM1dVUldVakJxUWtKbmQwWnZRVlV6T1ZCd2VqRlphMFZhWWpWeFRtcHdTMFpYYVhocE5Ga0tXa1E0ZDJObldVUldVakJTUVZGSUwwSkhaM2RhYjFwcllVaFNNR05JVFRaTWVUbHVZVmhTYjJSWFNYVlpNamwwVERKT2MySXpWbXRpYlVZd1lWaGFiQXBNV0VKdVRETkNkbU16VW01amJWWjZURmRPZG1KdVVtaGhWelZzWTI1TmRreHRaSEJrUjJneFdXazVNMkl6U25KYWJYaDJaRE5OZGxsdFJuSmFVelUxQ2xsWE1YTlJTRXBzV201TmRtRkhWbWhhU0UxMldrZFdNa3g2UlhwT2FrRTFRbWR2Y2tKblJVVkJXVTh2VFVGRlFrSkRkRzlrU0ZKM1kzcHZka3d6VW5ZS1lUSldkVXh0Um1wa1IyeDJZbTVOZFZveWJEQmhTRlpwWkZoT2JHTnRUblppYmxKc1ltNVJkVmt5T1hSTlFqaEhRMmx6UjBGUlVVSm5OemgzUVZGSlJRcEZXR1IyWTIxMGJXSkhPVE5ZTWxKd1l6TkNhR1JIVG05TlJGbEhRMmx6UjBGUlVVSm5OemgzUVZGTlJVdEVWWGRPUjBwc1RUSkZlVTVVVVRCUFIxcG9DazVVU1ROT01sa3pUVlJLYkZwVWFHdGFha1pyV2xkUmVFMUVXVEphVjFGNFRtcFJkMGRSV1V0TGQxbENRa0ZIUkhaNlFVSkNRVkZNVVcxR2NscFRRbkFLWWxkR2JscFlUWGROUVZsTFMzZFpRa0pCUjBSMmVrRkNRbEZSYVZreWVIWmtWMUoxV1ZoU2NHUnRWWFJqUjJOMlkwYzVlbVJIWkhsYVdFMTBXVEk1ZFFwa1IwWndZbTFXZVdONlFXZENaMjl5UW1kRlJVRlpUeTlOUVVWSFFrSktlVnBYV25wTU1taHNXVmRTZWt3eVVteGthVGg0VFhwWmQwOTNXVXRMZDFsQ0NrSkJSMFIyZWtGQ1EwRlJkRVJEZEc5a1NGSjNZM3B2ZGt3elVuWmhNbFoxVEcxR2FtUkhiSFppYmsxMVdqSnNNR0ZJVm1sa1dFNXNZMjFPZG1KdVVtd0tZbTVSZFZreU9YUk5TRkZIUTJselIwRlJVVUpuTnpoM1FWRnJSVnBuZUd0aFNGSXdZMGhOTmt4NU9XNWhXRkp2WkZkSmRWa3lPWFJNTWs1ellqTldhd3BpYlVZd1lWaGFiRXhZUW01TU0wSjJZek5TYm1OdFZucE1WMDUyWW01U2FHRlhOV3hqYmsxMlRHMWtjR1JIYURGWmFUa3pZak5LY2xwdGVIWmtNMDEyQ2xsdFJuSmFVelUxV1ZjeGMxRklTbXhhYmsxMllVZFdhRnBJVFhaYVIxWXlUSHBGZWs1cVFUUkNaMjl5UW1kRlJVRlpUeTlOUVVWTFFrTnZUVXRFVlhjS1RrZEtiRTB5UlhsT1ZGRXdUMGRhYUU1VVNUTk9NbGt6VFZSS2JGcFVhR3RhYWtacldsZFJlRTFFV1RKYVYxRjRUbXBSZDBoUldVdExkMWxDUWtGSFJBcDJla0ZDUTNkUlVFUkJNVzVoV0ZKdlpGZEpkR0ZIT1hwa1IxWnJUVVZWUjBOcGMwZEJVVkZDWnpjNGQwRlJkMFZPZDNjeFlVaFNNR05JVFRaTWVUbHVDbUZZVW05a1YwbDFXVEk1ZEV3eVRuTmlNMVpyWW0xR01HRllXbXhNV0VKdVRETkNkbU16VW01amJWWjZURmRPZG1KdVVtaGhWelZzWTI1TmQwOUJXVXNLUzNkWlFrSkJSMFIyZWtGQ1JGRlJjVVJEWnpGTlJGSnBXbFJPYUUxcVZUQk9SR2h0V1ZSVmVVNTZaRzFPZWtWNVdsZFZORnBIV1hoYVIxWnJUVlJCTWdwT2JWWnJUVlJaTUUxRFNVZERhWE5IUVZGUlFtYzNPSGRCVVRSRlJrRjNVMk50Vm0xamVUbHZXbGRHYTJONU9XdGFXRmwyVFZSTk1rMUNhMGREYVhOSENrRlJVVUpuTnpoM1FWRTRSVU4zZDBwT1JHTjNUbFJGTkUxNmEzcE5SRVZIUTJselIwRlJVVUpuTnpoM1FWSkJSVWwzZDJoaFNGSXdZMGhOTmt4NU9XNEtZVmhTYjJSWFNYVlpNamwwVERKT2MySXpWbXRpYlVZd1lWaGFiRXhZUW01TlFtdEhRMmx6UjBGUlVVSm5OemgzUVZKRlJVTjNkMHBOVkVGM1RYcGplZ3BQUkZWNVRVaFJSME5wYzBkQlVWRkNaemM0ZDBGU1NVVmFaM2hyWVVoU01HTklUVFpNZVRsdVlWaFNiMlJYU1hWWk1qbDBUREpPYzJJelZtdGliVVl3Q21GWVdteE1XRUp1VEROQ2RtTXpVbTVqYlZaNlRGZE9kbUp1VW1oaFZ6VnNZMjVOZGt4dFpIQmtSMmd4V1drNU0ySXpTbkphYlhoMlpETk5kbGx0Um5JS1dsTTFOVmxYTVhOUlNFcHNXbTVOZG1GSFZtaGFTRTEyV2tkV01reDZSWHBPYWtFMFFtZHZja0puUlVWQldVOHZUVUZGVkVKRGIwMUxSRlYzVGtkS2JBcE5Na1Y1VGxSUk1FOUhXbWhPVkVrelRqSlpNMDFVU214YVZHaHJXbXBHYTFwWFVYaE5SRmt5V2xkUmVFNXFVWGRKVVZsTFMzZFpRa0pCUjBSMmVrRkNDa1pCVVZSRVFrWXpZak5LY2xwdGVIWmtNVGxyWVZoT2QxbFlVbXBoUkVKd1FtZHZja0puUlVWQldVOHZUVUZGVmtKR2MwMVhWMmd3WkVoQ2VrOXBPSFlLV2pKc01HRklWbWxNYlU1MllsTTVhbUpIT1RGYVJ6Vm9aRWRzTWxwVE1YZGFlVGwzWWpOT01Gb3pTbXhqZVRGcVlqSTFNRmxYYkhWYVdFcDZUREpHYWdwa1IyeDJZbTVOZG1OdVZuVmplVGg0VFdwbk0wMXFVWGRQUkZVMVRrTTVhR1JJVW14aVdFSXdZM2s0ZUUxQ1dVZERhWE5IUVZGUlFtYzNPSGRCVWxsRkNrTkJkMGRqU0ZacFlrZHNhazFKUjB4Q1oyOXlRbWRGUlVGa1dqVkJaMUZEUWtnd1JXVjNRalZCU0dOQk0xUXdkMkZ6WWtoRlZFcHFSMUkwWTIxWFl6TUtRWEZLUzFoeWFtVlFTek12YURSd2VXZERPSEEzYnpSQlFVRkhWV2hLYjB4eVowRkJRa0ZOUVZORVFrZEJhVVZCYXpjMlNURmlibFF2VGtkcFYxTnNjd3BVUXpNeE1WZHhkSFFyVEZodlJVWnZRbmM1Y0ZCdFNVVjFPVkZEU1ZGRE9YbHJRM051VUc5TVpqaExhVTlpUmxCWllsUlRLM1ZKTkZkU2RrUXZMMnN6Q2twWGRWbFRhbUZzVFdwQlMwSm5aM0ZvYTJwUFVGRlJSRUYzVG05QlJFSnNRV3BCYVdkQ1Z5OWlPV1FyVkZsVE0yeFFLMEZaU0dsalMwTnFRVzVqTVd3S1JrSnFjSGxhUmpkaWVpdGFieTlUTkZwVlRGcGFaVVE1VmxKdmVGVlBRMWhZVFRoRFRWRkRWbFpXZWpSS0t6WmhVV1UzYW1KR04zSTVhak5DYjFaSGFncFVlR1J1VVZKMlNXSmxOR3hrUmxaeFpIbENObmhTTVhwcVYybEtRamxPTTFCa2NGWm5SR3M5Q2kwdExTMHRSVTVFSUVORlVsUkpSa2xEUVZSRkxTMHRMUzBLIn19fX0=",
          "integratedTime": 1737391476,
          "logIndex": 163912591,
          "logID": "c0d23d6ad406973f9559f3ba2d1ca01f84147d8ffc5b8445c224f98b9591801d"
        }
      },
      "Issuer": "https://token.actions.githubusercontent.com",
      "Subject": "https://github.com/cloudnative-pg/postgres-containers/.github/workflows/bake.yaml@refs/heads/dev/136",
      "githubWorkflowName": "Bake images",
      "githubWorkflowRef": "refs/heads/dev/136",
      "githubWorkflowRepository": "cloudnative-pg/postgres-containers",
      "githubWorkflowSha": "504be3a25448fa5277f712ee8df1ded1066ed164",
      "githubWorkflowTrigger": "workflow_dispatch"
    }
  }
]
```



## Trademarks

*[Postgres, PostgreSQL and the Slonik Logo](https://www.postgresql.org/about/policies/trademarks/)
are trademarks or registered trademarks of the PostgreSQL Community Association
of Canada, and used with their permission.*
