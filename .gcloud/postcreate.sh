#!/bin/bash

echo "🚀 Final service configuration changes"
export SERVICE_URL=$(gcloud run services describe $K_SERVICE  --format "value(status.url)" --platform managed --region ${GOOGLE_CLOUD_REGION})

echo "→ Setting CURRENT_HOST to deployed URL"
echo "  ${SERVICE_URL}"

echo "→ Connecting to SQL Instance"
echo "  ${GOOGLE_CLOUD_PROJECT}:${GOOGLE_CLOUD_REGION}:psql"

echo "→ Deploying service with service account"
echo "  ${K_SERVICE}@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com"

gcloud run services update $K_SERVICE --platform managed --region ${GOOGLE_CLOUD_REGION} \
    --update-env-vars "CURRENT_HOST=${SERVICE_URL}" \
    --add-cloudsql-instances ${GOOGLE_CLOUD_PROJECT}:${GOOGLE_CLOUD_REGION}:psql \
    --service-account ${K_SERVICE}@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com

echo "Post-create configuration complete ✨"

echo ""
echo ""
echo "Unicodex is now deployed to ${SERVICE_URL}"
echo ""
echo "To login into the Django admin: "
echo "  * go to ${SERVICE_URL}/admin"
echo "  * login with the username and password that are stored in Secret Manager"
echo ""
echo "gcloud secrets versions access latest --secret SUPERUSER"
echo "gcloud secrets versions access latest --secret SUPERPASS"
echo ""
