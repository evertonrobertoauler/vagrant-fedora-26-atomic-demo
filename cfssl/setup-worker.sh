WORKER_IP=$(ip addr show eth1 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)

sudo cat <<EOT > /etc/sysconfig/flanneld
# Flanneld configuration options

# etcd url location.  Point this to the server where etcd runs
FLANNEL_ETCD_ENDPOINTS="https://192.168.50.100:2379"

# etcd config key.  This is the configuration key that flannel queries
# For address range assignment
FLANNEL_ETCD_PREFIX="/atomic.io/network"

# Any additional options that you want to pass
FLANNEL_OPTIONS="-iface eth1 -etcd-cafile /etc/kubernetes/ssl/ca.pem -etcd-certfile /etc/kubernetes/ssl/worker.pem -etcd-keyfile /etc/kubernetes/ssl/worker-key.pem"
EOT

sudo cat <<EOT > /etc/kubernetes/config
###
# kubernetes system config
#
# The following values are used to configure various aspects of all
# kubernetes services, including
#
#   kube-apiserver.service
#   kube-controller-manager.service
#   kube-scheduler.service
#   kubelet.service
#   kube-proxy.service
# logging to stderr means we get it in the systemd journal
KUBE_LOGTOSTDERR="--logtostderr=true"

# journal message level, 0 is debug
KUBE_LOG_LEVEL="--v=0"

# Should this cluster be allowed to run privileged docker containers
KUBE_ALLOW_PRIV="--allow-privileged=false"

# How the controller-manager, scheduler, and proxy find the apiserver
KUBE_MASTER="--master=https://192.168.50.100:6443"
EOT

sudo cat <<EOT > /etc/kubernetes/kubelet
###
# kubernetes kubelet (minion) config

# The address for the info server to serve on (set to 0.0.0.0 or "" for all interfaces)
KUBELET_ADDRESS="--address=0.0.0.0"

# The port for the info server to serve on
# KUBELET_PORT="--port=10250"

# You may leave this blank to use the actual hostname
KUBELET_HOSTNAME="--hostname-override=$WORKER_IP"

# location of the api-server
KUBELET_API_SERVER="--api-servers=https://192.168.50.100:6443"

# Add your own!
KUBELET_ARGS="--cgroup-driver=systemd --kubeconfig=/etc/kubernetes/kube.config --logtostderr=true --anonymous-auth=false --register-node=true --client-ca-file=/etc/kubernetes/ssl/ca.pem --tls-cert-file=/etc/kubernetes/ssl/apiserver.pem --tls-private-key-file=/etc/kubernetes/ssl/apiserver-key.pem"
EOT

sudo cat <<EOT > /etc/kubernetes/proxy 
###
# kubernetes proxy config

# default config should be adequate

# Add your own!
KUBE_PROXY_ARGS="--master=https://192.168.50.100:6443 --kubeconfig=/etc/kubernetes/kube.config --logtostderr=true"
EOT

sudo cat <<EOT > /etc/kubernetes/kube.config
apiVersion: v1
kind: Config
users:
- name: worker
  user:
    client-certificate: /etc/kubernetes/ssl/worker.pem
    client-key: /etc/kubernetes/ssl/worker-key.pem
clusters:
- name: kube
  cluster:
    server: https://192.168.50.100:6443
    certificate-authority: /etc/kubernetes/ssl/ca.pem
contexts:
- context:
    cluster: kube
    user: worker
EOT

for SERVICES in kube-proxy kubelet docker flanneld; do
  sudo systemctl restart $SERVICES
  sudo systemctl enable $SERVICES
  sudo systemctl status $SERVICES 
done