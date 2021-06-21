#!/bin/bash
set -e

source .util/bash_helpers.sh

TEST_TYPE=$1

CI_PROJECT=$2

CLOUDBUILD_CONFIG=experimental/${TEST_TYPE}_test.yaml

if [ ! -f "$CLOUDBUILD_CONFIG" ]; then
    echo "❌ No configuration for $CLOUDBUILD_CONFIG."
    return
fi

echo "Running $CLOUDBUILD_CONFIG in $CI_PROJECT"
gcloud builds submit \
    --config $CLOUDBUILD_CONFIG \
    --timeout 1500 \
    --project $CI_PROJECT --log-http --verbosity debug
statuscode=$?

if [ $statuscode -ne 0 ]; then
    echo "Cloud Build Failed. It may not be recoverable."
else
    echo "✅ Success"
#   echo "It is now safe to turn off your CI project"
fi
