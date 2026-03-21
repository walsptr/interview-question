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

Selain itu, pada arsitektur menggunakan vault sebagai secret management. Kemudian, menggunakan transit vault untuk auto unseal, namun disini **node transit vault hanya menggunakan 1 node**. Sehingga jika node tersebut down, maka vault akan menjadi tidak dapat diakses.

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

**Problem 4: Node Transit Auto Unseal Vault tidak HA**
```
Node Transit Auto Unseal Vault hanya menggunakan 1 node. Sehingga jika node tersebut down, maka vault akan menjadi tidak dapat diakses.

Untuk best practice seharusnya menggunakan 3 node transit vault. Hal ini akan meningkatkan availability dan fault tolerance dari vault.
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

**Problem 1: Tidak ada Approval Sebelum Production**
```
Jika kita lihat pada diagram CI/CD Pipeline, kita bisa melihat bahwa tidak ada approval step sebelum deployment ke environment production. Hal ini bisa menyebabkan beberapa masalah, seperti:
- Deployment ke production tanpa approval dari tim manajemen.
- Deployment ke production tanpa testing yang cukup.
- Deployment ke production tanpa dokumentasi yang cukup.
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

## Architecture Infrastructure
![Architecture Infrastructure](image/Topology-Page-1.png)

## CI/CD Pipeline Diagram
![Architecture CI/CD](image/Topology-Page-2.png)
![CI/CD Pipeline](image/ci-cd-pipeline-question2.png)


# Soal 3: Implementasi / Demo Teknis (MVP)
Buatlah Proof of Concept (PoC) dari desain menyeluruh yang Anda buat pada Soal 2. Anda akan mendemonstrasikan hasil pekerjaan ini pada sesi interview di tahap selanjutnya. Simpan semua konfigurasi (manifes K8s, docker-compose, script pipeline, dan file pendukung lainnya) ke dalam repositori Git publik, yang akan anda submit nantinya.


# Setup Lab BooksLib 

Dokumen ini merangkum langkah yang saya lakukan di lab untuk menjalankan project BooksLib dengan pola GitOps. Setiap bagian menjelaskan apa yang dikerjakan dan kenapa dibutuhkan. Foto (jika ada) hanya sebagai ilustrasi dan boleh diabaikan.

## Preparation

### Node

**node-1 (Kubernetes / Control Plane)**
- OS: Ubuntu 24.04
- CPU: 2 vCPU
- Memory: 4 GB
- IP Address: 192.168.113.51/24

**node-2 (Infra services via Docker Compose + Jenkins agent host)**
- OS: Ubuntu 24.04
- CPU: 2 vCPU
- Memory: 4 GB
- IP Address: 192.168.113.52/24

---

## 1) Instalasi Kubernetes Cluster dengan RKE2 (node-1)

Tujuan: menyiapkan cluster Kubernetes (RKE2) sebagai tempat menjalankan aplikasi (Helm), Argo CD, External Secrets Operator, dan komponen in-cluster lainnya.

### 1.1 Install RKE2
```
curl -sfL https://get.rke2.io | sh -
```

Aktifkan service RKE2 server:
```
sudo systemctl enable --now rke2-server
sudo systemctl status rke2-server --no-pager
```

### 1.2 Install kubectl
Tujuan: `kubectl` dipakai untuk mengelola cluster (apply manifest, cek pod/service, dsb).
```
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### 1.3 Setup kubeconfig
Setelah install kubectl, kita setup kubeconfig agar bisa mengakses cluster RKE2.
```
mkdir -p $HOME/.kube
sudo cp -i /etc/rancher/rke2/rke2.yaml $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

export KUBECONFIG=$HOME/.kube/config
```

Tambahkan export kubeconfig dan auto-completion ke bash:
```
echo "export KUBECONFIG=$HOME/.kube/config" >> $HOME/.bashrc
echo "source <(kubectl completion bash)" >> $HOME/.bashrc
source $HOME/.bashrc
```

### 1.4 Install Helm
Sekarang kita install Helm untuk mempermudah ketika ingin deploy beberapa aplikasi nantinya.
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
./get_helm.sh
```

