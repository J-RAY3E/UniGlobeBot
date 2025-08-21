# Usamos Python completo para evitar problemas de dependencias
FROM python:3.12

# Directorio de trabajo
WORKDIR /app

# Copiamos el requirements.txt primero para aprovechar cache de Docker
COPY requirements.txt .

# Actualizamos pip e instalamos dependencias
RUN pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copiamos todo el código de la app
COPY . .

# Variables de entorno (puedes cambiar PORT si quieres)
ENV PORT=8080

# Exponemos el puerto
EXPOSE 8080

# Comando por defecto para correr la app
CMD ["uvicorn", "rag:app", "--host", "0.0.0.0", "--port", "8080"]
