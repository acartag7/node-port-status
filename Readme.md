
# About The Project

The following project consists of a small dockerized solution to gather the open ports on all the nodes of our k8s cluster and have an easy way to upload the report to an s3 bucket.

This project consists of 4 parts:
1. Terraform-AWS-EKS folder for the creation of all the required infrastructure with terraform (eks, vpc, security groups, auto scaling groups, etc..)
2. Docker Images folder for the Docker image with the bash script code for the logic of the program.
3. Kubernetes Resources for all the resources needed for our cron job to work (ServiceAccounts, ClusterRole, ClusterRoleBindings, Secrets, etc ...).
4. kube-promethes to install the prometheus operator, alertmanager and grafana to the cluster, for us to be able to have alerting whenever the cronjob fails and pushgateway to be able to gather metrics as prometheus can't gather metrics for such short lived process.

### Tools Used

* Terraform
* Kubernetes
* Bash
* Prometheus - Grafana - Pushproxy
* AWS
* nmap
* Docker

### Prerequisites

* Kubernetes Cluster.
* S3 Bucket if you want to save open port report.
* Terraform if you want to create the project from this repo.
* Prometheus operator with Grafana
* Pushproxy to gather metrics from K8s Cronjobs

### Main script: node_port_status

So let's explain what does the script do, part by part, this is the core function of the application.

The script basically do the following:
1. Get a list of all the kubernetes cluster nodes names and ips and save to file.
2. Loops through the file and do a port scan to every one of the nodes and save the open ports.
3. Loops again to check if it's in the whitelist and remove it from the report.
4. Save all the port and node information on the report and send the results as a metric to pushgateway.
5. Upload the report to S3 bucket for easy retrieval  (TODO: Create a Website hosted in S3 bucket to visualize the file)


### Installation

1. Initialize terraform infrastructure
   ```sh
   terraform init
   ```
2. Do a terraform apply and this will create all the necessary resources for this PoC
   ```sh
   terraform apply
   ...
   Plan: 52 to add, 0 to change, 0 to destroy.

   Changes to Outputs:
   +cluster_endpoint = (known after apply)
   +cluster_id       = (known after apply)

   Do you want to perform these actions?
   Terraform will perform the actions described above.
   Only 'yes' will be accepted to approve.

   ```
3. We need to login to aws so we need to have in hand our keys.
   ```sh
    Arnolds-MacBook-Pro:Terraform-AWS-EKS acartagena$ aws configure
    AWS Access Key ID [None]: **********************
    AWS Secret Access Key [None]: **********************
    Default region name [None]: us-east-1
    Default output format [None]:
   ```
4. Before we create our K8s resources we need to build our dockerimage that contains the script we are going to use to generate the report. Just rename the ```REPO``` with our repo created in ECR.
   ```sh
    docker build -t node_port_status .
    docker tag node_port_status:latest "REPO":latest
    docker push "REPO":latest
   ```
5. Get eks credentials so we can use our newly created cluster.
   ```sh
   Arnolds-MacBook-Pro:Terraform-AWS-EKS acartagena$ aws eks --region us-east-1 update-kubeconfig --name VMware-DEMO-Project

   Added new context arn:aws:eks:us-east-1:780067648615:cluster/VMware-DEMO-Project to /Users/acartagena/.kube/config
   ```
6. Now we need to deploy our resources to our eks cluster:
   ```kubectl apply -f resources.yaml```
   
   First we start with out resources.yaml. Resources include Namespace, ServiceAccount, ClusterRole, ClusterRoleBinding and Secrets.
   
   The reason for the following roles is to be able to use ```kubectl get nodes``` command inside our pod. We only provide the necessary permissions for this.
   ```yaml
    apiVersion: v1
    kind: Namespace
    metadata:
    name: vmware-nodes-project
    ---
    apiVersion: v1
    kind: ServiceAccount
    metadata:
    name: get-node-info
    namespace: nodes-project
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
    name: get-node-status
    rules:
    - apiGroups: [""]
        resources: ["nodes"]
        verbs: ["get", "list", "watch"]
    - apiGroups: [""]
        resources: ["secrets"]
        verbs: ["get"]
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
    name: node-status-getter
    roleRef:
    kind: ClusterRole
    name: get-node-status
    apiGroup: rbac.authorization.k8s.io
    subjects:
    - kind: ServiceAccount
        name: get-node-info
        namespace: nodes-project
    ---
    apiVersion: v1
    kind: Secret
    metadata:
    name: aws-credentials
    namespace: nodes-project
    type: Opaque
    data:
    AWS_ACCESS_KEY_ID: *******
    AWS_SECRET_ACCESS_KEY: *******
   ```
7. Now we deploy the cronjob yaml : ```kubectl apply -f cronjob.yaml```
   
   This Yaml file provides the user the option of setting a port ignore list, aws bucket location and AWS secret keys.
   
   ```yaml
    apiVersion: batch/v1
    kind: CronJob
    metadata:
    name: node-port-status-job
    namespace: nodes-project
    spec:
    schedule: "*/3 * * * *"
    jobTemplate:
        metadata:
        labels:
            cronjob: node-port-status-job
        spec:
        template:
            metadata:
            labels:
                cronjob: node-port-status-job
        template:
            spec:
            containers:
                - name: node-port-status
                image: ***********.dkr.ecr.us-east-1.amazonaws.com/node_port_status:latest
                env:
                - name: AWS_BUCKET
                    value: "node-status-project"
                - name: IGNORE_LIST
                    value: "35 80 111"
                - name: AWS_SECRET_ACCESS_KEY
                    valueFrom:
                    secretKeyRef:
                        name: aws-credentials
                        key: AWS_SECRET_ACCESS_KEY
                - name: AWS_ACCESS_KEY_ID
                    valueFrom:
                    secretKeyRef:
                        name: aws-credentials
                        key: AWS_ACCESS_KEY_ID
                command: ["./node_port_status.sh"]
            serviceAccountName: get-node-info
            restartPolicy: OnFailure
   ```
8. After deploying the cronjob, it will create a pod on the stated schedule and will upload a file to the S3 bucket with the report, the report has the following format:
   ```sh
    NODE                         OPEN_PORTS
    ip-10-0-4-51.ec2.internal:   [111,22,9091,80]
    ip-10-0-5-159.ec2.internal:  [111,22,9091]
    ip-10-0-6-131.ec2.internal:  [111,22,9091]
   ```

### EXTRA



