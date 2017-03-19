FROM BASEIMAGE

# If we're building for another architecture than amd64, the CROSS_BUILD_ placeholder is removed so e.g. CROSS_BUILD_COPY turns into COPY
# If we're building normally, for amd64, CROSS_BUILD lines are removed
CROSS_BUILD_COPY qemu-QEMUARCH-static /usr/bin/

RUN ln -s /hyperkube /apiserver \
 && ln -s /hyperkube /controller-manager \
 && ln -s /hyperkube /federation-apiserver \
 && ln -s /hyperkube /federation-controller-manager \
 && ln -s /hyperkube /kubectl \
 && ln -s /hyperkube /kubelet \
 && ln -s /hyperkube /proxy \
 && ln -s /hyperkube /scheduler \
 && ln -s /hyperkube /usr/local/bin/kube-apiserver \
 && ln -s /hyperkube /usr/local/bin/kube-controller-manager \
 && ln -s /hyperkube /usr/local/bin/federation-apiserver \
 && ln -s /hyperkube /usr/local/bin/federation-controller-manager \
 && ln -s /hyperkube /usr/local/bin/kubectl \
 && ln -s /hyperkube /usr/local/bin/kubelet \
 && ln -s /hyperkube /usr/local/bin/kube-proxy \
 && ln -s /hyperkube /usr/local/bin/kube-scheduler

# Copy the hyperkube binary
COPY hyperkube /hyperkube
