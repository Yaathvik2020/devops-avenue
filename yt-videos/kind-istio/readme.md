## What's in Here?
This dir contains resources covered in the istio video

**Overview:** A tutorial on how to get started with [Istio](https://istio.io/) Service Mesh. Start by creating an EC2 instance and a security group with Terraform. Configure the instance with Kind, deploy a web app with Nginx ingress, setup Istio and configure its features for app services

### Prerequisites
1. Ensure the AWS CLI and Terraform are installed and configured.
2. Create a new key pair or have an existing one accessible.
3. A valid Domain and able to add A record

### Create EC2 Instance and Security Group with Terraform

1. Switch to [terraform](terraform) dir
2. IMPORTANT: Provide your keypair [here](terraform/1-variables.tf). Otherwise you will get an error.
2. Initialize the dir and run `terraform plan` to check for errors and then `terraform apply` to create resources.
3. Make note of the IP address, as you will need them to access the node.

**NOTE:** default instance size is `t2.xlarge`. Smaller instance might run out of resouces with the app & Istio setup in this tutorial.

### Connect to the EC2 Instance

1. Connect to the node via ssh: `ssh -i <ssh_key_location> ec2-user@<PUBLIC_IP>`  
*Example:* 
    ```
    ssh -i ~/Downloads/demo-devops-avenue-ue2.pem ec2-user@3.15.44.218
    ```

### Install Docker

1. Install docker, start the service and add logged in user(ec2-user) to docker group to manage docker daemon:
    ```
    sudo yum install docker -y
    sudo systemctl start docker.service
    sudo usermod -aG docker $(logname)
    ```
2. Log out and login back for group membership to take in effect.
3. Test if docker is running:
    ```
    docker ps
    ```

### Create kind cluster

Bash script included [here](script/set_cluster.sh) would:  1) Install the latest version of kind. 2) latest kubectl version. 3) Tmux 4) Map http ports from host with kind container
  
1. Download [setup_cluster](script/set_cluster.sh) script on your node.  
    ```
    wget https://raw.githubusercontent.com/gurlal-1/devops-avenue/refs/heads/main/yt-videos/kind-istio/script/set_cluster.sh
    ```
3. Change permissions for the script and run it.  
    ```
    chmod +x set_cluster.sh
    ./set_cluster.sh 
    ```
4. Add kubectl autocompletion
    ```
    source <(kubectl completion bash)
    echo 'source <(kubectl completion bash)' >>~/.bashrc
    source ~/.bashrc
    ```

### Deploy the Web App

1. Download App manifests located [here](k8s/)
    ```
    wget https://raw.githubusercontent.com/gurlal-1/devops-avenue/refs/heads/main/yt-videos/kind-istio/k8s/
    ```

2. Switch to the downloaded directory and create a namespace
    ```
    kubectl apply -f namespace.yaml 
    ```
3. Create secrets either off the yaml((update the values)) or in terminal(secure)  
   3.1 yaml file
    ```
    kubectl apply -f secrets.yaml 
    ```
    3.2 directly in terminal
    ```
    create secrets manually to avoid hardcoding secrets into manifests
    kubectl create secret generic app-secrets \
      --namespace devops-avenue \
      --from-literal=JWT_SECRET=$#@dfklhjkdrfe24s@$%^rrd3 \
      --from-literal=APP_SECRET=we2acxadrfe2ere4s@$%$D2f
    ```
4. create a configmap and deploy different services of the app.  
These commands use manifest which include deployments and service(clusterIP) resources
    ```
    kubectl apply -f configmap.yaml
    kubectl apply -f analytics-service.yaml
    kubectl apply -f auth-service.yaml
    kubectl apply -f blog-service.yaml
    kubectl apply -f frontend.yaml
    kubectl apply -f recommendation-service.yaml
    kubectl apply -f user-service.yaml
    ```
5. Review the pods 
    ```
    kubectl get pods -n devops-avenue
    ```
6. Access the frontend app locally  
  6.1 enable port forwarding in tmux session
      ```
      tmux
      kubectl port-forward service/frontend 5001:5001
      ```
    Deattach tmux session: `ctrl+b` followed by `d`   
  6.2 Access the app
    ```
    curl http://localhost:5001
    ```

### Deploy Nginx Ingress controller and expose the app

