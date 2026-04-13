#########################################################
#########################################################

ARG BASE_IMAGE=debian:latest
FROM ${BASE_IMAGE} AS gitlab-docker-executor

# Install docker repo
RUN install -m 0755 -d /etc/apt/keyrings
COPY --chmod=0644 docker-executor/docker.asc /etc/apt/keyrings/docker.asc

RUN apt-get update && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        curl openssl ca-certificates && \
    echo "deb [arch=$(dpkg --print-architecture) \
      signed-by=/etc/apt/keyrings/docker.asc] \
      $(. /etc/os-release && echo "https://download.docker.com/linux/${ID} ${UBUNTU_CODENAME:-$VERSION_CODENAME}") \
      stable" | tee /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        docker-ce-cli docker-buildx-plugin && \
    apt-get autoclean && \
    apt-get autoremove && \
    rm -rf /var/cache/apt

RUN /usr/sbin/update-ca-certificates -v
