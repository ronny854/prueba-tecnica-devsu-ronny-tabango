#!/usr/bin/env bash
set -e

### ==========================
### CONFIGURA ESTAS VARIABLES
### ==========================

AZP_URL="https://dev.azure.com/tu-organizacion"
AZP_POOL="tu-pool"
AZP_AGENT_NAME="$(hostname)-agent-client"
AZP_TOKEN="PEGA_AQUI_TU_PAT"

AGENT_VERSION="4.266.2"
AGENT_DIR="/opt/azure-agent"
AGENT_USER="tu-usuario"

### ==========================
### VALIDACIONES
### ==========================

if [[ -z "$AZP_TOKEN" || "$AZP_TOKEN" == "PEGA_AQUI_TU_PAT" ]]; then
  echo "❌ Debes colocar tu Personal Access Token en AZP_TOKEN"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  echo "❌ Ejecuta este script como root: sudo ./install-azure-agent.sh"
  exit 1
fi

if ! id "$AGENT_USER" &>/dev/null; then
  echo "❌ El usuario $AGENT_USER no existe. Créalo primero."
  exit 1
fi

echo "✅ Iniciando instalación del agente Azure DevOps con usuario $AGENT_USER..."

### ==========================
### DEPENDENCIAS
### ==========================

apt-get update
apt-get install -y curl jq tar libicu-dev

### ==========================
### PREPARAR DIRECTORIO
### ==========================

mkdir -p "$AGENT_DIR"
chown "$AGENT_USER:$AGENT_USER" "$AGENT_DIR"

cd "$AGENT_DIR"

### ==========================
### DESCARGAR AGENTE
### ==========================

AGENT_PKG="vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz"

curl -LsS \
  https://download.agent.dev.azure.com/agent/${AGENT_VERSION}/${AGENT_PKG} \
  -o ${AGENT_PKG}

tar zxvf ${AGENT_PKG}
rm -f ${AGENT_PKG}

chown -R "$AGENT_USER:$AGENT_USER" "$AGENT_DIR"

### ==========================
### CONFIGURAR AGENTE
### ==========================

sudo -u "$AGENT_USER" ./config.sh --unattended \
  --url "$AZP_URL" \
  --auth pat \
  --token "$AZP_TOKEN" \
  --pool "$AZP_POOL" \
  --agent "$AZP_AGENT_NAME" \
  --acceptTeeEula \
  --work _work \
  --replace

### ==========================
### INSTALAR COMO SERVICIO
### ==========================

./svc.sh install "$AGENT_USER"
./svc.sh start

echo ""
echo "🎉 Agente Azure DevOps instalado y ejecutándose!"
echo "Pool: $AZP_POOL"
echo "Nombre: $AZP_AGENT_NAME"
echo "Usuario: $AGENT_USER"