### 1.5 Verifikasi cluster
Memastikan RKE2 + kubectl + helm sudah siap sebelum lanjut.
```
kubectl get nodes -o wide
kubectl get ns
helm version
```

## 2) Install NGINX Gateway Fabric (node-1)

Menyediakan layer Gateway API (HTTP routing) untuk expose service aplikasi via subdomain `*.syawal.local`.

### 2.1 Install Gateway API CRD
Install CRD standar Gateway API yang dibutuhkan NGINX Gateway Fabric.
```
kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v2.4.2" | kubectl apply -f -
```

### 2.2 Install NGINX Gateway Fabric
```
helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric --create-namespace -n nginx-gateway
```

## 3) Install MetalLB (node-1)

Karena lab berjalan on-prem/local, MetalLB dipakai untuk menyediakan IP LoadBalancer dari pool LAN.

### 3.1 Tambahkan repo Helm MetalLB
```
helm repo add metallb https://metallb.github.io/metallb
helm repo update
```

### 3.2 Install MetalLB
```
helm install metallb metallb/metallb \
  --namespace metallb-system \
  --create-namespace \
  --wait
```

### 3.3 Konfigurasi IP pool MetalLB
Buat file `metallb-config.yaml` untuk mendefinisikan rentang IP yang boleh dipakai:
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

Apply:
```
kubectl apply -f metallb-config.yaml
```

## 4) Install Docker (node-2)

Node-2 digunakan untuk menjalankan komponen infra via Docker Compose (Vault, Postgres, Jenkins controller, dsb) dan juga menjadi host Jenkins agent untuk build/push image.

### 4.1 Tambahkan repo Docker
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

### 4.2 Install Docker Engine + Compose plugin
```
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 4.3 Aktifkan Docker
```
sudo systemctl enable docker
sudo systemctl start docker
```

Cek status:
```
sudo systemctl status docker
```

## 5) Membuat Direktori untuk Persistent Volume (node-2)

Untuk menyediakan persisten storage bagi semua container infra, kita buat direktori di `/opt/` dengan owner `2000:2000`. 
```
sudo mkdir -p /opt/postgres/data
sudo mkdir -p /opt/postgres-keycloak/data
sudo mkdir -p /opt/keycloak/data
sudo mkdir -p /opt/keycloak/certs
sudo mkdir -p /opt/vault/data
sudo mkdir -p /opt/vault/certs
sudo mkdir -p /opt/vault/config
sudo mkdir -p /opt/jenkins/home

sudo chown -R 2000:2000 /opt/
```

## 6) Membuat Certificate Authority (CA) dan Server Certificate (node-2)

Lab akan menggunakan domain `*.syawal.local` dengan TLS self-signed (dipakai Vault dan komponen lain).

Clone repo yang berisi file pendukung (vault config/policy, dll):
```
git clone https://github.com/walsptr/interview-question.git
cd interview-question
```

Buat direktori cert:
```
mkdir certs
cd certs
```

### 6.1 Buat CA
Buat private key CA:
```
openssl genrsa -out syawal-ca.key 4096
```

Buat sertifikat CA:
```
openssl req -x509 -new -nodes \
-key syawal-ca.key \
-sha256 -days 3650 \
-out syawal-ca.crt \
-subj "/C=ID/ST=Indonesia/L=Jakarta/O=Syawal Local/CN=syawal.local"
```

### 6.2 Buat wildcard sertifikat `*.syawal.local`
Buat private key:
```
openssl genrsa -out syawal.local.key 4096
```

Buat CSR + SAN:
```
openssl req -new \
-key syawal.local.key \
-out syawal.local.csr \
-subj "/C=ID/ST=Indonesia/L=Jakarta/O=Syawal Local/CN=*.syawal.local"

