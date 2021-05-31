#!/bin/bash -ex
shopt -s expand_aliases

# Generated from docs/ on 2021-05-31 05:11:36.660005
# no local install of git found
# execute with: bash -ex script.sh

# 00-test-local.md

# 10-setup-gcp.md
export PROJECT_ID=test
gcloud config set project $PROJECT_ID

gcloud config set run/platform managed

export REGION=us-central1
gcloud config set run/region $REGION

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

export SERVICE_NAME=unicodex

gcloud iam service-accounts create $SERVICE_NAME \
  --display-name "$SERVICE_NAME service account"

export CLOUDRUN_SA=${SERVICE_NAME}@${PROJECT_ID}.iam.gserviceaccount.com

for role in cloudsql.client run.admin; do
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$CLOUDRUN_SA \
    --role roles/${role}
done

# 20-setup-sql.md
export INSTANCE_NAME=psql 
export ROOT_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)

gcloud sql instances create $INSTANCE_NAME \
  --database-version POSTGRES_11 \
  --tier db-f1-micro  \
  --region $REGION \
  --project $PROJECT_ID \
  --root-password $ROOT_PASSWORD

export DATABASE_INSTANCE=$PROJECT_ID:$REGION:$INSTANCE_NAME

export DATABASE_NAME=unicodex
gcloud sql databases create $DATABASE_NAME \
  --instance=$INSTANCE_NAME

export DBUSERNAME=unicodex-django
export DBPASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 40 | head -n 1)

gcloud sql users create $DBUSERNAME \
  --password $DBPASSWORD \
  --instance $INSTANCE_NAME

export DATABASE_URL=postgres://$DBUSERNAME:${DBPASSWORD}@//cloudsql/$PROJECT_ID:$REGION:$INSTANCE_NAME/$DATABASE_NAME

# 30-setup-bucket.md
export GS_BUCKET_NAME=${PROJECT_ID}-media

gsutil mb -l ${REGION} gs://${GS_BUCKET_NAME}

gsutil iam ch \
  serviceAccount:${CLOUDRUN_SA}:roles/storage.objectAdmin \
  gs://${GS_BUCKET_NAME} 

# 40-setup-secrets.md
export PROJECTNUM=$(gcloud projects describe ${PROJECT_ID} --format 'value(projectNumber)')
export CLOUDBUILD_SA=${PROJECTNUM}@cloudbuild.gserviceaccount.com

echo DATABASE_URL=\"${DATABASE_URL}\" > .env
echo GS_BUCKET_NAME=\"${GS_BUCKET_NAME}\" >> .env
echo SECRET_KEY=\"$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 50 | head -n 1)\" >> .env

gcloud secrets create django_settings --replication-policy automatic --data-file .env

gcloud secrets add-iam-policy-binding django_settings \
  --member serviceAccount:$CLOUDRUN_SA \
  --role roles/secretmanager.secretAccessor
  
  gcloud secrets add-iam-policy-binding django_settings \
  --member serviceAccount:$CLOUDBUILD_SA \
  --role roles/secretmanager.secretAccessor

export SUPERUSER="admin"
export SUPERPASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 30 | head -n 1)

for SECRET in SUPERUSER SUPERPASS; do
  gcloud secrets create $SECRET --replication-policy automatic
    
  echo -n "${!SECRET}" | gcloud secrets versions add $SECRET --data-file=-
    
  gcloud secrets add-iam-policy-binding $SECRET \
    --member serviceAccount:$CLOUDBUILD_SA \
    --role roles/secretmanager.secretAccessor
done 

# 50-first-deployment.md
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME .

gcloud run deploy $SERVICE_NAME \
  --allow-unauthenticated \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --add-cloudsql-instances $PROJECT_ID:$REGION:$INSTANCE_NAME \
  --service-account $CLOUDRUN_SA

export SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
  --format "value(status.url)")
	 
echo $SERVICE_URL

gcloud run services update $SERVICE_NAME \
  --update-env-vars "CURRENT_HOST=${SERVICE_URL}"

for role in cloudsql.client run.admin; do
  gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member serviceAccount:${CLOUDBUILD_SA} \
    --role roles/${role}
done

gcloud iam service-accounts add-iam-policy-binding ${CLOUDRUN_SA} \
  --member "serviceAccount:${CLOUDBUILD_SA}" \
  --role "roles/iam.serviceAccountUser"

# migrate and deploy
gcloud builds submit \
  --config .cloudbuild/build-migrate-deploy.yaml \
  --substitutions "_REGION=${REGION},_INSTANCE_NAME=${INSTANCE_NAME},_SERVICE=${SERVICE_NAME}"

# 60-ongoing-deployments.md

# 70-manual-deployments.md

# 80-automation.md

# 90-cleanup.md

# yy_styleguide.md

# zz_debugging.md

