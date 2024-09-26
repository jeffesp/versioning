#! /bin/bash

set +x

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
API_SECRET=stuff

function cleanup {
    echo "Stopping API and Tyk and cleaning up"
    kill "$(jobs -p)"
    kubectl delete namespace $APP_NAMESPACE --force
    if [ -z $TYK_RUNNING ]; then
        helm uninstall -n $TYK_NAMESPACE tyk-oss
        kubectl delete namespace $TYK_NAMESPACE --force
    fi
    exit 0
}
trap cleanup EXIT

function build {
  VERSION=$(poetry version -s)
  echo "Building API image with version $VERSION"
  docker build -t http-jokes:$VERSION -f Dockerfile . 
  docker tag http-jokes:$VERSION localhost:5001/http-jokes:$VERSION
  docker push localhost:5001/http-jokes:$VERSION 
}

function apply_config {
  echo "USING API_SECRET: $API_SECRET"
  curl -X POST "http://localhost:8080/tyk/apis/oas/import" \
    --header "x-tyk-authorization:$API_SECRET" \
    --header "Content-Type: text/plain" \
    --data "@./$1"
  curl -X GET "http://localhost:8080/tyk/reload/group" --header "x-tyk-authorization:$API_SECRET"
}

# script starts here

if [ -z $TYK_RUNNING ]; then
    kubectl create namespace $TYK_NAMESPACE

    echo "Installing Tyk"
    helm repo add tyk-helm https://helm.tyk.io/public/helm/charts/ > /dev/null
    helm repo update > /dev/null
    # tyk dependencies and then run tyk and port-forward to the API
    kubectl -n $TYK_NAMESPACE delete secret tyk-secret
    kubectl -n $TYK_NAMESPACE create secret generic tyk-secret --from-literal=APISecret=$API_SECRET
    helm upgrade tyk-redis oci://registry-1.docker.io/bitnamicharts/redis -n $TYK_NAMESPACE --install --version 19.0.2 --set replica.replicaCount=1 --wait
    helm upgrade tyk-oss tyk-helm/tyk-oss -n $TYK_NAMESPACE --install -f tyk-values.yaml --wait
    sleep 5
fi

kubectl -n $TYK_NAMESPACE port-forward svc/gateway-svc-tyk-oss-tyk-gateway 8080:8080 > /dev/null &
sleep 1
curl -X GET http://localhost:8080/hello | jq
echo "If you see a JSON object above, Tyk is running; press any key to continue."
read

# run the API at v1
kubectl create namespace $APP_NAMESPACE
#git checkout v1
build
kubectl -n $APP_NAMESPACE apply -f app-deploy.yaml
apply_config openapi-v1.json
curl -X GET http://localhost:8080/joke/tell

echo "API v1 is running; press any key to continue."
read

exit 0

git checkout v1.1
build
kubectl -n $APP_NAMESPACE apply -f app-deploy.yaml

curl -X POST http://localhost:8080/joke/tell --data '{"joke_type": 1}' -H 'Content-Type: application/json'

echo "API v1.1 is running; press any key to continue."
read

git checkout v2
build()
kubectl -n $APP_NAMESPACE apply -f app-deploy.yaml
curl --location --request POST 'http://localhost:8080/tyk/apis/oas?base_api_id=2d949b3489ec4fb2a803ce64deb2a45f&base_api_version_name=v1&new_version_name=v2&set_default=false' \
  --header 'x-tyk-authorization: stuff' \
  --header 'Content-Type: text/plain' \
  --data "@./http-jokes-v2.json"
# curl -X POST http://localhost:8080/tyk/api/oas --data @openapi-v2.json -H 'Content-Type: application/json' > /dev/null 2>&1
# TODO: adde second request with continuation token
curl -X GET http://localhost:8080/jokes/api/v2/jokes?joke_type=3
echo "API v2 is running; press any key to continue and remove all resources."
read

