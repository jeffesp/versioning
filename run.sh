#! /bin/bash

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -t|--tyk-running)
      TYK_RUNNING=1
      shift
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

TYK_NAMESPACE=tyk
APP_NAMESPACE=jokes
API_SECRET=$(openssl rand -base64 15)

function cleanup {
    echo "Stopping API and Tyk and cleaning up"
    kill "$(jobs -p)" > /dev/null 2>&1
    kubectl delete namespace $APP_NAMESPACE --force > /dev/null 2>&1
    if [ -z $TYK_RUNNING ]; then
        helm uninstall -n $TYK_NAMESPACE tyk-oss > /dev/null 2>&1
        kubectl delete namespace $TYK_NAMESPACE --force > /dev/null 2>&1
    fi
    exit 0
}
trap cleanup EXIT


if [ -z $TYK_RUNNING ]; then
    kubectl create namespace $TYK_NAMESPACE > /dev/null

    echo "Installing Tyk"
    helm repo add tyk-helm https://helm.tyk.io/public/helm/charts/ > /dev/null
    helm repo update > /dev/null
    # tyk dependencies and then run tyk and port-forward to the API
    kubectl -n $TYK_NAMESPACE create secret generic tyk-secret --from-literal=APISecret=$API_SECRET > /dev/null
    helm upgrade tyk-redis oci://registry-1.docker.io/bitnamicharts/redis -n $TYK_NAMESPACE --install --version 19.0.2 --set replica.replicaCount=1 --wait  > /dev/null 2>&1
    helm upgrade tyk-oss tyk-helm/tyk-oss -n $TYK_NAMESPACE --install -f tyk-values.yaml --wait > /dev/null
    sleep 5
fi

kubectl -n $TYK_NAMESPACE port-forward svc/gateway-svc-tyk-oss-tyk-gateway 8080:8080 > /dev/null &
sleep 1
curl -X GET http://localhost:8080/hello
echo "Tyk is running; press any key to continue."
read
exit 0

# run the API at v1
git checkout v1
kubectl create namespace $APP_NAMESPACE
kubectl -n $APP_NAMESPACE apply -f tyk-api-v1.yaml
kubectl -n $APP_NAMESPACE get pods
curl -X GET http://localhost:8080/jokes/api/v1/jokes

echo "API v1 is running"
read

git checkout v1.1
kubectl -n $APP_NAMESPACE apply -f tyk-api-v1.yaml
kubectl -n $APP_NAMESPACE get pods
curl -X GET http://localhost:8080/jokes/api/v1/jokes

echo "API v1.1 is running"
read

git checkout v2
kubectl -n $APP_NAMESPACE apply -f tyk-api-v2.yaml
kubectl -n $APP_NAMESPACE get pods
curl -X GET http://localhost:8080/jokes/api/v2/jokes
echo "API v2 is running"
read

