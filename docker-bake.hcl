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

extensions = [
  "pgaudit",
  "pgvector",
  "pg-failover-slots"
]

target "default" {
  matrix = {
    tgt = [
      "minimal",
      "standard"
    ]
    pgVersion = [
      "13.21",
      "14.18",
      "15.13",
      "16.9",
      "17.5",
      "18~beta2"
    ]
    base = [
      // renovate: datasource=docker versioning=loose
      "debian:bookworm-slim@sha256:b1a741487078b369e78119849663d7f1a5341ef2768798f7b7406c4240f86aef",
      // renovate: datasource=docker versioning=loose
      "debian:bullseye-slim@sha256:849d9d34d5fe0bf88b5fb3d09eb9684909ac4210488b52f4f7bbe683eedcb851"
    ]
  }
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
  dockerfile = "Dockerfile"
  name = "postgresql-${index(split(".",cleanVersion(pgVersion)),0)}-${tgt}-${distroVersion(base)}"
  tags = [
    "${fullname}:${index(split(".",cleanVersion(pgVersion)),0)}-${tgt}-${distroVersion(base)}",
    "${fullname}:${cleanVersion(pgVersion)}-${tgt}-${distroVersion(base)}",
    "${fullname}:${cleanVersion(pgVersion)}-${formatdate("YYYYMMDDhhmm", now)}-${tgt}-${distroVersion(base)}"
  ]
  context = "."
  target = "${tgt}"
  args = {
    PG_VERSION = "${pgVersion}"
    PG_MAJOR = "${getMajor(pgVersion)}"
    BASE = "${base}"
    EXTENSIONS = "${getExtensionsString(pgVersion, extensions)}"
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

function cleanVersion {
    params = [ version ]
    result = replace(version, "~", "")
}

function isBeta {
    params = [ version ]
    result = length(regexall("[0-9]+~beta.*", version)) > 0
}

function getMajor {
    params = [ version ]
    result = (isBeta(version) == true) ? index(split("~", version),0) : index(split(".", version),0)
}

function getExtensionsString {
    params = [ version, extensions ]
    result = (isBeta(version) == true) ? "" : join(" ", formatlist("postgresql-%s-%s", getMajor(version), extensions))
}
