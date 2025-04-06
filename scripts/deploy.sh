#!/bin/bash

# Salir si hay errores
set -e

# Obtener el directorio del script
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# Cargar variables de entorno desde .env de forma más robusta
if [ -f "$SCRIPT_DIR/../.env" ]; then
    set -a
    source "$SCRIPT_DIR/../.env"
    set +a
else
    echo "❌ Error: Archivo .env no encontrado en $SCRIPT_DIR/../. Por favor, crea un .env con APP_ID."
    exit 1
fi

# Validar que APP_ID esté definido
if [ -z "$APP_ID" ]; then
    echo "❌ Error: APP_ID no está definido en .env."
    exit 1
fi

# Variables de configuración
BRANCH="staging"
REGION="us-east-1"
BUILD_DIR="$SCRIPT_DIR/../build/web"
ZIP_FILE="$SCRIPT_DIR/../build.zip"

# Construir la aplicación Flutter para web
echo "🏗️ Construyendo la aplicación Flutter para web..."
if ! flutter build web --release; then
    echo "❌ Error: Falló la construcción de la aplicación Flutter para web."
    exit 1
fi

# Validar que el directorio de construcción exista
if [ ! -d "$BUILD_DIR" ]; then
    echo "❌ Error: El directorio '$BUILD_DIR' no existe después de ejecutar 'flutter build web'."
    exit 1
fi

# Crear archivo zip
echo "📦 Creando archivo zip..."
cd "$BUILD_DIR"
zip -r "$ZIP_FILE" . -x ".*"
cd "$SCRIPT_DIR/.."

# Obtener URL de carga pre-firmada y Job ID
echo "🔑 Obteniendo URL de carga y Job ID..."
response=$(aws amplify create-deployment \
  --app-id "$APP_ID" \
  --branch-name "$BRANCH" \
  --region "$REGION" \
  --query '{zipUploadUrl: zipUploadUrl, jobId: jobId}' \
  --output json) || { echo "❌ Error al obtener la URL de carga."; exit 1; }

UPLOAD_URL=$(echo "$response" | jq -r '.zipUploadUrl')
JOB_ID=$(echo "$response" | jq -r '.jobId')

# Validar que se obtuvo la URL de carga y el Job ID
if [ -z "$UPLOAD_URL" ] || [ -z "$JOB_ID" ]; then
    echo "❌ Error: No se pudo obtener la URL de carga o el Job ID."
    exit 1
fi

# Subir archivo zip usando curl
echo "📤 Subiendo archivo zip a AWS..."
curl -H "Content-Type: application/zip" --upload-file "$ZIP_FILE" "$UPLOAD_URL" || { echo "❌ Error al subir el archivo ZIP."; exit 1; }

# Iniciar el despliegue
echo "🚀 Iniciando despliegue en Amplify..."
aws amplify start-deployment \
  --app-id "$APP_ID" \
  --branch-name "$BRANCH" \
  --job-id "$JOB_ID" \
  --region "$REGION" || { echo "❌ Error al iniciar el despliegue."; exit 1; }

echo "✅ Despliegue iniciado con Job ID: $JOB_ID"
echo "Puedes verificar el estado en la consola de AWS Amplify"

echo "⏳ Esperando a que el Job finalice..."

while true; do
  STATUS=$(aws amplify get-job \
    --app-id "$APP_ID" \
    --branch-name "$BRANCH" \
    --job-id "$JOB_ID" \
    --region "$REGION" \
    --query 'job.summary.status' \
    --output text)

  echo "📡 Estado actual: $STATUS"

  if [ "$STATUS" == "SUCCEED" ]; then
    echo "✅ Despliegue completado exitosamente con Job ID: $JOB_ID"
    break
  elif [ "$STATUS" == "FAILED" ] || [ "$STATUS" == "CANCELLED" ]; then
    echo "❌ El despliegue falló o fue cancelado (estado: $STATUS)"
    exit 1
  else
    sleep 5
  fi
done
