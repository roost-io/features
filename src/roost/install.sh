#!/bin/bash
ROOST_DIR="/var/tmp/Roost"
LOG_FILE="$ROOST_DIR/cluster.log"

pre_checks() {
  ROOT_DISK_SIZE="${DISK_SIZE}GB"
  KUBE_DIR="/home/vscode/.kube"
  if [ -z $ALIAS ]; then
    ALIAS=$(date +%s)
  fi
}

install_kubectl() {
  which kubectl
  if [ $? -ne 0 ]; then
    sudo apt-get update -y
    sudo apt-get install -y apt-transport-https ca-certificates curl
    sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update -y
    curl -L "https://dl.k8s.io/release/v${K8S_VERSION}/bin/linux/amd64/kubectl" -o /var/tmp/kubectl && chmod +x /var/tmp/kubectl && sudo mv /var/tmp/kubectl /usr/local/bin/kubectl
  fi

  kubectl version | grep "${K8S_VERSION}"
  if [ $? -ne 0 ]; then
    echo "kubectl installation failed!"
  else
    echo "kubectl installed successfully."
  fi

}

create_cluster() {
  RESPONSE_CODE=$(curl --location --request POST "https://$ENT_SERVER/api/application/client/launchCluster" \
  --header "Content-Type: application/json" \
  --data-raw "{
    \"roost_auth_token\": \"$ROOST_AUTH_TOKEN\",
    \"alias\": \"$ALIAS\",
    \"namespace\": \"$NAMESPACE\",
    \"customer_email\": \"$EMAIL\",
    \"k8s_version\": \"$K8S_VERSION\",
    \"num_workers\": $NUM_WORKERS,
    \"preemptible\": $PREEMPTIBLE,
    \"cluster_expires_in_hours\": $CLUSTER_EXPIRES_IN_HOURS,
    \"region\": \"$REGION\",
    \"disk_size\": \"$ROOT_DISK_SIZE\",
    \"instance_type\": \"$INSTANCE_TYPE\",
    \"ami\": \"$AMI\"
  }" | jq -r '.ResponseCode')

  if [ $RESPONSE_CODE -eq 0 ]; then
    sleep 5m
    for i in {1..10}
    do
      if [ ! -s $KUBE_DIR/config ]; then
        echo "$i sleeping now for 30s"
        sleep 30
        get_kubeconfig
      fi
    done
  else
    echo "Failed to launch cluster. please try again"
  fi
}

get_kubeconfig() {
  if [ ! -d "$KUBE_DIR" ]; then
    mkdir -p $KUBE_DIR
  fi

  KUBECONFIG=$(curl --location --request POST "https://$ENT_SERVER/api/application/cluster/getKubeConfig" \
  --header "Content-Type: application/json" \
  --data-raw "{
    \"app_user_id\" : \"$ROOST_AUTH_TOKEN\",
    \"cluster_alias\" : \"$ALIAS\"
  }" | jq -r '.kubeconfig')

  if [ "$KUBECONFIG" != "null" ]; then
    echo "Kubconfig retrieved successfully"
    echo "$KUBECONFIG" >> "$KUBE_DIR/config"
  fi
}

write_stop_cmd() {

  cat > /usr/local/bin/roost \
<< EOF
ACTION=\$*
main() {
  case \$ACTION in
    stop)
      curl --location --request POST "https://$ENT_SERVER/api/application/client/stopLaunchedCluster" \
      --header "Content-Type: application/json" \
      --data-raw "{
        \"roost_auth_token\": \"$ROOST_AUTH_TOKEN\",
        \"alias\": \"$ALIAS\"
      }"
      sudo rm -f "$KUBE_DIR/config"
      ;;
    delete)
      curl --location --request POST "https://$ENT_SERVER/api/application/client/deleteLaunchedCluster" \
      --header "Content-Type: application/json" \
      --data-raw "{
        \"roost_auth_token\": \"$ROOST_AUTH_TOKEN\",
        \"alias\": \"$ALIAS\"
      }"
      sudo rm -f "$KUBE_DIR/config"
      ;;
    *)
      echo "Please try with valid parameter - stop or delete"
    ;;
  esac
}
main
EOF

chmod +x /usr/local/bin/roost
}

main() {
  pre_checks
  install_kubectl
  create_cluster
  write_stop_cmd
}

if [ ! -d "$ROOST_DIR" ]; then
   mkdir -p $ROOST_DIR
fi

main $* > $ROOST_DIR/roost.log 2>&1
echo "Logs are at $ROOST_DIR/roost.log"