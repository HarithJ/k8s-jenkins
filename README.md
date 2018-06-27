# k8s-jenkins
Deploying a microservice-app to k8s cluster on AWS and connecting it to CD pipeline on Jenkins

"DOCKER_USER_ID": "{{ env `DOCKER_USER_ID` }}",
"DOCKER_PASSWORD": "{{ env `DOCKER_PASSWORD` }}",
"CLUSTER_NAME": "{{ env `CLUSTER_NAME` }}",
"CLUSTER_ZONE": "{{ env `CLUSTER_ZONE` }}",
"KOPS_STATE_STORE": "{{ env `KOPS_STATE_STORE` }}",
