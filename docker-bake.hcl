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

fullname = ( environment == "testing") ? "${registry}/postgresql-testing" : "{registry}/postgresql"
now = timestamp()

target "default" {
  matrix = {
    tgt = [
      "minimal",
      "standard"
    ]
    pgVersion = [
      "13.18",
      "14.15",
      "15.10",
      "16.6",
      "17.2"
    ]
    base = [
      // renovate: datasource=docker versioning=loose
      "debian:bookworm-slim@sha256:d365f4920711a9074c4bcd178e8f457ee59250426441ab2a5f8106ed8fe948eb",
      // renovate: datasource=docker versioning=loose
      "debian:bullseye-slim@sha256:b0c91cc181796d34c53f7ea106fbcddaf87f3e601cc371af6a24a019a489c980"
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
    BASE  = "${base}"
  }
  attest = [
    "type=provenance,mode=max",
    "type=sbom"
  ]
  annotations = [
    "index,manifest:org.opencontainers.image.created=${now}",
    "index,manifest:org.opencontainers.image.url=https://github.com/cloudnative-pg/postgres-containers",
    "index,manifest:org.opencontainers.image.source=https://github.com/cloudnative-pg/postgres-containers",
    "index,manifest:org.opencontainers.image.version=${pgVersion}",
    "index,manifest:org.opencontainers.image.revision=${revision}",
    "index,manifest:org.opencontainers.image.vendor=The CloudNativePG Contributors",
    "index,manifest:org.opencontainers.image.title=CloudNativePG PostgreSQL ${pgVersion} ${tgt}",
    "index,manifest:org.opencontainers.image.description=A ${tgt} PostgreSQL ${pgVersion} container image",
    "index,manifest:org.opencontainers.image.documentation=https://github.com/cloudnative-pg/postgres-containers",
    "index,manifest:org.opencontainers.image.authors=The CloudNativePG Contributors",
    "index,manifest:org.opencontainers.image.licenses=Apache-2.0",
    "index,manifest:org.opencontainers.image.base.name=docker.io/library/${tag(base)}",
    "index,manifest:org.opencontainers.image.base.digest=${digest(base)}"
  ]
  labels = {
    "org.opencontainers.image.created" = "${now}",
    "org.opencontainers.image.url" = "https://github.com/cloudnative-pg/postgres-containers",
    "org.opencontainers.image.source" = "https://github.com/cloudnative-pg/postgres-containers",
    "org.opencontainers.image.version" = "${pgVersion}",
    "org.opencontainers.image.revision" = "${revision}",
    "org.opencontainers.image.vendor" = "The CloudNativePG Contributors",
    "org.opencontainers.image.title" = "CloudNativePG PostgreSQL ${pgVersion} ${tgt}",
    "org.opencontainers.image.description" = "A ${tgt} PostgreSQL ${pgVersion} container image",
    "org.opencontainers.image.documentation" = "https://github.com/cloudnative-pg/postgres-containers",
    "org.opencontainers.image.authors" = "The CloudNativePG Contributors",
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
