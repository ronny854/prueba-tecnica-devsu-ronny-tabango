# ==========================================
# Multi-stage Dockerfile para Django Application
# Optimizado para producción
# ==========================================

# ==========================================
# Stage 1: Builder - Instalar dependencias
# ==========================================
FROM python:3.11-slim AS builder

WORKDIR /build

# Copiar solo requirements para aprovechar cache de Docker
COPY requirements.txt .

# Instalar dependencias de compilación y crear wheels
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libpq-dev \
    && pip wheel --no-cache-dir --no-deps --wheel-dir /build/wheels -r requirements.txt \
    && apt-get purge -y --auto-remove gcc g++ \
    && rm -rf /var/lib/apt/lists/*

# ==========================================
# Stage 2: Production - Imagen final
# ==========================================
FROM python:3.11-slim AS production

# Metadata mejorada
LABEL maintainer="DevOps Team <devops@example.com>" \
      description="Demo DevOps Python - Django REST API" \
      version="2.0" \
      app="demo-devops-python" \
      python.version="3.11" \
      framework="django" \
      org.opencontainers.image.source="https://github.com/your-org/demo-devops-python" \
      org.opencontainers.image.vendor="Your Organization"

# Argumentos de build
ARG APP_USER=appuser
ARG APP_GROUP=appgroup
ARG APP_UID=1000
ARG APP_GID=1000

# Variables de entorno
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    APP_HOME=/app \
    PORT=8000

WORKDIR $APP_HOME

# Instalar dependencias del sistema necesarias y crear usuario
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    libpq5 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && groupadd --gid $APP_GID $APP_GROUP \
    && useradd --uid $APP_UID --gid $APP_GID --shell /bin/bash --create-home $APP_USER

# Copiar wheels del stage builder e instalar
COPY --from=builder /build/wheels /wheels
COPY --from=builder /build/requirements.txt .
RUN pip install --no-cache-dir --no-index --find-links=/wheels /wheels/* \
    && rm -rf /wheels

# Copiar código de la aplicación
COPY --chown=$APP_USER:$APP_GROUP . .

# Copiar y dar permisos al entrypoint
COPY --chown=$APP_USER:$APP_GROUP entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Crear directorios necesarios con permisos correctos
RUN mkdir -p \
    $APP_HOME/data \
    $APP_HOME/staticfiles \
    $APP_HOME/media \
    $APP_HOME/logs \
    && chown -R $APP_USER:$APP_GROUP $APP_HOME

# Cambiar al usuario no-root
USER $APP_USER

# Exponer puerto
EXPOSE $PORT

# Healthcheck mejorado
HEALTHCHECK --interval=30s \
            --timeout=10s \
            --start-period=40s \
            --retries=3 \
    CMD curl --fail http://localhost:$PORT/api/ || exit 1

# Entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Comando por defecto - Gunicorn para producción
CMD ["gunicorn", \
     "--bind", "0.0.0.0:8000", \
     "--workers", "2", \
     "--threads", "4", \
     "--timeout", "120", \
     "--graceful-timeout", "30", \
     "--keep-alive", "5", \
     "--log-level", "info", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "--log-file", "-", \
     "demo.wsgi:application"]