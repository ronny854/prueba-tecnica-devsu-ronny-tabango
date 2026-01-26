# 🚀 Prueba Técnica DevOps - Ronny Tabango

[![Pipeline Status](https://img.shields.io/badge/pipeline-passing-brightgreen)](https://dev.azure.com)
[![Docker](https://img.shields.io/badge/docker-hub-blue)](https://hub.docker.com/r/ronnyt854/demo-devops-python)
[![Kubernetes](https://img.shields.io/badge/kubernetes-1.28-326CE5)](https://kubernetes.io)
[![Python](https://img.shields.io/badge/python-3.11-3776AB)](https://www.python.org)

Implementación completa de CI/CD con Azure DevOps, Dockerización optimizada y despliegue en Kubernetes (Minikube) con arquitectura cliente-servidor.

---

## 📑 Tabla de Contenidos

- [Arquitectura](#-arquitectura)
  - [Diagrama de Arquitectura General](#diagrama-de-arquitectura-general)
  - [Características de las Máquinas Virtuales](#características-de-las-máquinas-virtuales)
  - [Estructura del Proyecto](#-estructura-del-proyecto)
  - [Pipeline CI/CD](#-pipeline-cicd)
    - [Funcionamiento del Pipeline](#funcionamiento-del-pipeline)
    - [Flujo del Pipeline](#flujo-del-pipeline)
    - [Tareas del Pipeline](#tareas-del-pipeline)
  - [Manifiestos de Kubernetes](#-manifiestos-de-kubernetes)
  - [Diagrama de Recursos K8s](#diagrama-de-recursos-k8s)
- [Requisitos Previos](#-requisitos-previos)
- [Guía de Configuración del Entorno](#️-guía-de-configuración-del-entorno)
  - [1. Configuración de Máquinas Virtuales](#1-configuración-de-máquinas-virtuales)
  - [2. Configuración de Minikube Server](#2-configuración-de-minikube-server)
  - [3. Configuración de Azure Agent](#3-configuración-de-azure-agent)
  - [4. Configuración de Red y Comunicación](#4-configuración-de-red-y-comunicación)
- [Configuración de Azure DevOps](#️-configuración-de-azure-devops)
  - [Service Connections](#service-connections)
  - [Variable Groups](#variable-groups)
- [Container de Build Especializado](#-container-de-build-especializado)
- [Cómo Usar](#-cómo-usar)
  - [Despliegue Automático (CI/CD)](#despliegue-automático-cicd)
  - [Acceso a la Aplicación](#acceso-a-la-aplicación)
- [Evidencias de Ejecución](#-evidencias-de-ejecución)
  - [Logs del Pipeline en Azure DevOps](#logs-del-pipeline-en-azure-devops)
  - [Pruebas de la Aplicación Desplegada en Minikube](#pruebas-de-la-aplicación-desplegada-en-minikube)
- [Troubleshooting](#-troubleshooting)
- [Monitoreo y Métricas](#-monitoreo-y-métricas)
- [Seguridad](#-seguridad)
- [Tecnologías Utilizadas](#️-tecnologías-utilizadas)
- [Autor](#-autor)
- [Licencia](#-licencia)
- [Referencias y Documentación](#-referencias-y-documentación)

---

## 🏗️ Arquitectura

### Diagrama de Arquitectura General
![alt text](capturasdepantalla/diagramaGeneral.png)

### Características de las Máquinas Virtuales

| Característica | Minikube Server (10.0.2.3) | Azure Agent (10.0.2.4) |
|----------------|----------------------------|------------------------|
| **Sistema Operativo** | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS |
| **RAM** | 4 GB | 2 GB |
| **CPUs** | 4 cores | 2 cores |
| **Disco** | 20 GB | 20 GB |
| **Software** | Docker, Minikube, kubectl | Docker, Azure Agent |
| **Rol** | Servidor de Kubernetes | Agente de CI/CD |
| **Red** | NatNetwork - 10.0.2.3 | NatNetwork - 10.0.2.4 |

### 📂 Estructura del Proyecto

```
prueba-tecnica-devsu-ronny-tabango/

├── capturasdepantalla/             # Screenshots documentación
├── devops/                         # CI/CD Azure DevOps
│   ├── azure-pipelines.yml        # Pipeline principal
│   ├── imagesDocker/              # Imágenes Docker de CI/CD
│   │   └── pythonBuildDocker/
│   │       └── Dockerfile         # Python Build Container
│   ├── jobs/                      # Jobs reutilizables
│   │   ├── jobBuildPython.yml
│   │   ├── jobDockerBuildPush.yml
│   │   └── jobSonarQubeAnalisys.yml
│   ├── stages/                    # Stages del pipeline
│   │   ├── buildPythonStage.yml   # Build, test y análisis
│   │   └── kubernetesDeploy.yml   # Despliegue K8s
│   └── steps/                     # Steps reutilizables
│       ├── docker/
│       │   ├── dockerBuild.yml
│       │   └── dockerPush.yml
│       ├── minikube/
│       │   ├── minikubeDeploy.yml
│       │   └── minikubeValidate.yml
│       ├── python/
│       │   └── pythonBuild.yml
│       ├── sonarqube/
│       │   └── sonarQubeAnalisysPython.yml
│       └── test/
│           ├── testPython.yml
│           └── testScanTrivyAnalysisContainer.yml
├── devsu-demo-devops-python/       # Aplicación Django
│   ├── api/                        # API REST
│   │   ├── migrations/            # Migraciones de BD
│   │   ├── models.py              # Modelos de datos
│   │   ├── serializers.py         # Serializadores DRF
│   │   ├── views.py               # Vistas/Controladores
│   │   ├── urls.py                # Rutas de la API
│   │   ├── health.py              # Health checks
│   │   └── tests.py               # Tests unitarios
│   ├── demo/                       # Configuración Django
│   │   ├── settings.py            # Configuración principal
│   │   ├── urls.py                # Rutas principales
│   │   ├── wsgi.py                # WSGI config
│   │   └── asgi.py                # ASGI config
│   ├── Dockerfile                 # Multi-stage build
│   ├── docker-compose.yml         # Compose para desarrollo
│   ├── entrypoint.sh              # Script de inicialización
│   ├── requirements.txt           # Dependencias Python
│   ├── manage.py                  # CLI de Django
│   └── README.md                  # Documentación de la app
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
│   ├── resourcequota.yaml
│   └── deploy.sh                  # Script de despliegue
├── scriptsMaquinasVirtuales/       # Scripts de instalación VMs
│   ├── minikube-install.sh        # Setup Minikube Server
│   └── azure-agent-install.sh     # Setup Azure Agent
├── .gitignore
└── README.md                       # Esta documentación
```

### 🔄 Pipeline CI/CD

#### Funcionamiento del Pipeline

El pipeline está diseñado con una **arquitectura modular** basada en templates reutilizables, separando stages, jobs y steps en archivos independientes para facilitar el mantenimiento y la escalabilidad.

##### Activación del Pipeline (Triggers)

El pipeline se ejecuta automáticamente cuando:

```yaml
trigger:
  branches:
    include:
      - main      # Rama principal (producción)
      - develop   # Rama de desarrollo
  paths:
    include:
      - devsu-demo-devops-python/**  # Solo cambios en la app

pr:
  branches:
    include:
      - main
      - develop
  paths:
    include:
      - devsu-demo-devops-python/**
```

> ℹ️ **Nota:** El pipeline solo se activa cuando hay cambios en el directorio `devsu-demo-devops-python/`. Cambios en documentación, scripts o manifiestos K8s no activan el pipeline automáticamente.

##### Parámetros Configurables

El pipeline acepta parámetros que pueden modificarse al ejecutarlo manualmente:

| Parámetro | Valor por Defecto | Descripción |
|-----------|-------------------|-------------|
| `projectname` | `devsu-demo-devops-python` | Nombre del directorio del proyecto |
| `imageRepository` | `ronnyt854/demo-devops-python` | Repositorio de imagen en Docker Hub |
| `runSonarAnalysis` | `true` | Habilitar/deshabilitar análisis SonarCloud |
| `sonarProjectName` | `prueba-tecnica-devsu-ronny-tabango` | Nombre del proyecto en SonarCloud |
| `sonarOrganization` | `ronny854` | Organización en SonarCloud |

##### Variables y Service Connections

**Variables definidas en el pipeline:**

| Variable | Valor | Uso |
|----------|-------|-----|
| `containerRegistry` | `docker.io` | Registry de Docker Hub |
| `buildImage` | `ronnyt854/python311_build:v1.1` | Imagen del container de build |
| `sonarServiceConnection` | `conection-sonarqube-github-account` | Service Connection de SonarCloud |
| `dockerRegistryServiceConnection` | `dockerRegistryServiceConnection` | Service Connection de Docker Hub |

**Variable Group requerido:** `MINIKUBE-VARS` (configurado en Azure DevOps Library)

##### Flujo de Ejecución y Dependencias

##### Condiciones de Ejecución

| Job | Condición | Descripción |
|-----|-----------|-------------|
| **BuildAndTest** | Siempre | Se ejecuta en cada push a main/develop |
| **SonarCloudAnalysis** | `runSonarAnalysis=true` | Solo si se habilita el parámetro |
| **DockerBuildPush** | `succeeded() AND (main OR develop) AND NOT PR` | Solo en ramas principales, no en PRs |
| **DeployAppMinikube** | `dependsOn: CI` | Solo si el stage CI fue exitoso |

##### Paso de Variables entre Stages

El pipeline utiliza **output variables** para pasar información entre stages:

```yaml
# En DockerBuildPush (Stage CI):
echo "##vso[task.setvariable variable=IMAGE_FULL_TAG;isOutput=true]$IMAGE_FULL_TAG"

# En DeployAppMinikube (Stage CD):
IMAGE_FULL_TAG: $[stageDependencies.CI.DockerBuildPush.outputs['PushImageStep.IMAGE_FULL_TAG']]
```

Esto permite que el stage de CD sepa exactamente qué imagen desplegar.

#### Flujo del Pipeline

```
azure-pipelines.yml
        │
        ├─► Stage 1: buildPythonStage.yml
        │        │
        │        ├─► Job: jobBuildPython.yml
        │        │      ├─► Step: pythonBuild.yml
        │        │      └─► Step: testPython.yml
        │        │
        │        ├─► Job: jobDockerBuildPush.yml
        │        │      ├─► Step: dockerBuild.yml
        │        │      ├─► Step: testScanTrivyAnalysisContainer.yml
        │        │      └─► Step: dockerPush.yml
        │        │
        │        └─► Job: jobSonarQubeAnalysis.yml
        │               └─► Step: sonarQubeAnalysisPython.yml
        │
        └─► Stage 2: kubernetesDeploy.yml
                 │
                 └─► Job: DeployToMinikube
                        ├─► Step: minikubeValidate.yml
                        └─► Step: minikubeDeploy.yml
```

#### Tareas del Pipeline

#### Stage 1: CI

##### Job 1: Build and Test Python App

| Step | Descripción |
|------|-------------|
| **Code Build** | Instala dependencias Python con pip desde requirements.txt |
| **Lint - Code Style & Static Analysis (Flake8)** | Análisis de estilo de código Python según PEP 8 |
| **Security - Static Analysis (Bandit)** | Escaneo de vulnerabilidades de seguridad en código Python |
| **Test - Unit Tests & Coverage** | Ejecuta tests de Django y genera reporte de cobertura con coverage.py |
| **Publish Coverage Results** | Publica resultados de cobertura en Azure DevOps |
| **Publish Analysis Reports** | Publica artefactos de reportes de análisis |

![alt text](capturasdepantalla/pythonBuildJob.png)

##### Job 2: SonarCloud Analysis (Condicional)

| Step | Descripción |
|------|-------------|
| **Download Coverage Reports** | Descarga artefactos de cobertura del job anterior |
| **SonarCloud - Prepare Analysis** | Configura el scanner de SonarCloud |
| **SonarCloud - Run Analysis** | Ejecuta análisis de calidad de código, code smells y bugs |
| **SonarCloud - Publish Quality Gate** | Publica resultado del Quality Gate |

![alt text](capturasdepantalla/jobSonar.png)

##### Job 3: Build & Push Docker Image

| Step | Descripción |
|------|-------------|
| **Docker Login** | Autenticación en Docker Registry |
| **Docker Build** | Construcción de imagen Docker multi-stage |
| **Docker Image Vulnerability Scan - Trivy** | Escaneo de vulnerabilidades HIGH/CRITICAL en imagen Docker |
| **Docker Push (tag & latest)** | Publicación de imagen a Docker Hub con tag de BUILD_ID y latest |
| **Docker Cleanup** | Limpieza de imágenes y logout del registry |

![alt text](capturasdepantalla/jobDocker.png)

#### Stage 2: CD - Minikube Deploy

##### Job: Deploy App

| Step | Descripción |
|------|-------------|
| **Status Minikube** | Verificación de conectividad SSH y estado de Minikube/Docker/Kubernetes |
| **Deploy App in Minikube** | Sincronización de manifiestos K8s y ejecución del script de despliegue |

![alt text](capturasdepantalla/jobDeploy.png)

### 📦 Manifiestos de Kubernetes

#### Estructura de Recursos K8s

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

#### Descripción de Manifiestos

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
│                                                  │
│  ┌────────────────────────────────────────────┐  │
│  │         Ingress (NGINX)                    │  │
│  │  prueba.devsu.demopython.ronnytabango.com  │  │
│  └────────────────┬───────────────────────────┘  │
│                   │                              │
│  ┌────────────────▼───────────────────────────┐  │
│  │    Service: demo-devops-python-service     │  │
│  │    Type: ClusterIP, Port: 80 → 8000        │  │
│  └────────────────┬───────────────────────────┘  │
│                   │                              │
│  ┌────────────────▼───────────────────────────┐  │
│  │   Deployment: demo-devops-python           │  │
│  │   Replicas: 2 (HPA: 2-5)                   │  │
│  │   ┌──────────┐      ┌──────────┐           │  │
│  │   │  Pod 1   │      │  Pod 2   │           │  │
│  │   │ Django   │      │ Django   │           │  │
│  │   │ App      │      │ App      │           │  │
│  │   └──────────┘      └──────────┘           │  │
│  │       │                   │                │  │
│  │       ▼                   ▼                │  │
│  │  ┌──────────┐      ┌──────────┐            │  │
│  │  │ConfigMap │      │ Secret   │            │  │
│  │  └──────────┘      └──────────┘            │  │
│  │       │                                    │  │
│  │       ▼                                    │  │
│  │  ┌──────────┐                              │  │
│  │  │   PVC    │                              │  │
│  │  │ SQLite   │                              │  │
│  │  └──────────┘                              │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  Managed by:                                     │
│  - HPA (Auto-scaling)                            │
│  - PDB (Disruption Budget)                       │
│  - NetworkPolicy (Firewall)                      │
│  - ResourceQuota (Limits)                        │
└──────────────────────────────────────────────────┘
```

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

![alt text](capturasdepantalla/redNat.png)

**Configurar Reenvío de Puertos (Port Forwarding):**

Para poder acceder a la aplicación desde la máquina host, es necesario configurar el reenvío de puertos en la red NAT:

1. Seleccionar la red NAT `NatNetwork`
2. Click en "Reenvío de puertos" o "Port Forwarding"
3. Agregar las siguientes reglas:

| Nombre | Protocolo | IP Host | Puerto Host | IP Invitado | Puerto Invitado |
|--------|-----------|---------|-------------|-------------|-----------------|
| `k8s-nodeport` | TCP | 127.0.0.1 | 30800 | 10.0.2.3 | 30800 |

> ℹ️ **Nota:** El puerto `30800` permite acceder a la aplicación Django desde `http://localhost:30800/api/` en la máquina host después de ejecutar el port-forward en Minikube.

![alt text](capturasdepantalla/reenviodePuertos.png)

#### 1.2 Crear VM: Minikube Server

1. **Nueva VM en VirtualBox:**
   - Nombre: `minikube-server`
   - Tipo: Linux
   - Versión: Ubuntu (64-bit)
   - RAM: 4096 MB (4 GB)
   - CPUs: 4
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

> ℹ️ **Este paso es opcional:** puedes utilizar la IP por defecto que asigne la máquina virtual. Solo asegúrate de identificar correctamente la IP generada para agregarla en el grupo de variables de Azure DevOps.


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

![alt text](capturasdepantalla/minikube-install.png)

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

> ⚠️ **IMPORTANTE:** Aplicar este comando al finalizar la ejecución del pipeline.

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

#### 3.1 Generar Personal Access Token (PAT)

Antes de ejecutar el script, necesitas generar un PAT en Azure DevOps:

1. Azure DevOps → User Settings → Personal Access Tokens
2. New Token
3. Name: `agent-pool-token`
4. Organization: `<tu-organizacion>`
5. Scopes: `Agent Pools (Read & manage)`
6. Create
7. **Copiar el token** (solo se muestra una vez)

**[INSERTE_IMAGEN_AQUI: azure-pat-creation.png]**

#### 3.2 Configurar Variables del Script

> ⚠️ **IMPORTANTE:** Antes de ejecutar el script, debes editar las variables de configuración al inicio del archivo `azure-agent-install.sh`:

```bash
# En la VM azure-agent (10.0.2.4)
cd ~
wget https://raw.githubusercontent.com/ronny854/prueba-tecnica-devsu-ronny-tabango/main/scriptsMaquinasVirtuales/azure-agent-install.sh
chmod +x azure-agent-install.sh

# Editar el script para configurar las variables
nano azure-agent-install.sh
```

**Variables a configurar:**

```bash
### ==========================
### CONFIGURA ESTAS VARIABLES
### ==========================

AZP_URL="https://dev.azure.com/tu-organizacion"    # URL de tu organización Azure DevOps
AZP_POOL="minikube-agents"                          # Nombre del Agent Pool
AZP_AGENT_NAME="$(hostname)-agent-client"           # Nombre del agente (opcional)
AZP_TOKEN="PEGA_AQUI_TU_PAT"                        # Tu Personal Access Token

AGENT_VERSION="4.266.2"                             # Versión del agente
AGENT_DIR="/opt/azure-agent"                        # Directorio de instalación
AGENT_USER="ronny"                                  # Usuario del sistema que ejecutará el agente
```

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `AZP_URL` | URL de tu organización en Azure DevOps | `https://dev.azure.com/miorganizacion` |
| `AZP_POOL` | Nombre del Agent Pool (debe existir en Azure DevOps) | `minikube-agents` |
| `AZP_AGENT_NAME` | Nombre único del agente | `azure-agent-01` |
| `AZP_TOKEN` | Personal Access Token generado en el paso anterior | `xxxxxxxxxxxxxxxxxxxx` |
| `AGENT_USER` | Usuario de Linux que ejecutará el agente | `ronny` |

#### 3.3 Ejecutar el Script de Instalación

Una vez configuradas las variables, ejecuta el script:

```bash
sudo ./azure-agent-install.sh
```

El script realiza automáticamente:
- ✅ Validación de parámetros y permisos
- ✅ Instalación de dependencias (`curl`, `jq`, `tar`, `libicu-dev`)
- ✅ Descarga del Azure DevOps Agent (versión 4.266.2)
- ✅ Configuración del agente en modo desatendido (unattended)
- ✅ Instalación como servicio systemd
- ✅ Inicio automático del agente

**Salida esperada:**
```
✅ Iniciando instalación del agente Azure DevOps con usuario ronny...
...
🎉 Agente Azure DevOps instalado y ejecutándose!
Pool: minikube-agents
Nombre: azure-agent-01
Usuario: ronny
```
#### 3.4 Verificar el Agente

Verificar en Azure DevOps:
1. Project Settings → Agent pools
2. `minikube-agents` → Agents
3. Ver el agente con estado **Online**

![alt text](capturasdepantalla/agente-instalado.png)

Verificar en la maquina azure-agent:
```bash
# Ver estado del servicio
sudo systemctl status vsts.agent.*

# Ver logs del agente
sudo journalctl -u vsts.agent.* -f
```

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

![alt text](capturasdepantalla/dockerconection.png)

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

![alt text](capturasdepantalla/sonarconection.png)

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

![alt text](capturasdepantalla/grupodevariables.png)

**Uso en Pipeline:**

```yaml
variables:
- group: MINIKUBE-VARS
```

Esto permite centralizar la configuración y reutilizar variables entre pipelines.

---

## 🐳 Container de Build Especializado

### Imagen Docker para Compilación de Python

El pipeline utiliza un **container especializado** para la etapa de Build & Test, optimizado específicamente para compilar y probar aplicaciones Python.

**Ubicación del Dockerfile:**
```
devops/imagesDocker/pythonBuildDocker/Dockerfile
```

**[INSERTE_IMAGEN_AQUI: python-build-container.png]**

### Características del Container

El container de build está basado en `ubuntu-latest` y contiene:

- ✅ **Python 3.11** preinstalado
- ✅ **pip** y herramientas de build
- ✅ **Dependencias del sistema** para compilación
- ✅ **Herramientas de análisis** (Flake8, Bandit, Coverage)
- ✅ **Optimizado para CI/CD** con caching de dependencias

### Uso en el Pipeline

El container se utiliza en el **Stage 1: Build & Test** del pipeline:

```yaml
jobs:
  - job: BuildAndTest
    displayName: 'Build and Test Python App'
    pool:
      vmImage: 'ubuntu-latest'
    container:
      image: {{ parameters.buildImage }}  # Python Build Container
```

**Ventajas del Container Especializado:**

1. **Consistencia**: Mismo ambiente de build en cada ejecución
2. **Velocidad**: Dependencias precargadas, menor tiempo de setup
3. **Reproducibilidad**: Builds idénticos en cualquier agente
4. **Aislamiento**: No contamina el agente con dependencias
5. **Versión específica**: Control preciso de versiones de Python y tools

### Build y Publicación del Container

El container de build se mantiene en Docker Hub y se actualiza periódicamente:

```bash
# Build del container
cd devops/imagesDocker/pythonBuildDocker/
docker build -t ronnyt854/python-build-container:3.11 .

# Push a Docker Hub
docker push ronnyt854/python-build-container:3.11

# Taggear como latest
docker tag ronnyt854/python-build-container:3.11 ronnyt854/python-build-container:latest
docker push ronnyt854/python-build-container:latest
```

### Configuración en azure-pipelines.yml

```yaml
parameters:
  - name: buildImage
    displayName: 'Python Build Container Image'
    type: string
    default: 'ronnyt854/python-build-container:3.11'

stages:
  - stage: BuildAndTest
    displayName: 'Build and Test'
    jobs:
      - job: BuildAndTest
        pool:
          vmImage: 'ubuntu-latest'
        container:
          image: ${{ parameters.buildImage }}
        steps:
          - script: |
              python3 --version
              pip3 --version
              flake8 --version
            displayName: 'Verify Build Environment'
```

### Actualización del Container

Para actualizar el container de build:

1. Modificar `devops/imagesDocker/pythonBuildDocker/Dockerfile`
2. Build con nuevo tag de versión
3. Push a Docker Hub
4. Actualizar parámetro `buildImage` en pipeline

**Ejemplo:**

```bash
# Después de modificar Dockerfile
docker build -t ronnyt854/python-build-container:3.11.1 .
docker push ronnyt854/python-build-container:3.11.1

# Actualizar en pipeline
# parameters.buildImage: 'ronnyt854/python-build-container:3.11.1'
```

---

## 🚀 Cómo Usar

### Despliegue Automático (CI/CD)

```bash
# Simplemente hacer push a la rama main o develop
git add .
git commit -m "feat: nueva funcionalidad"
git push origin main

# El pipeline se ejecutará automáticamente y desplegará
```

> ⚠️ **IMPORTANTE:** Después de que el pipeline finalice el despliegue, es necesario ejecutar el siguiente comando en el **Minikube Server (10.0.2.3)** para exponer la aplicación y poder acceder a ella:
>
> ```bash
> kubectl port-forward svc/demo-devops-python-service 30800:8000 -n myapp --address 0.0.0.0
> ```
>
> Este comando debe mantenerse en ejecución. Para hacerlo permanente, consulta la sección [Configuración de DNS y Port Forwarding](#23-configuración-de-dns-y-port-forwarding) donde se explica cómo configurarlo como servicio systemd.

### Acceso a la Aplicación

**Método 1: Port Forward**
```bash
# Desde Minikube Server
kubectl port-forward svc/demo-devops-python-service 30800:8000 -n myapp --address 0.0.0.0

# Acceder desde navegador o maquina host
http://localhost:30800/api/
```

**Método 2: Ingress**
```bash
# Acceder desde maquina virtual minikube
http://prueba.devsu.demopython.ronnytabango.com/api/
```

---

## 📸 Evidencias de Ejecución

### Logs del Pipeline en Azure DevOps

A continuación se muestran las capturas de pantalla de la ejecución exitosa del pipeline en Azure DevOps:

#### Ejecución Completa del Pipeline

![alt text](capturasdepantalla/logsEvidencias/ejecucionpipeline.png)

#### Stage CI - Build and Test Python App

**Job: BuildAndTest**

| Tarea | Captura |
|-------|---------|
| Code Build | ![alt text](capturasdepantalla/logsEvidencias/codeBuild.png) |
| Lint - Flake8 | ![alt text](capturasdepantalla/logsEvidencias/flake8.png) |
| Security - Bandit | ![alt text](capturasdepantalla/logsEvidencias/bandit.png) |
| Unit Tests & Coverage | ![alt text](capturasdepantalla/logsEvidencias/unitTest.png) |

#### Stage CI - SonarCloud Analysis (Opcional)

**Job: SonarCloudAnalysis**

| Tarea | Captura |
|-------|---------|
| SonarCloud Prepare | ![!\[alt text\](image.png)](capturasdepantalla/logsEvidencias/sonarPrepare.png) |
| SonarCloud Run Analysis | ![alt text](capturasdepantalla/logsEvidencias/sonarRun.png) |
| Quality Gate Result | ![!\[alt text\](image.png)](capturasdepantalla/logsEvidencias/sonarPublish.png) |
| Sonar Dashboard | ![alt text](capturasdepantalla/logsEvidencias/sonarDashboard.png) |

#### Stage CI - Docker Build & Push

**Job: DockerBuildPush**

| Tarea | Captura |
|-------|---------|
| Docker Login | ![alt text](capturasdepantalla/logsEvidencias/dockerLogin.png) |
| Docker Build | ![!\[alt text\](image.png)](capturasdepantalla/logsEvidencias/dockerBuild.png) |
| Trivy Security Scan | ![alt text](capturasdepantalla/logsEvidencias/dockerTrivy.png) |
| Docker Push | ![alt text](capturasdepantalla/logsEvidencias/dockerPush.png) |

#### Stage CD - Minikube Deploy

**Job: DeployAppMinikube**

| Tarea | Captura |
|-------|---------|
| Status Minikube | ![alt text](capturasdepantalla/logsEvidencias/minikubeStatus.png) |
| Deploy App in Minikube | ![!\[alt text\](image.png)](capturasdepantalla/logsEvidencias/minikubeDeploy1.png) ![alt text](capturasdepantalla/logsEvidencias/minikubeDeploy2.png) |

---

### Pruebas de la Aplicación Desplegada en Minikube

#### Estado de los Recursos en Kubernetes

```bash
# Verificar pods en ejecución
kubectl get pods -n myapp
```

![alt text](capturasdepantalla/logsEvidencias/getPods.png)

```bash
# Verificar servicios
kubectl get svc -n myapp
```

![alt text](capturasdepantalla/logsEvidencias/getServices.png)

```bash
# Verificar ingress
kubectl get ingress -n myapp
```

![alt text](capturasdepantalla/logsEvidencias/ingress.png)

```bash
# Verificar todos los recursos del namespace
kubectl get all -n myapp
```

![alt text](capturasdepantalla/logsEvidencias/allresourceApp.png)

#### Acceso desde Ingress en Maquina Virtual

**Interfaz de Django REST Framework**

![alt text](capturasdepantalla/logsEvidencias/accesoNavegador.png)

**Listado de Usuarios en el Navegador**

![alt text](capturasdepantalla/logsEvidencias/getUser.png)

#### Acceso desde NodePort Maquina Host

**Interfaz de Django REST Framework**

![alt text](capturasdepantalla/logsEvidencias/maquinaHost.png)

#### Métricas y Estado del HPA

```bash
# Ver estado del HPA
kubectl get hpa -n myapp

# Ver métricas de recursos
kubectl top pods -n myapp
```

![alt text](capturasdepantalla/logsEvidencias/metricas.png)

#### Applicacion desde el minikube dashboard

![alt text](capturasdepantalla/logsEvidencias/appDashboard.png)

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
| **Build Container** | Python Build Image (Ubuntu 22.04 + Python 3.11) | Custom |
| **Orquestación** | Kubernetes (Minikube) | 1.28 |
| **CI/CD** | Azure DevOps Pipelines | - |
| **Quality** | SonarCloud | - |
| **Security** | Bandit, Trivy | - |
| **Linting** | Flake8 | 6.1 |
| **Testing** | pytest, coverage | - |
| **Registry** | Docker Hub | - |

---

## 👤 Autor

**Ronny Tabango**

- GitHub: [@ronny854](https://github.com/ronny854)
- LinkedIn: [Ronny Tabango](www.linkedin.com/in/ronny-alexander-tabango-clavijo-6a1808226)
- Email: ronnytabango854@gmail.com

---

## 📄 Licencia

Este proyecto es parte de una prueba técnica para Devsu.

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