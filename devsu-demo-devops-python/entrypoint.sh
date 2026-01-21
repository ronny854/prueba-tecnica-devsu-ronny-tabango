#!/bin/bash
set -e

echo "==================================="
echo "  Demo DevOps Python - Starting   "
echo "==================================="

# Ejecutar migraciones de base de datos
echo "Aplicando migraciones de base de datos..."
python manage.py migrate --noinput

# Recolectar archivos estáticos (opcional para producción)
echo "Recolectando archivos estáticos..."
python manage.py collectstatic --noinput --clear 2>/dev/null || true

echo "Iniciando servidor..."
echo "==================================="

# Ejecutar el comando pasado como argumento
exec "$@"
