sudo cat <<EOT > /etc/etcd/etcd.conf
# [member]
ETCD_NAME=default
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
#ETCD_WAL_DIR=""
#ETCD_SNAPSHOT_COUNT="10000"
#ETCD_HEARTBEAT_INTERVAL="100"
#ETCD_ELECTION_TIMEOUT="1000"
#ETCD_LISTEN_PEER_URLS="http://localhost:2380"
ETCD_LISTEN_CLIENT_URLS="https://0.0.0.0:2379,http://localhost:4001"
#ETCD_MAX_SNAPSHOTS="5"
#ETCD_MAX_WALS="5"
#ETCD_CORS=""
#
#[cluster]
#ETCD_INITIAL_ADVERTISE_PEER_URLS="http://localhost:2380"
# if you use different ETCD_NAME (e.g. test), set ETCD_INITIAL_CLUSTER value for this name, i.e. "test=http://..."
#ETCD_INITIAL_CLUSTER="default=http://localhost:2380"
#ETCD_INITIAL_CLUSTER_STATE="new"
#ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="https://0.0.0.0:2379,http://localhost:4001"
#ETCD_DISCOVERY=""
#ETCD_DISCOVERY_SRV=""
#ETCD_DISCOVERY_FALLBACK="proxy"
#ETCD_DISCOVERY_PROXY=""
#ETCD_STRICT_RECONFIG_CHECK="false"
#ETCD_AUTO_COMPACTION_RETENTION="0"
#
#[proxy]
#ETCD_PROXY="off"
#ETCD_PROXY_FAILURE_WAIT="5000"
#ETCD_PROXY_REFRESH_INTERVAL="30000"
#ETCD_PROXY_DIAL_TIMEOUT="1000"
#ETCD_PROXY_WRITE_TIMEOUT="5000"
#ETCD_PROXY_READ_TIMEOUT="0"
#
#[security]
ETCD_CERT_FILE="/etc/kubernetes/ssl/etcd.pem"
ETCD_KEY_FILE="/etc/kubernetes/ssl/etcd-key.pem"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_TRUSTED_CA_FILE="/etc/kubernetes/ssl/ca.pem"
ETCD_AUTO_TLS="true"
#ETCD_PEER_CERT_FILE="/etc/kubernetes/ssl/etcd.pem"
#ETCD_PEER_KEY_FILE="/etc/kubernetes/ssl/etcd-key.pem"
#ETCD_PEER_CLIENT_CERT_AUTH="true"
#ETCD_PEER_TRUSTED_CA_FILE="/etc/kubernetes/ssl/ca.pem"
#ETCD_PEER_AUTO_TLS="true"
#
#[logging]
#ETCD_DEBUG="false"
# examples for -log-package-levels etcdserver=WARNING,security=DEBUG
#ETCD_LOG_PACKAGE_LEVELS=""
EOT

sudo cat <<EOT > /etc/kubernetes/apiserver
###
# kubernetes system config
#
# The following values are used to configure the kube-apiserver
#

# The address on the local server to listen to.
KUBE_API_ADDRESS="--bind-address=0.0.0.0 --insecure-bind-address=127.0.0.1 --advertise-address=192.168.50.100"

# The port on the local server to listen on.
#KUBE_API_PORT="--insecure-port=8080 --secure-port=6443"

# Port minions listen on
# KUBELET_PORT="--kubelet-port=10250"

# Comma separated list of nodes in the etcd cluster
KUBE_ETCD_SERVERS="--etcd-servers=https://192.168.50.100:2379 --etcd-cafile=/etc/kubernetes/ssl/ca.pem --etcd-certfile=/etc/kubernetes/ssl/client-apiserver.pem --etcd-keyfile=/etc/kubernetes/ssl/client-apiserver-key.pem"

# Address range to use for services
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.254.0.0/16"

# default admission control policies
KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota"

# Add your own!
KUBE_API_ARGS="--tls-cert-file=/etc/kubernetes/ssl/apiserver.pem --tls-private-key-file=/etc/kubernetes/ssl/apiserver-key.pem --client-ca-file=/etc/kubernetes/ssl/ca.pem --service-account-key-file=/etc/kubernetes/ssl/client-apiserver-key.pem --runtime-config=extensions/v1beta1/networkpolicies=true --anonymous-auth=false"
EOT

sudo cat <<EOT > /etc/kubernetes/controller-manager
###
# The following values are used to configure the kubernetes controller-manager

# defaults from config and apiserver should be adequate

# Add your own!
KUBE_CONTROLLER_MANAGER_ARGS="--master=http://127.0.0.1:8080 --leader-elect=true --service-account-private-key-file=/etc/kubernetes/ssl/client-apiserver-key.pem --root-ca-file=/etc/kubernetes/ssl/ca.pem"
EOT

sudo cat <<EOT > /home/vagrant/.bashrc
# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions

kubectl config set-cluster default-cluster --server=https://192.168.50.100:6443 --certificate-authority=/etc/kubernetes/ssl/ca.pem
kubectl config set-credentials default-admin --certificate-authority=/etc/kubernetes/ssl/ca.pem --client-key=/etc/kubernetes/ssl/client-apiserver-key.pem --client-certificate=/etc/kubernetes/ssl/client-apiserver.pem
kubectl config set-context default-system --cluster=default-cluster --user=default-admin
kubectl config use-context default-system
EOT

for SERVICES in etcd kube-controller-manager kube-scheduler kube-apiserver; do
  sudo systemctl restart $SERVICES
  sudo systemctl enable $SERVICES
  sudo systemctl status $SERVICES 
done

sudo etcdctl set /atomic.io/network/config '{"Network":"172.17.0.0/16"}'

# kubectl config set-cluster default-cluster --server=https://10.10.0.60:6443 --certificate-authority=certs/ca.pem
# kubectl config set-credentials default-admin --certificate-authority=certs/ca.pem --client-key=certs/client-apiserver-key.pem --client-certificate=certs/client-apiserver.pem
# kubectl config set-context default-system --cluster=default-cluster --user=default-admin
# kubectl config use-context default-system
