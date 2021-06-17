#!/bin/bash

# borrows heavily from fourkeys
# https://github.com/GoogleCloudPlatform/fourkeys/blob/main/experimental/terraform/setup.sh

# Sets up a parent project for CI work
source .util/bash_helpers.sh

export PARENT_PROJECT=$(gcloud config get-value project)
echo "🔨 configure parent project $PARENT_PROJECT"

export PARENT_PROJECTNUM=$(gcloud projects describe ${PARENT_PROJECT} --format='value(projectNumber)')
export DEFAULT_GCB=$PARENT_PROJECTNUM@cloudbuild.gserviceaccount.com

stepdo "Enable services on parent"
gcloud services enable --project $PARENT_PROJECT  \
    sqladmin.googleapis.com \
    cloudresourcemanager.googleapis.com \
    containerregistry.googleapis.com
stepdone

stepdo "Create service account"
SA_NAME=ci-serviceaccount
SA_EMAIL=$(gcloud iam service-accounts list --filter $SA_NAME --format 'value(email)')
if [ -z "$SA_EMAIL" ]; then
    gcloud iam service-accounts create $SA_NAME --project $PARENT_PROJECT
    SA_EMAIL=$(gcloud iam service-accounts list --filter $SA_NAME --format 'value(email)')
else
    echo "Service account $SA_EMAIL already exists. Skipping"
fi
stepdone

stepdo "Create CI logs bucket"
LOGS_BUCKET=gs://${PARENT_PROJECT}-buildlogs

if gsutil ls $LOGS_BUCKET 2>&1 | grep -q 'BucketNotFoundException'; then
    gsutil mb -p $PARENT_PROJECT $LOGS_BUCKET

    gsutil iam ch \
        serviceAccount:${DEFAULT_GCB}:roles/storage.objectAdmin \
        $LOGS_BUCKET
else
    echo "Bucket $LOGS_BUCKET already exists. Skipping"
fi
stepdone

stepdo "Grant access to default logs bucket"
DEFAULT_BUCKET=${PARENT_PROJECT}_cloudbuild
gsutil iam ch \
        serviceAccount:${SA_EMAIL}:roles/storage.admin \
        gs://$DEFAULT_BUCKET