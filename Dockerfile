FROM alpine:3.17 AS base

FROM base AS build

ARG JACKETT_VERSION=latest
ARG DOTNET_TAG

ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

WORKDIR /jackett-src
RUN set -eux; \
    apk add git; \
    [ "${JACKETT_VERSION:-latest}" = "latest" ] && export JACKETT_VERSION="$(git ls-remote --tags https://github.com/Jackett/Jackett.git | sort -k2 -V -r | awk -F/ '{print $3}'  | head -n1)"; \
    OS="$(uname)"; \
    LIBC=""; ldd /bin/ls | grep -qF 'musl' && LIBC="Musl"; \
    ARCH="$(uname -m | sed -e 's/aarch64/ARM64/' -e 's/armv.*/ARM32/' -e 's/x86_64/AMDx64/')"; \
    wget "https://github.com/Jackett/Jackett/releases/download/${JACKETT_VERSION}/Jackett.Binaries.${OS}${LIBC}${ARCH}.tar.gz"  -qO- | tar -xzvf - -C /

FROM base

ARG JACKETT_VERSION=latest
ARG BUILD_DATE

LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="fugkco/jackett"
LABEL org.label-schema.description="Jackett"
LABEL org.label-schema.url="https://github.com/Jackett/Jackett"
LABEL org.label-schema.vcs-url="https://github.com/fugkco/jackett-docker"
LABEL org.label-schema.vcs-ref=${JACKETT_VERSION:-master}
LABEL org.label-schema.vendor="Jackett"
LABEL org.label-schema.version=$BUILD_VERSION
LABEL org.label-schema.docker.cmd="podman run -it -v ./config:/config --rm -p 9117:9117 ghcr.io/fugkco/jackett"

COPY --from=build /Jackett/ /jackett

ARG CONFIG_DIR=/config

ARG APP_USER="jackett"
ARG APP_UID=5258
ARG APP_GID=5258

RUN set -eux; \
    apk add icu-data-en icu-libs; \
    mkdir -p $CONFIG_DIR; \
    addgroup -g $APP_UID -S $APP_USER; \
    adduser -u $APP_GID -D -S -s /sbin/nologin -G $APP_USER $APP_USER; \
    chown -R $APP_USER:$APP_USER $CONFIG_DIR

USER $APP_USER

VOLUME $CONFIG_DIR

EXPOSE 9117/TCP

HEALTHCHECK --start-period=10s --timeout=5s \
    CMD wget -qO /dev/null "http://localhost:9117/torznab/all"

COPY /entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
CMD ["-x", "-d", "/config", "--NoUpdates"]
