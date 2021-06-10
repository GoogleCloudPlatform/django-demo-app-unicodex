#!/bin/bash
source .util/bash_helpers.sh

TEST_TYPE=$1
PARENT_FOLDER=$2

PARENT_PROJECT=$(gcloud config get-value project)
CI_PROJECT_PREFIX=unicodex-ci
CLOUDBUILD_CONFIG=experimental/${TEST_TYPE}_test.yaml

if [ ! -f "$CLOUDBUILD_CONFIG" ]; then
    echo "❌ No configuration for $CLOUDBUILD_CONFIG."
    return
fi

echo "⏩ Quick start a $TEST_TYPE build"

stepdo "🔨 create CI project"
RANDOM_IDENTIFIER=$((RANDOM % 999999))
export CI_PROJECT=$(printf "%s-%06d" $CI_PROJECT_PREFIX $RANDOM_IDENTIFIER)-${TEST_TYPE:=manual}

if [[ -z $PARENT_FOLDER ]]
then PARENT_FOLDER=$(gcloud projects describe ${PARENT_PROJECT} --format="value(parent.id)")
fi

export BILLING_ACCOUNT=$(gcloud beta billing projects describe ${PARENT_PROJECT} --format="value(billingAccountName)" || sed -e 's/.*\///g')

gcloud projects create ${CI_PROJECT} --folder ${PARENT_FOLDER}
gcloud beta billing projects link ${CI_PROJECT} --billing-account=${BILLING_ACCOUNT}
stepdone

stepdo "assign IAM policies"
quiet gcloud projects add-iam-policy-binding $CI_PROJECT \
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


if [[ "$TEST_TYPE" == "terraform" ]]; then
    stepdo "setting up Terraform state bucket"
    TF_STATE_BUCKET=${CI_PROJECT}-tfstate
    gsutil mb -p ${CI_PROJECT} gs://$TF_STATE_BUCKET

    echo $TF_STATE_BUCKET exists now. Adding to terraform manifests

    cat > terraform/backend.tf <<_EOF
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
echo "🚀 Deploying with $CI_PROJECT from $CLOUDBUILD_CONFIG"
echo ""

gcloud builds submit --config $CLOUDBUILD_CONFIG --substitutions _CI_PROJECT=${CI_PROJECT} --timeout 1500
statuscode=$?

if [ $statuscode -ne 0 ]; then 
    echo "Cloud Build Failed. It may not be recoverable."
else
    echo "✅ Success"
    echo "It is now safe to turn off your CI project"
fi
gcloud projects delete $CI_PROJECT