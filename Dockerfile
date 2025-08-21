# Usamos Python 3.11 (compatible con huggingface y sentence-transformers)
FROM python:3.11-slim

WORKDIR /app

# Copiamos el requirements
COPY requirements.txt .

# Instalamos pip y dependencias sin cache
RUN pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copiamos la app
COPY . .

# Exponemos el puerto
ENV PORT=8080
EXPOSE 8080

# Comando por defecto
CMD ["uvicorn", "rag:app", "--host", "0.0.0.0", "--port", "8080"]
