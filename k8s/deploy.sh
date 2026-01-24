#!/bin/bash
# ==========================================
# Script de Despliegue Simplificado
# Demo DevOps Python - Kubernetes
# ==========================================

set -e

# Variables
NAMESPACE="myapp"
K8S_DIR="./k8s"

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}  Desplegando Demo DevOps Python${NC}"
echo -e "${BLUE}=======================================${NC}"
echo ""

# Verificar kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl no está instalado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ kubectl encontrado${NC}"
echo ""

# Crear namespace
echo "📦 Creando namespace..."
kubectl apply -f $K8S_DIR/namespace.yaml

# Aplicar configuración
echo "⚙️  Aplicando configuración..."
kubectl apply -f $K8S_DIR/configmap.yaml
kubectl apply -f $K8S_DIR/secret.yaml

# Crear PVC
echo "💾 Creando almacenamiento..."
kubectl apply -f $K8S_DIR/pvc.yaml

# Desplegar aplicación
echo "🚀 Desplegando aplicación..."
kubectl apply -f $K8S_DIR/deployment.yaml

# Crear servicios
echo "🌐 Creando servicios..."
kubectl apply -f $K8S_DIR/service.yaml

# Aplicar recursos opcionales
echo "📋 Aplicando recursos adicionales..."
[ -f "$K8S_DIR/ingress.yaml" ] && kubectl apply -f $K8S_DIR/ingress.yaml
[ -f "$K8S_DIR/hpa.yaml" ] && kubectl apply -f $K8S_DIR/hpa.yaml
[ -f "$K8S_DIR/pdb.yaml" ] && kubectl apply -f $K8S_DIR/pdb.yaml
[ -f "$K8S_DIR/networkpolicy.yaml" ] && kubectl apply -f $K8S_DIR/networkpolicy.yaml
[ -f "$K8S_DIR/resourcequota.yaml" ] && kubectl apply -f $K8S_DIR/resourcequota.yaml

# Esperar rollout
echo "⏳ Esperando rollout..."
kubectl rollout status deployment/demo-devops-python -n $NAMESPACE --timeout=5m

echo ""
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}  ✅ Despliegue Completado${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""

# Mostrar información
echo "📊 Estado:"
kubectl get pods -n $NAMESPACE
echo ""
kubectl get svc -n $NAMESPACE

echo ""
echo "🔗 Acceso:"
echo "  NodePort: kubectl get svc demo-devops-python-service -n $NAMESPACE"
echo "  Port-forward: kubectl port-forward svc/demo-devops-python-service -n $NAMESPACE 8080:8000"
echo ""