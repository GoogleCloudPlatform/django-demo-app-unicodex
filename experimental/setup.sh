#!/bin/bash

# borrows heavily from fourkeys
# https://github.com/GoogleCloudPlatform/fourkeys/blob/main/experimental/terraform/setup.sh

# Sets up a parent project for CI work, and creates a new CI project for testing.

source .util/bash_helpers.sh

CI_PREFIX=$1

export PARENT_PROJECT=$(gcloud config get-value project)
echo "🔨 configure parent project $PARENT_PROJECT"

export PARENT_PROJECTNUM=$(gcloud projects describe ${PARENT_PROJECT} --format='value(projectNumber)')
export BILLING_ACCOUNT=$(gcloud beta billing projects describe ${PARENT_PROJECT} --format="value(billingAccountName)" || sed -e 's/.*\///g')
export DEFAULT_GCB=$PARENT_PROJECTNUM@cloudbuild.gserviceaccount.com

stepdo "Enable services on parent"
gcloud services enable --project $PARENT_PROJECT  \
    sqladmin.googleapis.com \
    cloudresourcemanager.googleapis.com \
    containerregistry.googleapis.com
stepdone

stepdo "Create service account"
SA_NAME=ci-service-account
SA_EMAIL=$(gcloud iam service-accounts list --filter $SA_NAME --format 'value(email)')
if [ -z "$SA_EMAIL" ]; then
    gcloud iam service-accounts create $SA_NAME --project $PARENT_PROJECT
    SA_EMAIL=$(gcloud iam service-accounts list --filter $SA_NAME --format 'value(email)')
else
    echo "Service account $SA_EMAIL already exists. Skipping"
fi
stepdone

stepdo "Create CI logs bucket"
LOGS_BUCKET=gs://${PARENT_PROJECT}-ci-logs

if gsutil ls $LOGS_BUCKET 2>&1 | grep -q 'BucketNotFoundException'; then
    gsutil mb -p $PARENT_PROJECT $LOGS_BUCKET

    gsutil iam ch \
        serviceAccount:${DEFAULT_GCB}:roles/storage.objectAdmin \
        $LOGS_BUCKET
else
    echo "Bucket $LOGS_BUCKET already exists. Skipping"
fi
stepdone

stepdo "🔨 create CI project"
RANDOM_IDENTIFIER=$((RANDOM % 999999))
export CI_PROJECT=$(printf "unicodex-ci-%06d" $RANDOM_IDENTIFIER)-${CI_PREFIX:=manual}
gcloud projects create ${CI_PROJECT}
gcloud beta billing projects link ${CI_PROJECT} --billing-account=${BILLING_ACCOUNT}
stepdone

stepdo "assign IAM policies"
quiet gcloud projects add-iam-policy-binding $CI_PROJECT \
    --member serviceAccount:${SA_EMAIL} \
    --role roles/owner

# Too many permissions, needs fixing
quiet gcloud projects add-iam-policy-binding $PARENT_PROJECT \
    --member serviceAccount:${SA_EMAIL} \
    --role roles/owner
stepdone

stepdo "enable services on ci project"
gcloud services enable --project $CI_PROJECT \
    cloudresourcemanager.googleapis.com \
    containerregistry.googleapis.com
stepdone

echo ""
echo "✅ Project '${CI_PROJECT}' is now ready to use."
echo ""
