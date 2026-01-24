# Stage 1: Builder - Instalar dependencias
FROM python:3.11-slim as python-base
FROM python-base as builder

WORKDIR /app
COPY requirements.txt .

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt \
    && apt-get purge -y --auto-remove gcc \
    && rm -rf /var/lib/apt/lists/*

FROM python-base as production

# Metadata
LABEL maintainer="DevOps Team" \
      description="Demo DevOps Python - Django REST API" \
      version="1.0" \
      app="demo-devops-python"

ARG APP_USER=appuser
ARG APP_GROUP=appgroup
ARG APP_UID=1000
ARG APP_GID=1000

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    APP_HOME=/app \
    PORT=8000

WORKDIR $APP_HOME

# Instalar dependencias del sistema, crear usuario y configurar permisos en un solo RUN
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && groupadd --gid $APP_GID $APP_GROUP \
    && useradd --uid $APP_UID --gid $APP_GID --shell /bin/bash --create-home $APP_USER

# Copiar wheels del stage builder e instalar dependencias
COPY --from=builder /app/wheels /wheels
COPY --from=builder /app/requirements.txt .
RUN pip install --no-cache-dir /wheels/* \
    && rm -rf /wheels

# Copiar código de la aplicación y entrypoint
COPY --chown=$APP_USER:$APP_GROUP . .
COPY --chown=$APP_USER:$APP_GROUP entrypoint.sh /entrypoint.sh

# Crear directorios para base de datos y archivos estáticos, y asignar permisos
RUN mkdir -p $APP_HOME/data $APP_HOME/staticfiles \
    && chown -R $APP_USER:$APP_GROUP $APP_HOME \
    && chmod +x /entrypoint.sh

# Cambiar al usuario no-root
USER $APP_USER

# Exponer el puerto de la aplicación
EXPOSE $PORT

# Healthcheck para verificar que la aplicación está funcionando
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl --fail http://localhost:$PORT/api/ || exit 1

ENTRYPOINT ["/entrypoint.sh"]

# Comando por defecto - usar gunicorn para producción
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "--threads", "4", "demo.wsgi:application"]
