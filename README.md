# Technical Assessment - DevOps Engineer

# Soal 1: Analisa Sistem Design
Perhatikan sistem desain pada arsitektur infrastruktur dan CI/CD Pipeline yang terlampir. Apakah menurut Anda kedua rancangan ini sudah memenuhi standar best practice? Coba deskripsikan pemahaman Anda terhadap alur kerjanya. Kemudian, apakah ada kekurangan fatal atau celah keamanan dalam kedua sistem desain ini? Jelaskan temuan Anda. Terakhir, berikan rekomendasi Anda untuk perbaikan desain sistem tersebut agar menjadi lebih aman, efisien, dan andal.
![Arsitektur Infrastruktur](image/topo.png)
![CI/CD Pipeline](image/ci-cd.png)

## Answer:

Saya akan menjawab soal 1 dengan memberikan penjelasan dan analisis terhadap kedua rancangan desain. Saya akan breakdown menjadi 2 bagian, yaitu arsitektur infrastruktur dan CI/CD Pipeline.

### a. Arsitektur Infrastruktur
![Arsitektur Infrastruktur](image/topo.png)
Pada arsitektur tersebut dapat kita ketahui terdapat 2 segmen network utama, yaitu Compnay Network (192.168.0.0/24) dan Server Network (192.168.220.0/24). **Segmentasi Untuk Semua server menjadi 1 menggunakan Segmen Server Network.**

User dengan Company Network dapat mengakses Aplikasi http://app.example.com melalui LB dengan arsitektur active-passive menggunakan keepalived, selain daripada itu **user juga dapat langsung mengakses server melalui SSH**.

Jika diperhatikan pada **Rancher - Kubernetes Management, kita dapat melihat hanya terdapat 2 master node** dan 3 worker node. Kemudian, pada Production Workload Cluster menggunakan 3 master node dan 3 worker node. Kedua cluster menggunakan deployment RKE2.
<br>
**Dari hasil analisa saya dapat menyimpulkan beberapa problem pada arsitektur tersebut:**

**Problem 1: Segmentasi Network**
```
Segmentasi Network hanya terbagi 2 segmen, yaitu Compnay Network dan Server Network. Khususnya pada Management Server dan Production Server, seharusnya dapat dipisah menjadi 2 segmen network yang berbeda. Serta sebagai tambahan, mungkin untuk memisahkan juga Database Server dengan menggunakan segmen yang berbeda. Sehingga kita bisa menggunakan beberapa segmen seperti berikut:
- Company Network
- Management Network
- Production Network
- Data Network
```

**Problem 2: Direct SSH Access**
```
Pada ekosistem production seharusnya kita tidak langsung mengakses server secara langsung. Seharusnya kita mengakses server melalui Bastion Server dengan menggunakan SSO OIDC untuk akses ke infrastruktur server.

User
 ↓
SSO
 ↓
Bastion / PAM
 ↓
Servers
```

**Problem 3: Master Node Management Cluster tidak HA**
```
Jika diperhatikan pada Management cluster hanya menggunakan 2 master node, ini sangat berbahaya pada penggunaan cluster kubernetes. Master node pada kubernetes menggunakan etcd cluster sebagai database state. etcd menggunakan consensus algorithm (Raft) yang membutuhkan quorum. 

Rumus quorumnya adalah:
quorum = (N / 2) + 1

di mana N adalah jumlah node etcd.

Artinya Kedua node harus hidup agar cluster tetap berjalan. Jika salah satu node etcd down, maka cluster akan:
- kehilangan quorum
- etcd tidak bisa melakukan write
- API server menjadi read-only atau gagal

Akibatnya:
- tidak bisa deploy resource
- tidak bisa update cluster
- Rancher tidak bisa mengontrol cluster

Untuk best practice seharusnya menggunakan 3 master node. Hal ini akan meningkatkan availability dan fault tolerance dari cluster kubernetes.
```

### b. CI/CD Pipeline
![CI/CD Pipeline](image/ci-cd.png)
Diagram kedua menunjukkan pipeline CI/CD berbasis GitFlow.
Branch strategy:
```
feature/*
hotfix/*
develop
release/*
main/master
```
Flow:
```
feature -> develop
release -> main
hotfix -> main
```