cat <<EOF > san.cnf
subjectAltName = DNS:*.syawal.local,DNS:syawal.local
EOF
```

Sign sertifikat wildcard dengan CA:
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

Verifikasi issuer:
```
openssl x509 -in syawal.local.crt -text -noout | grep Issuer
```

### 6.3 Copy sertifikat ke direktori layanan
Copy CA + server cert ke Vault:
```
cp syawal-ca.crt /opt/vault/certs/ca.crt
cp syawal.local.crt /opt/vault/certs/vault.crt
cp syawal.local.key /opt/vault/certs/vault.key
```

Copy server cert ke Keycloak:
```
cp syawal.local.crt /opt/keycloak/certs/servercrt.pem
cp syawal.local.key /opt/keycloak/certs/serverkey.pem
sudo chmod 644 /opt/keycloak/certs/servercrt.pem
sudo chmod 644 /opt/keycloak/certs/serverkey.pem
```

Copy konfigurasi Vault:
```
cd ..
cp /vault/vault.hcl /opt/vault/config/
```

Copy policy BooksLib ke direktori Vault:
```
cp bookslib-dev.hcl /opt/vault/data/
cp bookslib-prod.hcl /opt/vault/data/
```

## 7) Deploy service infra dengan Docker Compose (node-2)

Tujuan: menjalankan layanan seperti Vault (dan service infra lain sesuai compose) dalam satu host.
```
docker compose up -d
```

## 8) Inisialisasi Vault (node-2)

Tujuan: Vault perlu di-initialize (generate unseal keys + root token) dan di-unseal sebelum bisa dipakai ESO.

Masuk ke shell container vault:
```
sudo docker exec -it vault sh
export VAULT_CACERT="/vault/certs/ca.crt"
```

Init vault:
```
vault operator init
```

Contoh output init:
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

Unseal vault (threshold 3 key):
```
vault operator unseal mAaip7WrZPM/lEgNXAMmavruO4EnqdLOaEgXzQNtxwII
vault operator unseal ua/0JeJCUHvPvf6AzsW47HCwvHa/qad+uJlrUXY7vml4
vault operator unseal EOF68j+tM2IYQmVOvgDflHZswuRIGyg8P7QY5Lo+hmtq
```

Login vault:
```
vault login hvs.qS0VkXVeRC7mvLn6c4sz8Fw5
```

Set alamat Vault + token, lalu enable KV v2:
```
export VAULT_ADDR="https://vault.syawal.local:8200"
export VAULT_TOKEN="hvs.qS0VkXVeRC7mvLn6c4sz8Fw5"

vault token lookup
vault secrets enable -path=kv kv-v2
vault secrets list
```

Masukkan secret untuk DEV/PROD (contoh di lab):
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

Cek secret DEV:
```
vault kv get kv/bookslib/dev/auth-service
vault kv get kv/bookslib/dev/books-service
vault kv get kv/bookslib/dev/reviews-service
```

Cek secret PROD:
```
vault kv get kv/bookslib/prod/auth-service
vault kv get kv/bookslib/prod/books-service
vault kv get kv/bookslib/prod/reviews-service
```

## 9) Install External Secrets Operator (node-1)

ESO digunakan untuk menarik secret dari Vault dan membuat Kubernetes Secret yang dipakai aplikasi.
```
helm repo add external-secrets https://charts.external-secrets.io

helm install external-secrets \
   external-secrets/external-secrets \
    -n external-secrets \
    --create-namespace \
    --set installCRDs=true
```

## 10) Membuat JWT Service Account Token Reviewer untuk Vault (node-1)

Vault Kubernetes auth perlu melakukan TokenReview ke API Server. Untuk itu Vault butuh `token_reviewer_jwt` yang punya RBAC `system:auth-delegator`. Token ini diambil dari Secret service-account token agar stabil.

Buat namespace + serviceaccount + clusterrolebinding:
```
kubectl create namespace vault
kubectl -n vault create serviceaccount vault-token-reviewer
kubectl create clusterrolebinding vault-token-reviewer-binding \
  --clusterrole=system:auth-delegator \
  --serviceaccount=vault:vault-token-reviewer
