# /bin/bash
set -eEuo pipefail

gcloud run deploy ${_SERVICE} \
    --platform managed --region ${_REGION} \
    --image gcr.io/$PROJECT_ID/${_SERVICE}  \
    --allow-unauthenticated  \
    --add-cloudsql-instances ${_DATABASE_INSTANCE} \
    --service-account cloudrun-berglas-python@${PROJECT_ID}.iam.gserviceaccount.com \
    --update-env-vars DATABASE_URL=berglas://${_BERGLAS_BUCKET}/database_url \
    --update-env-vars SECRET_KEY=berglas://${_BERGLAS_BUCKET}/secret_key \
    --update-env-vars GS_BUCKET_NAME=berglas://${_BERGLAS_BUCKET}/media_bucket

# This is getting the deployed URL and ensuring Django knows it's an ALLOWED_HOST
SERVICE_URL=$(gcloud run services describe ${_SERVICE} --format="value(status.url)")

echo "Setting ${_SERVICE} CURRENT_HOST to <$SERVICE_URL>."

gcloud run services update ${_SERVICE}  \
    --platform managed --region ${_REGION}\
    --update-env-vars CURRENT_HOST=${SERVICE_URL}
