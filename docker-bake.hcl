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

// PostgreSQL versions to build
postgreSQLVersions = [
  "14.23",
  "15.18",
  "16.14",
  "17.10",
  "18.4"
]

// PostgreSQL preview versions to build, such as "18~beta1" or "18~rc1"
// Preview versions are automatically filtered out if present in the stable list
// MANUALLY EDIT THE CONTENT - AND UPDATE THE README.md FILE TOO
postgreSQLPreviewVersions = [
  "19~beta1",
]

// Barman version to build
// renovate: datasource=pypi versioning=loose depName=barman
barmanVersion = "3.19.1"

// Extensions to be included in the `standard` image
extensions = [
  "pgaudit",
  "pgvector",
  "pg-failover-slots"
]

target "default" {
  matrix = {
    tgt = [
      "minimal",
      "standard",
      "system"
    ]
    // Get the list of PostgreSQL versions, filtering preview versions if already stable
    pgVersion = getPgVersions(postgreSQLVersions, postgreSQLPreviewVersions)
    base = [
      // renovate: datasource=docker versioning=loose
      "debian:trixie-slim@sha256:28de0877c2189802884ccd20f15ee41c203573bd87bb6b883f5f46362d24c5c2",
      // renovate: datasource=docker versioning=loose
      "debian:bookworm-slim@sha256:60eac759739651111db372c07be67863818726f754804b8707c90979bda511df",
      // renovate: datasource=docker versioning=loose
      "debian:bullseye-slim@sha256:f18adf4e1d04b1d8ba48025b8e35003f4c748ddd3dd8e875fe4e7d9a9c0dec84"
    ]
  }
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
  dockerfile = "Dockerfile"
  name = "postgresql-${index(split(".",cleanVersion(pgVersion)),0)}-${tgt}-${distroVersion(base)}"
  tags = concat([
    "${fullname}:${index(split(".",cleanVersion(pgVersion)),0)}-${tgt}-${distroVersion(base)}",
    "${fullname}:${cleanVersion(pgVersion)}-${tgt}-${distroVersion(base)}",
    "${fullname}:${cleanVersion(pgVersion)}-${formatdate("YYYYMMDDhhmm", now)}-${tgt}-${distroVersion(base)}",
  ], (tgt == "system" && distroVersion(base) == "bullseye" && isPreview(pgVersion) == false) ? getRollingTags("${fullname}", pgVersion) : [])
  context = "."
  target = "${tgt}"
  args = {
    PG_VERSION = "${pgVersion}"
    PG_MAJOR = "${getMajor(pgVersion)}"
    BASE = "${base}"
    EXTENSIONS = "${getExtensionsString(pgVersion, extensions)}"
    STANDARD_ADDITIONAL_POSTGRES_PACKAGES = "${getStandardAdditionalPostgresPackagesPerMajorVersion(getMajor(pgVersion))}"
    BARMAN_VERSION = "${barmanVersion}"
  }
  output = [
    "type=image,oci-mediatypes=true,oci-artifact=true",
  ]
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
    "index,manifest:org.opencontainers.image.documentation=${url}",
    "index,manifest:org.opencontainers.image.authors=${authors}",
    "index,manifest:org.opencontainers.image.licenses=Apache-2.0",
    "index,manifest:org.opencontainers.image.base.name=docker.io/library/debian:${tag(base)}",
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

function isPreview {
    params = [ version ]
    result = length(regexall("[0-9]+~(alpha|beta|rc).*", version)) > 0
}

function getMajor {
    params = [ version ]
    result = (isPreview(version) == true) ? index(split("~", version),0) : index(split(".", version),0)
}

function getExtensionsString {
    params = [ version, extensions ]
    result = (isPreview(version) == true) ? "" : join(" ", formatlist("postgresql-%s-%s", getMajor(version), extensions))
}

// This function conditionally adds recommended PostgreSQL packages based on
// the version. For example, starting with version 18, PGDG moved `jit` out of
// the main package and into a separate one.
function getStandardAdditionalPostgresPackagesPerMajorVersion {
    params = [ majorVersion ]
    // Add PostgreSQL jit package from version 18
    result = join(" ", [
      majorVersion < 18 ? "" : format("postgresql-%s-jit", majorVersion)
    ])
}

function isMajorPresent {
  params = [major, pgVersions]
  result = contains([for v in pgVersions : getMajor(v)], major)
}

function getPgVersions {
  params = [stableVersions, previewVersions]
  // Remove any preview version if already present as stable
  result = concat(stableVersions,
    [
      for v in previewVersions : v
      if !isMajorPresent(getMajor(v), stableVersions)
    ]
  )
}

function getRollingTags {
    params = [ imageName, pgVersion ]
    result = [
      format("%s:%s", imageName, pgVersion),
      format("%s:%s", imageName, getMajor(pgVersion))
    ]
}
