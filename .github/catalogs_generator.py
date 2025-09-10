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

repo_name = "cloudnative-pg/postgresql"
full_repo_name = f"ghcr.io/{repo_name}"
pg_regexp = r"(\d+)(?:\.\d+|beta\d+|rc\d+|alpha\d+)-(\d{12})"
_token_cache = {"value": None, "expires_at": 0}


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


def get_token(repository_name):
    global _token_cache
    now = time.time()

    if _token_cache["value"] and now < _token_cache["expires_at"]:
        return _token_cache["value"]

    url = "https://ghcr.io/token?scope=repository:{}:pull".format(repository_name)
    with urllib.request.urlopen(url) as response:
        data = json.load(response)
        token = data["token"]

    _token_cache["value"] = token
    _token_cache["expires_at"] = now + 300
    return token


def get_digest(repository_name, tag):
    token = get_token(repository_name)
    media_types = [
        "application/vnd.oci.image.index.v1+json",
        "application/vnd.oci.image.manifest.v1+json",
        "application/vnd.docker.distribution.manifest.v2+json",
    ]
    url = f"https://ghcr.io/v2/{repository_name}/manifests/{tag}"
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
    tags.sort(key=lambda v: version.Version(v.removesuffix(image_suffix)), reverse=True)

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
            digest = get_digest(repo_name, item)
            results[major] = [f"{full_repo_name}:{item}@{digest}"]

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
                "images.cnpg.io/publisher": "github.com/cloudnative-pg",
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
        "--output-dir", default=".", help="Directory to save the YAML files"
    )
    args = parser.parse_args()

    repo_json = get_json(full_repo_name)
    tags = repo_json["Tags"]

    for img_type in supported_img_types:
        for os_name in supported_os_names:
            print(f"Generating catalog-{img_type}-{os_name}.yaml")
            write_catalog(tags, pg_regexp, img_type, os_name, args.output_dir)
