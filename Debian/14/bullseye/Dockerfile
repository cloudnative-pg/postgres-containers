#
# Copyright The CloudNativePG Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
FROM postgres:14.18-bullseye

# Do not split the description, otherwise we will see a blank space in the labels
LABEL name="PostgreSQL Container Images" \
      vendor="The CloudNativePG Contributors" \
      version="${PG_VERSION}" \
      release="20" \
      summary="PostgreSQL Container images." \
      description="This Docker image contains PostgreSQL and Barman Cloud based on Postgres 14.18-bullseye."

LABEL org.opencontainers.image.description="This Docker image contains PostgreSQL and Barman Cloud based on Postgres 14.18-bullseye."

COPY requirements.txt /

# Install additional extensions
RUN set -xe; \
	rm -fr /var/lib/postgresql/data; \
	apt-get update; \
	if apt-get -s upgrade | grep "^Inst postgres"; then \
		echo "ERROR: Upgradable postgres packages found!"; \
		apt-get -s upgrade | grep "^Inst postgres"; \
		exit 1; \
	fi; \
	apt-get install -y --no-install-recommends \
		"postgresql-${PG_MAJOR}-pgaudit" \
		"postgresql-${PG_MAJOR}-pgvector" \
		"postgresql-${PG_MAJOR}-pg-failover-slots" \
	; \
	rm -fr /tmp/* ; \
	rm -rf /var/lib/apt/lists/*;

# Install barman-cloud
RUN set -xe; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		# We require build-essential and python3-dev to build lz4 on arm64 since there isn't a pre-compiled wheel available
		build-essential python3-dev \
		python3-pip \
		python3-psycopg2 \
		python3-setuptools \
	; \
	pip3 install  --upgrade pip; \
	# TODO: Remove --no-deps once https://github.com/pypa/pip/issues/9644 is solved
	pip3 install  --no-deps -r requirements.txt; \
	apt-get remove -y --purge --autoremove build-essential python3-dev; \
	rm -rf /var/lib/apt/lists/*;

# Change the uid of postgres to 26
RUN usermod -u 26 postgres
USER 26
