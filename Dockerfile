# ==============================
# Etapa 1: Build / instalación
# ==============================
FROM python:3.12-slim AS builder

WORKDIR /app

# Dependencias del sistema necesarias solo para compilación
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        git \
        wget \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements
COPY requirements.txt .

# Instalar dependencias de Python en carpeta temporal /install
RUN pip install --upgrade pip \
    && pip install --prefix=/install --no-cache-dir -r requirements.txt


# ==============================
# Etapa 2: Imagen final ligera
# ==============================
FROM python:3.12-slim

WORKDIR /app

# Variables de entorno para que Python sea más eficiente
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

# Copiar dependencias desde builder
COPY --from=builder /install /usr/local

# Copiar solo el código de la app
COPY . .

# Exponer puerto (FastAPI por defecto 8000)
EXPOSE 8080
CMD ["uvicorn", "rag:app", "--host", "0.0.0.0", "--port", "8080"]