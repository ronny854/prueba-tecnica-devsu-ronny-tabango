# 🚀 Prueba Técnica DevOps - Ronny Tabango

[![Pipeline Status](https://img.shields.io/badge/pipeline-passing-brightgreen)](https://dev.azure.com)
[![Docker](https://img.shields.io/badge/docker-hub-blue)](https://hub.docker.com/r/ronnyt854/demo-devops-python)
[![Kubernetes](https://img.shields.io/badge/kubernetes-1.28-326CE5)](https://kubernetes.io)
[![Python](https://img.shields.io/badge/python-3.11-3776AB)](https://www.python.org)

Implementación completa de CI/CD con Azure DevOps, Dockerización optimizada y despliegue en Kubernetes (Minikube) con arquitectura cliente-servidor.

---

## 📑 Tabla de Contenidos

- [Arquitectura](#-arquitectura)
- [Requisitos Previos](#-requisitos-previos)
- [Guía de Configuración del Entorno](#️-guía-de-configuración-del-entorno)
  - [1. Configuración de Máquinas Virtuales](#1-configuración-de-máquinas-virtuales)
  - [2. Configuración de Minikube Server](#2-configuración-de-minikube-server)
  - [3. Configuración de Azure Agent](#3-configuración-de-azure-agent)
  - [4. Configuración de Red y Comunicación](#4-configuración-de-red-y-comunicación)
- [Configuración de Azure DevOps](#️-configuración-de-azure-devops)
  - [Service Connections](#service-connections)
  - [Variable Groups](#variable-groups)
- [Pipeline CI/CD](#-pipeline-cicd)
- [Manifiestos de Kubernetes](#-manifiestos-de-kubernetes)
- [Cómo Usar](#-cómo-usar)
- [Endpoints de la API](#-endpoints-de-la-api)
- [Troubleshooting](#-troubleshooting)

---

## 🏗️ Arquitectura

### Diagrama de Arquitectura General

**[INSERTE_IMAGEN_AQUI: arquitectura-general.png]**

```
┌─────────────────────────────────────────────────────────────┐
│                    VirtualBox Host                          │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │         NatNetwork (10.0.2.0/24)                   │    │
│  │                                                     │    │
│  │  ┌──────────────────┐      ┌──────────────────┐   │    │
│  │  │  Minikube Server │      │   Azure Agent    │   │    │
│  │  │   10.0.2.3       │◄────►│    10.0.2.4      │   │    │
│  │  │                  │ SSH  │                  │   │    │
│  │  │  ┌────────────┐  │      │  ┌────────────┐ │   │    │
│  │  │  │ Minikube   │  │      │  │Azure DevOps│ │   │    │
│  │  │  │ Cluster    │  │      │  │   Agent    │ │   │    │
│  │  │  │            │  │      │  └────────────┘ │   │    │
│  │  │  │ Django App │  │      │                  │   │    │
│  │  │  └────────────┘  │      │                  │   │    │
│  │  └──────────────────┘      └──────────────────┘   │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
         │                            ▲
         │                            │
         ▼                            │
   ┌──────────┐              ┌───────────────┐
   │  Docker  │              │ Azure DevOps  │
   │   Hub    │              │   Pipelines   │
   └──────────┘              └───────────────┘
```

### Características de las Máquinas Virtuales

| Característica | Minikube Server (10.0.2.3) | Azure Agent (10.0.2.4) |
|----------------|----------------------------|------------------------|
| **Sistema Operativo** | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS |
| **RAM** | 3 GB | 2 GB |
| **CPUs** | 3 cores | 2 cores |
| **Disco** | 20 GB | 20 GB |
| **Software** | Docker, Minikube, kubectl | Docker, Azure Agent, kubectl |
| **Rol** | Servidor de Kubernetes | Agente de CI/CD |
| **Red** | NatNetwork - 10.0.2.3 | NatNetwork - 10.0.2.4 |

---

## 📋 Requisitos Previos

### Software Necesario

- **VirtualBox** (>= 6.1)
- **Ubuntu 22.04 LTS** ISO
- **Azure DevOps Account** con permisos de administrador
- **Docker Hub Account**
- **Cuenta de SonarCloud** (opcional)

### Conocimientos Requeridos

- Básicos de Linux y terminal
- Conceptos de Docker y Kubernetes
- Fundamentos de CI/CD
- Configuración de VirtualBox

---

## 🛠️ Guía de Configuración del Entorno

### 1. Configuración de Máquinas Virtuales

#### 1.1 Crear Red NAT en VirtualBox

```bash
# Desde la terminal de tu sistema host (Windows/Linux/Mac)
VBoxManage natnetwork add --netname NatNetwork --network "10.0.2.0/24" --enable
```

O desde la interfaz gráfica de VirtualBox:
1. Archivo → Preferencias → Red
2. Click en el ícono "+" para agregar red NAT
3. Nombre: `NatNetwork`
4. CIDR IPv4: `10.0.2.0/24`
5. Habilitar DHCP: ❌ (desmarcar)

**[INSERTE_IMAGEN_AQUI: virtualbox-natnetwork.png]**

#### 1.2 Crear VM: Minikube Server

1. **Nueva VM en VirtualBox:**
   - Nombre: `minikube-server`
   - Tipo: Linux
   - Versión: Ubuntu (64-bit)
   - RAM: 3072 MB (3 GB)
   - CPUs: 3
   - Disco: 20 GB (dinámico)

2. **Configurar Red:**
   - Red → Adaptador 1
   - Conectar a: `Red NAT`
   - Nombre: `NatNetwork`

3. **Instalar Ubuntu 22.04:**
   - Usuario: `ronny` (o el que prefieras)
   - Contraseña: `<tu-password>`
   - Hostname: `minikube-server`

4. **Configurar IP Estática:**

```bash
# Dentro de la VM minikube-server
sudo nano /etc/netplan/00-installer-config.yaml
```

Contenido:
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      addresses:
        - 10.0.2.3/24
      routes:
        - to: default
          via: 10.0.2.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
```

Aplicar configuración:
```bash
sudo netplan apply
ip addr show enp0s3  # Verificar IP 10.0.2.3
```

#### 1.3 Crear VM: Azure Agent

Repetir el proceso anterior con las siguientes diferencias:

- Nombre: `azure-agent`
- RAM: 2048 MB (2 GB)
- CPUs: 2
- Hostname: `azure-agent`
- IP: `10.0.2.4/24` (en netplan)

---

### 2. Configuración de Minikube Server

#### 2.1 Instalación Automática con Script

**Descargar e instalar Minikube** usando el script `minikube-install.sh`:

```bash
# En la VM minikube-server (10.0.2.3)
cd ~
wget https://raw.githubusercontent.com/ronny854/prueba-tecnica-devsu-ronny-tabango/main/scripts/minikube-install.sh
chmod +x minikube-install.sh
sudo ./minikube-install.sh
```

El script realiza:
- ✅ Instalación de Docker
- ✅ Instalación de kubectl
- ✅ Instalación de Minikube
- ✅ Inicio de Minikube con configuración optimizada
- ✅ Habilitación de addons: `ingress`, `metrics-server`
- ✅ Configuración de permisos para usuario

**[INSERTE_IMAGEN_AQUI: minikube-installation.png]**

#### 2.2 Verificación de Minikube

```bash
# Verificar instalación
minikube status
kubectl get nodes
kubectl get pods -A

# Debería mostrar:
# minikube
# type: Control Plane
# host: Running
# kubelet: Running
# apiserver: Running
```

#### 2.3 Configuración de DNS y Port Forwarding

**Configurar hosts para Ingress:**

```bash
# Agregar entrada en /etc/hosts
sudo sh -c "echo '$(minikube ip) prueba.devsu.demopython.ronnytabango.com' >> /etc/hosts"

# Verificar
cat /etc/hosts | grep prueba.devsu
```

**Habilitar Port Forwarding (mantener en ejecución):**

```bash
# En una sesión de terminal permanente o usando screen/tmux
kubectl port-forward svc/demo-devops-python-service 30800:8000 -n myapp --address 0.0.0.0
```

Para mantenerlo permanente:

```bash
# Crear servicio systemd
sudo nano /etc/systemd/system/k8s-portforward.service
```

Contenido:
```ini
[Unit]
Description=Kubernetes Port Forward for Demo App
After=network.target

[Service]
Type=simple
User=ronny
ExecStart=/usr/bin/kubectl port-forward svc/demo-devops-python-service 30800:8000 -n myapp --address 0.0.0.0
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Habilitar:
```bash
sudo systemctl daemon-reload
sudo systemctl enable k8s-portforward
sudo systemctl start k8s-portforward
sudo systemctl status k8s-portforward
```

---

### 3. Configuración de Azure Agent

#### 3.1 Instalación con Script

**Descargar e instalar Azure Agent** usando el script `azure-agent-install.sh`:

```bash
# En la VM azure-agent (10.0.2.4)
cd ~
wget https://raw.githubusercontent.com/ronny854/prueba-tecnica-devsu-ronny-tabango/main/scripts/azure-agent-install.sh
chmod +x azure-agent-install.sh
sudo ./azure-agent-install.sh
```

El script realiza:
- ✅ Instalación de Docker
- ✅ Instalación de kubectl
- ✅ Descarga del Azure DevOps Agent
- ✅ Instalación de dependencias necesarias
- ✅ Creación de directorio `/opt/azagent`

**[INSERTE_IMAGEN_AQUI: azure-agent-installation.png]**

#### 3.2 Configuración del Agente

Después de ejecutar el script, configurar manualmente:

```bash
cd /opt/azagent

# Configurar el agente
./config.sh
```

**Información a proporcionar:**

```
Server URL: https://dev.azure.com/<tu-organizacion>
Authentication type: PAT
Personal Access Token: <tu-token-con-permisos-agent-pools>
Agent pool: minikube-agents
Agent name: azure-agent-01
Work folder: _work
Run agent as service: Y
```

**Generar Personal Access Token (PAT):**

1. Azure DevOps → User Settings → Personal Access Tokens
2. New Token
3. Name: `agent-pool-token`
4. Organization: `<tu-organizacion>`
5. Scopes: `Agent Pools (Read & manage)`
6. Create
7. **Copiar el token** (solo se muestra una vez)

**[INSERTE_IMAGEN_AQUI: azure-pat-creation.png]**

#### 3.3 Iniciar el Agente

```bash
# Instalar como servicio
sudo ./svc.sh install

# Iniciar servicio
sudo ./svc.sh start

# Verificar estado
sudo ./svc.sh status
```

Verificar en Azure DevOps:
1. Project Settings → Agent pools
2. `minikube-agents` → Agents
3. Ver `azure-agent-01` con estado **Online**

**[INSERTE_IMAGEN_AQUI: azure-agent-online.png]**

---

### 4. Configuración de Red y Comunicación

#### 4.1 Configuración SSH entre VMs

**En Minikube Server (10.0.2.3):**

```bash
# Generar clave SSH
ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""

# Mostrar clave pública
cat ~/.ssh/id_rsa.pub
```

**En Azure Agent (10.0.2.4):**

```bash
# Crear directorio SSH si no existe
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Agregar clave pública de Minikube Server
nano ~/.ssh/authorized_keys
# Pegar la clave pública de minikube-server
chmod 600 ~/.ssh/authorized_keys
```

**Verificar conexión desde Azure Agent:**

```bash
# Desde azure-agent
ssh ronny@10.0.2.3

# Debería conectar sin pedir contraseña
# Probar comando kubectl
ssh ronny@10.0.2.3 "kubectl get nodes"
```

**[INSERTE_IMAGEN_AQUI: ssh-configuration.png]**

#### 4.2 Configuración de kubectl en Azure Agent

```bash
# En azure-agent
mkdir -p ~/.kube

# Copiar kubeconfig desde minikube-server
scp ronny@10.0.2.3:~/.kube/config ~/.kube/config

# Verificar acceso
kubectl get nodes

# Debería mostrar el nodo de minikube
```

#### 4.3 Diagrama de Comunicación

**[INSERTE_IMAGEN_AQUI: network-diagram.png]**

```
┌──────────────────────────────────────────────────┐
│          NatNetwork (10.0.2.0/24)                │
│                                                   │
│  ┌────────────────┐          ┌────────────────┐ │
│  │ Minikube Server│          │  Azure Agent   │ │
│  │   10.0.2.3     │◄────────►│   10.0.2.4     │ │
│  │                │   SSH    │                │ │
│  │                │  kubectl │                │ │
│  └────────────────┘          └────────────────┘ │
│         ▲                            │          │
│         │                            │          │
│         │ kubectl                    │ Pipeline │
│         │                            ▼          │
│  ┌──────────────────────────────────────────┐  │
│  │       Kubernetes (Minikube)              │  │
│  │  - Namespace: myapp                      │  │
│  │  - Pods: demo-devops-python (2 réplicas) │  │
│  │  - Service: ClusterIP :8000              │  │
│  │  - Ingress: prueba.devsu...com           │  │
│  └──────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
```

---

## ⚙️ Configuración de Azure DevOps

### Service Connections

Crear las siguientes Service Connections en Azure DevOps:

#### 1. Docker Hub Connection

**Pasos:**

1. Azure DevOps → Project Settings → Service connections
2. New service connection → Docker Registry
3. Configuración:
   - **Registry type:** Docker Hub
   - **Docker Registry:** `https://index.docker.io/v1/`
   - **Docker ID:** `<tu-usuario-dockerhub>`
   - **Docker Password:** `<tu-password-o-token>`
   - **Service connection name:** `dockerRegistryServiceConnection`
4. Verify and save

**[INSERTE_IMAGEN_AQUI: dockerhub-service-connection.png]**

#### 2. SonarCloud Connection

**Pasos:**

1. New service connection → SonarCloud
2. Configuración:
   - **SonarCloud Token:** `<tu-token-sonarcloud>`
   - **Service connection name:** `conection-sonarqube-github-account`
3. Verify and save

**Generar Token en SonarCloud:**

1. SonarCloud → My Account → Security
2. Generate Tokens
3. Name: `azure-devops-token`
4. Generate
5. **Copiar el token**

**[INSERTE_IMAGEN_AQUI: sonarcloud-service-connection.png]**

---

### Variable Groups

Crear Variable Group en Azure DevOps Library:

**Pasos:**

1. Azure DevOps → Pipelines → Library
2. + Variable group
3. Nombre: `MINIKUBE-VARS`
4. Agregar las siguientes variables:

| Variable Name | Value | Secret |
|---------------|-------|--------|
| `DJANGO_SECRET_KEY` | `<django-secret-key-generado>` | ✅ Yes |
| `VM_IP` | `10.0.2.3` | ❌ No |
| `VM_USER` | `ronny` | ❌ No |

**Generar Django Secret Key:**

```bash
python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

5. Save

**[INSERTE_IMAGEN_AQUI: variable-group.png]**

**Uso en Pipeline:**

```yaml
variables:
- group: MINIKUBE-VARS
```

Esto permite centralizar la configuración y reutilizar variables entre pipelines.

---

## 🔄 Pipeline CI/CD

### Diagrama del Pipeline

**[INSERTE_IMAGEN_AQUI: pipeline-diagram.png]**

```
┌─────────────────────────────────────────────────────────┐
│                  STAGE 1: BUILD & TEST                  │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐           │
│  │  Unit    │──►│  Flake8  │──►│ Coverage │           │
│  │  Tests   │   │  Linting │   │  Report  │           │
│  └──────────┘   └──────────┘   └──────────┘           │
│                                                          │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐           │
│  │  Bandit  │──►│SonarCloud│──►│  Docker  │           │
│  │ Security │   │ Analysis │   │  Build   │           │
│  └──────────┘   └──────────┘   └──────────┘           │
│                                      │                   │
└──────────────────────────────────────┼──────────────────┘
                                       ▼
┌─────────────────────────────────────────────────────────┐
│              STAGE 2: DOCKER PUSH                       │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐           │
│  │  Trivy   │──►│  Docker  │──►│  Publish │           │
│  │  Scan    │   │   Tag    │   │   Hub    │           │
│  └──────────┘   └──────────┘   └──────────┘           │
│                                      │                   │
└──────────────────────────────────────┼──────────────────┘
                                       ▼
┌─────────────────────────────────────────────────────────┐
│         STAGE 3: KUBERNETES DEPLOY                      │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐           │
│  │SSH Check │──►│  Apply   │──►│  Verify  │           │
│  │          │   │Manifests │   │ Rollout  │           │
│  └──────────┘   └──────────┘   └──────────┘           │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Tareas del Pipeline

#### Stage 1: Build & Test

| Tarea | Descripción |
|-------|-------------|
| **Install Dependencies** | Instala dependencias Python con pip desde requirements.txt |
| **Run Unit Tests** | Ejecuta tests de Django con pytest/unittest |
| **Code Coverage** | Genera reporte de cobertura de código con coverage.py |
| **Flake8 Linting** | Análisis de estilo de código Python según PEP 8 |
| **Bandit Security** | Escaneo de vulnerabilidades de seguridad en código Python |
| **SonarCloud Analysis** | Análisis de calidad de código, code smells y bugs |
| **Docker Build** | Construcción de imagen Docker multi-stage |

#### Stage 2: Docker Push

| Tarea | Descripción |
|-------|-------------|
| **Trivy Scan** | Escaneo de vulnerabilidades en imagen Docker |
| **Docker Tag** | Etiquetado de imagen con BUILD_ID y latest |
| **Docker Push** | Publicación de imagen a Docker Hub |

#### Stage 3: Kubernetes Deploy

| Tarea | Descripción |
|-------|-------------|
| **SSH Validation** | Verificación de conectividad SSH a Minikube Server |
| **rsync Manifests** | Sincronización de archivos K8s a servidor |
| **Apply Manifests** | Aplicación de recursos de Kubernetes con kubectl |
| **Update Image** | Actualización de deployment con nueva imagen |
| **Rollout Status** | Verificación de despliegue exitoso |
| **Smoke Tests** | Pruebas básicas de conectividad a pods |

---

## 📦 Manifiestos de Kubernetes

### Estructura de Recursos K8s

```
k8s/
├── namespace.yaml          # Namespace aislado
├── configmap.yaml          # Variables de configuración
├── secret.yaml             # Información sensible
├── pvc.yaml                # Almacenamiento persistente
├── deployment.yaml         # Pods y replicación
├── service.yaml            # Exposición interna
├── ingress.yaml            # Exposición externa
├── hpa.yaml                # Auto-escalado
├── pdb.yaml                # Disponibilidad
├── networkpolicy.yaml      # Seguridad de red
└── resourcequota.yaml      # Límites de recursos
```

### Descripción de Manifiestos

| Archivo | Descripción | Recursos Clave |
|---------|-------------|----------------|
| **namespace.yaml** | Crea namespace `myapp` para aislar recursos | namespace: myapp |
| **configmap.yaml** | Variables de entorno no sensibles (DEBUG, ALLOWED_HOSTS) | ConfigMap con configs de Django |
| **secret.yaml** | Datos sensibles en base64 (DJANGO_SECRET_KEY) | Secret con credenciales |
| **pvc.yaml** | Solicitud de almacenamiento persistente para SQLite | PVC de 2Gi |
| **deployment.yaml** | Define pods, réplicas, health checks, recursos | 2 réplicas con rolling update |
| **service.yaml** | Expone pods internamente en el cluster | ClusterIP en puerto 80 |
| **ingress.yaml** | Expone aplicación externamente vía NGINX | Host: prueba.devsu... |
| **hpa.yaml** | Escalado automático basado en CPU/Memoria | Min: 2, Max: 5 réplicas |
| **pdb.yaml** | Garantiza disponibilidad durante actualizaciones | Min: 1 pod disponible |
| **networkpolicy.yaml** | Reglas de firewall para pods | Ingress/Egress controlado |
| **resourcequota.yaml** | Límites de recursos en el namespace | CPU/Memory quotas |

### Diagrama de Recursos K8s

**[INSERTE_IMAGEN_AQUI: kubernetes-resources.png]**

```
┌──────────────────────────────────────────────────┐
│            Namespace: myapp                      │
│                                                   │
│  ┌────────────────────────────────────────────┐ │
│  │         Ingress (NGINX)                    │ │
│  │  prueba.devsu.demopython.ronnytabango.com  │ │
│  └────────────────┬───────────────────────────┘ │
│                   │                              │
│  ┌────────────────▼───────────────────────────┐ │
│  │    Service: demo-devops-python-service     │ │
│  │    Type: ClusterIP, Port: 80 → 8000        │ │
│  └────────────────┬───────────────────────────┘ │
│                   │                              │
│  ┌────────────────▼───────────────────────────┐ │
│  │   Deployment: demo-devops-python           │ │
│  │   Replicas: 2 (HPA: 2-5)                   │ │
│  │   ┌──────────┐      ┌──────────┐          │ │
│  │   │  Pod 1   │      │  Pod 2   │          │ │
│  │   │ Django   │      │ Django   │          │ │
│  │   │ App      │      │ App      │          │ │
│  │   └──────────┘      └──────────┘          │ │
│  │       │                   │                 │ │
│  │       ▼                   ▼                 │ │
│  │  ┌──────────┐      ┌──────────┐           │ │
│  │  │ConfigMap │      │ Secret   │           │ │
│  │  └──────────┘      └──────────┘           │ │
│  │       │                                     │ │
│  │       ▼                                     │ │
│  │  ┌──────────┐                              │ │
│  │  │   PVC    │                              │ │
│  │  │ SQLite   │                              │ │
│  │  └──────────┘                              │ │
│  └────────────────────────────────────────────┘ │
│                                                   │
│  Managed by:                                     │
│  - HPA (Auto-scaling)                            │
│  - PDB (Disruption Budget)                       │
│  - NetworkPolicy (Firewall)                      │
│  - ResourceQuota (Limits)                        │
└──────────────────────────────────────────────────┘
```

---

## 🚀 Cómo Usar

### Despliegue Manual (Primera Vez)

```bash
# 1. Clonar repositorio
git clone https://github.com/ronny854/prueba-tecnica-devsu-ronny-tabango.git
cd prueba-tecnica-devsu-ronny-tabango

# 2. En Minikube Server (10.0.2.3)
# Aplicar manifiestos
kubectl create namespace myapp
kubectl apply -f k8s/configmap.yaml -n myapp
kubectl apply -f k8s/secret.yaml -n myapp
kubectl apply -f k8s/pvc.yaml -n myapp
kubectl apply -f k8s/deployment.yaml -n myapp
kubectl apply -f k8s/service.yaml -n myapp
kubectl apply -f k8s/ingress.yaml -n myapp
kubectl apply -f k8s/hpa.yaml -n myapp
kubectl apply -f k8s/pdb.yaml -n myapp

# 3. Verificar despliegue
kubectl get all -n myapp
kubectl rollout status deployment/demo-devops-python -n myapp

# 4. Obtener URL
minikube service demo-devops-python-service -n myapp --url
```

### Despliegue Automático (CI/CD)

```bash
# Simplemente hacer push a la rama main o develop
git add .
git commit -m "feat: nueva funcionalidad"
git push origin main

# El pipeline se ejecutará automáticamente y desplegará
```

### Acceso a la Aplicación

**Método 1: Port Forward**
```bash
# Desde Minikube Server
kubectl port-forward svc/demo-devops-python-service 30800:8000 -n myapp --address 0.0.0.0

# Acceder desde navegador
http://10.0.2.3:30800/api/
```

**Método 2: Ingress**
```bash
# Configurar /etc/hosts en tu máquina local
# <minikube-ip> prueba.devsu.demopython.ronnytabango.com

# Acceder desde navegador
http://prueba.devsu.demopython.ronnytabango.com/api/
```

**Método 3: NodePort (desde VMs)**
```bash
# Obtener NodePort
kubectl get svc -n myapp

# Acceder
curl http://$(minikube ip):30800/api/
```

---

## 📡 Endpoints de la API

La aplicación Django REST expone los siguientes endpoints:

### Health Check
```bash
GET /api/
Response: {"status": "ok", "message": "API is running"}
```

### Users CRUD

**Listar Usuarios**
```bash
GET /api/users/
Response: [
  {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com"
  }
]
```

**Crear Usuario**
```bash
POST /api/users/
Body: {
  "username": "nuevo_usuario",
  "email": "nuevo@example.com",
  "password": "password123"
}
Response: {
  "id": 2,
  "username": "nuevo_usuario",
  "email": "nuevo@example.com"
}
```

**Obtener Usuario**
```bash
GET /api/users/{id}/
Response: {
  "id": 1,
  "username": "admin",
  "email": "admin@example.com"
}
```

**Actualizar Usuario**
```bash
PUT /api/users/{id}/
Body: {
  "username": "admin_updated",
  "email": "admin@example.com"
}
```

**Eliminar Usuario**
```bash
DELETE /api/users/{id}/
Response: 204 No Content
```

---

## 🐛 Troubleshooting

### Problemas Comunes

#### 1. Pipeline Falla en Stage de Deploy

**Síntoma:** Error de conexión SSH al servidor Minikube

**Solución:**
```bash
# Verificar SSH desde Azure Agent
ssh ronny@10.0.2.3

# Si falla, verificar:
# 1. IP correcta en variable VM_IP
# 2. Clave SSH en ~/.ssh/authorized_keys de minikube-server
# 3. Firewall en minikube-server

# Regenerar clave SSH si es necesario
ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa
ssh-copy-id ronny@10.0.2.3
```

#### 2. Pods en CrashLoopBackOff

**Síntoma:** Pods se reinician constantemente

**Solución:**
```bash
# Ver logs del pod
kubectl logs -l app=demo-devops-python -n myapp --tail=50

# Describir pod para ver eventos
kubectl describe pod -l app=demo-devops-python -n myapp

# Causas comunes:
# - DJANGO_SECRET_KEY no configurado
# - Migraciones fallidas
# - Puerto 8000 ya en uso
```

#### 3. Servicio No Accesible

**Síntoma:** No se puede acceder a la aplicación

**Solución:**
```bash
# Verificar que los pods están Running
kubectl get pods -n myapp

# Verificar que el servicio tiene endpoints
kubectl get endpoints demo-devops-python-service -n myapp

# Verificar Ingress
kubectl get ingress -n myapp
kubectl describe ingress demo-devops-python-ingress -n myapp

# Verificar port-forward
sudo systemctl status k8s-portforward
```

#### 4. HPA No Escala

**Síntoma:** HPA no crea réplicas adicionales

**Solución:**
```bash
# Verificar metrics-server
kubectl get pods -n kube-system | grep metrics-server

# Si no está, habilitar addon
minikube addons enable metrics-server

# Verificar métricas
kubectl top pods -n myapp
kubectl top nodes

# Ver estado de HPA
kubectl describe hpa demo-devops-python-hpa -n myapp
```

#### 5. Imagen Docker No Se Descarga

**Síntoma:** ImagePullBackOff en pods

**Solución:**
```bash
# Verificar que la imagen existe en Docker Hub
docker pull ronnyt854/demo-devops-python:latest

# Verificar imagePullPolicy en deployment
# Cambiar a Always si es necesario

# Verificar que no hay rate limits de Docker Hub
```

---

## 📊 Monitoreo y Métricas

### Ver Logs de la Aplicación

```bash
# Logs de todos los pods
kubectl logs -l app=demo-devops-python -n myapp

# Logs en tiempo real
kubectl logs -f -l app=demo-devops-python -n myapp

# Logs del pod específico
kubectl logs <pod-name> -n myapp
```

### Métricas de Recursos

```bash
# CPU y Memoria de pods
kubectl top pods -n myapp

# CPU y Memoria de nodos
kubectl top nodes

# Estado del HPA
kubectl get hpa -n myapp -w
```

### Dashboard de Kubernetes

```bash
# Habilitar dashboard
minikube addons enable dashboard

# Acceder al dashboard
minikube dashboard

# O acceder remotamente
kubectl proxy --address='0.0.0.0' --accept-hosts='.*'
# http://10.0.2.3:8001/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/
```

---

## 📂 Estructura del Proyecto

```
prueba-tecnica-devsu-ronny-tabango/
├── devsu-demo-devops-python/       # Aplicación Django
│   ├── api/                        # API REST
│   │   ├── models.py              # Modelos de datos
│   │   ├── serializers.py         # Serializadores DRF
│   │   ├── views.py               # Vistas de API
│   │   └── urls.py                # URLs de API
│   ├── demo/                       # Configuración Django
│   │   ├── settings.py            # Settings de producción
│   │   ├── urls.py                # URLs principales
│   │   └── wsgi.py                # WSGI para Gunicorn
│   ├── Dockerfile                 # Multi-stage build
│   ├── entrypoint.sh              # Script de inicialización
│   ├── requirements.txt           # Dependencias Python
│   └── manage.py                  # CLI de Django
├── devops/                         # CI/CD Azure DevOps
│   ├── azure-pipelines.yml        # Pipeline principal
│   └── stages/
│       ├── buildPythonStage.yml   # Build, test y análisis
│       └── kubernetesDeploy.yml   # Despliegue K8s
├── k8s/                            # Manifiestos Kubernetes
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── pvc.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── hpa.yaml
│   ├── pdb.yaml
│   ├── networkpolicy.yaml
│   └── resourcequota.yaml
├── scripts/                        # Scripts de instalación
│   ├── minikube-install.sh        # Setup Minikube Server
│   └── azure-agent-install.sh     # Setup Azure Agent
├── .gitignore
└── README.md                       # Esta documentación
```

---

## 🔐 Seguridad

### Prácticas Implementadas

- ✅ **Contenedores no-root**: Ejecución con UID 1000
- ✅ **Secrets en base64**: Información sensible en Secrets
- ✅ **Network Policies**: Firewall a nivel de pods
- ✅ **Resource Quotas**: Límites de CPU/Memoria
- ✅ **Security Scanning**: Bandit (código) y Trivy (imagen)
- ✅ **Least Privilege**: Capabilities mínimos necesarios
- ✅ **SonarCloud**: Análisis de calidad y vulnerabilidades

### Recomendaciones Adicionales

Para producción real:

1. **Usar HashiCorp Vault o Azure Key Vault** para secrets
2. **Habilitar RBAC** en Kubernetes
3. **Implementar Pod Security Policies**
4. **Usar cert-manager** para TLS automático
5. **Habilitar audit logging** en Kubernetes
6. **Implementar service mesh** (Istio/Linkerd)

---

## 🛠️ Tecnologías Utilizadas

| Categoría | Tecnología | Versión |
|-----------|------------|---------|
| **Lenguaje** | Python | 3.11 |
| **Framework** | Django | 4.2 |
| **API** | Django REST Framework | 3.14 |
| **Servidor Web** | Gunicorn | 21.2 |
| **Contenedores** | Docker | 24.0+ |
| **Orquestación** | Kubernetes (Minikube) | 1.28 |
| **CI/CD** | Azure DevOps Pipelines | - |
| **Quality** | SonarCloud | - |
| **Security** | Bandit, Trivy | - |
| **Linting** | Flake8 | 6.1 |
| **Testing** | pytest, coverage | - |
| **Registry** | Docker Hub | - |

---

## 📝 Notas Importantes

### URLs Públicas

Si desplegaste la aplicación en un entorno públicamente accesible, comparte la URL para validación:

```
URL Pública: https://prueba.devsu.demopython.ronnytabango.com/api/
```

**[INSERTE_IMAGEN_AQUI: app-running-public.png]**

### Credenciales de Acceso (Solo para Evaluación)

**Azure DevOps:**
- URL: `https://dev.azure.com/<tu-organizacion>`
- Pipeline: `https://dev.azure.com/<tu-organizacion>/<proyecto>/_build`

**Docker Hub:**
- Imagen: `https://hub.docker.com/r/ronnyt854/demo-devops-python`

**SonarCloud:**
- Proyecto: `https://sonarcloud.io/dashboard?id=<proyecto-id>`

---

## 👤 Autor

**Ronny Tabango**

- GitHub: [@ronny854](https://github.com/ronny854)
- LinkedIn: [Ronny Tabango](https://linkedin.com/in/ronny-tabango)
- Email: ronny.tabango@example.com

---

## 📄 Licencia

Este proyecto es parte de una prueba técnica para Devsu.

---

## 🙏 Agradecimientos

Agradecimientos a:
- **Devsu** por la oportunidad de realizar esta prueba técnica
- **Comunidad de Kubernetes** por la excelente documentación
- **Azure DevOps** por la plataforma de CI/CD

---

## 📚 Referencias y Documentación

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Azure DevOps Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/)
- [Django Documentation](https://docs.djangoproject.com/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)

---

**¿Preguntas o Sugerencias?**

Si tienes alguna pregunta sobre la implementación o encuentras algún problema, no dudes en abrir un [Issue](https://github.com/ronny854/prueba-tecnica-devsu-ronny-tabango/issues) en el repositorio.

---

**Última Actualización:** Enero 2026

---