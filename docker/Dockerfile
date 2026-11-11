FROM scratch
ARG BUILD_DATE
ARG VCS_REF
ADD openwrt-docker-armvirt-64-default-rootfs.tar.gz /
LABEL org.opencontainers.image.title="ImmortalWrt N1" \
      org.opencontainers.image.description="ImmortalWrt ARM64 Docker image for Phicomm N1" \
      org.opencontainers.image.source="https://github.com/1911086027/immortalwrt-N1" \
      org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.revision=$VCS_REF
ENTRYPOINT ["/sbin/init"]