Proses CI Pipeline yang terjadi:
```
Push / PR
```
Pipeline akan berjalan:
```
Trigger CI/CD Job
      ↓
Unit Test
      ↓
Build Image
      ↓
Push Image to Registry
```
Artinya: Pipeline menghasilkan container image.

Proses CD Pipeline yang terjadi:
Flow:
```
Deploy to Dev
```
Jika branch **develop** pipeline berhenti di Dev.

Jika branch **release / main** akan lanjut ke:
```
Deploy to Staging
       ↓
Integration Test
       ↓
UAT
       ↓
Deploy to Production
```
Ini menunjukkan environment promotion pipeline.
<br>
**Dari hasil analisa saya dapat menyimpulkan beberapa problem pada pipeline CI/CD tersebut:**

**Problem 1: CI pipeline tidak ada security scanning**
```
```
**Problem 2: Tidak ada image signing**
```
```

# 2. System Design & Architecture
**Skenario Kebutuhan:**
Perusahaan sedang membangun ekosistem cloud-native on-premise yang menyeluruh. Kami membutuhkan fondasi infrastruktur yang sangat tangguh sekaligus sistem pengiriman aplikasi yang terotomatisasi penuh. Anda ditugaskan merancang arsitektur terintegrasi yang mencakup kluster Kubernetes High Availability (HA) yang tahan terhadap kegagalan perangkat keras (terhindar dari Single Point of Failure), serta alur CI/CD pipeline dari source code hingga production yang mendukung zero downtime deployment. Infrastruktur ini harus dikelola terpusat melalui platform manajemen kluster, mengadopsi prinsip shift-left security, memastikan rahasia (secrets) dikelola secara terpusat tanpa kebocoran di repositori, serta dilindungi oleh sistem manajemen identitas dan akses (PAM & IAM) yang ketat sesuai regulasi perusahaan.

**Kebutuhan Teknis:**

A) Wajib:
1. Penggunaan platform manajemen kluster terpusat untuk melakukan provisioning/bootstrap kluster Kubernetes dengan fokus pada arsitektur HA.
2. Implementasi Continuous Integration (CI) dan Continuous Delivery (CD) menggunakan pendekatan GitOps untuk deployment aplikasi microservices.
3. Menerapkan strategi Zero Downtime deployment seperti Rolling Update, Blue-Green, atau Canary. Hasil deployment aplikasi juga haruslah bersifat scalable secara on-demand berdasarkan beban penggunaannya.
4. Integrasi keamanan terpusat menggunakan alat manajemen rahasia (Centralized Secrets Management) dan manajemen sertifikat TLS (Internal PKI) yang disuntikkan secara aman ke dalam kluster/aplikasi.
5. Implementasi manajemen identitas berbasis SSO OIDC (IAM)

B) Opsional:
1. Desain kluster basis data relasional (Relational Database) dan backend manajemen secrets dengan topologi High Availability (HA) terdistribusi.
2. Penggunaan spesifikasi routing tingkat lanjut (seperti Gateway API modern) untuk manajemen trafik ingress ke aplikasi.
3. Implementasi Infrastructure as Code (IaC) untuk mengotomatisasi provisioning platform manajemen atau kluster infrastrukturnya.

## Answer:

# Soal 3: Implementasi / Demo Teknis (MVP)
Buatlah Proof of Concept (PoC) dari desain menyeluruh yang Anda buat pada Soal 2. Anda akan mendemonstrasikan hasil pekerjaan ini pada sesi interview di tahap selanjutnya. Simpan semua konfigurasi (manifes K8s, docker-compose, script pipeline, dan file pendukung lainnya) ke dalam repositori Git publik, yang akan anda submit nantinya.

## Preparation

node-1
- OS Ubuntu 24.04
- CPU: 2 vCPU
- Memory: 4GB
- IP Address: 192.168.113.51/24

node-2
- OS Ubuntu 24.04
- CPU: 2 vCPU
- Memory: 4GB
- IP Address: 192.168.113.52/24

##  Instalasi Kubernetes Cluster dengan RKE2 pada node-1
deploy rke2
```
curl -sfL https://get.rke2.io | sh -
```

install kubectl
```
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

create kubectl config
```
mkdir -p $HOME/.kube
sudo cp -i /etc/rancher/rke2/rke2.yaml $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

