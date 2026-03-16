#!/bin/bash
set -e  # Salir si hay un error

# Variables de entorno esperadas:
# DB_HOST -> nombre del servicio de la base de datos en Docker Compose
# DB_PORT -> puerto de la base de datos (normalmente 5432 para PostgreSQL)

echo "🔌 Comprobando conexión con la base de datos..."

while ! nc -z "$DB_HOST" "$DB_PORT"; do
  echo "Esperando a que la base de datos esté lista en $DB_HOST:$DB_PORT..."
  sleep 1
done

echo "✅ Base de datos disponible"

# Ejecutar migraciones si se indica
if [ "$MIGRATE" = "true" ]; then
  echo "🚀 Ejecutando migraciones con Alembic..."
  alembic upgrade head
  echo "✅ Migraciones aplicadas"
fi

# Arranca la API
echo "🌐 Arrancando API con Uvicorn..."
exec uvicorn app.main:app --host 0.0.0.0 --port 8000