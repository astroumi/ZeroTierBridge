FROM debian:buster as stage
ARG PACKAGE_BASEURL=https://download.zerotier.com/debian/buster/pool/main/z/zerotier-one
ARG ARCH=amd64
ARG VERSION=1.8.4
RUN apt-get update -qq && apt-get install -qq --no-install-recommends -y ca-certificates curl
RUN curl -sSL -o zerotier-one.deb "${PACKAGE_BASEURL}/zerotier-one_${VERSION}_${ARCH}.deb"

FROM debian:buster
COPY --from=stage zerotier-one.deb .
RUN apt-get update -qq && apt-get install -qq --no-install-recommends -y procps iptables \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN dpkg -i zerotier-one.deb && rm -f zerotier-one.deb
RUN echo "${VERSION}" >/etc/zerotier-version
COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
