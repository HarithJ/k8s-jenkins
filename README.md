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

Copy the `public-ipv4` address given by AWS of the instance that you created earlier, and paste it in your browser. VOILA! It's Jenkins startup page. Unlock Jenkins and click on `install suggested plugins` on the next page. After it has done installing the plugins, create Admin user and continue to the next stage. On the next page, confirm that the ip address is same as your instance, and continue.

If you are seeing `Welcome to Jenkins`, then you can now move forward! On the left panel, click on the `credentials` link, under `credentials` link you will see another link show up; `system`, click on that as well. Now you will be seeing a `system`'s page, under that page you will see one `domain` named `Global credentials (unrestricted)`, click on that. Roll your eyes over to the right panel, you see a link that reads: `Add credentials`, yup! Click on it! Under `kind` dropdown menu, select `secret text`, on the `secret` field type out your docker-hub password, and type out `DOCKER_HUB` on the `ID` text field, click on `OK`. This is same as exporting environment variable, we will now be able to use `DOCKER_HUB` "secret" variable as we build our application using Jenkins. Following the same steps, create another `secret text`, this time the `secret` field should contain you docker-hub username and set `ID` as `DOCKER_USERNAME`

OKAY! Head back to Jenkins home page by clicking on the `Jenkins` link located on the left panel.

Follow these steps:
1. click on `create new jobs`

2. Give your Job a name, and select `Freestyle Project`. Click `OK` button on the bottom left.

3. Under `General Tab`

    a. click on `Github project`, and paste in your github URL of microservice app.

4. Under `Source Code management`:

    a. Select `Git`.
  
    b. Again, enter you gihub url.
  
    c. You can leave the rest as default.
   
5. Under `Build Triggers`:

    a. Select `GitHub hook trigger for GITScm polling`, this will build the project whenever you push to gihub.
  
6. Under `Build environment`:

    a. Select: `Use secret text(s) or file(s)`. This will allow us to use `DOCKER_HUB` variable we had defined.
  
7. Under Build (here we will write out the commands that will build the microservice app and update the deployments to k8s):

    a. Select `Execute shell` and type out (to build frontend image):
    ```
    IMAGE_NAME="${DOCKER_USERNAME}/sentiment-analysis-frontend:${BUILD_NUMBER}"
    docker build . -t ${IMAGE_NAME} -f sa-frontend/Dockerfile
    docker login -u ${DOCKER_USERNAME} -p ${DOCKER_HUB}
    docker push ${IMAGE_NAME}
    ```
    
    b. Again Select `Execute shell` and type out:
  
    ```
    IMAGE_NAME="${DOCKER_USERNAME}/sentiment-analysis-frontend:${BUILD_NUMBER}"
    kubectl apply -f resource-manifests/sa-frontend-deployment.yaml
    ```
    
    c. Again Select `Execute shell` and type out (for building python microservice):
    ```
    IMAGE_NAME="${DOCKER_USERNAME}/sentiment-analysis-logic:${BUILD_NUMBER}"
    docker build . -t ${IMAGE_NAME} -f sa-logic/Dockerfile
    docker login -u ${DOCKER_USERNAME} -p ${DOCKER_HUB}
    docker push ${IMAGE_NAME}
    ```
    
    d. Again Select `Execute shell` and type out:
  
    ```
    IMAGE_NAME="${DOCKER_USERNAME}/sentiment-analysis-logic:${BUILD_NUMBER}"
    kubectl apply -f resource-manifests/sa-logic-deployment.yaml --record
    ```
    
    e. Again Select `Execute shell` and type out (for building Java microservice):
    ```
    IMAGE_NAME="${DOCKER_USERNAME}/sentiment-analysis-web-app:${BUILD_NUMBER}"
    docker build . -t ${IMAGE_NAME} -f sa-webapp/Dockerfile
    docker login -u ${DOCKER_USERNAME} -p ${DOCKER_HUB}
    docker push ${IMAGE_NAME}
    ```
    
    f. Again Select `Execute shell` and type out:
  
    ```
    IMAGE_NAME="${DOCKER_USERNAME}/sentiment-analysis-web-app:${BUILD_NUMBER}"
    kubectl apply -f resource-manifests/sa-web-app-deployment.yaml --record
    ```