```

Buat secret token yang persisten untuk SA:
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

Ambil JWT token dari secret (token reviewer):
```
kubectl -n vault get secret vault-token-reviewer-token -o jsonpath='{.data.token}' |base64 -d
```

Ambil CA Kubernetes (dipakai Vault untuk verify API server):
```
kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' \
| base64 -d > ca-kube.crt
```

## 11) Konfigurasi Vault Auth Kubernetes (node-2)

Mengaktifkan auth method `kubernetes` di Vault dan mengaitkan Vault dengan API server Kubernetes (host+CA+token reviewer).

Enable auth kubernetes:
```
vault auth enable kubernetes
vault auth list
```

Masuk ke container vault dan konfigurasi `auth/kubernetes/config`:
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

Apply policy DEV:
```
vault policy write bookslib-dev /vault/data/bookslib-dev.hcl
```

Buat role untuk ESO DEV (ESO memakai ServiceAccount `bookslib-vault-auth` di namespace `bookslib-dev`):
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

Cek role:
```
vault list auth/kubernetes/role
```

## 12) Setup Jenkins (node-2)

Jenkins dipakai untuk build/test aplikasi, push image ke DockerHub, lalu update repo GitOps.

Akses Jenkins menggunakan domain/IP address dari node-2:
![jenkins 1](image/jenkins-1.png)

Ambil initial admin password Jenkins dari volume `/opt/jenkins`:
```
sudo cat /opt/jenkins/home/secrets/initialAdminPassword
```
![jenkins 2](image/jenkins-2.png)

Install plugin yang dibutuhkan (pakai suggested plugins):
![jenkins 3](image/jenkins-3.png)
![jenkins 4](image/jenkins-4.png)

Buat user admin Jenkins:
![jenkins 5](image/jenkins-5.png)

Set URL akses Jenkins:
![jenkins 6](image/jenkins-6.png)

Jenkins siap digunakan:
![jenkins 7](image/jenkins-7.png)

Sekarang kita akan setup node-2 sebagai agent Jenkins.
Buatkan user `jenkins` di node-2:
```
sudo useradd -m -s /bin/bash jenkins
sudo usermod -aG docker jenkins
sudo mkdir -p /home/jenkins/agent
sudo chown -R jenkins:jenkins /home/jenkins
```

Generate key pair untuk Jenkins agent (untuk SSH ke host agent):
```
ssh-keygen -t rsa
cat .ssh/id_rsa.pub

# Taruh public key di sini
sudo -u jenkins mkdir -p /home/jenkins/.ssh
sudo -u jenkins chmod 700 /home/jenkins/.ssh
sudo tee -a /home/jenkins/.ssh/authorized_keys > /dev/null <<'EOF'
REPLACE_ME_PUBLIC_KEY
EOF
sudo -u jenkins chmod 600 /home/jenkins/.ssh/authorized_keys
```

Install dependencies di node-2:
```
sudo apt-get update
sudo apt-get install -y openjdk-21-jre-headless git openssh-server python3 python3-pip
sudo -u jenkins python3 -m pip install --user pyyaml --break-system-packages
```

Tambahkan node-2 sebagai agent Jenkins:
![jenkins add agent](image/jenkins-add-agent.png)

Buat token akses DockerHub (untuk push image):
![dockerhub token](image/jenkins-create-dockerhub-token.png)

Tambahkan credential DockerHub (untuk push image):
- Menu: Manage Jenkins -> Manage Credentials -> Global credentials (unrestricted) -> Add Credentials
- Pilih: Username with password
- Password: token dari DockerHub
![jenkins docker creds](image/jenkins-add-dockerhub-creds.png)

Buat key pair GitHub untuk user `jenkins` (dipakai push repo GitOps via SSH):
```
sudo -i
su - jenkins
ssh-keygen -t ed25519 -C "jenkins-gitops" -f ~/.ssh/jenkins_gitops
```

Tambahkan public key ke GitHub (deploy key / ssh key) agar Jenkins agent bisa autentikasi:
![add pubkey jenkins to github](image/jenkins-add-pubkey-github.png)

Tambahkan private key ke Jenkins Credentials:
- Menu: Manage Jenkins -> Manage Credentials -> Global credentials (unrestricted) -> Add Credentials
- Pilih: SSH Username with private key
![add private jenkins to credential](image/jenkins-add-privkey-github.png)

## 13) Install Argo CD (node-1)

Tujuan: Argo CD menjadi engine GitOps yang membaca repo GitOps dan melakukan deploy/sync ke cluster.

Deploy Argo CD:
```
kubectl create ns argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Verifikasi pod Argo CD:
```
kubectl -n argocd get pods
kubectl -n argocd get svc
```

