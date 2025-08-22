# Usamos Python 3.11 completo
FROM python:3.11

WORKDIR /app

# Copiamos requirements
COPY requirements.txt .

# Instalamos dependencias del sistema y pip
RUN apt-get update && apt-get install -y \
        build-essential \
        git \
        curl \
        ffmpeg \
        libgl1 \
        libglib2.0-0 \
        gsutil \
    && pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copiamos la app
COPY . .

# Copiamos el modelo HuggingFace (ya descargado localmente)
COPY ./models ./models

# Descargamos vectorstore de GCS al build-time
RUN mkdir -p /app/vectorstore && \
    gsutil cp gs://rag-vectorstore-1755763542/vectorstore.faiss /app/vectorstore/ && \
    gsutil cp gs://rag-vectorstore-1755763542/vectorstore_meta.pkl /app/vectorstore/

# Exponemos el puerto
ENV PORT=8080
EXPOSE 8080

# Comando por defecto
CMD ["uvicorn", "rag:app", "--host", "0.0.0.0", "--port", "8080"]

