FROM python:3.11-slim

LABEL maintainer="ronnyt854"
LABEL description="Python 3.11 Build Image for CI/CD Pipelines"
LABEL version="1.1"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget git ca-certificates gnupg lsb-release \
    gcc g++ make \
    libpq-dev libffi-dev libssl-dev \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
      > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

RUN pip install --upgrade pip setuptools wheel \
    && pip install --no-cache-dir \
      pytest pytest-cov pytest-django coverage \
      flake8 pylint black isort mypy \
      bandit safety \
      django django-environ djangorestframework \
      gunicorn whitenoise

WORKDIR /workspace

CMD ["python", "--version"]