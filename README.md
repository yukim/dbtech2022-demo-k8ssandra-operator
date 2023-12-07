# DB Tech Showcase 2022 - Session B-9: Apache Cassandra on Kubernetes 最新情報

- https://www.db-tech-showcase.com/2022/schedule/
- Link to the recording will be added once it is released (it is in Japanese tho)


This repository contains Terraform scripts to set up 3 EKS cluster over two regions in ap-northeast-1 and ap-northeast-3,
and K8ssandraCluster resource YAML file to deploy multi-DC Cassandra cluster.

## Demo scripts

- infra
    - Terraform scripts to set up EKS and necessary network configuration
- k8s
    - K8ssandraCluster resource YAML

## Demo instruction

### 1. Create 3 EKSs

Go into the `infra` directory:

```
cd infra
```

Since this demo avoid creating IAM roles for EKS clusters, you need to prepare [Cluster IAM role](https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html) and [Node IAM role](https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html) before using the terraform scripts.

Create `terraform.tfvars` file with the above IAM roles.

```
cluster_service_role = "my_cluster_role"
nodegroup_role = "my_nodegroup_role"
```
You need two phases to complete the setup.

Run the following command to create 3 EKS clusters across two regions:

```
terraform plan -target module.control-plane -target module.dc-tokyo -target module.dc-osaka
terraform apply
```

After EKS clusters are created, run the following command to establish VPC peering among the clusters:

```
terraform plan
terraform apply
```

Update the kubeconfig file to access these 3 EKS clusters:

```
aws eks --region ap-northeast-1 update-kubeconfig --name eks-control-plane --alias eks-control-plane
aws eks --region ap-northeast-1 update-kubeconfig --name eks-dc-tokyo --alias eks-dc-tokyo
aws eks --region ap-northeast-3 update-kubeconfig --name eks-dc-osaka --alias eks-dc-osaka
```

Alias names(--alias) above are referenced in the following steps to specify Kubernetes context.

### 2. Install Cert Manager

k8ssandra-operator requires [Cert Manager](https://cert-manager.io/) to be installed.

Run the following commands to install cert manager to each EKS cluster.

```
kubectl --context eks-control-plane apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml
kubectl --context eks-dc-tokyo apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml
kubectl --context eks-dc-osaka apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml
```

After installation is completed, proceed to k8ssandra-operator install.

### 3. Install k8ssandra-operator

k8ssandra-operator can be install using helm or kustomize, but in this demo, use kustomize.

#### Control plane

Run the following to install k8ssandra-operator control plane:

```
kubectl --context eks-control-plane apply --force-conflicts --server-side -k "github.com/k8ssandra/k8ssandra-operator/config/deployments/control-plane?ref=v1.10.3"
```

#### Data plane

Run the following to install k8ssandra-operator data plane:

```
kubectl --context eks-dc-tokyo apply --force-conflicts --server-side -k "github.com/k8ssandra/k8ssandra-operator/config/deployments/data-plane?ref=v1.10.3"
kubectl --context eks-dc-osaka apply --force-conflicts --server-side -k "github.com/k8ssandra/k8ssandra-operator/config/deployments/data-plane?ref=v1.10.3"
```

### 4. Create ClientConfig

Download the `create-clientconfig.sh` script from the k8ssandra-operator repository.

https://github.com/k8ssandra/k8ssandra-operator/blob/main/scripts/create-clientconfig.sh

Use this script to create ClientConfig so that control plane can communicate with data planes.

```
./create-clientconfig.sh --namespace k8ssandra-operator --src-context eks-dc-tokyo --dest-context eks-control-plane --output-dir clientconfig
./create-clientconfig.sh --namespace k8ssandra-operator --src-context eks-dc-osaka --dest-context eks-control-plane --output-dir clientconfig
```

### 5. Deploy multi-DC K8ssandraCluster

Run the following command to deploy multi-DC K8ssadnraCluster.

```
kubectl --context eks-control-plane -n k8ssandra-operator apply -f k8s/k8ssandra.yaml 
```
