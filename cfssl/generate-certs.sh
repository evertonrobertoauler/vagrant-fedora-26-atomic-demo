CFSSL_DIR=$(dirname "${BASH_SOURCE[0]}")
CERTS_DIR="$CFSSL_DIR/../certs"

if [ -d $CERTS_DIR ]; then
  echo "Certificados já foram gerrados"
else
  echo "Gerando certificados"
  mkdir certs

  # CA
  cfssl gencert -initca $CFSSL_DIR/ca-csr.json | cfssljson -bare $CERTS_DIR/ca -

  # SERVER - ETCD
  cat $CFSSL_DIR/server.json | sed "s/\${SERVERNAME}/kube-master/g" | cfssl gencert \
      -ca=$CERTS_DIR/ca.pem \
      -ca-key=$CERTS_DIR/ca-key.pem \
      -config=$CFSSL_DIR/ca-config.json \
      -profile=server \
      -hostname="192.168.50.100" - | cfssljson -bare $CERTS_DIR/etcd

  # SERVER - APISERVER
  cat $CFSSL_DIR/server.json | sed "s/\${SERVERNAME}/kube-master/g" | cfssl gencert \
      -ca=$CERTS_DIR/ca.pem \
      -ca-key=$CERTS_DIR/ca-key.pem \
      -config=$CFSSL_DIR/ca-config.json \
      -profile=server \
      -hostname="192.168.50.100,192.168.50.101,10.10.0.60"  - | cfssljson -bare $CERTS_DIR/apiserver

  # CLIENT - APISERVER
  cfssl gencert -ca=$CERTS_DIR/ca.pem \
    -ca-key=$CERTS_DIR/ca-key.pem \
    -config=$CFSSL_DIR/ca-config.json \
    -profile=client $CFSSL_DIR/client.json | cfssljson -bare $CERTS_DIR/client-apiserver

  # CLIENT - ADMIN
  cfssl gencert -ca=$CERTS_DIR/ca.pem \
    -ca-key=$CERTS_DIR/ca-key.pem \
    -config=$CFSSL_DIR/ca-config.json \
    -profile=client $CFSSL_DIR/client.json | cfssljson -bare $CERTS_DIR/admin

  # CLIENT - WORKER
  cfssl gencert -ca=$CERTS_DIR/ca.pem \
    -ca-key=$CERTS_DIR/ca-key.pem \
    -config=$CFSSL_DIR/ca-config.json \
    -profile=client $CFSSL_DIR/client.json | cfssljson -bare $CERTS_DIR/worker

  echo "Certificados gerados com sucesso!"
fi