CFSSL_DIR=$(dirname "${BASH_SOURCE[0]}")
CERTS_DIR="$CFSSL_DIR/../certs"

if [ -d $CERTS_DIR ]; then
  echo "Certificados já foram gerrados"
else
  echo "Gerando certificados"
  mkdir certs

  # CA
  cfssl gencert -initca $CFSSL_DIR/ca-csr.json | cfssljson -bare $CERTS_DIR/ca -

  # ETCD
  cat $CFSSL_DIR/server.json | sed "s/\${SERVERNAME}/kube-master/g" | cfssl gencert \
      -ca=$CERTS_DIR/ca.pem \
      -ca-key=$CERTS_DIR/ca-key.pem \
      -config=$CFSSL_DIR/ca-config.json \
      -profile=server - | cfssljson -bare $CERTS_DIR/etcd

  # APISERVER
  cat $CFSSL_DIR/server.json | sed "s/\${SERVERNAME}/kube-master/g" | cfssl gencert \
      -ca=$CERTS_DIR/ca.pem \
      -ca-key=$CERTS_DIR/ca-key.pem \
      -config=$CFSSL_DIR/ca-config.json \
      -profile=server  - | cfssljson -bare $CERTS_DIR/apiserver

  # # APISERVER - CLIENT
  cfssl gencert -ca=$CERTS_DIR/ca.pem \
    -ca-key=$CERTS_DIR/ca-key.pem \
    -config=$CFSSL_DIR/ca-config.json \
    -profile=client $CFSSL_DIR/client.json | cfssljson -bare $CERTS_DIR/client-apiserver

  # # ADMIN
  cfssl gencert -ca=$CERTS_DIR/ca.pem \
    -ca-key=$CERTS_DIR/ca-key.pem \
    -config=$CFSSL_DIR/ca-config.json \
    -profile=client $CFSSL_DIR/client.json | cfssljson -bare $CERTS_DIR/admin

  echo "Certificados gerados com sucesso!"
fi