#!/bin/bash -eux
#
# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

export DATABASE_URL=berglas://${BERGLAS_BUCKET}/database_url?destination=/secrets/database_url
export SECRET_KEY=berglas://${BERGLAS_BUCKET}/secret_key?destination=/secrets/secret_key
export MEDIA_BUCKET=berglas://${BERGLAS_BUCKET}/media_bucket?destination=/secrets/media_bucket

export SUPERUSER=berglas://${BERGLAS_BUCKET}/superuser?destination=/secrets/superuser
export SUPERPASS=berglas://${BERGLAS_BUCKET}/superpass?destination=/secrets/superpass

berglas exec --local -- /bin/sh

ENVFILE=/secrets/.env

touch $ENVFILE
echo "DATABASE_URL=$(cat /secrets/database_url)" >> $ENVFILE 
echo "SECRET_KEY=$(cat /secrets/secret_key)" >> $ENVFILE 
echo "GS_BUCKET_NAME=$(cat /secrets/media_bucket)" >> $ENVFILE 

DBFILE=/secrets/database
echo "$(cat /secrets/database_url | cut -d'/' -f6)" >> $DBFILE

echo "DEBUGGING: cat $ENVFILE"
for i in $(cat $ENVFILE); do echo $i | cut -d"=" -f1; done

echo "DEBUGGING: cat $DBFILE"
cat $DBFILE
echo "\nDEBUGGING: echo DATABASE_URL | cut -d'@' -f2"
echo $DATABASE_URL | cut -d'@' -f2