export KUBECONFIG=$HOME/.kube/config
```

setup bash for export kubeconfig & completion
```
echo "export KUBECONFIG=$HOME/.kube/config" >> $HOME/.bashrc
echo "source <(kubectl completion bash)" >> $HOME/.bashrc
source $HOME/.bashrc
```

install helm
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
./get_helm.sh
```

## Install Nginx Gateway Fabric pada node-1
Install gateway api. First, create CRD Nginx Gateway Fabric
```
kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v2.4.2" | kubectl apply -f -
```

Install nginx gateway fabric
```
helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric --create-namespace -n nginx-gateway
```

## Install MetalLB pada node-1
Add the official MetalLB Helm chart repository
```
helm repo add metallb https://metallb.github.io/metallb
```

Update your local Helm chart cache
```
helm repo update
```

Install MetalLB using Helm
```
helm install metallb metallb/metallb \
  --namespace metallb-system \
  --create-namespace \
  --wait
```

Create file metallb-config.yaml
This file defines the IP pool and advertisement method for MetalLB
```
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: rke2-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.113.241-192.168.113.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: rke2-l2-advert
  namespace: metallb-system
spec:
  ipAddressPools:
    - rke2-pool
```

apply metallb-config.yaml
```
kubectl apply -f metallb-config.yaml
```
## Install Docker pada node-2

update repository
```
# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
```

install latest version docker
```
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

enable and start service
```
sudo systemctl enable docker
sudo systemctl start docker
```

check status
```
sudo systemctl status docker
```

## Membuat Direktori untuk Persistent Volume
```
sudo mkdir -p /opt/postgres/data
sudo mkdir -p /opt/postgres-keycloak/data
sudo mkdir -p /opt/keycloak/data
sudo mkdir -p /opt/keycloak/certs
sudo mkdir -p /opt/vault/data
sudo mkdir -p /opt/jenkins/home

sudo chown -R 2000:2000 /opt/
```

## Membuat Certificate Authority (CA) dan Server Certificate

Clone the repository
```
git clone https://github.com/syawal/Question-Answer.git
cd Question-Answer
```

create certs directory
```
mkdir certs
cd certs
```

create key for ca
```
openssl genrsa -out syawal-ca.key 4096
```

create cert for ca
```
openssl req -x509 -new -nodes \
-key syawal-ca.key \
-sha256 -days 3650 \
-out syawal-ca.crt \
-subj "/C=ID/ST=Indonesia/L=Jakarta/O=Syawal Local/CN=syawal.local"
```

create key for syawal.local
```
openssl genrsa -out syawal.local.key 4096
```

create csr for syawal.local
```
openssl req -new \
-key syawal.local.key \
-out syawal.local.csr \
-subj "/C=ID/ST=Indonesia/L=Jakarta/O=Syawal Local/CN=*.syawal.local"

cat <<EOF > san.cnf
subjectAltName = DNS:*.syawal.local,DNS:syawal.local
EOF
```

create cert for syawal.local
```
openssl x509 -req \
-in syawal.local.csr \
-CA syawal-ca.crt \
-CAkey syawal-ca.key \
-CAcreateserial \
-out syawal.local.crt \
-days 365 \
-sha256 \
-extfile san.cnf
```

check cert for syawal.local
```
openssl x509 -in syawal.local.crt -text -noout | grep Issuer
```

Copy ca.crt dan server certificate ke vault directory
```
cp syawal-ca.crt /opt/vault/certs/ca.crt
cp syawal.local.crt /opt/vault/certs/vault.crt
cp syawal.local.key /opt/vault/certs/vault.key
```

Copy server certificate ke keycloak directory
```
cp syawal.local.crt /opt/keycloak/certs/server.crt
cp syawal.local.key /opt/keycloak/certs/server.key
```

Copy vault.hcl ke vault directory
```
cd ..
cp /vault/vault.hcl /opt/vault/config/
```

copy policy bookslib ke vault directory
```
cp bookslib-dev.hcl /opt/vault/data/
cp bookslib-prod.hcl /opt/vault/data/
```

Deploy service dengan docker compose
```
docker compose up -d
```

## Inisialisasi Vault
exec shell docker container vault
```
sudo docker exec -it vault sh
export VAULT_CACERT="/vault/certs/ca.crt"
```

init vault
```
vault operator init
```

example output init
```
Unseal Key 1: mAaip7WrZPM/lEgNXAMmavruO4EnqdLOaEgXzQNtxwII
Unseal Key 2: ua/0JeJCUHvPvf6AzsW47HCwvHa/qad+uJlrUXY7vml4
Unseal Key 3: EOF68j+tM2IYQmVOvgDflHZswuRIGyg8P7QY5Lo+hmtq
Unseal Key 4: 9Pygcb7qGTV1v4LickiHl0zBe1SgvSWbNIU2IKz2LbrN
Unseal Key 5: NgFs14zG6FlkfJoRvLBJVP9Hsi+677lJ6kGxxxDzfFcs

