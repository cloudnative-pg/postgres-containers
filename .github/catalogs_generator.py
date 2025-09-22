#
# Copyright © contributors to CloudNativePG, established as
# CloudNativePG a Series of LF Projects, LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0
#

import argparse
import re
import json
import os
import time
import yaml
import urllib.request
from packaging import version
from subprocess import check_output

supported_img_types = ["minimal", "standard", "system"]
supported_os_names = ["bullseye", "bookworm", "trixie"]
min_supported_major = 13

default_registry = "ghcr.io/cloudnative-pg/postgresql"
default_regex = r"(\d+)(?:\.\d+|beta\d+|rc\d+|alpha\d+)-(\d{12})"
_token_cache = {"value": None, "expires_at": 0}

normalized_pattern = re.compile(
    r"""
    ^(?P<pg_version>\d+(?:\.\d+|beta\d+|rc\d+|alpha\d+)) # A mandatory PostgreSQL version
    (?:-(?P<extension_version>\d+(?:\.\d+)+))?           # An optional extension version
    (?:-(?P<timestamp>\d{12}))?                          # An optional timestamp
    $
    """,
    re.VERBOSE,
)


# Normalize a tag to make it a valid PEP 440 version.
# Optional capture groups after the Postgres version will
# be appended using a "+"" as a local version segment, and
# concatenated with "." in case there's more then one.
def normalize_tag(tag):
    match = normalized_pattern.match(tag)
    if not match:
        raise ValueError(f"Unrecognized tag format: {tag}")

    pg_version = match.group("pg_version")
    extension_version = match.group("extension_version")
    timestamp = match.group("timestamp")

    # Build PEP 440 compliant version
    # e.g 17.6, 17.6+202509161052, 17.6+3.6.0.202509161052
    extra_match = []
    if extension_version:
        extra_match.append(extension_version)
    if timestamp:
        extra_match.append(timestamp)

    if extra_match:
        normalized_tag = f"{pg_version}+{'.'.join(extra_match)}"
    else:
        normalized_tag = pg_version

    return version.Version(normalized_tag)


def get_json(image_name):
    data = check_output(
        [
            "docker",
            "run",
            "--rm",
            "quay.io/skopeo/stable",
            "list-tags",
            f"docker://{image_name}",
        ]
    )
    repo_json = json.loads(data.decode("utf-8"))
    return repo_json


def get_token(image_name):
    global _token_cache
    now = time.time()

    if _token_cache["value"] and now < _token_cache["expires_at"]:
        return _token_cache["value"]

    url = "https://ghcr.io/token?scope=repository:{}:pull".format(image_name)
    with urllib.request.urlopen(url) as response:
        data = json.load(response)
        token = data["token"]

    _token_cache["value"] = token
    _token_cache["expires_at"] = now + 300
    return token


def get_digest(repository_name, tag):
    image_name = repository_name.removeprefix("ghcr.io/")
    token = get_token(image_name)
    media_types = [
        "application/vnd.oci.image.index.v1+json",
        "application/vnd.oci.image.manifest.v1+json",
        "application/vnd.docker.distribution.manifest.v2+json",
    ]
    url = f"https://ghcr.io/v2/{image_name}/manifests/{tag}"
    req = urllib.request.Request(url)
    req.add_header("Authorization", "Bearer {}".format(token))
    req.add_header("Accept", ",".join(media_types))
    with urllib.request.urlopen(req) as response:
        digest = response.headers.get("Docker-Content-Digest")
        return digest


def write_catalog(tags, version_re, img_type, os_name, output_dir="."):
    image_suffix = f"-{img_type}-{os_name}"
    version_re = re.compile(rf"^{version_re}{re.escape(image_suffix)}$")

    # Filter out all the tags which do not match the version regexp
    tags = [item for item in tags if version_re.search(item)]

    # Filter out preview versions
    exclude_preview = re.compile(r"(alpha|beta|rc)")
    tags = [item for item in tags if not exclude_preview.search(item)]

    # Sort the tags according to semantic versioning
    tags.sort(key=lambda v: normalize_tag(v.removesuffix(image_suffix)), reverse=True)

    results = {}
    for item in tags:
        match = version_re.search(item)
        if not match:
            continue

        major = match.group(1)

        # Skip too old versions
        if int(major) < min_supported_major:
            continue

        if major not in results:
            digest = get_digest(args.registry, item)
            results[major] = [f"{args.registry}:{item}@{digest}"]

    catalog = {
        "apiVersion": "postgresql.cnpg.io/v1",
        "kind": "ClusterImageCatalog",
        "metadata": {
            "name": f"postgresql{image_suffix}",
            "labels": {
                "images.cnpg.io/family": "postgresql",
                "images.cnpg.io/type": img_type,
                "images.cnpg.io/os": os_name,
                "images.cnpg.io/date": time.strftime("%Y%m%d"),
                "images.cnpg.io/publisher": "cnpg.io",
            },
        },
        "spec": {
            "images": [
                {"major": int(major), "image": images[0]}
                for major, images in sorted(results.items(), key=lambda x: int(x[0]))
            ]
        },
    }

    os.makedirs(output_dir, exist_ok=True)
    output_file = os.path.join(output_dir, f"catalog{image_suffix}.yaml")
    with open(output_file, "w") as f:
        yaml.dump(catalog, f, sort_keys=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="CloudNativePG ClusterImageCatalog YAML generator"
    )
    parser.add_argument(
        "--registry",
        default=default_registry,
        help=f"The registry to interrogate (default: {default_registry})",
    )
    parser.add_argument(
        "--output-dir", default=".", help="Directory to save the YAML files"
    )
    parser.add_argument(
        "--regex",
        default=default_regex,
        help=f"The regular expression used to retrieve container image. The first capturing group must be the PostgreSQL major version. (default: {default_regex})",
    )
    parser.add_argument(
        "--image-types",
        nargs="+",
        default=supported_img_types,
        help=f"Image types to retrieve (default: {supported_img_types})",
    )
    parser.add_argument(
        "--distributions",
        nargs="+",
        default=supported_os_names,
        help=f"Distributions to retrieve (default: {supported_os_names})",
    )
    args = parser.parse_args()

    repo_json = get_json(args.registry)
    tags = repo_json["Tags"]

    catalogs = []
    for img_type in args.image_types:
        for os_name in args.distributions:
            filename = f"catalog-{img_type}-{os_name}.yaml"
            print(f"Generating {filename}")
            write_catalog(tags, args.regex, img_type, os_name, args.output_dir)
            catalogs.append(filename)

    kustomization = {
        "apiVersion": "kustomize.config.k8s.io/v1beta1",
        "kind": "Kustomization",
        "resources": sorted(catalogs),
    }
    kustomization_file = os.path.join(args.output_dir, "kustomization.yaml")
    with open(kustomization_file, "w") as f:
        yaml.dump(kustomization, f, sort_keys=False)