Install Argo CD CLI:
```
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

Expose Argo CD (lab):
```
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
```

Ambil initial password admin:
```
argocd admin initial-password -n argocd
```
atau:
```
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d; echo
```

Login via CLI:
```
argocd login 192.168.113.51:<Port NodePort SVC argocd-server> --username admin --password "<PASSWORD>"
```

Tambahkan repository ke Argo CD (repo public):
```
argocd repo add https://github.com/walsptr/bookslib.git --type git
argocd repo add https://github.com/walsptr/gitops.git --type git
```

## 14) Update ConfigMap CoreDNS (node-1)

Tujuan: pod di cluster perlu bisa resolve `vault.syawal.local`. Karena ini domain local lab, resolusinya ditambahkan via CoreDNS `hosts` plugin.

Export ConfigMap CoreDNS:
```
kubectl  get cm -n kube-system rke2-coredns-rke2-coredns -o yaml > coredns.yaml
```

Tambahkan blok berikut pada Corefile:
```
hosts  {
    192.168.113.52  vault.syawal.local
    fallthrough
}
```

Apply ConfigMap:
```
kubectl apply -f coredns.yaml
```

Restart deployment CoreDNS:
```
kubectl rollout restart deployment rke2-coredns-rke2-coredns -n kube-system
```

## 15) Bootstrap Project BooksLib (node-1)

Tujuan: menyiapkan prasyarat GitOps (CA secret untuk koneksi Vault), lalu bootstrap Argo CD AppProject dan App-of-Apps.

Buat namespace aplikasi:
```
kubectl create ns bookslib-dev
kubectl create ns bookslib-prod
```

Buat secret `ca-cert-secret` untuk koneksi SecretStore -> Vault (gunakan CA yang dibuat di node-2):
```
kubectl -n bookslib-dev create secret generic ca-cert-secret \
  --from-file=ca=./ca-vault.crt

kubectl -n bookslib-prod create secret generic ca-cert-secret \
  --from-file=ca=./ca-vault.crt
```

Apply AppProject:
```
kubectl apply -n argocd -f https://raw.githubusercontent.com/walsptr/gitops/main/argocd/project-bookslib.yaml
```

Deploy App-of-Apps (dev & prod):
```
kubectl apply -n argocd -f https://raw.githubusercontent.com/walsptr/gitops/main/argocd/app-of-apps/dev.yaml
kubectl apply -n argocd -f https://raw.githubusercontent.com/walsptr/gitops/main/argocd/app-of-apps/prod.yaml
```

Verifikasi dari CLI:
```
argocd app list
argocd app get bookslib-dev
```

## 16) Setup Pipeline Jenkins (node-2)
Buat job baru pada jenkins dengan type multibranch pipeline.
![jenkins create multibranch pipeline](image/jenkins-create-multibranch-pipeline.png)

Tambahkan branch source, arahkan branch source ke repository aplikasi bookslib:
![jenkins add branch source](image/jenkins-add-branch-source.png)

Tentukan nama jenkinsfile yang akan digunakan oleh pipeline, pastikan jenkinsfile ada di root repository aplikasi bookslib:
![jenkins add jenkinsfile](image/jenkins-add-jenkinsfile.png)
Disini saya juga enable auto scan repository, agar setiap ada perubahan di branch, pipeline akan di trigger.

Untuk pertama kali build, edit environment variable 'FORCE_BUILD_ALL' dengan nilai 'true':
![jenkins add env var](image/jenkins-add-env-var.png)

Jika build berhasil, edit environment variable 'FORCE_BUILD_ALL' dengan nilai 'false', agar hanya build aplikasi yang ada perubahan:
![jenkins add env var](image/jenkins-add-env-var-2.png)

Pada branch/environment prod, perlu dilakukan approval pull request sebelum di merge ke branch main gitops.
![jenkins add approval](image/jenkins-add-approval.png)
![jenkins add approval](image/jenkins-add-approval-2.png)
Kemudian baru kita lakukan sync secara manual di Argo CD.