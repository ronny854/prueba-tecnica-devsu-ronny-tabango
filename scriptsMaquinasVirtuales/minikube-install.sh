#!/bin/bash

# ==========================================
# Script de Instalación de Minikube Server
# Para Ubuntu 22.04 LTS
# ==========================================

set -e

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Instalación de Minikube Server${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Este script debe ejecutarse como root${NC}"
    echo "   Ejecutar: sudo $0"
    exit 1
fi

# Verificar sistema operativo
if [ ! -f /etc/os-release ]; then
    echo -e "${RED}❌ No se puede determinar el sistema operativo${NC}"
    exit 1
fi

. /etc/os-release
if [ "$ID" != "ubuntu" ]; then
    echo -e "${YELLOW}⚠️  Este script está diseñado para Ubuntu${NC}"
    echo "   Continuando de todas formas..."
fi

# ==========================================
# 1. ACTUALIZAR SISTEMA
# ==========================================
echo -e "${GREEN}[1/7] Actualizando sistema...${NC}"
apt-get update -qq
apt-get upgrade -y -qq
echo -e "${GREEN}✅ Sistema actualizado${NC}"
echo ""

# ==========================================
# 2. INSTALAR DEPENDENCIAS
# ==========================================
echo -e "${GREEN}[2/7] Instalando dependencias...${NC}"
apt-get install -y -qq \
    curl \
    wget \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    conntrack \
    socat

echo -e "${GREEN}✅ Dependencias instaladas${NC}"
echo ""

# ==========================================
# 3. INSTALAR DOCKER
# ==========================================
echo -e "${GREEN}[3/7] Instalando Docker...${NC}"

# Agregar Docker GPG key
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Agregar Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Iniciar y habilitar Docker
systemctl start docker
systemctl enable docker

# Agregar usuario al grupo docker
SUDO_USER=${SUDO_USER:-$USER}
usermod -aG docker $SUDO_USER

echo -e "${GREEN}✅ Docker instalado: $(docker --version)${NC}"
echo ""

# ==========================================
# 4. INSTALAR KUBECTL
# ==========================================
echo -e "${GREEN}[4/7] Instalando kubectl...${NC}"

# Descargar kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Instalar kubectl
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

echo -e "${GREEN}✅ kubectl instalado: $(kubectl version --client --short 2>/dev/null || kubectl version --client)${NC}"
echo ""

# ==========================================
# 5. INSTALAR MINIKUBE
# ==========================================
echo -e "${GREEN}[5/7] Instalando Minikube...${NC}"

# Descargar Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Instalar Minikube
install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

echo -e "${GREEN}✅ Minikube instalado: $(minikube version --short)${NC}"
echo ""

# ==========================================
# 6. INICIAR MINIKUBE
# ==========================================
echo -e "${GREEN}[6/7] Iniciando Minikube...${NC}"

# Cambiar a usuario no-root para iniciar minikube
su - $SUDO_USER << 'EOF'
# Iniciar Minikube con configuración optimizada
minikube start

# Esperar a que el cluster esté listo
echo "⏳ Esperando a que el cluster esté listo..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo "✅ Minikube iniciado correctamente"
EOF

echo ""

# ==========================================
# 7. HABILITAR ADDONS
# ==========================================
echo -e "${GREEN}[7/7] Habilitando addons de Minikube...${NC}"

su - $SUDO_USER << 'EOF'
# Habilitar Ingress
echo "📦 Habilitando Ingress..."
minikube addons enable ingress

# Habilitar Metrics Server
echo "📊 Habilitando Metrics Server..."
minikube addons enable metrics-server

# Esperar a que los addons estén listos
echo "⏳ Esperando a que los addons estén listos..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=ingress-nginx -n ingress-nginx --timeout=300s
kubectl wait --for=condition=Ready pod -l k8s-app=metrics-server -n kube-system --timeout=300s

echo "✅ Addons habilitados"
EOF

echo ""

# ==========================================
# 8. VERIFICACIÓN FINAL
# ==========================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Verificación Final${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

su - $SUDO_USER << 'EOF'
echo "🔍 Estado de Minikube:"
minikube status

echo ""
echo "🔍 Nodos de Kubernetes:"
kubectl get nodes

echo ""
echo "🔍 Pods del sistema:"
kubectl get pods -A

echo ""
echo "🔍 Addons habilitados:"
minikube addons list | grep enabled
EOF

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✅ Instalación Completada${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

echo "📋 Información importante:"
echo ""
echo "  Minikube IP: $(su - $SUDO_USER -c 'minikube ip')"
echo "  Usuario: $SUDO_USER"
echo "  Driver: docker"
echo ""
echo "📖 Comandos útiles:"
echo ""
echo "  minikube status           - Ver estado del cluster"
echo "  minikube dashboard        - Abrir dashboard web"
echo "  kubectl get pods -A       - Ver todos los pods"
echo "  kubectl get nodes         - Ver nodos"
echo "  minikube addons list      - Ver addons disponibles"
echo ""
echo "⚠️  IMPORTANTE:"
echo "  - Cierra sesión y vuelve a entrar para que los cambios de grupo (docker) tomen efecto"
echo "  - O ejecuta: newgrp docker"
echo ""
echo -e "${YELLOW}🔧 Próximos pasos:${NC}"
echo ""
echo "  1. Configurar /etc/hosts:"
echo "     sudo sh -c \"echo '\$(minikube ip) prueba.devsu.demopython.ronnytabango.com' >> /etc/hosts\""
echo ""
echo "  2. Configurar port-forward (después de desplegar la app):"
echo "     kubectl port-forward svc/demo-devops-python-service 30800:8000 -n myapp --address 0.0.0.0"
echo ""
echo -e "${GREEN}¡Minikube Server listo para usar!${NC}"
echo ""
