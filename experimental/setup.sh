#!/bin/bash

# borrows heavily from fourkeys
# https://github.com/GoogleCloudPlatform/fourkeys/blob/main/experimental/terraform/setup.sh

# Sets up a parent project for CI work, and creates a new CI project for testing.

RANDOM_IDENTIFIER=$((RANDOM % 999999))

gcloud services enable \
    sqladmin.googleapis.com \
    cloudresourcemanager.googleapis.com \
    containerregistry.googleapis.com

export CI_REGION=us-central1
export PARENT_PROJECT=$(gcloud config get-value project)
export PARENT_PROJECTNUM=$(gcloud projects describe ${PARENT_PROJECT} --format='value(projectNumber)')
export BILLING_ACCOUNT=$(gcloud beta billing projects describe ${PARENT_PROJECT} --format="value(billingAccountName)" || sed -e 's/.*\///g')

SA_NAME=ci-service-account
SA_EMAIL=$(gcloud iam service-accounts list --filter $SA_NAME --format 'value(email)')
if [ -z "$SA_EMAIL" ]; then
    gcloud iam service-accounts create $SA_NAME --project $PARENT_PROJECT
    SA_EMAIL=$(gcloud iam service-accounts list --filter $SA_NAME --format 'value(email)')
else
    echo "Service account $SA_EMAIL already exists. Skipping"
fi

LOGS_BUCKET=gs://${PARENT_PROJECT}-ci-logs

if gsutil ls $LOGS_BUCKET 2>&1 | grep -q 'BucketNotFoundException'; then
    gsutil mb -p $PARENT_PROJECT $LOGS_BUCKET
else
    echo "Bucket $LOGS_BUCKET already exists. Skipping"
fi

export CI_PROJECT=$(printf "unicodex-ci-%06d" $RANDOM_IDENTIFIER)
gcloud projects create ${CI_PROJECT}
gcloud beta billing projects link ${CI_PROJECT} --billing-account=${BILLING_ACCOUNT}

gcloud projects add-iam-policy-binding $CI_PROJECT \
    --member serviceAccount:${SA_EMAIL} \
    --role roles/owner

# Too many permissions, needs fixing

gcloud projects add-iam-policy-binding $PARENT_PROJECT \
    --member serviceAccount:${SA_EMAIL} \
    --role roles/owner

DEFAULT_GCB=$PARENT_PROJECTNUM@cloudbuild.gserviceaccount.com

gsutil iam ch \
    serviceAccount:${DEFAULT_GCB}:roles/storage.objectAdmin \
    $LOGS_BUCKET

TF_STATE_BUCKET=gs://${CI_PROJECT}-tfstate
gsutil mb -p ${CI_PROJECT} $TF_STATE_BUCKET

echo "CI_PROJECT ${CI_PROJECT} is now ready to use."
echo "TF_STATE_BUCKET is $TF_STATE_BUCKET"