Initial Root Token: hvs.qS0VkXVeRC7mvLn6c4sz8Fw5

Vault initialized with 5 key shares and a key threshold of 3. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 3 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated root key. Without at least 3 keys to
reconstruct the root key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
```

unseal vault
```
vault operator unseal mAaip7WrZPM/lEgNXAMmavruO4EnqdLOaEgXzQNtxwII
vault operator unseal ua/0JeJCUHvPvf6AzsW47HCwvHa/qad+uJlrUXY7vml4
vault operator unseal EOF68j+tM2IYQmVOvgDflHZswuRIGyg8P7QY5Lo+hmtq
```

login vault
```
vault login hvs.qS0VkXVeRC7mvLn6c4sz8Fw5
```


export vault token and create kv-v2 secret engine
```
export VAULT_ADDR="https://vault.syawal.local:8200"
export VAULT_TOKEN="hvs.qS0VkXVeRC7mvLn6c4sz8Fw5"

vault token lookup
vault secrets enable -path=kv kv-v2
vault secrets list
```

```
# DEV
vault kv put kv/bookslib/dev/auth-service \
  db_dsn="postgres://user:userpassowrd@192.168.113.52:5432/auth_db?sslmode=disable"

vault kv put kv/bookslib/dev/books-service \
  connection_string="Host=192.168.113.52;Port=5432;Database=books_db;Username=user;Password=userpassowrd"

vault kv put kv/bookslib/dev/reviews-service \
  db_password="userpassowrd"

# PROD (siapkan dari sekarang, bisa sama atau beda password)
vault kv put kv/bookslib/prod/auth-service \
  db_dsn="postgres://user:userpassowrd@192.168.113.52:5432/auth_db?sslmode=disable"

vault kv put kv/bookslib/prod/books-service \
  connection_string="Host=192.168.113.52;Port=5432;Database=books_db;Username=user;Password=userpassowrd"

vault kv put kv/bookslib/prod/reviews-service \
  db_password="userpassowrd"
```

check
```
vault kv get kv/bookslib/dev/auth-service
vault kv get kv/bookslib/dev/books-service
vault kv get kv/bookslib/dev/reviews-service
```

check prod
```
vault kv get kv/bookslib/prod/auth-service
vault kv get kv/bookslib/prod/books-service
vault kv get kv/bookslib/prod/reviews-service
```

## Install External Secrets Operator di node-1
install external secrets operator
```
helm repo add external-secrets https://charts.external-secrets.io

helm install external-secrets \
   external-secrets/external-secrets \
    -n external-secrets \
    --create-namespace \
    --set installCRDs=true
```

## Membuat JWT Service Account Token Reviewer untuk Vault di node-1
Create jwt serviceaccount token reviewer
```
kubectl create namespace vault
kubectl -n vault create serviceaccount vault-token-reviewer
kubectl create clusterrolebinding vault-token-reviewer-binding \
  --clusterrole=system:auth-delegator \
  --serviceaccount=vault:vault-token-reviewer
```

buat secret token yang persisten untuk SA
```
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: vault-token-reviewer-token
  namespace: vault
  annotations:
    kubernetes.io/service-account.name: vault-token-reviewer
type: kubernetes.io/service-account-token
YAML
```
generate jwt token
```
kubectl -n vault create token vault-token-reviewer
```

get ca for vault
```
kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' \
| base64 -d > ca-kube.crt
```

## Konfigurasi Vault Auth Kubernetes di node-2
enable auth kubernetes
```
vault auth enable kubernetes
vault auth list
```

copy token serviceaccount pada kube yang telah dibuat ke sini
```
sudo docker exec -it vault sh
export VAULT_CACERT="/vault/certs/ca.crt"
vault login hvs.qS0VkXVeRC7mvLn6c4sz8Fw5

