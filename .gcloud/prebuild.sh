#!/bin/bash
shopt -s expand_aliases

source .util/bash_helpers.sh

echo "🚀 Deploying $K_SERVICE to $GOOGLE_CLOUD_PROJECT in $GOOGLE_CLOUD_REGION"
export PROJECT_ID=$GOOGLE_CLOUD_PROJECT
gcloud config set project $PROJECT_ID
gcloud config set run/platform managed
export REGION=$GOOGLE_CLOUD_REGION
gcloud config set run/region $REGION
export SERVICE_NAME=$K_SERVICE
export INSTANCE_NAME=psql

stepdo "Enabling Google API services"
gcloud services enable \
  run.googleapis.com \
  iam.googleapis.com \
  compute.googleapis.com \
  sql-component.googleapis.com \
  sqladmin.googleapis.com \
  cloudbuild.googleapis.com \
  cloudkms.googleapis.com \
  cloudresourcemanager.googleapis.com \
  secretmanager.googleapis.com
stepdone

stepdo "Creating dedicated service account for $SERVICE_NAME"
gcloud iam service-accounts create $SERVICE_NAME \
  --display-name "$SERVICE_NAME service account"
stepdone

export CLOUDRUN_SA=${SERVICE_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
export PROJECTNUM=$(gcloud projects describe ${PROJECT_ID} --format 'value(projectNumber)')
export CLOUDBUILD_SA=${PROJECTNUM}@cloudbuild.gserviceaccount.com

stepdo "Grant IAM permissions to service accounts"
for role in cloudsql.client run.admin; do
  quiet gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$CLOUDRUN_SA \
    --role roles/${role}
  quiet gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member serviceAccount:${CLOUDBUILD_SA} \
    --role roles/${role}
done
quiet gcloud iam service-accounts add-iam-policy-binding ${CLOUDRUN_SA} \
  --member "serviceAccount:${CLOUDBUILD_SA}" \
  --role "roles/iam.serviceAccountUser"
stepdone

stepdo "Create SQL Instance (may take some time)"
export ROOT_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
export DATABASE_INSTANCE=$PROJECT_ID:$REGION:$INSTANCE_NAME
operation_id=$(gcloud sql instances create $INSTANCE_NAME \
  --database-version POSTGRES_13 --cpu 2 --memory 4GB  \
  --region $REGION \
  --project $PROJECT_ID \
  --root-password $ROOT_PASSWORD \
  --async --format="value(name)")
gcloud sql operations wait $operation_id --timeout=unlimited
stepdone

stepdo "Create SQL Database and User"
export DATABASE_NAME=unicodex
gcloud sql databases create $DATABASE_NAME \
  --instance=$INSTANCE_NAME
export DBUSERNAME=unicodex-django
export DBPASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 40 | head -n 1)
export DATABASE_URL=postgres://$DBUSERNAME:${DBPASSWORD}@//cloudsql/$PROJECT_ID:$REGION:$INSTANCE_NAME/$DATABASE_NAME
gcloud sql users create $DBUSERNAME \
  --password $DBPASSWORD \
  --instance $INSTANCE_NAME
stepdone

stepdo "Create Storage bucket"
export GS_BUCKET_NAME=${PROJECT_ID}-media
gsutil mb -l ${REGION} gs://${GS_BUCKET_NAME}
gsutil iam ch \
  serviceAccount:${CLOUDRUN_SA}:roles/storage.objectAdmin \
  gs://${GS_BUCKET_NAME} 
stepdone

stepdo "Creating Django settings secret, and allowing service access"
echo DATABASE_URL=\"${DATABASE_URL}\" > .env
echo GS_BUCKET_NAME=\"${GS_BUCKET_NAME}\" >> .env
echo SECRET_KEY=\"$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 50 | head -n 1)\" >> .env
gcloud secrets create django_settings --replication-policy automatic
gcloud secrets versions add django_settings --data-file .env
quiet gcloud secrets add-iam-policy-binding django_settings \
  --member serviceAccount:$CLOUDRUN_SA \
  --role roles/secretmanager.secretAccessor
quiet gcloud secrets add-iam-policy-binding django_settings \
  --member serviceAccount:$CLOUDBUILD_SA \
  --role roles/secretmanager.secretAccessor
rm .env
stepdone

stepdo "Creating Django admin user secrets, and allowing limited access"
export SUPERUSER="admin"
export SUPERPASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 30 | head -n 1)
for SECRET in SUPERUSER SUPERPASS; do
  gcloud secrets create $SECRET --replication-policy automatic
  echo -n "${!SECRET}" | gcloud secrets versions add $SECRET --data-file=-
  quiet gcloud secrets add-iam-policy-binding $SECRET \
    --member serviceAccount:$CLOUDBUILD_SA \
    --role roles/secretmanager.secretAccessor
done 
stepdone

echo "Pre-build provisioning complete ✨"
