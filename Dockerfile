ARG BASE=debian:bookworm-slim
FROM $BASE AS minimal

ARG PG_VERSION
ARG PG_MAJOR=${PG_VERSION%%.*}

ENV PATH=$PATH:/usr/lib/postgresql/$PG_MAJOR/bin

RUN apt-get update && \
    apt-get install -y --no-install-recommends postgresql-common ca-certificates gnupg && \
    /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y && \
    apt-get install -y --no-install-recommends -o Dpkg::::="--force-confdef" -o Dpkg::::="--force-confold" postgresql-common && \
    sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf && \
    apt-get install -y --no-install-recommends \
      -o Dpkg::::="--force-confdef" -o Dpkg::::="--force-confold" "postgresql-${PG_MAJOR}=${PG_VERSION}*" && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    rm -rf /var/lib/apt/lists/* /var/cache/* /var/log/*

RUN usermod -u 26 postgres
USER 26


FROM minimal AS standard

USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends locales-all \
      "postgresql-${PG_MAJOR}-pgaudit" \
      "postgresql-${PG_MAJOR}-pgvector" \
      "postgresql-${PG_MAJOR}-pg-failover-slots" && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    rm -rf /var/lib/apt/lists/* /var/cache/* /var/log/*

USER 26
