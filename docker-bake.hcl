variable "environment" {
  default = "testing"
  validation {
    condition = contains(["testing", "production"], environment)
    error_message = "environment must be either testing or production"
  }
}

variable "registry" {
  default = "localhost:5000"
}

// Use the revision variable to identify the commit that generated the image
variable "revision" {
  default = ""
}

fullname = ( environment == "testing") ? "${registry}/postgresql-testing" : "${registry}/postgresql"
now = timestamp()
authors = "The CloudNativePG Contributors"
url = "https://github.com/cloudnative-pg/postgres-containers"

target "default" {
  matrix = {
    tgt = [
      "minimal",
      "standard"
    ]
    pgVersion = [
      "13.20",
      "14.17",
      "15.12",
      "16.8",
      "17.4"
    ]
    base = [
      // renovate: datasource=docker versioning=loose
      "debian:bookworm-slim@sha256:1209d8fd77def86ceb6663deef7956481cc6c14a25e1e64daec12c0ceffcc19d",
      // renovate: datasource=docker versioning=loose
      "debian:bullseye-slim@sha256:e4b93db6aad977a95aa103917f3de8a2b16ead91cf255c3ccdb300c5d20f3015"
    ]
  }
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
  dockerfile = "Dockerfile"
  name = "postgresql-${index(split(".",pgVersion),0)}-${tgt}-${distroVersion(base)}"
  tags = [
    "${fullname}:${index(split(".",pgVersion),0)}-${tgt}-${distroVersion(base)}",
    "${fullname}:${pgVersion}-${tgt}-${distroVersion(base)}",
    "${fullname}:${pgVersion}-${formatdate("YYYYMMDDhhmm", now)}-${tgt}-${distroVersion(base)}"
  ]
  context = "."
  target = "${tgt}"
  args = {
    PG_VERSION = "${pgVersion}"
    BASE = "${base}"
  }
  attest = [
    "type=provenance,mode=max",
    "type=sbom"
  ]
  annotations = [
    "index,manifest:org.opencontainers.image.created=${now}",
    "index,manifest:org.opencontainers.image.url=${url}",
    "index,manifest:org.opencontainers.image.source=${url}",
    "index,manifest:org.opencontainers.image.version=${pgVersion}",
    "index,manifest:org.opencontainers.image.revision=${revision}",
    "index,manifest:org.opencontainers.image.vendor=${authors}",
    "index,manifest:org.opencontainers.image.title=CloudNativePG PostgreSQL ${pgVersion} ${tgt}",
    "index,manifest:org.opencontainers.image.description=A ${tgt} PostgreSQL ${pgVersion} container image",
    "index,manifest:org.opencontainers.image.documentation=https://github.com/cloudnative-pg/postgres-containers",
    "index,manifest:org.opencontainers.image.authors=${authors}",
    "index,manifest:org.opencontainers.image.licenses=Apache-2.0",
    "index,manifest:org.opencontainers.image.base.name=docker.io/library/${tag(base)}",
    "index,manifest:org.opencontainers.image.base.digest=${digest(base)}"
  ]
  labels = {
    "org.opencontainers.image.created" = "${now}",
    "org.opencontainers.image.url" = "${url}",
    "org.opencontainers.image.source" = "${url}",
    "org.opencontainers.image.version" = "${pgVersion}",
    "org.opencontainers.image.revision" = "${revision}",
    "org.opencontainers.image.vendor" = "${authors}",
    "org.opencontainers.image.title" = "CloudNativePG PostgreSQL ${pgVersion} ${tgt}",
    "org.opencontainers.image.description" = "A ${tgt} PostgreSQL ${pgVersion} container image",
    "org.opencontainers.image.documentation" = "${url}",
    "org.opencontainers.image.authors" = "${authors}",
    "org.opencontainers.image.licenses" = "Apache-2.0"
    "org.opencontainers.image.base.name" = "docker.io/library/debian:${tag(base)}"
    "org.opencontainers.image.base.digest" = "${digest(base)}"
  }
}

function tag {
  params = [ imageNameWithSha ]
  result = index(split("@", index(split(":", imageNameWithSha), 1)), 0)
}

function distroVersion {
  params = [ imageNameWithSha ]
  result = index(split("-", tag(imageNameWithSha)), 0)
}

function digest {
  params = [ imageNameWithSha ]
  result = index(split("@", imageNameWithSha), 1)
}
