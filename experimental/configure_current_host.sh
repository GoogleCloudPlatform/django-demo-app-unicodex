#!/bin/bash

# This is a workaround script for Terraform, to configure the CURRENT_HOST variable that Django needs for CSRF
# TODO workout a better way to do this, as this information is not know to the service itself.

K_SERVICE=unicodex
GOOGLE_CLOUD_REGION=us-central1

echo "before"
gcloud run services describe unicodex --region us-central1 --platform managed --project unicodex-prod | grep CURRENT_HOST

export SERVICE_URL=$(gcloud run services describe $K_SERVICE --format "value(status.url)" --platform managed --region ${GOOGLE_CLOUD_REGION})

gcloud run services update $K_SERVICE --platform managed --region ${GOOGLE_CLOUD_REGION} \
    --update-env-vars "CURRENT_HOST=${SERVICE_URL}"


echo "after: "
gcloud run services describe unicodex --region us-central1 --platform managed --project unicodex-prod | grep CURRENT_HOST
