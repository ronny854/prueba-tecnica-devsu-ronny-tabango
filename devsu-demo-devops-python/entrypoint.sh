#!/bin/bash
set -e  # Exit on error

# Colores para logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Banner de inicio
echo "==========================================="
echo "  Demo DevOps Python - Starting"
echo "  Environment: ${ENVIRONMENT:-production}"
echo "  Python: $(python --version)"
echo "  Django: $(python -c 'import django; print(django.get_version())')"
echo "==========================================="

# Verificar variables de entorno críticas
if [ -z "$DJANGO_SECRET_KEY" ]; then
    log_error "DJANGO_SECRET_KEY no está configurada!"
    log_error "La aplicación no puede iniciar sin esta variable."
    exit 1
fi

log_success "Variables de entorno validadas"

# Ejecutar migraciones
log_info "Aplicando migraciones de base de datos..."
if python manage.py migrate --noinput; then
    log_success "Migraciones aplicadas correctamente"
else
    log_error "Falló la aplicación de migraciones"
    exit 1
fi

# Recolectar archivos estáticos
log_info "Recolectando archivos estáticos..."
if python manage.py collectstatic --noinput --clear 2>/dev/null; then
    log_success "Archivos estáticos recolectados"
else
    log_warning "No se pudieron recolectar archivos estáticos (esto puede ser normal si no hay archivos estáticos)"
fi

# Crear superusuario si no existe (solo en desarrollo)
if [ "$DEBUG" = "True" ] && [ -n "$DJANGO_SUPERUSER_USERNAME" ]; then
    log_info "Creando superusuario de desarrollo..."
    python manage.py shell << EOF || true
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='$DJANGO_SUPERUSER_USERNAME').exists():
    User.objects.create_superuser('$DJANGO_SUPERUSER_USERNAME', '$DJANGO_SUPERUSER_EMAIL', '$DJANGO_SUPERUSER_PASSWORD')
    print('Superusuario creado')
else:
    print('Superusuario ya existe')
EOF
fi

# Verificar el estado de la aplicación
log_info "Verificando configuración de Django..."
if python manage.py check --deploy 2>/dev/null; then
    log_success "Verificación de Django exitosa"
else
    log_warning "Algunas verificaciones de Django fallaron (puede ser normal)"
fi

log_info "Iniciando servidor..."
echo "==========================================="

# Ejecutar el comando pasado como argumento
exec "$@"