1. Download Ingress Controller yaml from the official [source](https://kubernetes.github.io/ingress-nginx/deploy/#quick-start):  
    ```
    wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.14.3/deploy/static/provider/cloud/deploy.yaml
    ```
3. Map host ports to NGINX Controller Pods. Edit the container section below and add `hostPort:80` and `hostPort:443` for container ports 80 and 443 respectively.
    ```
    sed -i '/containerPort: 80/a \          hostPort: 80' deploy.yaml
    sed -i '/containerPort: 443/a \          hostPort: 443' deploy.yaml
    ```
3. Deploy the NGINX Controller:  
    ```
    kubectl create -f deploy.yaml
    ```
4. Wait for the Controller to Become Ready. Review nginx pods:
    ```
   watch -n 2 kubectl get pods -n ingress-nginx
    ```
5. Once ready, visit the IP address of the node to verify if the NGINX Controller is working:
    ```
    http://<node_IP_address>
    ```
    Should get `404 Not Found` as not path are defined for nginx yet.

6. Create ingress. It has paths defined.  
    *Edit the yaml if would like to add domain*
    ```
    kubectl apply -f ingress.yaml 
    ```
7. Add `A` DNS record type for subdomain. Wait 5-10 minutes for it to populate.
7. Test the app. Go to
`http://istio.gurlal.com`  
 Access login page, enter in this credential: `admin` `password`

### Setup Istio

1. Download, install and add its path to bin
    ```
    curl -L https://istio.io/downloadIstio | sh -
    cd istio*
    export PATH="$PATH:/home/ec2-user/istio-1.29.0/istio-1.29.0/bin"
    ```
2. Install Istio with`demo` profile
    ```
    istioctl install --set profile=demo -y
    ```
3. Now you can check resources got installed
    ```
    kubectl get all -n istio-system
    ```
4. Label your namespace to enable sidecar injection 
    ```
    kubectl label namespace devops-avenue istio-injection=enabled
    ```
6. Now restart the deployments for injection  
  *Should have 2 containers per pod*
    ```
    kubectl -n devops-avenue rollout restart deployment analytics-service 
    kubectl -n devops-avenue rollout restart deployment auth-service
    kubectl -n devops-avenue rollout restart deployment blog-service-v1
    kubectl -n devops-avenue rollout restart deployment frontend
    kubectl -n devops-avenue rollout restart deployment recommendation-service
    kubectl -n devops-avenue rollout restart deployment user-service
    watch -n 2 kubectl get pods -n devops-avenue
    ```
7. Install default add-ons
    ```
    kubectl apply -f samples/addons
    ```

    *Installs grafana, jaeger, kiali, prometheus*
8. Check how they are exposed via services
    ```
    kubectl get svc -n istio-system
    ```
4. Port-forwarding to access add ons

    ```
    tmux set -g mouse on
    tmux
    ```
    have three vertical panes: `ctrl+b`, `&`
    ```
    kubectl -n istio-system port-forward --address 0.0.0.0 svc/grafana 3000:3000
    ```
    ```
    kubectl -n istio-system port-forward --address 0.0.0.0 svc/kiali 20001:20001
    ```
    ```
    kubectl -n istio-system port-forward --address 0.0.0.0 svc/prometheus 9090:9090
    ```
9. Generate app traffic using the script [here](/script/generate_traffic.sh)
10. Access envoy logs from your pods about traffic
    ```
    kubectl logs -n devops-avenue <pod-name> -c istio-proxy
    ```
    Further dig into container to get logs like incoming requests from different services:

    ```
    kubectl exec -n devops-avenue blog-service-v1-5649585dcd-cb87t -c istio-proxy --   curl -s localhost:15000/stats | grep istio_requests_total
    ```
11. Easier way to access those logs via grafana: <http://NodeIP:3000>

### VirtualService & Destination Rules

1. Deploy VirtualService & DestinationRule to split blog service traffic:(switch to k8s dir)
  
    ```
    kubectl apply -f blog-service-v2.yaml
    kubectl apply -f blog-canary.yaml
    ```
2. Explore Kiali and view the traffic split in grafana. 
3. Abort traffic coming in via VirtualService to see errors in Grafana & Kiali
    ```
    kubectl apply -f traffilc-fault-injection.yaml
    ```
4. Pool limit, Circuit breaker, retry via destination rules
    ```
    kubectl apply -f destination-rules.yaml
    ```
### Setup Jaeger
1. It is isntalled but not enabled, to enable tracing:
    ```
    kubectl apply -f telemetry.yaml
    ```
2. Expose and Access the jaeger UI
    ```
    kubectl -n istio-system port-forward --address 0.0.0.0 svc/tracing 8080:80
    ```
    Access it: <http://NodeIP:8080>

### Istioctl tool
1. Check the istioctl proxies
    ```
    istioctl proxy-status
    ```
2. Other options to access and configure Istio
    ```
    istio -help
    ```

### Cleanup

Don't forget to exit out and destroy the resources created on AWS

1. Switch to [terraform](terraform) dir & run `terraform destroy`