export VAULT_ADDR="https://vault.syawal.local:8200"
export VAULT_TOKEN="hvs.qS0VkXVeRC7mvLn6c4sz8Fw5"

cd /vault/certs
vault write auth/kubernetes/config \
  kubernetes_host="https://192.168.113.51:6443" \
  kubernetes_ca_cert=@ca-kube.crt \
  token_reviewer_jwt="<SERVICEACCOUNT_TOKEN>"
```

Apply policy dev:
```
vault policy write bookslib-dev /vault/data/bookslib-dev.hcl
```

Di repo GitOps kita, ESO pakai ServiceAccount bookslib-vault-auth di namespace bookslib-dev . Buat role:
```
vault write auth/kubernetes/role/bookslib-dev-eso \
  bound_service_account_names="bookslib-vault-auth" \
  bound_service_account_namespaces="bookslib-dev" \
  policies="bookslib-dev" \
  ttl="10h"
```

Ulangi untuk PROD (policy & role terpisah)
Apply policy prod: 
```
vault policy write bookslib-prod /vault/data/bookslib-prod.hcl

vault write auth/kubernetes/role/bookslib-prod-eso \
  bound_service_account_names="bookslib-vault-auth" \
  bound_service_account_namespaces="bookslib-prod" \
  policies="bookslib-prod" \
  ttl="10h"
```

check
```
vault list auth/kubernetes/role
```

## Setup Jenkins

![jenkins 1](image/jenkins-1.png)

![jenkins 2](image/jenkins-2.png)

![jenkins 3](image/jenkins-3.png)

![jenkins 4](image/jenkins-4.png)

![jenkins 5](image/jenkins-5.png)

![jenkins 6](image/jenkins-6.png)

![jenkins 7](image/jenkins-7.png)

Create key pair for jenkins
```
ssh-keygen -t rsa
```

Create key pair for jenkins-gitops
```
sudo -i
su - jenkins
ssh-keygen -t ed25519 -C "jenkins-gitops" -f ~/.ssh/jenkins_gitops
```

## Install ArgoCD di node-1
deploy argocd
```
kubectl create ns argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

install argocd cli
```
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

expose argocd
```
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
```

get initial password admin
```
argocd admin initial-password -n argocd
```
atau
```
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d; echo
```

Jika `argocd` CLI sudah terpasang:
```
argocd login 192.168.113.51:<Port NodePort SVC argocd-server> --username admin --password "<PASSWORD>"
```

Tambahkan repository ke Argo CD. Karena repo kamu public, repo dapat ditambahkan tanpa credential:
```
argocd repo add https://github.com/walsptr/bookslib.git --type git
argocd repo add https://github.com/walsptr/gitops.git --type git
```

## Update Configmap CoreDNS
```
kubectl  get cm -n kube-system rke2-coredns-rke2-coredns -o yaml > coredns.yaml
```

add line
```
hosts  {
    192.168.113.52  vault.syawal.local
    fallthrough
}
```

apply configmap
```
kubectl apply -f coredns.yaml
```

restart deployment coredns
```
kubectl rollout restart deployment rke2-coredns-rke2-coredns -n kube-system
```

## Bootstrap Project Bookslib di node-1
Buatkan secret ca-cert-secret untuk koneksi secretstore ke vault. Gunakan ca yang tadi kita buat di node-2
```
kubectl -n bookslib-dev create secret generic ca-cert-secret \
  --from-file=ca=./ca-vault.crt

kubectl -n bookslib-prod create secret generic ca-cert-secret \
  --from-file=ca=./ca-vault.crt
```

Apply project:
```
kubectl apply -n argocd -f https://raw.githubusercontent.com/walsptr/gitops/main/argocd/project-bookslib.yaml
```

Deploy App-of-Apps (dev & prod). Cukup apply root Application:
```
kubectl apply -n argocd -f https://raw.githubusercontent.com/walsptr/gitops/main/argocd/app-of-apps/dev.yaml
kubectl apply -n argocd -f https://raw.githubusercontent.com/walsptr/gitops/main/argocd/app-of-apps/prod.yaml
```

Lalu cek di Argo CD UI/CLI:
```
argocd app list
argocd app get bookslib-dev
```
