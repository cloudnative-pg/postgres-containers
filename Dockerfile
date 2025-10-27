ARG BASE=debian:bookworm-20250929-slim
FROM $BASE AS minimal

ARG PG_VERSION
ARG PG_MAJOR

ENV PATH=$PATH:/usr/lib/postgresql/$PG_MAJOR/bin

RUN apt-get update && \
    apt-get install -y --no-install-recommends postgresql-common ca-certificates gnupg && \
    /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y -c "${PG_MAJOR}" && \
    apt-get install -y --no-install-recommends -o Dpkg::::="--force-confdef" -o Dpkg::::="--force-confold" postgresql-common && \
    sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf && \
    apt-get install -y --no-install-recommends \
      libsasl2-modules libldap-common \
      -o Dpkg::::="--force-confdef" -o Dpkg::::="--force-confold" "postgresql-${PG_MAJOR}=${PG_VERSION}*" && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    rm -rf /var/lib/apt/lists/* /var/cache/* /var/log/*

RUN usermod -u 26 postgres
USER 26


FROM minimal AS standard
ARG EXTENSIONS
ARG STANDARD_ADDITIONAL_POSTGRES_PACKAGES
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends locales-all ${STANDARD_ADDITIONAL_POSTGRES_PACKAGES} ${EXTENSIONS} && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    rm -rf /var/lib/apt/lists/* /var/cache/* /var/log/*

USER 26

FROM standard AS system
ARG BARMAN_VERSION

# We need to break the system packages to install barman-cloud in bookworm and later
ENV PIP_BREAK_SYSTEM_PACKAGES=1

USER root
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		# We require build-essential and python3-dev to build lz4 on arm64 since there isn't a pre-compiled wheel available
		build-essential python3-dev \
		python3-pip \
		python3-psycopg2 \
		python3-setuptools \
	&& \
	pip3 install --no-cache-dir barman[cloud,azure,snappy,google,zstandard,lz4]==${BARMAN_VERSION} && \
	apt-get remove -y --purge --autoremove build-essential python3-dev && \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
	rm -rf /var/lib/apt/lists/* /var/cache/* /var/log/*

USER 26
