#!/bin/bash
source .util/bash_helpers.sh

TEST_TYPE=$1
CI_PROJECT=$2
PARENT_FOLDER=$3

PARENT_PROJECT=$(gcloud config get-value project)
#CI_PROJECT_PREFIX=unicodex-ci
CLOUDBUILD_CONFIG=experimental/${TEST_TYPE}_test.yaml

if [ ! -f "$CLOUDBUILD_CONFIG" ]; then
    echo "❌ No configuration for $CLOUDBUILD_CONFIG."
    return
fi

echo "⏩ Quick start a $TEST_TYPE build on $CI_PROJECT"

SA_NAME=ci-serviceaccount
SA_EMAIL=$(gcloud iam service-accounts list --filter $SA_NAME --format 'value(email)')

#RANDOM_IDENTIFIER=${_CI_RANDOM:-$((RANDOM % 999999))
#export CI_PROJECT=$(printf "%s-%06d" $CI_PROJECT_PREFIX $RANDOM_IDENTIFIER)-${TEST_TYPE:=manual}

if [[ -z $PARENT_FOLDER ]]; then
    export PARENT_FOLDER=$(gcloud projects describe ${PARENT_PROJECT} --format="value(parent.id)")
fi

export BILLING_ACCOUNT=$(gcloud beta billing projects describe ${PARENT_PROJECT} --format="value(billingAccountName)" || sed -e 's/.*\///g')

stepdo "🔨 create CI project $CI_PROJECT"
gcloud projects create ${CI_PROJECT} --folder ${PARENT_FOLDER}
stepdone

stepdo "check IAM policies"
gcloud projects get-iam-policy ${CI_PROJECT}
stepdone

stepdo "assign IAM policies"
quiet gcloud projects add-iam-policy-binding $CI_PROJECT \
    --member serviceAccount:${SA_EMAIL} \
    --role roles/iam.serviceAccountTokenCreator
stepdone

stepdo "setup billing"
gcloud beta billing projects link ${CI_PROJECT} \
    --billing-account=${BILLING_ACCOUNT}
stepdone

stepdo "enable services on ci project"
gcloud services enable --project $CI_PROJECT \
    cloudresourcemanager.googleapis.com \
    containerregistry.googleapis.com \
    cloudbuild.googleapis.com
stepdone


if [[ "$TEST_TYPE" == "terraform" ]]; then
    stepdo "setting up Terraform state bucket"
    TF_STATE_BUCKET=${CI_PROJECT}-tfstate
    gsutil mb -p ${CI_PROJECT} gs://$TF_STATE_BUCKET

    echo $TF_STATE_BUCKET exists now. Adding to terraform manifests

    cat >terraform/backend.tf <<_EOF
terraform { 
  backend gcs {
    bucket = "$TF_STATE_BUCKET"
  }
}
_EOF
    cat terraform/backend.tf
    stepdone
fi


echo ""
echo "✅ Project '${CI_PROJECT}' is now ready to use."
echo ""

