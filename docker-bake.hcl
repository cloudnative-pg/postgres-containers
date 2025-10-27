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
barmanFullname = ( environment == "testing") ? "${registry}/barman-testing" : "${registry}/barman"
now = timestamp()
authors = "The CloudNativePG Contributors"
url = "https://github.com/cloudnative-pg/postgres-containers"

// PostgreSQL versions to build
postgreSQLVersions = [
  "13.22",
  "14.19",
  "15.14",
  "16.10",
  "17.6",
  "18.0"
]

// PostgreSQL preview versions to build, such as "18~beta1" or "18~rc1"
// Preview versions are automatically filtered out if present in the stable list
// MANUALLY EDIT THE CONTENT - AND UPDATE THE README.md FILE TOO
postgreSQLPreviewVersions = [
]

// Barman version to build
// renovate: datasource=pypi versioning=loose depName=barman
barmanVersion = "3.16.1"

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
      "debian:trixie-slim@sha256:66b37a5078a77098bfc80175fb5eb881a3196809242fd295b25502854e12cbec",
      // renovate: datasource=docker versioning=loose
      "debian:bookworm-slim@sha256:78d2f66e0fec9e5a39fb2c72ea5e052b548df75602b5215ed01a17171529f706",
      // renovate: datasource=docker versioning=loose
      "debian:bullseye-slim@sha256:52927eff8153b563244f98cdc802ba97918afcdf67f9e4867cbf1f7afb3d147b"
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

target "barman" {
  matrix = {
    pgVersion = postgreSQLVersions
    base = [
      // renovate: datasource=docker versioning=loose
      "debian:trixie-slim@sha256:c85a2732e97694ea77237c61304b3bb410e0e961dd6ee945997a06c788c545bb",
      // renovate: datasource=docker versioning=loose
      "debian:bookworm-slim@sha256:b1a741487078b369e78119849663d7f1a5341ef2768798f7b7406c4240f86aef",
      // renovate: datasource=docker versioning=loose
      "debian:bullseye-slim@sha256:849d9d34d5fe0bf88b5fb3d09eb9684909ac4210488b52f4f7bbe683eedcb851"
    ]
    barmanVersion = [
      "3.14.1",
      "3.15.0"
    ]
  }
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]


  dockerfile = "Dockerfile.barman"
  name = "barman-${barmanVersion}-${distroVersion(base)}"
  tags = [
    "${barmanFullname}:${barmanVerison}-${distroVersion(base)}",
    "${barmanFullname}:${barmanVersion}-${formatdate("YYYYMMDDhhmm", now)}-${distroVersion(base)}"
  ]
  context = "."
  target = "barman"
  args = {
    BARMAN_VERSION = "${barmanVersion}"
    BASE = "${base}"
  }
  attest = [
    "type=provenance,mode=max",
    "type=sbom"
  ]
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
