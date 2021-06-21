#!/bin/bash
set -e

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

echo "⏩ Quick start a $TEST_TYPE"

SA_NAME=ci-serviceaccount
SA_EMAIL=$(gcloud iam service-accounts list --filter $SA_NAME --format 'value(email)')


RANDOM_IDENTIFIER=$((RANDOM % 999999))
export CI_PROJECT=$(printf "%s-%06d" $CI_PROJECT_PREFIX $RANDOM_IDENTIFIER)-${TEST_TYPE:=manual}

if [[ -z $PARENT_FOLDER ]]; then
    export PARENT_FOLDER=$(gcloud projects describe ${PARENT_PROJECT} --format="value(parent.id)")
    echo "🔍 Found folder ${PARENT_FOLDER} from ${PARENT_PROJECT}"
else
    echo "📦 Using provided $PARENT_FOLDER"
fi

export BILLING_ACCOUNT=$(gcloud beta billing projects describe ${PARENT_PROJECT} --format="value(billingAccountName)" || sed -e 's/.*\///g')

stepdo "🔨 create CI project $CI_PROJECT in folder $PARENT_FOLDER"
gcloud projects create ${CI_PROJECT} --folder ${PARENT_FOLDER}
stepdone

stepdo "assign IAM policies to service account"
quiet gcloud projects add-iam-policy-binding $CI_PROJECT \
    --member serviceAccount:${SA_EMAIL} \
    --role roles/iam.serviceAccountTokenCreator

quiet gcloud projects add-iam-policy-binding $CI_PROJECT \
    --member serviceAccount:${SA_EMAIL} \
    --role roles/iam.serviceAccountUser
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


stepdo "assign IAM owner role to Cloud Build service account"
CI_PROJECTNUMBER=$(gcloud projects describe ${CI_PROJECT} --format='value(projectNumber)')
CLOUDBUILD_SA=$CI_PROJECTNUMBER@cloudbuild.gserviceaccount.com
quiet gcloud projects add-iam-policy-binding $CI_PROJECT \
    --member serviceAccount:${CLOUDBUILD_SA} \
    --role roles/owner
stepdone

echo ""
echo "✅ Project '${CI_PROJECT}' is now ready to use."
echo ""

echo "Running $CLOUDBUILD_CONFIG in $CI_PROJECT"
gcloud builds submit \
    --config $CLOUDBUILD_CONFIG \
    --timeout 1500 \
    --project $CI_PROJECT
statuscode=$?

if [ $statuscode -ne 0 ]; then
    echo "Cloud Build Failed. It may not be recoverable."
else
    echo "✅ Success"
#   echo "It is now safe to turn off your CI project"
fi

#gcloud projects delete $CI_PROJECT --quiet

#echo "Project deleted."
