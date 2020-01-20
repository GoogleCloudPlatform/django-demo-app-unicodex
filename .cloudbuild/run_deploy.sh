# /bin/bash

gcloud run deploy ${_SERVICE} \
    --platform managed --region ${_REGION} \
    --image gcr.io/$PROJECT_ID/${_SERVICE}  \
    --allow-unauthenticated  \
    --add-cloudsql-instances ${_DATABASE_INSTANCE} \
    --service-account cloudrun-berglas-python@${PROJECT_ID}.iam.gserviceaccount.com \
    --update-env-vars DATABASE_URL=berglas://${_BERGLAS_BUCKET}/database_url,SECRET_KEY=berglas://${_BERGLAS_BUCKET}/secret_key,GS_BUCKET_NAME=berglas://${_BERGLAS_BUCKET}/media_bucket

# This is annoying to have to branch out just because of this stip.  I'd love to do this inline. 
SERVICE_URL=$(gcloud run services list --platform managed --format="value(status.url)" --filter="metadata.name=${_SERVICE}")

echo "Setting ${_SERVICE} CURRENT_HOST to <$SERVICE_URL>."

gcloud run services update ${_SERVICE}  \
    --platform managed --region ${_REGION}\
    --update-env-vars CURRENT_HOST=${SERVICE_URL}
