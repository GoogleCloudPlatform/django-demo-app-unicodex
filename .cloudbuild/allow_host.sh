#!/bin/bash -eu

# This is getting the deployed URL and ensuring Django knows it's an ALLOWED_HOST
echo "🤔 Checking CURRENT_HOST configuration"

CURRENT_HOST=$(gcloud run services describe ${_SERVICE} --platform managed --region ${_REGION} --format json | grep CURRENT_HOST)

if [ -z "$CURRENT_HOST" ]; then
  SERVICE_URL=$(gcloud run services describe ${_SERVICE} --platform managed --region ${_REGION} --format="value(status.url)")
  echo " ❗️ Setting ${_SERVICE} CURRENT_HOST to <$SERVICE_URL>."
  gcloud run services update ${_SERVICE}  \
      --platform managed --region ${_REGION}\
      --update-env-vars CURRENT_HOST=${SERVICE_URL}
else
  echo " ⏩ Service ${_SERVICE} already has CURRENT_HOST. Skipping."
fi
