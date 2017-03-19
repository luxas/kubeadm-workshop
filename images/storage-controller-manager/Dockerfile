FROM BASEIMAGE

# If we're building for another architecture than amd64, the CROSS_BUILD_ placeholder is removed so e.g. CROSS_BUILD_COPY turns into COPY
# If we're building normally, for amd64, CROSS_BUILD lines are removed
CROSS_BUILD_COPY qemu-QEMUARCH-static /usr/bin/

RUN clean-install \
    ceph-common

COPY kube-controller-manager /usr/local/bin/
