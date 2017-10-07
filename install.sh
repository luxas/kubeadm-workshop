
# Add the kubernetes apt repo
apt-get update && apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

# Install docker and kubeadm
apt-get update && apt-get install -y docker.io kubeadm ceph-common

# Set current arch
ARCH=${ARCH:-"amd64"}

# Enable hostPort support using CNI & Weave
mkdir -p /etc/cni/net.d/
cat > /etc/cni/net.d/10-mynet.conflist <<EOF
{
    "cniVersion": "0.3.0",
    "name": "mynet",
    "plugins": [
        {
            "name": "weave",
            "type": "weave-net",
            "hairpinMode": true
        },
        {
            "type": "portmap",
            "capabilities": {"portMappings": true},
            "snat": true
        }
    ]
}
EOF

# Download portmap which is responsible for the hostPort mappings
curl -sSL https://github.com/containernetworking/plugins/releases/download/v0.6.0/cni-plugins-${ARCH}-v0.6.0.tgz | tar -xz -C /opt/cni/bin ./portmap

# Install helm
curl -sSL https://storage.googleapis.com/kubernetes-helm/helm-v2.6.2-linux-${ARCH}.tar.gz | tar -xz -C /usr/local/bin linux-${ARCH}/helm --strip-components=1

# Use overlay as the docker storage driver
cat /proc/mounts | awk '{print $2}' | grep '/var/lib/docker' | xargs -r umount
rm -rf /var/lib/docker
sed -e "s|/usr/bin/dockerd|/usr/bin/dockerd -s overlay2|g" -i /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl restart docker

git clone https://github.com/luxas/kubeadm-workshop
cd kubeadm-workshop
