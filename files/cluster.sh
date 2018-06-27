#!/bin/bash

PROJECT_DIR=/var/project/microservice-app

docker login -u="$DOCKER_USER_ID" -p="$DOCKER_PASSWORD"

cd ${PROJECT_DIR}/sa-frontend
docker build -f Dockerfile -t $DOCKER_USER_ID/sentiment-analysis-frontend .

cd ${PROJECT_DIR}/sa-frontend
docker push $DOCKER_USER_ID/sentiment-analysis-frontend

cd "${PROJECT_DIR}/sa-webapp"
docker build -f Dockerfile -t $DOCKER_USER_ID/sentiment-analysis-web-app .

cd "${PROJECT_DIR}/sa-webapp"
docker push $DOCKER_USER_ID/sentiment-analysis-web-app

cd "${PROJECT_DIR}/sa-logic"
docker build -f Dockerfile -t $DOCKER_USER_ID/sentiment-analysis-logic .

cd "${PROJECT_DIR}/sa-logic"
docker push $DOCKER_USER_ID/sentiment-analysis-logic

# http://raman-kumar.blogspot.com/2018/05/fixed-ssh-public-key-must-be-specified.html
echo -e "\n\n\n" | ssh-keygen

kops create cluster \
     --name=${NAME} \
     --zones=${CLUSTER_ZONE} \
     --master-size="t2.micro" \
     --node-size="t2.micro" \
     --node-count="3"

kops update cluster --yes $CLUSTER_NAME

echo "Waiting for cluster to be Ready"
sleep 60

while true; do
  kops validate cluster | grep 'is ready' &> /dev/null
  if [ $? == 0 ]; then
     break
  fi
    sleep 30
done

cd ${PROJECT_DIR}/resource-manifests
kubectl apply -f sa-frontend-deployment.yaml
kubectl create -f service-sa-frontend-lb.yaml

kubectl apply -f sa-logic-deployment.yaml --record
kubectl apply -f service-sa-logic.yaml

kubectl apply -f sa-web-app-deployment.yaml --record
kubectl apply -f service-sa-web-app-lb.yaml

# Add jenkins to docker group
sudo usermod -a -G docker jenkins
sudo service jenkins restart

# Enable jenkins to access K8s cluster
sudo mkdir /var/lib/jenkins/.kube
sudo cp ~/.kube/config /var/lib/jenkins/.kube/
cd /var/lib/jenkins/.kube/
sudo chown jenkins:jenkins config
sudo chmod 750 config
