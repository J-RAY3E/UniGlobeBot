# Usamos Python 3.11 completo
FROM python:3.11

WORKDIR /app

# Copiamos el requirements
COPY requirements.txt .

# Instalamos dependencias del sistema y pip
RUN apt-get update && apt-get install -y \
        build-essential \
        git \
        curl \
        ffmpeg \
        libgl1 \
        libglib2.0-0 \
    && pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copiamos la app
COPY . .

# Exponemos el puerto
ENV PORT=8080
EXPOSE 8080

# Comando por defecto
CMD ["uvicorn", "rag:app", "--host", "0.0.0.0", "--port", "8080"]

