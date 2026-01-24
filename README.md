# Prueba Técnica DevOps - Ronny Tabango

Repositorio con la solución completa de la prueba técnica DevOps para Devsu, que incluye CI/CD, Dockerización y despliegue en Kubernetes (Minikube).

## Estructura del Proyecto

```
.
├── devsu-demo-devops-python/    # Aplicación Django REST API
│   ├── api/                     # Módulo de API REST
│   ├── demo/                    # Configuración de Django
│   ├── Dockerfile              # Dockerfile multi-stage optimizado
│   ├── requirements.txt        # Dependencias de Python
│   └── entrypoint.sh          # Script de inicialización
├── devops/                     # Configuración de CI/CD
│   ├── azure-pipelines.yml    # Pipeline principal
│   └── stages/                # Stages del pipeline
│       ├── buildPythonStage.yml      # Build, test y análisis
│       └── kubernetesDeploy.yml      # Despliegue a K8s
└── k8s/                       # Manifiestos de Kubernetes
    ├── namespace.yaml         # Namespace: myapp
    ├── configmap.yaml         # Variables de configuración
    ├── secret.yaml            # Secrets (Django Secret Key)
    ├── deployment.yaml        # Deployment con 2 réplicas
    ├── service.yaml           # Service ClusterIP
    ├── hpa.yaml              # HorizontalPodAutoscaler
    └── ingress.yaml          # Ingress NGINX
```

## Pipeline CI/CD

El pipeline de Azure DevOps implementa las siguientes etapas:

### Stage 1: Build & Test
- **Code Build**: Instalación de dependencias con pip
- **Unit Tests**: Ejecución de tests de Django
- **Static Code Analysis**: Análisis con Flake8
- **Code Coverage**: Reporte de cobertura de código
- **Security Scan**: Análisis de seguridad con Bandit
- **SonarCloud Analysis**: Análisis de calidad de código (opcional)

### Stage 2: Docker Build & Push
- **Docker Build**: Construcción de imagen multi-stage
- **Vulnerability Scan**: Escaneo con Trivy
- **Docker Push**: Publicación en Docker Hub

### Stage 3: Kubernetes Deploy
- **Validación**: Verificación de acceso a Minikube
- **Deployment**: Despliegue en Kubernetes
  - Aplicación de namespace
  - Configuración (ConfigMap y Secret)
  - Service y Deployment
  - HPA (Horizontal Pod Autoscaler)
  - Ingress NGINX

## Arquitectura de Kubernetes

### Recursos Desplegados

- **Namespace**: `myapp`
- **Deployment**: `demo-devops-python`
  - Réplicas: 2 (mínimo)
  - Imagen: `docker.io/ronnyt854/demo-devops-python:<tag>`
  - Usuario no-root (UID 1000)
  - Health checks (liveness, readiness, startup)
  - Resources: requests (256Mi/250m) y limits (512Mi/500m)
- **Service**: `demo-devops-python-service` (ClusterIP)
  - Puerto: 80 → 8000
- **HPA**: Escalado automático
  - Min: 2, Max: 5 réplicas
  - Métricas: CPU (70%) y Memoria (80%)
- **Ingress**: Exposición externa
  - Host: `demo-devops-python.local`
  - Clase: NGINX

### Buenas Prácticas Implementadas

#### Seguridad
- Usuario no-root en contenedores
- Security context con capabilities mínimos
- Secrets para información sensible (Django Secret Key)
- ConfigMaps para configuración no sensible
- Análisis de vulnerabilidades (Bandit, Trivy)

#### Alta Disponibilidad
- 2+ réplicas con HPA
- Rolling updates (maxSurge: 1, maxUnavailable: 0)
- Health checks configurados
- Resource requests y limits

#### Rendimiento
- Multi-stage Docker build
- Image caching y layer optimization
- Gunicorn con workers configurados
- HPA con métricas de CPU y memoria

#### Observabilidad
- Health probes (liveness, readiness, startup)
- Labels consistentes en todos los recursos
- Logs estructurados

## Requisitos

- Azure DevOps con pipelines configurados
- Acceso a Docker Hub
- Servidor Minikube con kubectl
- Conexión SSH configurada para deployment

## Deployment Local

Para desplegar localmente en Minikube:

```bash
# Aplicar manifiestos
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/ -n myapp

# Verificar despliegue
kubectl get pods -n myapp
kubectl get svc -n myapp
kubectl get ingress -n myapp

# Obtener URL del ingress
minikube service demo-devops-python-service -n myapp --url
```

## API Endpoints

La aplicación expone los siguientes endpoints:

- `GET /api/` - Health check
- `GET /api/users/` - Listar usuarios
- `POST /api/users/` - Crear usuario
- `GET /api/users/<id>/` - Obtener usuario

## Configuración

### Variables de Entorno (ConfigMap)
- `DEBUG`: False (producción)
- `DATABASE_NAME`: data/db.sqlite3
- `ALLOWED_HOSTS`: Lista de hosts permitidos
- `PYTHONUNBUFFERED`: 1

### Secrets
- `DJANGO_SECRET_KEY`: Secret key de Django (base64)

## Tecnologías Utilizadas

- **Aplicación**: Python 3.11, Django 4.2, Django REST Framework
- **Servidor Web**: Gunicorn, WhiteNoise
- **Contenedores**: Docker (multi-stage build)
- **Orquestación**: Kubernetes (Minikube)
- **CI/CD**: Azure DevOps Pipelines
- **Análisis de Código**: Flake8, Bandit, SonarCloud
- **Seguridad**: Trivy (vulnerability scanning)

## Autor

Ronny Tabango - Prueba Técnica DevOps Devsu