# k8s-jenkins
Deploying a microservice-app to k8s cluster on AWS and connecting it to CD pipeline on Jenkins.

## Tools used:
Github, Kubernetes (k8s), Kops, AWS, Jenkins, Docker, DockerHub.

NOTE: You would also need to create a role on AWS that would allow kops to create cluster on AWS. If you are wondering what permissions to give to this role, then you can just give it `Administration` permission.

## GET the repo
First and foremost fork this repo: https://github.com/HarithJ/k8s-mastery, as it contains the microservice-app that we would be using.

## Creating the image on AWS
We would be using packer+ansible to create an image on AWS. Before building the image though, make sure you have set the github username (on which you forked the microservice repo) as an environment variable:

`export GITHUB_USER=your-github-username`

Now, you can go ahead and build the packer image:

`packer build jenkins-packer.json`

NOTE: Make sure you have AWS credentials file in `~/.aws/credentials`. More on this: https://docs.aws.amazon.com/cli/latest/userguide/cli-config-files.html

## After building the image
After having the image, log into your aws console and create a instance based off of that image. While creating the instance make sure:
1. You set its IAM role to the role you created earlier. This setting is found under; `Step 3: Configure Instance Details`
2. Configure security group appropriately; basically you would need SSH access and HTTP access. (Just to make sure that SG does not get into your way, allow `All traffic` from `anywhere`).

Roll out the instance!!!

RECOMMENDED: Attach elastic IP to this instance.

## Got the instance???
After having the instance, you would need to create two more resources on AWS: `S3 bucket` and `Route 53 zone`. 

Next, SSH into the instance and `export` the following environment variables:
`export DOCKER_USER_ID=your-dockerhub-username`
`export DOCKER_PASSWORD=your-dockerhub-password`
`export CLUSTER_NAME=domain-name-you-want-to-use-for-cluster`
`export CLUSTER_ZONE=zone-you-want-to-place-the-cluster-in`
`export KOPS_STATE_STORE=s3://your-s3-bucket`

Make sure you are in your home directory and run the following command:
`sudo source cluster.sh`

This script would do the following:
1. Log into docker
2. Build the docker images and push them to your docker-hub account
3. Generate ssh-keygen which will be needed by k8s.
4. Create the k8s cluster.
5. Deploy the microservice to the cluster.
6. Allow Jenkins to access docker.
7. Allow Jenkins to access k8s cluster.

NOTE: If you get any prompts from the shell, then just hit `enter`.

## Jenkins!
All right!!! Now to setup the CI/CD pipeline!
