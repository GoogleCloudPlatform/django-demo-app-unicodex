#!/bin/bash

TEST_TYPE=$1

CLOUDBUILD_CONFIG=experimental/${TEST_TYPE}_test.yaml

if [ ! -f "$CLOUDBUILD_CONFIG" ]; then
    echo "❌ No configuration for $CLOUDBUILD_CONFIG."
    return
fi

echo "⏩ Quick start a $TEST_TYPE build"

echo ".. running setup"
source experimental/setup.sh $TEST_TYPE


if [[ "$TEST_TYPE" == "terraform" ]]; then

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

fi

echo ""
echo "🚀 Deploying with $CI_PROJECT from $CLOUDBUILD_CONFIG"
echo ""

gcloud builds submit --config $CLOUDBUILD_CONFIG --substitutions _CI_PROJECT=${CI_PROJECT} --timeout 1500
statuscode=$?

if [ $statuscode -ne 0 ]; then 
    echo "Cloud Build Failed. It may not be recoverable."
    echo "If you wish to delete it and try again:"
else
    echo "✅ Success"
    echo "It is now safe to turn off your CI project:"
fi
echo ""
echo "gcloud projects delete $CI_PROJECT"
echo "" 