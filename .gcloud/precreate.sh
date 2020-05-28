#!/bin/bash
# migrate
echo "🚀 Running initial Django migration (this will take a few minutes)..."
echo "   Configurations: service ${K_SERVICE}, region ${GOOGLE_CLOUD_REGION}, instance psql"

gcloud builds submit --config .gcloud/djangomigrate.yaml \
    --project $GOOGLE_CLOUD_PROJECT \
    --substitutions _SERVICE=${K_SERVICE},_REGION=${GOOGLE_CLOUD_REGION},_INSTANCE_NAME=psql

echo "Pre-create data migration complete ✨"
